#!/usr/bin/env bats
# Regression test: SUBMISSIONS.md and submit-to-awesome-lists.sh

setup() {
  load "../helpers/test_helper"
  _common_setup
}

# ── SUBMISSIONS.md existence and structure ──

@test "SUBMISSIONS.md exists at project root" {
  [ -f "$KOVA_ROOT/SUBMISSIONS.md" ]
}

@test "SUBMISSIONS.md does not exceed 300 lines" {
  local lines
  lines="$(wc -l < "$KOVA_ROOT/SUBMISSIONS.md")"
  [ "$lines" -le 300 ]
}

@test "SUBMISSIONS.md contains status table" {
  run grep '| # | Repository' "$KOVA_ROOT/SUBMISSIONS.md"
  assert_success
}

@test "SUBMISSIONS.md lists at least 10 target repositories" {
  run grep -c '| [0-9]' "$KOVA_ROOT/SUBMISSIONS.md"
  assert_success
  [ "$output" -ge 10 ]
}

# ── Required repositories are listed ──

@test "SUBMISSIONS.md includes hesreallyhim/awesome-claude-code" {
  run grep 'hesreallyhim/awesome-claude-code' "$KOVA_ROOT/SUBMISSIONS.md"
  assert_success
}

@test "SUBMISSIONS.md includes ComposioHQ/awesome-claude-skills" {
  run grep 'ComposioHQ/awesome-claude-skills' "$KOVA_ROOT/SUBMISSIONS.md"
  assert_success
}

@test "SUBMISSIONS.md includes VoltAgent/awesome-claude-code-subagents" {
  run grep 'VoltAgent/awesome-claude-code-subagents' "$KOVA_ROOT/SUBMISSIONS.md"
  assert_success
}

@test "SUBMISSIONS.md includes e2b-dev/awesome-ai-agents" {
  run grep 'e2b-dev/awesome-ai-agents' "$KOVA_ROOT/SUBMISSIONS.md"
  assert_success
}

# ── PR content sections ──

@test "SUBMISSIONS.md contains PR titles for each repo" {
  run grep -c 'PR title' "$KOVA_ROOT/SUBMISSIONS.md"
  assert_success
  [ "$output" -ge 10 ]
}

@test "SUBMISSIONS.md contains markdown entries for each repo" {
  run grep -c '\[Kova\](https://github.com/ChiFungHillmanChan/kova)' "$KOVA_ROOT/SUBMISSIONS.md"
  assert_success
  [ "$output" -ge 10 ]
}

@test "SUBMISSIONS.md contains priority tiers" {
  run grep 'Tier 1' "$KOVA_ROOT/SUBMISSIONS.md"
  assert_success
  run grep 'Tier 2' "$KOVA_ROOT/SUBMISSIONS.md"
  assert_success
  run grep 'Tier 3' "$KOVA_ROOT/SUBMISSIONS.md"
  assert_success
}

# ── Helper script ──

@test "submit-to-awesome-lists.sh exists" {
  [ -f "$KOVA_ROOT/scripts/submit-to-awesome-lists.sh" ]
}

@test "submit-to-awesome-lists.sh is executable" {
  [ -x "$KOVA_ROOT/scripts/submit-to-awesome-lists.sh" ]
}

@test "submit-to-awesome-lists.sh shows usage with no args" {
  run bash "$KOVA_ROOT/scripts/submit-to-awesome-lists.sh"
  assert_failure
  assert_output --partial "Usage"
}

@test "submit-to-awesome-lists.sh shows usage with --help" {
  run bash "$KOVA_ROOT/scripts/submit-to-awesome-lists.sh" --help
  assert_success
  assert_output --partial "Usage"
}

@test "submit-to-awesome-lists.sh --list shows all targets" {
  run bash "$KOVA_ROOT/scripts/submit-to-awesome-lists.sh" --list
  assert_success
  assert_output --partial "awesome-claude-code"
  assert_output --partial "awesome-claude-skills"
  assert_output --partial "awesome-ai-agents"
}

@test "submit-to-awesome-lists.sh rejects invalid number" {
  run bash "$KOVA_ROOT/scripts/submit-to-awesome-lists.sh" 99
  assert_failure
  assert_output --partial "Invalid number"
}

# ── Content quality checks ──

@test "all entries mention bash-enforced or verification" {
  # Every Kova entry should reference the key differentiator
  local entries
  entries=$(grep -c 'bash-enforced\|verification\|7-layer' "$KOVA_ROOT/SUBMISSIONS.md")
  [ "$entries" -ge 10 ]
}

@test "repo URL is consistent across all entries" {
  run grep -c 'https://github.com/ChiFungHillmanChan/kova' "$KOVA_ROOT/SUBMISSIONS.md"
  assert_success
  [ "$output" -ge 10 ]
}
