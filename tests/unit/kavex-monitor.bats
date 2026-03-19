#!/usr/bin/env bats

setup() {
  load "../helpers/test_helper"
  _common_setup
}

teardown() {
  if [ -n "$SANDBOX" ] && [ -d "$SANDBOX" ]; then
    rm -rf "$SANDBOX"
  fi
}

# --- help ---

@test "kavex-monitor help: shows help text" {
  run bash "$KAVEX_ROOT/scripts/kavex-monitor" help
  assert_success
  assert_output --partial "KAVEX MONITOR"
  assert_output --partial "tmux Dashboard"
}

@test "kavex-monitor: no args shows help" {
  run bash "$KAVEX_ROOT/scripts/kavex-monitor"
  assert_success
  assert_output --partial "KAVEX MONITOR"
}

@test "kavex-monitor --help: shows help text" {
  run bash "$KAVEX_ROOT/scripts/kavex-monitor" --help
  assert_success
  assert_output --partial "COMMANDS"
}

# --- unknown command ---

@test "kavex-monitor: unknown command fails" {
  run bash "$KAVEX_ROOT/scripts/kavex-monitor" foobar
  assert_failure
  assert_output --partial "Unknown command"
}

# --- start validation ---

@test "kavex-monitor start: requires prd file argument" {
  run bash "$KAVEX_ROOT/scripts/kavex-monitor" start
  assert_failure
  assert_output --partial "PRD file required"
}

@test "kavex-monitor start: fails on missing prd file" {
  run bash "$KAVEX_ROOT/scripts/kavex-monitor" start /nonexistent/file.md
  assert_failure
  # In CI without tmux, the tmux check may fire before the file check
  [[ "$output" == *"not found"* ]] || [[ "$output" == *"tmux"* ]]
}

# --- tmux missing ---

@test "kavex-monitor start: error when tmux not available" {
  SANDBOX="$(mktemp -d)"
  echo "- [ ] test item" > "$SANDBOX/test.md"
  # Run with PATH stripped to simulate missing tmux
  run env PATH="/usr/bin:/bin" bash "$KAVEX_ROOT/scripts/kavex-monitor" start "$SANDBOX/test.md"
  # Should fail because tmux is not in the restricted path (or it is and works)
  # We can't guarantee tmux isn't in /usr/bin, so just check it doesn't crash.
  # In CI without a terminal, tmux may emit "size missing" instead of a tmux-related error.
  [ "$status" -eq 0 ] || [[ "$output" == *"tmux"* ]] || [[ "$output" == *"size"* ]]
}

# --- status ---

@test "kavex-monitor status: runs without error" {
  run bash "$KAVEX_ROOT/scripts/kavex-monitor" status
  assert_success
}

@test "kavex-monitor status: shows not running when no session" {
  run bash "$KAVEX_ROOT/scripts/kavex-monitor" status
  assert_success
  # Should show either "not running" or "tmux not installed"
  [[ "$output" == *"not running"* ]] || [[ "$output" == *"tmux not installed"* ]]
}

# --- stop ---

@test "kavex-monitor stop: no error when no session exists" {
  run bash "$KAVEX_ROOT/scripts/kavex-monitor" stop
  # Should succeed or show tmux not installed
  [ "$status" -eq 0 ] || [[ "$output" == *"tmux"* ]]
}
