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

@test "status: runs without error on fresh install" {
  run_install "$SANDBOX"
  run run_kavex "$SANDBOX" status
  assert_success
  assert_output --partial "KAVEX STATUS"
}

@test "status: reports all hooks present after install" {
  run_install "$SANDBOX"
  run run_kavex "$SANDBOX" status
  assert_success
  assert_output --partial "all present"
}

@test "status: reports missing hooks when none installed" {
  mkdir -p "$SANDBOX/.claude/hooks"
  run run_kavex "$SANDBOX" status
  assert_output --partial "missing"
}

@test "status: shows configured hook count with settings.json" {
  run_install "$SANDBOX"
  run run_kavex "$SANDBOX" status
  assert_output --partial "configured"
}

@test "status: detects shared library" {
  run_install "$SANDBOX"
  run run_kavex "$SANDBOX" status
  assert_output --partial "OK"
}

@test "status: detects Team Loop" {
  run_install "$SANDBOX"
  run run_kavex "$SANDBOX" status
  assert_output --partial "available"
}

@test "status: detects Node.js stack" {
  run_install "$SANDBOX"
  echo '{}' > "$SANDBOX/package.json"
  run run_kavex "$SANDBOX" status
  assert_output --partial "Node.js"
}

@test "status: shows command count" {
  run_install "$SANDBOX"
  run run_kavex "$SANDBOX" status
  assert_output --partial "available"
}

# --- kavex help ---

@test "help: displays without error" {
  run run_kavex "$SANDBOX" help
  assert_success
  assert_output --partial "KAVEX PROTOCOL"
}

@test "help: lists correct hook filenames" {
  run run_kavex "$SANDBOX" help
  assert_output --partial "format.sh"
  assert_output --partial "block-dangerous.sh"
  assert_output --partial "protect-files.sh"
  assert_output --partial "verify-on-stop.sh"
  assert_output --partial "kavex-loop.sh"
  refute_output --partial "auto-format.sh"
  refute_output --partial "protected-files.sh"
}

@test "help: no flag shows help" {
  run run_kavex "$SANDBOX"
  assert_success
  assert_output --partial "KAVEX PROTOCOL"
}

# --- unknown command ---

@test "unknown command: exits with error" {
  run run_kavex "$SANDBOX" foobar
  assert_failure
  assert_output --partial "Unknown command"
}
