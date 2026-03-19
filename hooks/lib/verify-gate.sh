#!/bin/bash
# verify-gate.sh — Standalone verification gate for Kavex Smart Loop
# Source this file: source "$(dirname "$0")/lib/verify-gate.sh"
#
# Runs the same 7-layer verification as verify-on-stop.sh but:
#   - Returns exit code (0=pass, non-zero=fail)
#   - Writes full output to a capture file for parsing
#   - No retry counter, no self-healing spawn
#   - Pure "run checks, return results"
#
# Prerequisites: detect-stack.sh must be sourced first (detect_pm, detect_languages)

# Run the full 7-layer verification gate
# Usage: run_verify_gate <capture_file>
# Sets: FAILURES (count), RESULTS (formatted string)
# Returns: 0 if all pass, 1 if any fail
run_verify_gate() {
  local capture_file="$1"
  FAILURES=0
  RESULTS=""

  # Clear capture file
  : > "$capture_file"

  # Ensure stack is detected
  if [ -z "$LANGS" ]; then
    detect_pm
    detect_languages
  fi

  # --- Layer 1: Build ---
  if [ -n "$PM" ] && [ -n "$(pkg_field '.scripts.build')" ]; then
    run_and_report_capture 1 "Build ($PM)" "$capture_file" "$PM" run build
  elif has_lang go;     then run_and_report_capture 1 "Build (go)" "$capture_file" go build ./...
  elif has_lang rust;   then run_and_report_capture 1 "Build (cargo)" "$capture_file" cargo build
  elif has_lang java; then
    if [ -f "pom.xml" ]; then
      run_and_report_capture 1 "Build (maven)" "$capture_file" mvn compile -q
    else
      run_and_report_capture 1 "Build (gradle)" "$capture_file" gradle build -q
    fi
  elif has_lang dotnet; then run_and_report_capture 1 "Build (dotnet)" "$capture_file" dotnet build --nologo -v q
  else RESULTS="$RESULTS\n[1] SKIP — No build system detected"
  fi

  # --- Layer 2: Unit Tests (with retry + capture) ---
  if [ -n "$PM" ]; then
    if [ -n "$(pkg_field '.scripts["test:unit"]')" ]; then
      run_and_retry_capture 2 "Unit tests ($PM)" "$capture_file" "$PM" run test:unit
    elif [ -n "$(pkg_field '.devDependencies.vitest // .dependencies.vitest')" ]; then
      run_and_retry_capture 2 "Vitest" "$capture_file" "$PM" run test -- --run
    elif [ -n "$(pkg_field '.devDependencies.jest // .dependencies.jest')" ]; then
      run_and_retry_capture 2 "Jest" "$capture_file" "$PM" run test
    elif [ -n "$(pkg_field '.scripts.test')" ]; then
      run_and_retry_capture 2 "Tests ($PM)" "$capture_file" "$PM" run test
    fi
  fi
  has_lang python && command -v pytest &>/dev/null && run_and_retry_capture 2 "Pytest" "$capture_file" pytest --tb=short -q
  has_lang go      && run_and_retry_capture 2 "Go tests" "$capture_file" go test ./...
  has_lang rust    && run_and_retry_capture 2 "Cargo tests" "$capture_file" cargo test
  has_lang ruby    && command -v rspec &>/dev/null && run_and_retry_capture 2 "RSpec" "$capture_file" bundle exec rspec
  has_lang java && {
    if [ -f "pom.xml" ]; then
      run_and_retry_capture 2 "Maven tests" "$capture_file" mvn test -q
    else
      run_and_retry_capture 2 "Gradle tests" "$capture_file" gradle test -q
    fi
  }
  has_lang dotnet  && run_and_retry_capture 2 "Dotnet tests" "$capture_file" dotnet test --nologo -v q
  echo -e "$RESULTS" | grep -q '\[2\]' || RESULTS="$RESULTS\n[2] SKIP — No unit test runner"

  # --- Layer 3: Integration Tests (with retry + capture) ---
  if [ -n "$PM" ] && [ -n "$(pkg_field '.scripts["test:integration"]')" ]; then
    run_and_retry_capture 3 "Integration tests" "$capture_file" "$PM" run test:integration
  else
    RESULTS="$RESULTS\n[3] SKIP — No integration test script"
  fi

  # --- Layer 4: E2E Tests (Playwright) ---
  local HAS_PW=""
  [ -n "$PM" ] && HAS_PW=$(pkg_field '.devDependencies["@playwright/test"] // .dependencies["@playwright/test"]')
  if [ -n "$HAS_PW" ]; then
    if [ -n "$(pkg_field '.scripts["test:e2e"] // .scripts.e2e')" ]; then
      run_and_retry_capture 4 "Playwright E2E" "$capture_file" "$PM" run test:e2e
    elif [ -f "playwright.config.ts" ] || [ -f "playwright.config.js" ]; then
      run_and_retry_capture 4 "Playwright E2E" "$capture_file" npx playwright test
    fi
  else
    RESULTS="$RESULTS\n[4] SKIP — No Playwright installed"
  fi

  # --- Layer 5: Lint ---
  if [ -n "$PM" ] && [ -n "$(pkg_field '.scripts.lint')" ]; then
    run_and_report_capture 5 "Lint ($PM)" "$capture_file" "$PM" run lint
  fi
  has_lang python && {
    command -v ruff &>/dev/null && run_and_report_capture 5 "Ruff" "$capture_file" ruff check .
    ! command -v ruff &>/dev/null && command -v flake8 &>/dev/null && run_and_report_capture 5 "Flake8" "$capture_file" flake8 .
  }
  has_lang go     && command -v golangci-lint &>/dev/null && run_and_report_capture 5 "Go lint" "$capture_file" golangci-lint run
  has_lang rust   && run_and_report_capture 5 "Clippy" "$capture_file" cargo clippy -- -D warnings
  has_lang ruby   && command -v rubocop &>/dev/null && run_and_report_capture 5 "RuboCop" "$capture_file" rubocop
  has_lang dotnet && run_and_report_capture 5 "Dotnet format" "$capture_file" dotnet format --verify-no-changes --nologo -v q
  echo -e "$RESULTS" | grep -q '\[5\]' || RESULTS="$RESULTS\n[5] SKIP — No linter"

  # --- Layer 6: Type Check ---
  if [ -n "$PM" ]; then
    local TC_SCRIPT
    TC_SCRIPT=$(pkg_field '.scripts.typecheck // .scripts["type-check"]')
    if [ -n "$TC_SCRIPT" ]; then
      run_and_report_capture 6 "Type check ($PM)" "$capture_file" "$PM" run typecheck
    elif [ -f "tsconfig.json" ]; then
      run_and_report_capture 6 "tsc --noEmit" "$capture_file" npx tsc --noEmit
    fi
  fi
  has_lang python && {
    command -v mypy &>/dev/null && run_and_report_capture 6 "Mypy" "$capture_file" mypy .
    ! command -v mypy &>/dev/null && command -v pyright &>/dev/null && run_and_report_capture 6 "Pyright" "$capture_file" pyright
  }
  has_lang go   && run_and_report_capture 6 "Go vet" "$capture_file" go vet ./...
  has_lang rust && run_and_report_capture 6 "Cargo check" "$capture_file" cargo check
  echo -e "$RESULTS" | grep -q '\[6\]' || RESULTS="$RESULTS\n[6] SKIP — No type checker"

  # --- Layer 7: Security Audit (warn only) ---
  if [ -n "$PM" ] && { [ -f "package-lock.json" ] || [ -f "pnpm-lock.yaml" ] || [ -f "yarn.lock" ] || [ -f "bun.lockb" ]; }; then
    if [ "$PM" = "yarn" ]; then
      run_and_warn_capture 7 "Security audit (yarn)" "$capture_file" yarn audit --level high
    else
      run_and_warn_capture 7 "Security audit ($PM)" "$capture_file" "$PM" audit --audit-level=high
    fi
  fi
  has_lang python && command -v pip-audit &>/dev/null    && run_and_warn_capture 7 "Pip audit" "$capture_file" pip-audit
  has_lang rust   && command -v cargo-audit &>/dev/null   && run_and_warn_capture 7 "Cargo audit" "$capture_file" cargo audit
  has_lang ruby   && command -v bundle-audit &>/dev/null  && run_and_warn_capture 7 "Bundle audit" "$capture_file" bundle-audit check
  has_lang go     && command -v govulncheck &>/dev/null   && run_and_warn_capture 7 "Go vulncheck" "$capture_file" govulncheck ./...
  echo -e "$RESULTS" | grep -q '\[7\]' || RESULTS="$RESULTS\n[7] SKIP — No security auditor"

  # --- Report ---
  echo "" >&2
  echo "========================================" >&2
  echo " VERIFY GATE" >&2
  echo "========================================" >&2
  echo -e "$RESULTS" >&2
  echo "========================================" >&2

  if [ $FAILURES -gt 0 ]; then
    return 1
  fi
  return 0
}
