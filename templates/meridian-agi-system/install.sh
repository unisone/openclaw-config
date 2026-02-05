#!/bin/bash
# Meridian AGI System Installer
set -e

MERIDIAN_WORKSPACE="${MERIDIAN_WORKSPACE:-~/meridian-workspace}"

echo "Installing AGI system to $MERIDIAN_WORKSPACE..."

# Create directories
mkdir -p "$MERIDIAN_WORKSPACE/scripts/agi"
mkdir -p "$MERIDIAN_WORKSPACE/.learnings"
mkdir -p "$MERIDIAN_WORKSPACE/memory"

# Copy scripts
cp -r agi/* "$MERIDIAN_WORKSPACE/scripts/agi/"
chmod +x "$MERIDIAN_WORKSPACE/scripts/agi/"*.sh

# Copy templates
cp THINKING.md "$MERIDIAN_WORKSPACE/"
cp self-review.md "$MERIDIAN_WORKSPACE/memory/"
cp AGI-SYSTEM.md "$MERIDIAN_WORKSPACE/docs/" 2>/dev/null || mkdir -p "$MERIDIAN_WORKSPACE/docs" && cp AGI-SYSTEM.md "$MERIDIAN_WORKSPACE/docs/"

# Create empty learnings files
touch "$MERIDIAN_WORKSPACE/.learnings/ERRORS.md"
touch "$MERIDIAN_WORKSPACE/.learnings/LEARNINGS.md"

echo ""
echo "✅ AGI system installed!"
echo ""
echo "Next steps:"
echo "1. Add AGENTS-AGI-PATCH.md content to your AGENTS.md"
echo "2. Set up the crons (see AGI-SYSTEM.md)"
echo ""
