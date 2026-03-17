#!/bin/bash
# kova-cleanup.sh — Sourceable library for kova loop state cleanup
# Source this file: source "$LIB_DIR/kova-cleanup.sh"
#
# Provides: kova_cleanup <state_dir>
# Removes the .kova-loop/ state directory.
# Prevents commit gate from blocking all future commits after loop ends.

# Clean up kova loop state.
# Usage: kova_cleanup <state_dir>
kova_cleanup() {
  local state_dir="${1:-.kova-loop}"
  if [ -d "$state_dir" ]; then
    rm -rf "$state_dir"
  fi
}
