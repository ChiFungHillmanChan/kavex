#!/usr/bin/env bats

setup() {
  load "../helpers/test_helper"
  _common_setup

  SANDBOX="$(mktemp -d)"
  cd "$SANDBOX"

  source "$KAVEX_ROOT/hooks/lib/codex-assist.sh"
}

teardown() {
  rm -rf "$SANDBOX"
}

# --- codex_available ---

@test "codex_available: returns 1 when codex is not installed" {
  run env PATH="/usr/bin:/bin" /bin/bash -c "source '$KAVEX_ROOT/hooks/lib/codex-assist.sh' && codex_available"
  assert_failure
}

@test "codex_available: returns 0 when stub codex is on PATH" {
  mkdir -p "$SANDBOX/bin"
  printf '#!/bin/bash\necho "stub"\n' > "$SANDBOX/bin/codex"
  chmod +x "$SANDBOX/bin/codex"
  run env PATH="$SANDBOX/bin:/usr/bin:/bin" /bin/bash -c "source '$KAVEX_ROOT/hooks/lib/codex-assist.sh' && codex_available"
  assert_success
}

# --- codex_diagnose ---

@test "codex_diagnose: returns 1 when codex is not available" {
  run env PATH="/usr/bin:/bin" /bin/bash -c "source '$KAVEX_ROOT/hooks/lib/codex-assist.sh' && codex_diagnose /dev/null /dev/null"
  assert_failure
}

@test "codex_diagnose: returns 1 when context file is missing" {
  mkdir -p "$SANDBOX/bin"
  printf '#!/bin/bash\necho "diagnosis"\n' > "$SANDBOX/bin/codex"
  chmod +x "$SANDBOX/bin/codex"
  run env PATH="$SANDBOX/bin:/usr/bin:/bin" /bin/bash -c "source '$KAVEX_ROOT/hooks/lib/codex-assist.sh' && codex_diagnose '$SANDBOX/nonexistent.md' '$SANDBOX/out.md'"
  assert_failure
}

@test "codex_diagnose: returns 1 when context file is empty" {
  mkdir -p "$SANDBOX/bin"
  printf '#!/bin/bash\necho "diagnosis"\n' > "$SANDBOX/bin/codex"
  chmod +x "$SANDBOX/bin/codex"
  touch "$SANDBOX/empty.md"
  run env PATH="$SANDBOX/bin:/usr/bin:/bin" /bin/bash -c "source '$KAVEX_ROOT/hooks/lib/codex-assist.sh' && codex_diagnose '$SANDBOX/empty.md' '$SANDBOX/out.md'"
  assert_failure
}

@test "codex_diagnose: writes diagnosis on success" {
  mkdir -p "$SANDBOX/bin"
  cat > "$SANDBOX/bin/codex" << 'STUB'
#!/bin/bash
echo "The root cause is a missing null check on line 42."
STUB
  chmod +x "$SANDBOX/bin/codex"
  echo "Test failure: cannot read property of undefined" > "$SANDBOX/context.md"

  run env PATH="$SANDBOX/bin:/usr/bin:/bin" /bin/bash -c "source '$KAVEX_ROOT/hooks/lib/codex-assist.sh' && codex_diagnose '$SANDBOX/context.md' '$SANDBOX/out.md'"
  assert_success
  run cat "$SANDBOX/out.md"
  assert_output --partial "Cross-Model Diagnosis [codex]"
  assert_output --partial "missing null check"
}

@test "codex_diagnose: returns 1 when codex produces empty output" {
  mkdir -p "$SANDBOX/bin"
  cat > "$SANDBOX/bin/codex" << 'STUB'
#!/bin/bash
# Output nothing
STUB
  chmod +x "$SANDBOX/bin/codex"
  echo "Some failure" > "$SANDBOX/context.md"

  run env PATH="$SANDBOX/bin:/usr/bin:/bin" /bin/bash -c "source '$KAVEX_ROOT/hooks/lib/codex-assist.sh' && codex_diagnose '$SANDBOX/context.md' '$SANDBOX/out.md'"
  assert_failure
}

