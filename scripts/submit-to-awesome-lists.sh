#!/usr/bin/env bash
# submit-to-awesome-lists.sh — Fork, branch, and open a PR to an awesome list.
# Usage: ./scripts/submit-to-awesome-lists.sh <number>
# Example: ./scripts/submit-to-awesome-lists.sh 1
#
# Requires: gh (GitHub CLI), authenticated with your account.

set -euo pipefail

REPO_URL="https://github.com/ChiFungHillmanChan/kova"
MAX_TARGETS=12

# Target repos indexed 1-12 (element 0 is unused placeholder)
REPOS=(
  ""
  "hesreallyhim/awesome-claude-code"
  "ComposioHQ/awesome-claude-skills"
  "VoltAgent/awesome-claude-code-subagents"
  "travisvn/awesome-claude-skills"
  "rohitg00/awesome-claude-code-toolkit"
  "BehiSecc/awesome-claude-skills"
  "ccplugins/awesome-claude-code-plugins"
  "ComposioHQ/awesome-claude-plugins"
  "e2b-dev/awesome-ai-agents"
  "Prat011/awesome-llm-skills"
  "tonysurfly/awesome-claude"
  "tensorchord/Awesome-LLMOps"
)

PR_TITLES=(
  ""
  "Add Kova — bash-enforced verification hooks and orchestrator"
  "Add Kova — bash-enforced verification workflow for Claude Code"
  "Add Kova — bash orchestrator for verification-gated subagent loops"
  "Add Kova — bash-enforced engineering protocol and verification skills"
  "Add Kova — comprehensive hook-based verification toolkit"
  "Add Kova — bash-enforced verification for Claude Code"
  "Add Kova — hook-based verification enforcement"
  "Add Kova — bash-enforced verification hooks"
  "Add Kova — verification-gated orchestrator for AI coding agents"
  "Add Kova — bash-enforced verification for LLM coding agents"
  "Add Kova — bash-enforced engineering protocol for Claude Code"
  "Add Kova — verification gates for LLM-driven development"
)

usage() {
  echo "Usage: $0 <number>"
  echo ""
  echo "Submit Kova to an awesome list by number (see SUBMISSIONS.md):"
  echo ""
  for i in $(seq 1 "$MAX_TARGETS"); do
    echo "  $i  ${REPOS[$i]}"
  done
  echo ""
  echo "Options:"
  echo "  --list    Show all targets with status"
  echo "  --help    Show this help"
}

show_list() {
  echo "Awesome List Submission Targets:"
  echo ""
  printf "  %-4s %-50s %s\n" "#" "Repository" "PR Title"
  printf "  %-4s %-50s %s\n" "---" "--------------------------------------------------" "--------"
  for i in $(seq 1 "$MAX_TARGETS"); do
    printf "  %-4s %-50s %s\n" "$i" "${REPOS[$i]}" "${PR_TITLES[$i]}"
  done
}

if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

if [[ "${1:-}" == "--list" ]]; then
  show_list
  exit 0
fi

if [[ -z "${1:-}" ]]; then
  usage
  exit 1
fi

NUM="$1"

# Validate numeric input in range 1-MAX_TARGETS
if ! [[ "$NUM" =~ ^[0-9]+$ ]] || [ "$NUM" -lt 1 ] || [ "$NUM" -gt "$MAX_TARGETS" ]; then
  echo "Error: Invalid number '$NUM'. Valid range: 1-$MAX_TARGETS"
  exit 1
fi

TARGET="${REPOS[$NUM]}"
TITLE="${PR_TITLES[$NUM]}"
BRANCH="add-kova"

echo "=== Submitting Kova to $TARGET ==="
echo ""

# Check gh is authenticated
if ! gh auth status &>/dev/null; then
  echo "Error: gh CLI is not authenticated. Run 'gh auth login' first."
  exit 1
fi

# Step 1: Fork the repo
echo "Step 1: Forking $TARGET..."
gh repo fork "$TARGET" --clone=false 2>/dev/null || echo "  (already forked)"

# Get the authenticated user's GitHub username
GH_USER=$(gh api user --jq '.login')
FORK="${GH_USER}/$(basename "$TARGET")"

echo "  Fork: $FORK"

# Step 2: Clone the fork to a temp directory
WORK_DIR=$(mktemp -d)
echo "Step 2: Cloning fork to $WORK_DIR..."
gh repo clone "$FORK" "$WORK_DIR" -- --depth=1

# Step 3: Create branch
echo "Step 3: Creating branch '$BRANCH'..."
cd "$WORK_DIR"
git checkout -b "$BRANCH"

# Step 4: Prompt user to make edits
echo ""
echo "============================================"
echo "  Fork cloned to: $WORK_DIR"
echo "  Branch: $BRANCH"
echo "  Target: $TARGET"
echo ""
echo "  Next steps:"
echo "  1. Edit the README.md in $WORK_DIR"
echo "     (See SUBMISSIONS.md for the exact entry to add)"
echo "  2. Run: cd $WORK_DIR && git add -A && git commit -m 'Add Kova'"
echo "  3. Run: git push origin $BRANCH"
echo "  4. Run: gh pr create --repo $TARGET --title '$TITLE' \\"
echo "       --body 'Add [Kova]($REPO_URL) — bash-enforced verification for Claude Code.'"
echo "============================================"
echo ""
echo "Or press Enter to open the fork directory in your editor..."
read -r

if command -v code &>/dev/null; then
  code "$WORK_DIR"
elif [[ -n "${EDITOR:-}" ]]; then
  "$EDITOR" "$WORK_DIR/README.md"
else
  echo "Open $WORK_DIR/README.md in your editor to add the Kova entry."
fi
