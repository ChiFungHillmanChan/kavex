#!/bin/bash
# kova-safe-commit.sh — Sourceable library for safe commit during kova loop
# Source this file: source "$LIB_DIR/kova-safe-commit.sh"
#
# Provides: kova_safe_commit <item_num> <description> [no_commit]
# Stages only files changed since the last snapshot, commits with conventional message.
# Refuses to stage if no snapshot exists or snapshot is stale (>10 min).
#
# Prerequisites: kova-snapshot.sh must be sourced (for working_tree_hash)

# Stage only files that changed SINCE the pre-iteration snapshot.
# Ensures only files Claude touched get committed — pre-existing dirty work stays.
# Usage: _kova_stage_changes <state_dir>
_kova_stage_changes() {
  local state_dir="$1"

  # Current state
  git diff --name-only HEAD 2>/dev/null | sort > "$state_dir/.post-tracked"
  git ls-files --others --exclude-standard 2>/dev/null | sort > "$state_dir/.post-untracked"

  local changed_file

  # Stage tracked files that are new (in post but not pre)
  comm -13 "$state_dir/.pre-tracked" "$state_dir/.post-tracked" 2>/dev/null | while IFS= read -r changed_file; do
    [ -n "$changed_file" ] && git add -- "$changed_file" 2>/dev/null || true
  done

  # Stage tracked files that were already dirty only if their contents changed after snapshot
  comm -12 "$state_dir/.pre-tracked" "$state_dir/.post-tracked" 2>/dev/null | while IFS= read -r changed_file; do
    [ -z "$changed_file" ] && continue

    local pre_hash post_hash
    pre_hash=$(awk -F '\t' -v target="$changed_file" '$1 == target { print $2; exit }' "$state_dir/.pre-tracked-hashes")
    post_hash=$(working_tree_hash "$changed_file")

    if [ -n "$pre_hash" ] && [ "$pre_hash" != "$post_hash" ]; then
      git add -- "$changed_file" 2>/dev/null || true
    fi
  done

  # Stage only NEW untracked files (not present before Claude ran)
  comm -13 "$state_dir/.pre-untracked" "$state_dir/.post-untracked" 2>/dev/null | while IFS= read -r changed_file; do
    [ -z "$changed_file" ] && continue
    # Skip sensitive files and kova state dir
    case "$changed_file" in
      .kova-loop/*) continue ;;
      *.env|*.env.*|*.pem|*.key|*.p12|*.pfx|*.jks) continue ;;
      secrets/*|credentials/*|.secrets/*|.credentials/*) continue ;;
      *) git add -- "$changed_file" 2>/dev/null || true ;;
    esac
  done

  # Safety net: unstage any sensitive files and kova state
  git reset HEAD -- '.kova-loop/' '*.env' '*.env.*' '*.pem' '*.key' '*.p12' '*.pfx' '*.jks' \
    'secrets/' 'credentials/' '.secrets/' '.credentials/' >/dev/null 2>&1 || true
}

# Commit changes for a PRD item with safe staging.
# Usage: kova_safe_commit <item_num> <description> [no_commit]
# Args:
#   item_num    - PRD item number (for commit message)
#   description - Short description of the item
#   no_commit   - If "true", skip actual commit (dry-run mode)
# Returns: 0=success, 1=error
kova_safe_commit() {
  local item_num="$1"
  local description="$2"
  local no_commit="${3:-false}"
  local state_dir="${4:-.kova-loop}"

  # Guard: snapshot must exist and be recent (<10 min)
  if [ ! -f "$state_dir/.pre-tracked" ]; then
    echo "ERROR: No snapshot found at $state_dir/.pre-tracked. Run kova_snapshot first." >&2
    return 1
  fi

  local snapshot_age
  if [[ "$OSTYPE" == darwin* ]]; then
    snapshot_age=$(( $(date +%s) - $(stat -f %m "$state_dir/.pre-tracked") ))
  else
    snapshot_age=$(( $(date +%s) - $(stat -c %Y "$state_dir/.pre-tracked") ))
  fi

  if [ "$snapshot_age" -gt 600 ]; then
    echo "ERROR: Snapshot is ${snapshot_age}s old (>600s). Re-run kova_snapshot." >&2
    return 1
  fi

  if [ "$no_commit" = "true" ]; then
    echo "no-commit" > "$state_dir/commit-item-$item_num.txt"
    return 0
  fi

  # Stage only files changed since snapshot
  _kova_stage_changes "$state_dir"

  if git diff --cached --quiet 2>/dev/null; then
    echo "nothing-to-commit" > "$state_dir/commit-item-$item_num.txt"
    return 0
  fi

  local short_desc
  short_desc=$(echo "$description" | head -c 60)
  if ! git commit -m "feat(loop): $short_desc

Kova Smart Loop — PRD item $item_num

Co-Authored-By: Claude <noreply@anthropic.com>" 2>/dev/null; then
    echo "COMMIT_ERROR" > "$state_dir/commit-item-$item_num.txt"
    echo "ERROR: git commit failed for item $item_num" >&2
    return 1
  fi

  local hash
  hash=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
  echo "$hash" > "$state_dir/commit-item-$item_num.txt"

  # Clear verify log so commit gate blocks next commit until re-verified
  rm -f "$state_dir/verify-output-latest.log"

  echo "Committed item $item_num: $hash" >&2
}
