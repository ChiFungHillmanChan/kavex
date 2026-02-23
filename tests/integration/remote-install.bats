#!/usr/bin/env bats

setup() {
  load "../helpers/test_helper"
  _common_setup

  SANDBOX="$(mktemp -d)"
  mkdir -p "$SANDBOX/.git"
}

teardown() {
  rm -rf "$SANDBOX"
}

# --- remote-install.sh structure ---

@test "remote-install: script exists and is executable" {
  [ -f "$KOVA_ROOT/remote-install.sh" ]
  [ -x "$KOVA_ROOT/remote-install.sh" ]
}

@test "remote-install: uses set -e for safety" {
  run grep -c "^set -e" "$KOVA_ROOT/remote-install.sh"
  assert_output "1"
}

@test "remote-install: has cleanup trap to remove temp directory" {
  run grep -c "trap cleanup EXIT" "$KOVA_ROOT/remote-install.sh"
  assert_output "1"
}

@test "remote-install: checks for git before proceeding" {
  run grep "command -v git" "$KOVA_ROOT/remote-install.sh"
  assert_success
}

@test "remote-install: passes arguments through to install.sh" {
  run grep 'INSTALL_ARGS=("$@")' "$KOVA_ROOT/remote-install.sh"
  assert_success
  run grep '${INSTALL_ARGS\[@\]}' "$KOVA_ROOT/remote-install.sh"
  assert_success
}

@test "remote-install: clones with --depth 1 for speed" {
  run grep "\-\-depth 1" "$KOVA_ROOT/remote-install.sh"
  assert_success
}

@test "remote-install: validates install.sh exists after clone" {
  run grep 'if \[ ! -f "$CLONE_DIR/install.sh" \]' "$KOVA_ROOT/remote-install.sh"
  assert_success
}

# --- Simulated remote install (using local repo as source) ---

@test "remote-install: simulated local run installs hooks" {
  # Simulate what remote-install.sh does: clone locally then run install.sh
  # We use the local repo instead of cloning from GitHub
  run bash -c "cd '$SANDBOX' && bash '$KOVA_ROOT/install.sh'"
  assert_success
  [ -d "$SANDBOX/.claude/hooks" ]
  [ -d "$SANDBOX/.claude/hooks/lib" ]
  [ -f "$SANDBOX/.claude/hooks/format.sh" ]
  [ -x "$SANDBOX/.claude/hooks/format.sh" ]
}

@test "remote-install: simulated --dry-run makes no changes" {
  # Simulate the --dry-run flag being passed through
  run bash -c "cd '$SANDBOX' && bash '$KOVA_ROOT/install.sh' --dry-run"
  assert_success
  assert_output --partial "DRY RUN"
  assert_output --partial "No changes made"
  [ ! -d "$SANDBOX/.claude/hooks" ]
}

@test "remote-install: git missing produces clear error" {
  # Create a script that shadows git with a failing command
  local fake_bin="$(mktemp -d)"
  cat > "$fake_bin/git" <<'EOF'
#!/bin/bash
exit 127
EOF
  # Override command -v git by using a wrapper script
  # Test the error message directly from the script's guard clause
  run bash -c "
    git() { return 1; }
    command() {
      if [ \"\$2\" = 'git' ]; then return 1; fi
      builtin command \"\$@\"
    }
    export -f git command
    bash '$KOVA_ROOT/remote-install.sh'
  "
  assert_failure
  assert_output --partial "git is required"
  rm -rf "$fake_bin"
}

@test "remote-install: failed clone exits non-zero" {
  # Override git to simulate a clone failure
  run bash -c "
    export PATH='$(mktemp -d):\$PATH'
    cat > \"\$(echo \$PATH | cut -d: -f1)/git\" <<'FAKEGIT'
#!/bin/bash
# Fake git that fails on clone but passes command -v check
if [ \"\$1\" = 'clone' ]; then exit 128; fi
exit 0
FAKEGIT
    chmod +x \"\$(echo \$PATH | cut -d: -f1)/git\"
    cd '$SANDBOX'
    bash '$KOVA_ROOT/remote-install.sh'
  "
  assert_failure
}
