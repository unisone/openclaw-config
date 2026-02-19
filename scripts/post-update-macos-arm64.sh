#!/bin/bash
# Post-Update Hook for macOS ARM64
# 
# Run this after `npm update -g openclaw` to reinstall native dependencies
# that get wiped during updates.
#
# Why this is needed:
# - @lancedb/lancedb-darwin-arm64 is an optional dependency
# - npm doesn't reinstall optionalDependencies on updates
# - The memory-lancedb plugin fails without it
#
# Usage:
#   chmod +x post-update-macos-arm64.sh
#   ./post-update-macos-arm64.sh
#
# Or add to your update cron:
#   npm update -g openclaw && /path/to/post-update-macos-arm64.sh

set -e

OPENCLAW_PATH="${OPENCLAW_PATH:-/opt/homebrew/lib/node_modules/openclaw}"

echo "🦞 OpenClaw Post-Update Hook (macOS ARM64)"
echo "   Installing native dependencies..."

cd "$OPENCLAW_PATH"

# Install LanceDB ARM64 native binary
npm install @lancedb/lancedb-darwin-arm64@0.24.1 --no-save

echo "✅ Done. Native dependencies installed."
echo "   Restart the gateway: openclaw gateway restart"
