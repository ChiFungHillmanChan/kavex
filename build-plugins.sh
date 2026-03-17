#!/bin/bash
# build-plugins.sh — Assemble kova and kova-full plugin directories for distribution
# Usage: bash build-plugins.sh
# Output: dist/kova/ and dist/kova-full/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="$SCRIPT_DIR/dist"

echo "Building Kova plugins..."
echo ""

# Clean previous build
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/kova" "$DIST_DIR/kova-full"

# ─────────────────────────────────────────────
# Plugin 1: kova (lightweight — commands + skills)
# ─────────────────────────────────────────────
echo "Building kova (lightweight)..."

cp -r "$SCRIPT_DIR/plugins/kova/.claude-plugin" "$DIST_DIR/kova/"
cp -r "$SCRIPT_DIR/plugins/kova/commands"       "$DIST_DIR/kova/"
cp -r "$SCRIPT_DIR/plugins/kova/skills"         "$DIST_DIR/kova/"
cp "$SCRIPT_DIR/README.md"                      "$DIST_DIR/kova/"
cp "$SCRIPT_DIR/LICENSE"                        "$DIST_DIR/kova/"

echo "  dist/kova/ — commands + skills"

# ─────────────────────────────────────────────
# Plugin 2: kova-full (complete — commands + skills + hooks + enforcement)
# ─────────────────────────────────────────────
echo "Building kova-full (complete)..."

cp -r "$SCRIPT_DIR/.claude-plugin"  "$DIST_DIR/kova-full/"
cp -r "$SCRIPT_DIR/commands"        "$DIST_DIR/kova-full/"
cp -r "$SCRIPT_DIR/skills"          "$DIST_DIR/kova-full/"
cp -r "$SCRIPT_DIR/hooks"           "$DIST_DIR/kova-full/"
mkdir -p "$DIST_DIR/kova-full/scripts"
cp "$SCRIPT_DIR/scripts/kova"         "$DIST_DIR/kova-full/scripts/"
cp "$SCRIPT_DIR/scripts/kova-monitor" "$DIST_DIR/kova-full/scripts/"
cp "$SCRIPT_DIR/README.md"            "$DIST_DIR/kova-full/"
cp "$SCRIPT_DIR/LICENSE"              "$DIST_DIR/kova-full/"

# Make scripts executable
chmod +x "$DIST_DIR/kova-full/hooks/"*.sh
chmod +x "$DIST_DIR/kova-full/hooks/lib/"*.sh
chmod +x "$DIST_DIR/kova-full/scripts/"*

echo "  dist/kova-full/ — commands + skills + hooks + scripts"

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────
echo ""
echo "Build complete!"
echo ""
echo "  dist/kova/      — Lightweight plugin (commands + skills)"
echo "  dist/kova-full/  — Full plugin (commands + skills + hooks + enforcement)"
echo ""
echo "To test locally:"
echo "  claude /install file://$DIST_DIR/kova"
echo "  claude /install file://$DIST_DIR/kova-full"
