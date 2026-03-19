#!/usr/bin/env bats

setup() {
  load "../helpers/test_helper"
  _common_setup

  SANDBOX="$(mktemp -d)"
  mkdir -p "$SANDBOX/.git"
}

teardown() {
  rm -rf "$SANDBOX"
}

# --- install copies kavex-monitor ---

@test "install: copies kavex-monitor script" {
  run_install "$SANDBOX"
  [ -f "$SANDBOX/.claude/kavex-monitor" ]
}

@test "install: kavex-monitor is executable after install" {
  run_install "$SANDBOX"
  [ -x "$SANDBOX/.claude/kavex-monitor" ]
}

@test "install --dry-run: mentions kavex-monitor" {
  run bash -c "cd '$SANDBOX' && bash '$KAVEX_ROOT/install.sh' --dry-run"
  assert_success
  assert_output --partial "kavex-monitor"
}

# --- kavex CLI delegates monitor ---

@test "kavex help: mentions monitor command" {
  run bash "$KAVEX_ROOT/scripts/kavex" help
  assert_success
  assert_output --partial "monitor"
}

@test "kavex help: mentions setup command" {
  run bash "$KAVEX_ROOT/scripts/kavex" help
  assert_success
  assert_output --partial "setup"
}

# --- install copies new lib files ---

@test "install: copies rate-limiter.sh" {
  run_install "$SANDBOX"
  [ -f "$SANDBOX/.claude/hooks/lib/rate-limiter.sh" ]
}

@test "install: copies circuit-breaker.sh" {
  run_install "$SANDBOX"
  [ -f "$SANDBOX/.claude/hooks/lib/circuit-breaker.sh" ]
}

@test "install: rate-limiter.sh is executable" {
  run_install "$SANDBOX"
  [ -x "$SANDBOX/.claude/hooks/lib/rate-limiter.sh" ]
}

@test "install: circuit-breaker.sh is executable" {
  run_install "$SANDBOX"
  [ -x "$SANDBOX/.claude/hooks/lib/circuit-breaker.sh" ]
}
