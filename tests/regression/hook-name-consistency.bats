#!/usr/bin/env bats
# Regression test: every hook script referenced by 'kova activate' and
# 'kova status' must exist as a file shipped by install.sh.
# This prevents the class of bug where activate/status reference hooks
# that are never installed.

setup() {
  load "../helpers/test_helper"
  _common_setup
}

# Extract hook filenames referenced in kova activate's JSON config
_activate_hook_refs() {
  grep -oE '\.claude/hooks/[a-z_-]+\.sh' "$KOVA_ROOT/scripts/kova" | sort -u | sed 's|\.claude/hooks/||'
}

# Extract hook filenames checked in kova status's for-loop
_status_hook_refs() {
  grep -A1 'for hook in' "$KOVA_ROOT/scripts/kova" | grep -oE '[a-z_-]+\.sh' | sort -u
}

# Extract hook filenames listed in kova help text
_help_hook_refs() {
  sed -n '/HOOKS (automatic/,/SUPPORTED LANGUAGES/p' "$KOVA_ROOT/scripts/kova" \
    | grep -oE '[a-z_-]+\.sh' | sort -u
}

# Extract hook filenames installed by install.sh
_installed_hooks() {
  grep -oE 'hooks/[a-z_-]+\.sh' "$KOVA_ROOT/install.sh" \
    | sed 's|hooks/||' | sort -u
}

# Extract actual hook files present in hooks/
_actual_hook_files() {
  ls "$KOVA_ROOT/hooks/"*.sh 2>/dev/null | xargs -n1 basename | sort -u
}

# --- Core regression: activate only references installed hooks ---

@test "regression: activate references only hooks that install.sh installs" {
  local missing=0
  local installed
  installed=$(_installed_hooks)

  while IFS= read -r hook; do
    if ! echo "$installed" | grep -qx "$hook"; then
      echo "MISSING: kova activate references '$hook' but install.sh does not install it" >&2
      missing=$((missing + 1))
    fi
  done < <(_activate_hook_refs)

  [ "$missing" -eq 0 ]
}

# --- Core regression: status checks only hooks that install.sh installs ---

@test "regression: status checks only hooks that install.sh installs" {
  local missing=0
  local installed
  installed=$(_installed_hooks)

  while IFS= read -r hook; do
    if ! echo "$installed" | grep -qx "$hook"; then
      echo "MISSING: kova status checks '$hook' but install.sh does not install it" >&2
      missing=$((missing + 1))
    fi
  done < <(_status_hook_refs)

  [ "$missing" -eq 0 ]
}

# --- Core regression: help lists only hooks that install.sh installs ---

@test "regression: help lists only hooks that install.sh installs" {
  local missing=0
  local installed
  installed=$(_installed_hooks)

  while IFS= read -r hook; do
    if ! echo "$installed" | grep -qx "$hook"; then
      echo "MISSING: kova help lists '$hook' but install.sh does not install it" >&2
      missing=$((missing + 1))
    fi
  done < <(_help_hook_refs)

  [ "$missing" -eq 0 ]
}

# --- Core regression: activate references only actual files ---

@test "regression: activate references only hooks that exist on disk" {
  local missing=0
  local actual
  actual=$(_actual_hook_files)

  while IFS= read -r hook; do
    if ! echo "$actual" | grep -qx "$hook"; then
      echo "MISSING: kova activate references '$hook' but file does not exist in hooks/" >&2
      missing=$((missing + 1))
    fi
  done < <(_activate_hook_refs)

  [ "$missing" -eq 0 ]
}

# --- settings.json references only installed hooks ---

@test "regression: settings.json references only hooks that exist on disk" {
  local missing=0
  local actual
  actual=$(_actual_hook_files)

  local refs
  refs=$(grep -oE 'hooks/[a-z_-]+\.sh' "$KOVA_ROOT/.claude/settings.json" | sed 's|hooks/||' | sort -u)

  while IFS= read -r hook; do
    [ -z "$hook" ] && continue
    if ! echo "$actual" | grep -qx "$hook"; then
      echo "MISSING: settings.json references '$hook' but file does not exist" >&2
      missing=$((missing + 1))
    fi
  done <<< "$refs"

  [ "$missing" -eq 0 ]
}

# --- install.sh installs only files that exist in source ---

@test "regression: install.sh copies only hooks that exist in source repo" {
  local missing=0

  while IFS= read -r hook; do
    if [ ! -f "$KOVA_ROOT/hooks/$hook" ]; then
      echo "MISSING: install.sh references '$hook' but source file does not exist" >&2
      missing=$((missing + 1))
    fi
  done < <(_installed_hooks)

  [ "$missing" -eq 0 ]
}

# --- Bidirectional: all actual hooks are referenced somewhere ---

@test "regression: all hooks in hooks/ are referenced by install.sh" {
  local unreferenced=0
  local installed
  installed=$(_installed_hooks)

  while IFS= read -r hook; do
    if ! echo "$installed" | grep -qx "$hook"; then
      echo "UNREFERENCED: '$hook' exists in hooks/ but install.sh does not copy it" >&2
      unreferenced=$((unreferenced + 1))
    fi
  done < <(_actual_hook_files)

  [ "$unreferenced" -eq 0 ]
}
