#!/usr/bin/env bats

setup() {
  load "../helpers/test_helper"
  _common_setup

  SANDBOX="$(mktemp -d)"
  cd "$SANDBOX"

  source "$KAVEX_ROOT/hooks/lib/parse-failures.sh"
}

teardown() {
  rm -rf "$SANDBOX"
}

# --- parse_test_failures ---

@test "parse_test_failures: extracts Jest FAIL lines" {
  cat > output.log <<'EOF'
PASS src/utils.test.ts
FAIL src/auth.test.ts
  ● login should reject bad creds
    Expected: 401
    Received: 200
EOF
  local result
  result=$(parse_test_failures output.log)
  [[ "$result" == *"FAIL src/auth.test.ts"* ]]
  [[ "$result" == *"Expected"* ]]
  [[ "$result" == *"Received"* ]]
}

@test "parse_test_failures: extracts pytest FAILED lines" {
  cat > output.log <<'EOF'
FAILED tests/test_auth.py::test_login - assert 200 == 401
E       assert 200 == 401
EOF
  local result
  result=$(parse_test_failures output.log)
  [[ "$result" == *"FAILED tests/test_auth.py"* ]]
  [[ "$result" == *"assert"* ]]
}

@test "parse_test_failures: extracts Go test FAIL" {
  cat > output.log <<'EOF'
--- FAIL: TestLogin (0.01s)
    auth_test.go:42: expected 401 got 200
FAIL
EOF
  local result
  result=$(parse_test_failures output.log)
  [[ "$result" == *"FAIL: TestLogin"* ]]
}

@test "parse_test_failures: extracts Rust test FAILED" {
  cat > output.log <<'EOF'
test auth::test_login ... FAILED
thread 'auth::test_login' panicked at 'assertion failed'
EOF
  local result
  result=$(parse_test_failures output.log)
  [[ "$result" == *"test auth::test_login ... FAILED"* ]]
  [[ "$result" == *"panicked"* ]]
}

@test "parse_test_failures: empty on clean output" {
  cat > output.log <<'EOF'
PASS src/utils.test.ts
All tests passed
EOF
  local result
  result=$(parse_test_failures output.log)
  [ -z "$result" ]
}

# --- parse_lint_errors ---

@test "parse_lint_errors: extracts eslint-style errors" {
  cat > output.log <<'EOF'
src/foo.ts:10:5: error no-unused-vars
src/bar.ts:22:1: warning semi
EOF
  local result
  result=$(parse_lint_errors output.log)
  [[ "$result" == *"src/foo.ts:10:5: error"* ]]
  [[ "$result" == *"src/bar.ts:22:1: warning"* ]]
}

@test "parse_lint_errors: extracts ruff/flake8 errors" {
  cat > output.log <<'EOF'
src/foo.py:10:5: E501 line too long
src/bar.py:3:1: W291 trailing whitespace
EOF
  local result
  result=$(parse_lint_errors output.log)
  [[ "$result" == *"E501"* ]]
  [[ "$result" == *"W291"* ]]
}

@test "parse_lint_errors: extracts clippy errors" {
  cat > output.log <<'EOF'
error[E0308]: mismatched types
  --> src/main.rs:5:9
EOF
  local result
  result=$(parse_lint_errors output.log)
  [[ "$result" == *"error[E0308]"* ]]
}

# --- parse_type_errors ---

@test "parse_type_errors: extracts TypeScript TS errors" {
  cat > output.log <<'EOF'
src/foo.ts:10:5 - error TS2345: Argument of type 'string' is not assignable
src/bar.tsx:3:1 - error TS2304: Cannot find name 'Foo'
EOF
  local result
  result=$(parse_type_errors output.log)
  [[ "$result" == *"error TS2345"* ]]
  [[ "$result" == *"error TS2304"* ]]
}

@test "parse_type_errors: extracts mypy errors" {
  cat > output.log <<'EOF'
foo.py:10: error: Incompatible types in assignment
bar.py:5: note: See docs for more info
EOF
  local result
  result=$(parse_type_errors output.log)
  [[ "$result" == *"foo.py:10: error"* ]]
}

# --- parse_build_errors ---

@test "parse_build_errors: extracts module not found" {
  cat > output.log <<'EOF'
Module not found: Can't resolve './missing' in '/app/src'
Cannot find module '@/utils'
EOF
  local result
  result=$(parse_build_errors output.log)
  [[ "$result" == *"Module not found"* ]]
  [[ "$result" == *"Cannot find module"* ]]
}

@test "parse_build_errors: extracts Python ImportError" {
  cat > output.log <<'EOF'
ImportError: No module named 'nonexistent'
ModuleNotFoundError: No module named 'missing_pkg'
EOF
  local result
  result=$(parse_build_errors output.log)
  [[ "$result" == *"ImportError"* ]]
  [[ "$result" == *"ModuleNotFoundError"* ]]
}

# --- parse_all_failures ---

@test "parse_all_failures: writes structured output for test failures" {
  cat > input.log <<'EOF'
FAIL src/auth.test.ts
  Expected: 401
  Received: 200
EOF
  parse_all_failures input.log output.md
  [ -f output.md ]
  run cat output.md
  assert_output --partial "Test Failures"
  assert_output --partial "FAIL src/auth.test.ts"
}

@test "parse_all_failures: writes raw tail when no structured failures" {
  cat > input.log <<'EOF'
Everything is fine
No errors here
All good
EOF
  run parse_all_failures input.log output.md
  assert_failure
  [ -f output.md ]
  run cat output.md
  assert_output --partial "No structured failures detected"
}

@test "parse_all_failures: fails on missing input file" {
  run parse_all_failures nonexistent.log output.md
  assert_failure
  assert_output --partial "not found"
}
