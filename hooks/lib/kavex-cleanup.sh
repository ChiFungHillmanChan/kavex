#!/bin/bash
# kavex-cleanup.sh — Sourceable library for kavex loop state cleanup
# Source this file: source "$LIB_DIR/kavex-cleanup.sh"
#
# Provides: kavex_cleanup <state_dir>
# Removes the .kavex-loop/ state directory.
# Prevents commit gate from blocking all future commits after loop ends.

# Clean up kavex loop state.
# Usage: kavex_cleanup <state_dir>
kavex_cleanup() {
  local state_dir="${1:-.kavex-loop}"
  if [ -d "$state_dir" ]; then
    rm -rf "$state_dir"
  fi
}
