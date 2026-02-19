#!/bin/bash
# AGI System Installer (workspace scaffolding)
#
# Installs the optional AGI self-review / learn loop scaffolding into a target workspace.
#
# Usage:
#   ./install.sh [TARGET_WORKSPACE]
#
# Defaults:
#   $OPENCLAW_WORKSPACE  (if set)
#   ~/.openclaw/workspace

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TARGET_WORKSPACE="${1:-${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}}"

echo "Installing AGI system to: $TARGET_WORKSPACE"

# Create directories
mkdir -p "$TARGET_WORKSPACE/scripts/agi" \
         "$TARGET_WORKSPACE/.learnings" \
         "$TARGET_WORKSPACE/memory" \
         "$TARGET_WORKSPACE/docs"

# Copy scripts
cp -r "$SCRIPT_DIR/agi/." "$TARGET_WORKSPACE/scripts/agi/"
chmod +x "$TARGET_WORKSPACE/scripts/agi/"*.sh || true

# Copy templates
cp "$SCRIPT_DIR/THINKING.md" "$TARGET_WORKSPACE/"
cp "$SCRIPT_DIR/self-review.md" "$TARGET_WORKSPACE/memory/"
cp "$SCRIPT_DIR/AGI-SYSTEM.md" "$TARGET_WORKSPACE/docs/"

# Create empty learnings files
: > "$TARGET_WORKSPACE/.learnings/ERRORS.md"
: > "$TARGET_WORKSPACE/.learnings/LEARNINGS.md"

cat <<'EOF'

✅ AGI system installed.

Next steps:
1) Merge `AGENTS-AGI-PATCH.md` into your `AGENTS.md` (optional)
2) Add scheduled jobs if you want automated learning (see docs/AGI-SYSTEM.md)

EOF
