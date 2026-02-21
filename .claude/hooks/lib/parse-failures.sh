#!/bin/bash
# parse-failures.sh — Parse verification output into structured diagnostics
# Source this file: source "$(dirname "$0")/lib/parse-failures.sh"
#
# Takes raw verification/test/lint output and extracts structured error info
# with file:line detail for targeted fix prompts.

# Parse test failures from various test runners
# Extracts: file, line, test name, expected/received
parse_test_failures() {
  local input_file="$1"
  local output=""

  # Jest/Vitest failures: "FAIL src/foo.test.ts" + assertion details
  while IFS= read -r line; do
    output="$output\n$line"
  done < <(grep -E '(FAIL |✕|✗|FAILED|AssertionError|Expected|Received|expect\(|assert)' "$input_file" 2>/dev/null | head -50)

  # Pytest failures: "FAILED tests/test_foo.py::test_bar"
  while IFS= read -r line; do
    output="$output\n$line"
  done < <(grep -E '(FAILED |ERROR |E\s+assert|>.*assert|tests/.*::)' "$input_file" 2>/dev/null | head -50)

  # Go test failures: "--- FAIL: TestFoo (0.00s)"
  while IFS= read -r line; do
    output="$output\n$line"
  done < <(grep -E '(--- FAIL:|FAIL\s|panic:)' "$input_file" 2>/dev/null | head -30)

  # Rust test failures: "test foo::bar ... FAILED"
  while IFS= read -r line; do
    output="$output\n$line"
  done < <(grep -E '(test .* FAILED|panicked at|thread .* panicked)' "$input_file" 2>/dev/null | head -30)

  # RSpec failures: "rspec ./spec/foo_spec.rb:42"
  while IFS= read -r line; do
    output="$output\n$line"
  done < <(grep -E '(rspec \./|Failure/Error:|expected:|got:)' "$input_file" 2>/dev/null | head -30)

  echo -e "$output" | grep -v '^$' || true
}

# Parse lint errors from various linters
parse_lint_errors() {
  local input_file="$1"
  local output=""

  # ESLint: "src/foo.ts:10:5: error ..."
  # Ruff/Flake8: "src/foo.py:10:5: E501 ..."
  # golangci-lint: "foo.go:10:5: ..."
  # Clippy: "error[E0308]: ..."
  # RuboCop: "foo.rb:10:5: C: ..."
  while IFS= read -r line; do
    output="$output\n$line"
  done < <(grep -E '(:[0-9]+:[0-9]+:?\s*(error|warning|Error|Warning|E[0-9]|W[0-9]|C:|F:)|error\[E[0-9]+\])' "$input_file" 2>/dev/null | head -50)

  echo -e "$output" | grep -v '^$' || true
}

# Parse type errors from various type checkers
parse_type_errors() {
  local input_file="$1"
  local output=""

  # TypeScript: "src/foo.ts(10,5): error TS2345:"
  while IFS= read -r line; do
    output="$output\n$line"
  done < <(grep -E '(error TS[0-9]+|\.ts[x]?\([0-9]+,[0-9]+\)|\.ts[x]?:[0-9]+:[0-9]+)' "$input_file" 2>/dev/null | head -50)

  # Mypy/Pyright: "foo.py:10: error: ..."
  while IFS= read -r line; do
    output="$output\n$line"
  done < <(grep -E '\.py:[0-9]+:?\s*(error|note):' "$input_file" 2>/dev/null | head -30)

  # Go vet: "foo.go:10:5: ..."
  while IFS= read -r line; do
    output="$output\n$line"
  done < <(grep -E '\.go:[0-9]+:[0-9]+:' "$input_file" 2>/dev/null | head -30)

  echo -e "$output" | grep -v '^$' || true
}

# Parse build errors
parse_build_errors() {
  local input_file="$1"
  local output=""

  # Common build error patterns across languages
  while IFS= read -r line; do
    output="$output\n$line"
  done < <(grep -E '(Cannot find module|Module not found|undefined reference|unresolved import|cannot find|error\[|BUILD FAILED|Compilation failed|SyntaxError|ImportError|ModuleNotFoundError)' "$input_file" 2>/dev/null | head -30)

  echo -e "$output" | grep -v '^$' || true
}

# Main entry point: parse all failures from verification output
# Usage: parse_all_failures <input_file> <output_file>
# Returns 0 if failures were found (and written), 1 if no failures detected
parse_all_failures() {
  local input_file="$1"
  local output_file="$2"

  if ! [ -f "$input_file" ]; then
    echo "ERROR: Input file not found: $input_file" >&2
    return 1
  fi

  local has_failures=false

  {
    echo "# Parsed Failures — $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""

    local test_failures
    test_failures=$(parse_test_failures "$input_file")
    if [ -n "$test_failures" ]; then
      has_failures=true
      echo "## Test Failures"
      echo '```'
      echo "$test_failures"
      echo '```'
      echo ""
    fi

    local lint_errors
    lint_errors=$(parse_lint_errors "$input_file")
    if [ -n "$lint_errors" ]; then
      has_failures=true
      echo "## Lint Errors"
      echo '```'
      echo "$lint_errors"
      echo '```'
      echo ""
    fi

    local type_errors
    type_errors=$(parse_type_errors "$input_file")
    if [ -n "$type_errors" ]; then
      has_failures=true
      echo "## Type Errors"
      echo '```'
      echo "$type_errors"
      echo '```'
      echo ""
    fi

    local build_errors
    build_errors=$(parse_build_errors "$input_file")
    if [ -n "$build_errors" ]; then
      has_failures=true
      echo "## Build Errors"
      echo '```'
      echo "$build_errors"
      echo '```'
      echo ""
    fi

    if ! $has_failures; then
      echo "## No structured failures detected"
      echo ""
      echo "Raw output tail (last 50 lines):"
      echo '```'
      tail -50 "$input_file"
      echo '```'
    fi
  } > "$output_file"

  if $has_failures; then
    return 0
  else
    return 1
  fi
}
