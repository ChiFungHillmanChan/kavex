#!/bin/bash
# kavex-verify.sh — Sourceable library for running verification
# Source this file: source "$LIB_DIR/kavex-verify.sh"
#
# Provides: kavex_verify <state_dir>
# Runs the 7-layer verification gate and writes results.
# On failure, parses structured diagnostics for fix prompts.
#
# Prerequisites: detect-stack.sh, verify-gate.sh, parse-failures.sh must be sourced

# Run the full verification gate.
# Writes verify-output-latest.log (always) and parsed-failures-latest.md (on failure).
# Usage: kavex_verify <state_dir>
# Returns: 0=pass, 1=fail
kavex_verify() {
  local state_dir="${1:-.kavex-loop}"
  mkdir -p "$state_dir"

  local verify_output="$state_dir/verify-output-latest.log"
  : > "$verify_output"

  # Ensure stack detection has run
  if [ -z "$LANGS" ]; then
    detect_pm
    detect_languages
  fi

  if run_verify_gate "$verify_output"; then
    echo "VERIFY: PASS" >&2
    return 0
  else
    echo "VERIFY: FAIL ($FAILURES layer(s))" >&2
    parse_all_failures "$verify_output" "$state_dir/parsed-failures-latest.md"
    return 1
  fi
}
