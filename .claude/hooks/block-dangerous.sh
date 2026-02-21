#!/bin/bash
# block-dangerous.sh — Block catastrophic commands before Claude runs them
# Runs on PreToolUse for Bash

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

if [ -z "$CMD" ]; then
  exit 0
fi

# Patterns that are always blocked
BLOCKED_PATTERNS=(
  "rm -rf /"
  "rm -rf ~"
  "rm -rf \$HOME"
  "git push --force"
  "git push -f"
  "DROP TABLE"
  "DROP DATABASE"
  "TRUNCATE TABLE"
  "rm -rf \*"
  "> /dev/sda"
  "mkfs"
  "dd if="
  ":(){:|:&};:"
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$CMD" | grep -qiF "$pattern"; then
    echo "BLOCKED: Dangerous command detected: \"$pattern\"" >&2
    echo '{"decision":"block","reason":"This command matches a dangerous pattern and has been blocked by Kova safety protocol. If you genuinely need to run this, ask the human explicitly."}'
    exit 0
  fi
done

# Warn (but allow) for semi-dangerous patterns
WARN_PATTERNS=(
  "rm -rf"
  "force-with-lease"
  "drop_table"
)

for pattern in "${WARN_PATTERNS[@]}"; do
  if echo "$CMD" | grep -qiF "$pattern"; then
    echo "WARNING: Potentially destructive command detected. Proceeding, but double-check." >&2
  fi
done

exit 0
