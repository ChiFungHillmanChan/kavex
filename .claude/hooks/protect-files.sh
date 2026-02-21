#!/bin/bash
# protect-files.sh — Block writes to sensitive files
# Runs on PreToolUse for Write|Edit|MultiEdit

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

if [ -z "$FILE" ]; then
  exit 0
fi

# Files/patterns that should never be auto-edited
PROTECTED=(
  ".env.production"
  ".env.prod"
  "secrets/"
  "credentials/"
  ".pem"
  ".key"
  "id_rsa"
  "serviceAccountKey.json"
  "firebase-adminsdk"
)

for pattern in "${PROTECTED[@]}"; do
  if [[ "$FILE" == *"$pattern"* ]]; then
    echo "BLOCKED: Protected file pattern matched: $pattern" >&2
    echo "{\"decision\":\"block\",\"reason\":\"File '$FILE' matches protected pattern '$pattern'. This file contains sensitive data. Ask the human before editing.\"}"
    exit 0
  fi
done

exit 0
