#!/bin/bash
# kavex-statusline.sh — Kavex status indicator for Claude Code status line
# Detects kavex activation state and outputs a colored indicator.
#
# Usage (in a statusline script):
#   source "/path/to/.claude/hooks/lib/kavex-statusline.sh"
#   kavex_indicator=$(kavex_statusline_indicator)
#   echo "... $kavex_indicator ..."
#
# Or standalone:
#   bash .claude/hooks/lib/kavex-statusline.sh
#
# Output: colored text like "[KAVEX]" (green=active, yellow=loop, dim=inactive)

# Detect kavex hook state by checking settings files for registered kavex hooks.
# Returns: "active", "loop", or "inactive"
kavex_detect_state() {
  local project_dir="${1:-.}"
  local settings_local="$project_dir/.claude/settings.local.json"
  local settings="$project_dir/.claude/settings.json"

  # Check for active loop first (highest priority)
  if [ -d "$project_dir/.kavex-loop" ]; then
    echo "loop"
    return 0
  fi

  # Check settings files for kavex hooks.
  # If settings.local.json exists and has a "hooks" key, use it (it overrides).
  # If settings.local.json exists but has no "hooks" key, fall through to settings.json
  # (Claude Code merges both files, with local taking priority per-key).
  if ! command -v jq &>/dev/null; then
    echo "inactive"
    return 0
  fi

  local settings_file=""
  if [ -f "$settings_local" ]; then
    local has_hooks_key
    has_hooks_key=$(jq 'has("hooks")' "$settings_local" 2>/dev/null || echo "false")
    if [ "$has_hooks_key" = "true" ]; then
      settings_file="$settings_local"
    fi
  fi
  if [ -z "$settings_file" ] && [ -f "$settings" ]; then
    settings_file="$settings"
  fi

  if [ -z "$settings_file" ]; then
    echo "inactive"
    return 0
  fi

  local has_kavex_hooks
  has_kavex_hooks=$(jq -r '
    [.hooks // {} | to_entries[] | .value[] | .hooks[]? | .command // ""] |
    map(select(test("kavex|block-dangerous|protect-files|verify-on-stop|format"))) |
    length
  ' "$settings_file" 2>/dev/null || echo "0")

  if [ -n "$has_kavex_hooks" ] && [ "$has_kavex_hooks" != "0" ] && [ "$has_kavex_hooks" != "null" ]; then
    echo "active"
    return 0
  fi

  echo "inactive"
  return 0
}

# Generate the colored indicator string for the status line.
# Uses ANSI escape codes for color.
kavex_statusline_indicator() {
  local project_dir="${1:-.}"
  local state
  state=$(kavex_detect_state "$project_dir")

  case "$state" in
    active)
      # Green indicator
      printf '\033[0;32m[KAVEX]\033[0m'
      ;;
    loop)
      # Yellow indicator with spinning context
      printf '\033[0;33m[KAVEX LOOP]\033[0m'
      ;;
    inactive)
      # Dim indicator
      printf '\033[0;2m[kavex off]\033[0m'
      ;;
  esac
}

# When run directly (not sourced), output the indicator
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  # Accept project dir as first argument, default to cwd
  kavex_statusline_indicator "${1:-.}"
fi
