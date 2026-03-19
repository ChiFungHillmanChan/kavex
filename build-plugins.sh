#!/bin/bash
# build-plugins.sh — Assemble kavex and kavex-full plugin directories for distribution
# Usage: bash build-plugins.sh
# Output: dist/kavex/ and dist/kavex-full/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="$SCRIPT_DIR/dist"

echo "Building Kavex plugins..."
echo ""

# Clean previous build
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/kavex" "$DIST_DIR/kavex-full"

# ─────────────────────────────────────────────
# Plugin 1: kavex (lightweight — commands + skills)
# ─────────────────────────────────────────────
echo "Building kavex (lightweight)..."

cp -r "$SCRIPT_DIR/plugins/kavex/.claude-plugin" "$DIST_DIR/kavex/"
cp -r "$SCRIPT_DIR/plugins/kavex/commands"       "$DIST_DIR/kavex/"
cp -r "$SCRIPT_DIR/plugins/kavex/skills"         "$DIST_DIR/kavex/"
cp "$SCRIPT_DIR/README.md"                      "$DIST_DIR/kavex/"
cp "$SCRIPT_DIR/LICENSE"                        "$DIST_DIR/kavex/"

echo "  dist/kavex/ — commands + skills"

# ─────────────────────────────────────────────
# Plugin 2: kavex-full (complete — commands + skills + hooks + enforcement)
# ─────────────────────────────────────────────
echo "Building kavex-full (complete)..."

cp -r "$SCRIPT_DIR/.claude-plugin"  "$DIST_DIR/kavex-full/"
cp -r "$SCRIPT_DIR/commands"        "$DIST_DIR/kavex-full/"
cp -r "$SCRIPT_DIR/skills"          "$DIST_DIR/kavex-full/"
cp -r "$SCRIPT_DIR/hooks"           "$DIST_DIR/kavex-full/"
mkdir -p "$DIST_DIR/kavex-full/scripts"
cp "$SCRIPT_DIR/scripts/kavex"         "$DIST_DIR/kavex-full/scripts/"
cp "$SCRIPT_DIR/scripts/kavex-monitor" "$DIST_DIR/kavex-full/scripts/"
cp "$SCRIPT_DIR/README.md"            "$DIST_DIR/kavex-full/"
cp "$SCRIPT_DIR/LICENSE"              "$DIST_DIR/kavex-full/"

# Make scripts executable
chmod +x "$DIST_DIR/kavex-full/hooks/"*.sh
chmod +x "$DIST_DIR/kavex-full/hooks/lib/"*.sh
chmod +x "$DIST_DIR/kavex-full/scripts/"*

echo "  dist/kavex-full/ — commands + skills + hooks + scripts"

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────
echo ""
echo "Build complete!"
echo ""
echo "  dist/kavex/      — Lightweight plugin (commands + skills)"
echo "  dist/kavex-full/  — Full plugin (commands + skills + hooks + enforcement)"
echo ""
echo "To test locally:"
echo "  claude /install file://$DIST_DIR/kavex"
echo "  claude /install file://$DIST_DIR/kavex-full"
