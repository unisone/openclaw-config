#!/bin/bash
# AGI Pre-Flight Check - Run before complex tasks
# Outputs context that should be reviewed before responding

set -e
CLAWD_DIR="${CLAWD_DIR:-/Users/danbot/clawd}"
TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -v-1d +%Y-%m-%d 2>/dev/null || date -d "yesterday" +%Y-%m-%d)

echo "=== AGI PRE-FLIGHT CHECK ==="
echo "Date: $TODAY"
echo ""

# 1. Recent errors to avoid
echo "## Recent Errors (last 7 days)"
if [ -f "$CLAWD_DIR/.learnings/ERRORS.md" ]; then
    # Extract last 3 error entries
    grep -A5 "^### " "$CLAWD_DIR/.learnings/ERRORS.md" | tail -30
else
    echo "No errors file found"
fi
echo ""

# 2. Self-review items
echo "## Self-Review Items"
if [ -f "$CLAWD_DIR/memory/self-review.md" ]; then
    cat "$CLAWD_DIR/memory/self-review.md"
else
    echo "No self-review file"
fi
echo ""

# 3. Recent corrections from memory files
echo "## Recent Corrections (from memory)"
for file in "$CLAWD_DIR/memory/$TODAY.md" "$CLAWD_DIR/memory/$YESTERDAY.md"; do
    if [ -f "$file" ]; then
        grep -i -E "(correction|wrong|actually|mistake|no that)" "$file" 2>/dev/null | head -10
    fi
done
echo ""

# 4. Active blockers
echo "## Active Blockers"
if [ -f "$CLAWD_DIR/MEMORY.md" ]; then
    grep -A2 "Blocker" "$CLAWD_DIR/MEMORY.md" 2>/dev/null | head -10
fi
echo ""

echo "=== PRE-FLIGHT COMPLETE ==="
