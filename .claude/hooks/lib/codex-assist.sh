#!/bin/bash
# codex-assist.sh — Cross-model diagnostic integration via OpenAI Codex CLI
# Source this file: source "$LIB_DIR/codex-assist.sh"
#
# All functions are optional and non-blocking. If Codex CLI is not installed
# or fails, existing flows continue unchanged.
#
# Env: CODEX_TIMEOUT (default 120s)

# Check if Codex CLI is available
# Returns: 0 if available, 1 if not
codex_available() {
  command -v codex &>/dev/null
}

# Run a command with a timeout (portable — no GNU coreutils dependency)
# Usage: _codex_run_with_timeout <seconds> <cmd...>
# Returns: command exit code, or 124 on timeout
_codex_run_with_timeout() {
  local timeout_secs="$1"
  shift

  "$@" &
  local cmd_pid=$!

  # Watchdog: sleep in background, trap TERM to clean up the sleep child
  (
    trap 'kill $sleep_pid 2>/dev/null; exit 0' TERM
    sleep "$timeout_secs" &
    sleep_pid=$!
    wait $sleep_pid 2>/dev/null
    kill "$cmd_pid" 2>/dev/null
  ) &
  local watchdog_pid=$!

  wait "$cmd_pid" 2>/dev/null
  local exit_code=$?

  # Kill the watchdog if the command finished before timeout
  kill "$watchdog_pid" 2>/dev/null
  wait "$watchdog_pid" 2>/dev/null

  # If the command was killed by our watchdog, return 124 (timeout convention)
  if [ $exit_code -eq 137 ] || [ $exit_code -eq 143 ]; then
    return 124
  fi

  return $exit_code
}

# Send failure context to Codex for cross-model diagnosis
# Usage: codex_diagnose <context_file> <output_file>
# Returns: 0 on success (diagnosis written), 1 on skip/failure
codex_diagnose() {
  local context_file="$1"
  local output_file="$2"
  local timeout="${CODEX_TIMEOUT:-120}"

  if ! codex_available; then
    return 1
  fi

  if [ ! -f "$context_file" ] || [ ! -s "$context_file" ]; then
    return 1
  fi

  # Cap input at 500 lines to avoid token limits
  local context_content
  context_content=$(head -500 "$context_file")

  local prompt="You are diagnosing why an AI coding agent is stuck fixing failures. Analyze the following failure context and provide:
1. Root cause analysis — what is likely going wrong
2. Specific fix suggestions — concrete code changes or approaches
3. Common pitfalls — things the original agent may have overlooked

Be concise and actionable. Focus on the most likely root cause.

Failure context:

$context_content"

  local raw_output
  raw_output=$(_codex_run_with_timeout "$timeout" codex -q "$prompt" 2>/dev/null)
  local exit_code=$?

  if [ $exit_code -ne 0 ] || [ -z "$raw_output" ]; then
    return 1
  fi

  {
    echo "## Cross-Model Diagnosis [codex]"
    echo ""
    echo "$raw_output"
  } > "$output_file"

  return 0
}

# Send diff to Codex for cross-model code review
# Usage: codex_review <diff_file> <output_file>
# Returns: 0 on success (review written), 1 on skip/failure
codex_review() {
  local diff_file="$1"
  local output_file="$2"
  local timeout="${CODEX_TIMEOUT:-120}"

  if ! codex_available; then
    return 1
  fi

  if [ ! -f "$diff_file" ] || [ ! -s "$diff_file" ]; then
    return 1
  fi

  # Cap input at 500 lines
  local diff_content
  diff_content=$(head -500 "$diff_file")

  local prompt="You are reviewing a code diff for HIGH-severity issues. Focus on:
- Security vulnerabilities (injection, XSS, hardcoded secrets, auth bypass)
- Logic bugs (wrong conditions, off-by-one, null derefs, race conditions)
- Missing error handling that could crash in production
- Data loss risks

Output format:
- Start with SEVERITY: HIGH or SEVERITY: LOW_ONLY or SEVERITY: CLEAN
- For HIGH issues, list each as: HIGH: file:line - description
- For LOW issues, list as: LOW: description

Diff:

$diff_content"

  local raw_output
  raw_output=$(_codex_run_with_timeout "$timeout" codex -q "$prompt" 2>/dev/null)
  local exit_code=$?

  if [ $exit_code -ne 0 ] || [ -z "$raw_output" ]; then
    return 1
  fi

  {
    echo "## Cross-Model Review [codex]"
    echo ""
    echo "$raw_output"
  } > "$output_file"

  return 0
}
