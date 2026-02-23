#!/usr/bin/env bats
# Regression test: demo.tape must exist and be a valid VHS tape file.
# Covers full lifecycle: install → activate → implement → bug catch → self-heal → commit.

setup() {
  load "../helpers/test_helper"
  _common_setup
}

# ── File existence ──

@test "demo.tape exists at project root" {
  [ -f "$KOVA_ROOT/demo.tape" ]
}

@test "demo.tape does not exceed 300 lines" {
  local lines
  lines="$(wc -l < "$KOVA_ROOT/demo.tape")"
  [ "$lines" -le 300 ]
}

# ── VHS structure ──

@test "demo.tape contains required VHS Set directives" {
  run grep -c '^Set ' "$KOVA_ROOT/demo.tape"
  assert_success
  # Should have at least the basic settings (Shell, FontSize, Width, Height, etc.)
  [ "$output" -ge 5 ]
}

# ── Scene 1: Install ──

@test "demo.tape shows install command" {
  run grep 'curl.*install' "$KOVA_ROOT/demo.tape"
  assert_success
}

@test "demo.tape shows install output with hooks" {
  run grep 'Installing hooks' "$KOVA_ROOT/demo.tape"
  assert_success
}

# ── Scene 2: Activate ──

@test "demo.tape contains Type commands for kova activate" {
  run grep 'Type.*kova activate' "$KOVA_ROOT/demo.tape"
  assert_success
}

@test "demo.tape contains Type commands for kova status" {
  run grep 'Type.*kova status' "$KOVA_ROOT/demo.tape"
  assert_success
}

# ── Scene 3: Run feature ──

@test "demo.tape contains Type commands for kova:loop" {
  run grep 'Type.*kova:loop' "$KOVA_ROOT/demo.tape"
  assert_success
}

# ── Scene 4: Verification catches a bug ──

@test "demo.tape shows verification gate output" {
  run grep 'Verification' "$KOVA_ROOT/demo.tape"
  assert_success
}

@test "demo.tape shows verification failure" {
  run grep 'FAIL' "$KOVA_ROOT/demo.tape"
  assert_success
}

# ── Scene 5: Self-healing ──

@test "demo.tape shows self-heal attempt" {
  run grep -i 'self-heal\|Self-Heal' "$KOVA_ROOT/demo.tape"
  assert_success
}

@test "demo.tape shows fix applied" {
  run grep 'applied fix' "$KOVA_ROOT/demo.tape"
  assert_success
}

@test "demo.tape shows verification retry passes" {
  run grep 'Verification PASSED' "$KOVA_ROOT/demo.tape"
  assert_success
}

# ── Scene 6: Commit clean code ──

@test "demo.tape shows commit output" {
  run grep 'Commit' "$KOVA_ROOT/demo.tape"
  assert_success
}

@test "demo.tape shows code review" {
  run grep 'Code Review' "$KOVA_ROOT/demo.tape"
  assert_success
}

# ── Related files ──

@test "examples/prd-todo-app.md exists (referenced by demo)" {
  [ -f "$KOVA_ROOT/examples/prd-todo-app.md" ]
}

@test "README references demo.gif" {
  run grep 'demo\.gif' "$KOVA_ROOT/README.md"
  assert_success
}

@test "README references demo.tape" {
  run grep 'demo\.tape' "$KOVA_ROOT/README.md"
  assert_success
}
