#!/bin/bash
# remote-install.sh — One-line installer for Kova
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/ChiFungHillmanChan/kova/main/remote-install.sh | bash
#   curl -fsSL ... | bash -s -- --dry-run    # preview without changes
#   curl -fsSL ... | bash -s -- --global      # install kova CLI globally
#
# What it does:
#   1. Clones the kova repo to a temporary directory
#   2. Runs install.sh from the cloned repo into $PWD
#   3. Cleans up the temporary clone
#
# ASSUMPTION: User has git installed. curl implies network access so git should be available.

set -e

KOVA_REPO="https://github.com/ChiFungHillmanChan/kova.git"
KOVA_BRANCH="main"
TMPDIR_PREFIX="kova-install"

# Collect all arguments to pass through to install.sh
INSTALL_ARGS=("$@")

# ─────────────────────────────────────────────
# Preflight checks
# ─────────────────────────────────────────────
if ! command -v git &>/dev/null; then
  echo "ERROR: git is required but not installed." >&2
  echo "  Install git first: https://git-scm.com/downloads" >&2
  exit 1
fi

# ─────────────────────────────────────────────
# Clone to temp directory
# ─────────────────────────────────────────────
CLONE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/${TMPDIR_PREFIX}.XXXXXX")"

cleanup() {
  if [ -n "$CLONE_DIR" ] && [ -d "$CLONE_DIR" ]; then
    rm -rf "$CLONE_DIR"
  fi
}
trap cleanup EXIT

echo "Kova: downloading latest release..."
git clone --depth 1 --branch "$KOVA_BRANCH" "$KOVA_REPO" "$CLONE_DIR" 2>/dev/null

if [ ! -f "$CLONE_DIR/install.sh" ]; then
  echo "ERROR: Failed to download Kova. Check your network connection." >&2
  exit 1
fi

# ─────────────────────────────────────────────
# Run the local installer from the cloned repo
# ─────────────────────────────────────────────
echo ""
bash "$CLONE_DIR/install.sh" "${INSTALL_ARGS[@]}"
