#!/usr/bin/env bats

setup() {
  load "../helpers/test_helper"
  _common_setup

  SANDBOX="$(mktemp -d)"
  mkdir -p "$SANDBOX/.git"
  run_install "$SANDBOX"
}

teardown() {
  rm -rf "$SANDBOX"
}

# --- kova activate ---

@test "activate: creates settings.local.json" {
  run_kova "$SANDBOX" activate
  [ -f "$SANDBOX/.claude/settings.local.json" ]
}

@test "activate: JSON is valid" {
  run_kova "$SANDBOX" activate
  run jq '.' "$SANDBOX/.claude/settings.local.json"
  assert_success
}

@test "activate: has PreToolUse hooks" {
  run_kova "$SANDBOX" activate
  local count
  count=$(jq '.hooks.PreToolUse | length' "$SANDBOX/.claude/settings.local.json")
  [ "$count" -ge 1 ]
}

@test "activate: has PostToolUse hooks" {
  run_kova "$SANDBOX" activate
  local count
  count=$(jq '.hooks.PostToolUse | length' "$SANDBOX/.claude/settings.local.json")
  [ "$count" -ge 1 ]
}

@test "activate: has Stop hooks" {
  run_kova "$SANDBOX" activate
  local count
  count=$(jq '.hooks.Stop | length' "$SANDBOX/.claude/settings.local.json")
  [ "$count" -ge 1 ]
}

@test "activate: references block-dangerous.sh" {
  run_kova "$SANDBOX" activate
  run jq -r '[.hooks.PreToolUse[].hooks[].command] | join(" ")' "$SANDBOX/.claude/settings.local.json"
  assert_output --partial "block-dangerous.sh"
}

@test "activate: references protect-files.sh (not protected-files.sh)" {
  run_kova "$SANDBOX" activate
  run jq -r '[.hooks.PreToolUse[].hooks[].command] | join(" ")' "$SANDBOX/.claude/settings.local.json"
  assert_output --partial "protect-files.sh"
  refute_output --partial "protected-files.sh"
}

@test "activate: references format.sh (not auto-format.sh)" {
  run_kova "$SANDBOX" activate
  run jq -r '[.hooks.PostToolUse[].hooks[].command] | join(" ")' "$SANDBOX/.claude/settings.local.json"
  assert_output --partial "format.sh"
  refute_output --partial "auto-format.sh"
}

@test "activate: references verify-on-stop.sh" {
  run_kova "$SANDBOX" activate
  run jq -r '[.hooks.Stop[].hooks[].command] | join(" ")' "$SANDBOX/.claude/settings.local.json"
  assert_output --partial "verify-on-stop.sh"
}

@test "activate: does NOT reference non-existent hooks" {
  run_kova "$SANDBOX" activate
  local all_commands
  all_commands=$(jq -r '.. | .command? // empty' "$SANDBOX/.claude/settings.local.json")
  [[ "$all_commands" != *"task-notify.sh"* ]]
  [[ "$all_commands" != *"test-runner.sh"* ]]
  [[ "$all_commands" != *"session-start.sh"* ]]
}

@test "activate: preserves permissions from settings" {
  run_kova "$SANDBOX" activate
  run jq '.permissions.allow | length' "$SANDBOX/.claude/settings.local.json"
  assert_success
  local count
  count=$(jq '.permissions.allow | length' "$SANDBOX/.claude/settings.local.json")
  [ "$count" -gt 0 ]
}

@test "activate: prints success message" {
  run run_kova "$SANDBOX" activate
  assert_success
  assert_output --partial "KOVA ACTIVATED"
}

# --- kova deactivate ---

@test "deactivate: removes hooks key" {
  run_kova "$SANDBOX" activate
  run_kova "$SANDBOX" deactivate
  run jq 'has("hooks")' "$SANDBOX/.claude/settings.local.json"
  assert_output "false"
}

@test "deactivate: preserves permissions key" {
  run_kova "$SANDBOX" activate
  run_kova "$SANDBOX" deactivate
  run jq 'has("permissions")' "$SANDBOX/.claude/settings.local.json"
  assert_output "true"
}

@test "deactivate: prints success message" {
  run_kova "$SANDBOX" activate
  run run_kova "$SANDBOX" deactivate
  assert_success
  assert_output --partial "KOVA DEACTIVATED"
}

@test "deactivate: no settings.local.json is harmless" {
  rm -f "$SANDBOX/.claude/settings.local.json"
  run run_kova "$SANDBOX" deactivate
  assert_output --partial "already inactive"
}

# --- activate/deactivate cycle ---

@test "activate then deactivate then activate: idempotent" {
  run_kova "$SANDBOX" activate
  run_kova "$SANDBOX" deactivate
  run_kova "$SANDBOX" activate
  run jq 'has("hooks")' "$SANDBOX/.claude/settings.local.json"
  assert_output "true"
}
