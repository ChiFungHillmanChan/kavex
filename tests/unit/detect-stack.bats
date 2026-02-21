#!/usr/bin/env bats

setup() {
  load "../helpers/test_helper"
  _common_setup

  SANDBOX="$(mktemp -d)"
  cd "$SANDBOX"

  source "$KOVA_ROOT/.claude/hooks/lib/detect-stack.sh"
}

teardown() {
  rm -rf "$SANDBOX"
}

# --- detect_pm ---

@test "detect_pm: empty dir yields empty PM" {
  detect_pm
  assert_equal "$PM" ""
}

@test "detect_pm: package.json alone yields npm" {
  echo '{}' > package.json
  detect_pm
  assert_equal "$PM" "npm"
}

@test "detect_pm: pnpm-lock.yaml yields pnpm" {
  echo '{}' > package.json
  touch pnpm-lock.yaml
  detect_pm
  assert_equal "$PM" "pnpm"
}

@test "detect_pm: yarn.lock yields yarn" {
  echo '{}' > package.json
  touch yarn.lock
  detect_pm
  assert_equal "$PM" "yarn"
}

@test "detect_pm: bun.lockb yields bun" {
  touch bun.lockb
  detect_pm
  assert_equal "$PM" "bun"
}

@test "detect_pm: bunfig.toml yields bun" {
  touch bunfig.toml
  detect_pm
  assert_equal "$PM" "bun"
}

@test "detect_pm: bun takes precedence over npm" {
  echo '{}' > package.json
  touch bun.lockb
  detect_pm
  assert_equal "$PM" "bun"
}

# --- detect_languages ---

@test "detect_languages: empty dir yields empty LANGS" {
  detect_languages
  assert_equal "$LANGS" ""
}

@test "detect_languages: package.json yields node" {
  echo '{}' > package.json
  detect_languages
  assert_equal "$LANGS" "node"
}

@test "detect_languages: go.mod yields go" {
  echo 'module test' > go.mod
  detect_languages
  assert_equal "$LANGS" "go"
}

@test "detect_languages: Cargo.toml yields rust" {
  touch Cargo.toml
  detect_languages
  assert_equal "$LANGS" "rust"
}

@test "detect_languages: pyproject.toml yields python" {
  touch pyproject.toml
  detect_languages
  assert_equal "$LANGS" "python"
}

@test "detect_languages: requirements.txt yields python" {
  touch requirements.txt
  detect_languages
  assert_equal "$LANGS" "python"
}

@test "detect_languages: setup.py yields python" {
  touch setup.py
  detect_languages
  assert_equal "$LANGS" "python"
}

@test "detect_languages: Pipfile yields python" {
  touch Pipfile
  detect_languages
  assert_equal "$LANGS" "python"
}

@test "detect_languages: Gemfile yields ruby" {
  touch Gemfile
  detect_languages
  assert_equal "$LANGS" "ruby"
}

@test "detect_languages: pom.xml yields java" {
  touch pom.xml
  detect_languages
  assert_equal "$LANGS" "java"
}

@test "detect_languages: build.gradle yields java" {
  touch build.gradle
  detect_languages
  assert_equal "$LANGS" "java"
}

@test "detect_languages: build.gradle.kts yields java" {
  touch build.gradle.kts
  detect_languages
  assert_equal "$LANGS" "java"
}

@test "detect_languages: multiple ecosystems detected" {
  echo '{}' > package.json
  touch pyproject.toml
  echo 'module test' > go.mod
  detect_languages
  [[ "$LANGS" == *"node"* ]]
  [[ "$LANGS" == *"python"* ]]
  [[ "$LANGS" == *"go"* ]]
}

# --- has_lang ---

@test "has_lang: returns true for detected language" {
  echo '{}' > package.json
  detect_languages
  has_lang "node"
}

@test "has_lang: returns false for undetected language" {
  detect_languages
  ! has_lang "rust"
}

# --- project_hash ---

@test "project_hash: produces non-empty deterministic hash" {
  local h1 h2
  h1=$(project_hash "/tmp/test-project")
  h2=$(project_hash "/tmp/test-project")
  assert_equal "$h1" "$h2"
  [ -n "$h1" ]
}

@test "project_hash: different paths produce different hashes" {
  local h1 h2
  h1=$(project_hash "/tmp/project-a")
  h2=$(project_hash "/tmp/project-b")
  [ "$h1" != "$h2" ]
}

# --- pkg_field ---

@test "pkg_field: reads existing script from package.json" {
  cat > package.json <<'EOF'
{"scripts": {"build": "tsc", "test": "vitest"}}
EOF
  local val
  val=$(pkg_field '.scripts.build')
  assert_equal "$val" "tsc"
}

@test "pkg_field: returns empty for missing field" {
  cat > package.json <<'EOF'
{"scripts": {"test": "jest"}}
EOF
  local val
  val=$(pkg_field '.scripts.build')
  assert_equal "$val" ""
}

@test "pkg_field: returns empty when no package.json" {
  local val
  val=$(pkg_field '.scripts.build' || true)
  assert_equal "$val" ""
}
