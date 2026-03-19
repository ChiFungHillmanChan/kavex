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

@test "uninstall: removes generated settings.json when no backup exists" {
  run_kavex "$SANDBOX" uninstall

  [ ! -f "$SANDBOX/.claude/settings.json" ]
}

@test "uninstall: preserves non-Kavex hook libraries" {
  cat > "$SANDBOX/.claude/hooks/lib/custom-helper.sh" <<'EOF'
#!/bin/bash
echo custom
EOF

  run_kavex "$SANDBOX" uninstall

  [ -f "$SANDBOX/.claude/hooks/lib/custom-helper.sh" ]
  [ ! -f "$SANDBOX/.claude/hooks/lib/detect-stack.sh" ]
}

@test "uninstall: preserves user-defined hooks in settings.local.json" {
  cat > "$SANDBOX/.claude/settings.local.json" <<'JSON'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {"type": "command", "command": "cat | .claude/hooks/block-dangerous.sh", "timeout": 5}
        ]
      },
      {
        "matcher": "Read",
        "hooks": [
          {"type": "command", "command": "cat | ./custom-local-hook.sh", "timeout": 7}
        ]
      }
    ]
  },
  "permissions": {
    "allow": ["Bash(ls *)"]
  }
}
JSON

  run_kavex "$SANDBOX" uninstall

  run jq -r '.hooks.PreToolUse[0].hooks[0].command' "$SANDBOX/.claude/settings.local.json"
  assert_success
  assert_output "cat | ./custom-local-hook.sh"

  run jq -r '.. | .command? // empty' "$SANDBOX/.claude/settings.local.json"
  refute_output --partial "block-dangerous.sh"
}

@test "uninstall: strips Kavex hooks from mixed settings.json without backup" {
  cat > "$SANDBOX/.claude/settings.json" <<'JSON'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {"type": "command", "command": "cat | .claude/hooks/block-dangerous.sh", "timeout": 5}
        ]
      },
      {
        "matcher": "Read",
        "hooks": [
          {"type": "command", "command": "cat | ./custom-project-hook.sh", "timeout": 7}
        ]
      }
    ]
  },
  "permissions": {
    "allow": ["Bash(ls *)"]
  },
  "custom": true
}
JSON

  run_kavex "$SANDBOX" uninstall

  [ -f "$SANDBOX/.claude/settings.json" ]

  run jq -r '.hooks.PreToolUse[0].hooks[0].command' "$SANDBOX/.claude/settings.json"
  assert_success
  assert_output "cat | ./custom-project-hook.sh"

  run jq -r '.. | .command? // empty' "$SANDBOX/.claude/settings.json"
  refute_output --partial "block-dangerous.sh"
}