@test "codex_diagnose: returns 1 on timeout" {
  mkdir -p "$SANDBOX/bin"
  cat > "$SANDBOX/bin/codex" << 'STUB'
#!/bin/bash
exec sleep 30
STUB
  chmod +x "$SANDBOX/bin/codex"
  echo "Some failure" > "$SANDBOX/context.md"

  run env PATH="$SANDBOX/bin:/usr/bin:/bin" CODEX_TIMEOUT=1 /bin/bash -c "source '$KAVEX_ROOT/hooks/lib/codex-assist.sh' && codex_diagnose '$SANDBOX/context.md' '$SANDBOX/out.md'"
  assert_failure
}

@test "codex_diagnose: caps input at 500 lines" {
  mkdir -p "$SANDBOX/bin"
  cat > "$SANDBOX/bin/codex" << 'STUB'
#!/bin/bash
echo "diagnosis output"
STUB
  chmod +x "$SANDBOX/bin/codex"

  # Create a file with 600 lines
  seq 1 600 > "$SANDBOX/big-context.md"

  run env PATH="$SANDBOX/bin:/usr/bin:/bin" /bin/bash -c "source '$KAVEX_ROOT/hooks/lib/codex-assist.sh' && codex_diagnose '$SANDBOX/big-context.md' '$SANDBOX/out.md'"
  assert_success
}

# --- codex_review ---

@test "codex_review: returns 1 when codex is not available" {
  run env PATH="/usr/bin:/bin" /bin/bash -c "source '$KAVEX_ROOT/hooks/lib/codex-assist.sh' && codex_review /dev/null /dev/null"
  assert_failure
}

@test "codex_review: returns 1 when diff file is missing" {
  mkdir -p "$SANDBOX/bin"
  printf '#!/bin/bash\necho "review"\n' > "$SANDBOX/bin/codex"
  chmod +x "$SANDBOX/bin/codex"
  run env PATH="$SANDBOX/bin:/usr/bin:/bin" /bin/bash -c "source '$KAVEX_ROOT/hooks/lib/codex-assist.sh' && codex_review '$SANDBOX/nonexistent.diff' '$SANDBOX/out.md'"
  assert_failure
}

@test "codex_review: writes review on success" {
  mkdir -p "$SANDBOX/bin"
  cat > "$SANDBOX/bin/codex" << 'STUB'
#!/bin/bash
echo "SEVERITY: CLEAN"
echo "No issues found."
STUB
  chmod +x "$SANDBOX/bin/codex"
  echo "+console.log('hello')" > "$SANDBOX/diff.txt"

  run env PATH="$SANDBOX/bin:/usr/bin:/bin" /bin/bash -c "source '$KAVEX_ROOT/hooks/lib/codex-assist.sh' && codex_review '$SANDBOX/diff.txt' '$SANDBOX/out.md'"
  assert_success
  run cat "$SANDBOX/out.md"
  assert_output --partial "Cross-Model Review [codex]"
  assert_output --partial "SEVERITY: CLEAN"
}

@test "codex_review: returns 1 when codex fails" {
  mkdir -p "$SANDBOX/bin"
  cat > "$SANDBOX/bin/codex" << 'STUB'
#!/bin/bash
exit 1
STUB
  chmod +x "$SANDBOX/bin/codex"
  echo "+some code" > "$SANDBOX/diff.txt"

  run env PATH="$SANDBOX/bin:/usr/bin:/bin" /bin/bash -c "source '$KAVEX_ROOT/hooks/lib/codex-assist.sh' && codex_review '$SANDBOX/diff.txt' '$SANDBOX/out.md'"
  assert_failure
}

# --- _codex_run_with_timeout ---

@test "_codex_run_with_timeout: returns command exit code on success" {
  run _codex_run_with_timeout 5 echo "hello"
  assert_success
  assert_output "hello"
}

@test "_codex_run_with_timeout: returns 124 on timeout" {
  local rc=0
  _codex_run_with_timeout 1 sleep 30 || rc=$?
  assert_equal "$rc" "124"
}
