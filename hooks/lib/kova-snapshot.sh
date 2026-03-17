#!/bin/bash
# kova-snapshot.sh — Sourceable library for working-tree snapshots
# Source this file: source "$LIB_DIR/kova-snapshot.sh"
#
# Provides: kova_snapshot <state_dir>
# Records tracked file hashes and untracked file list before an iteration.
# Clears stale verify results so commit gate blocks until re-verified.
#
# Hash the current working-tree contents for a tracked path so we can tell
# whether a file that was already dirty changed again during this iteration.
# Usage: working_tree_hash <file_path>
working_tree_hash() {
  local path="$1"
  if [ -e "$path" ]; then
    git hash-object --no-filters -- "$path" 2>/dev/null || echo "__HASH_ERROR__"
  else
    echo "__MISSING__"
  fi
}

# Snapshot the working tree state before an iteration.
# Creates the state dir if needed, records baseline for safe staging.
# Usage: kova_snapshot <state_dir>
kova_snapshot() {
  local state_dir="${1:-.kova-loop}"
  mkdir -p "$state_dir"

  # Clear stale verify results so commit gate blocks until re-verified
  rm -f "$state_dir/verify-output-latest.log"

  # List tracked files with uncommitted changes
  git diff --name-only HEAD 2>/dev/null | sort > "$state_dir/.pre-tracked"
  # List untracked files (excluding .gitignore'd)
  git ls-files --others --exclude-standard 2>/dev/null | sort > "$state_dir/.pre-untracked"
  : > "$state_dir/.pre-tracked-hashes"

  local tracked_file
  while IFS= read -r tracked_file; do
    [ -z "$tracked_file" ] && continue
    printf '%s\t%s\n' "$tracked_file" "$(working_tree_hash "$tracked_file")" >> "$state_dir/.pre-tracked-hashes"
  done < "$state_dir/.pre-tracked"
}
