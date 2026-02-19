#!/bin/bash
# SELF-REVIEW — Nightly self-assessment from daily logs
# Reads today's daily file, extracts actual misses/fixes, appends to memory/self-review.md
# Run: ./self-review.sh [date]   (default: today)

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(cd "$SCRIPT_DIR/../.." && pwd)"
DAILY_DIR="$WORKSPACE/memory"
REVIEW_FILE="$DAILY_DIR/self-review.md"
TARGET_DATE="${1:-$(date +%Y-%m-%d)}"
DAILY_FILE="$DAILY_DIR/$TARGET_DATE.md"

echo "🔍 Self-review: $TARGET_DATE"
echo "================================"

if [ ! -f "$DAILY_FILE" ]; then
  echo "   No daily file for $TARGET_DATE — skipping"
  exit 0
fi

# Initialize review file if missing
if [ ! -f "$REVIEW_FILE" ]; then
  cat > "$REVIEW_FILE" << 'HEADER'
# Self-Review Log

Agent self-assessment from daily activity. Entries are MISS/FIX pairs extracted from actual errors, corrections, and wasted effort. Read on boot to avoid repeating mistakes.

---
HEADER
  echo "   Created $REVIEW_FILE"
fi

# Extract signals from daily file
CONTENT=$(cat "$DAILY_FILE")
LINE_COUNT=$(wc -l < "$DAILY_FILE" | tr -d ' ')

echo "   Daily file: $LINE_COUNT lines"

# Look for error/correction signals
ERRORS=$(grep -ci -E "error|fail|wrong|broke|bug|fix|issue|overflow|corrupt" "$DAILY_FILE" 2>/dev/null || echo "0")
CORRECTIONS=$(grep -ci -E "actually|not that|should be|was wrong|my bad|misunderstood" "$DAILY_FILE" 2>/dev/null || echo "0")
RESETS=$(grep -ci -E "reset|restart|wipe|rebuild|re-do" "$DAILY_FILE" 2>/dev/null || echo "0")

echo "   Signals: errors=$ERRORS corrections=$CORRECTIONS resets=$RESETS"

# Only write an entry if there were actual problems
TOTAL=$((ERRORS + CORRECTIONS + RESETS))
if [ "$TOTAL" -eq 0 ]; then
  echo "   Clean day — no misses detected"
  exit 0
fi

# Extract relevant lines (context around problems)
echo "" >> "$REVIEW_FILE"
echo "## $TARGET_DATE" >> "$REVIEW_FILE"
echo "" >> "$REVIEW_FILE"

# Errors
if [ "$ERRORS" -gt 0 ]; then
  echo "**Errors detected: $ERRORS**" >> "$REVIEW_FILE"
  grep -i -E "error|fail|wrong|broke|bug|overflow|corrupt" "$DAILY_FILE" | head -5 | while read -r line; do
    echo "- MISS: $line" >> "$REVIEW_FILE"
  done
  echo "" >> "$REVIEW_FILE"
fi

# Corrections
if [ "$CORRECTIONS" -gt 0 ]; then
  echo "**Corrections: $CORRECTIONS**" >> "$REVIEW_FILE"
  grep -i -E "actually|not that|should be|was wrong|my bad|misunderstood" "$DAILY_FILE" | head -5 | while read -r line; do
    echo "- FIX: $line" >> "$REVIEW_FILE"
  done
  echo "" >> "$REVIEW_FILE"
fi

# Resets
if [ "$RESETS" -gt 0 ]; then
  echo "**Resets/Rebuilds: $RESETS**" >> "$REVIEW_FILE"
  grep -i -E "reset|restart|wipe|rebuild|re-do" "$DAILY_FILE" | head -3 | while read -r line; do
    echo "- RESET: $line" >> "$REVIEW_FILE"
  done
  echo "" >> "$REVIEW_FILE"
fi

# Summary tags
echo "**Tags:** " >> "$REVIEW_FILE"
[ "$ERRORS" -gt 3 ] && echo "- [reliability] Multiple errors — check tooling stability" >> "$REVIEW_FILE"
[ "$CORRECTIONS" -gt 2 ] && echo "- [accuracy] Multiple corrections — slow down, verify before responding" >> "$REVIEW_FILE"
[ "$RESETS" -gt 1 ] && echo "- [stability] Multiple resets — investigate root cause" >> "$REVIEW_FILE"
echo "" >> "$REVIEW_FILE"
echo "---" >> "$REVIEW_FILE"

echo "   ✅ Review entry written to $REVIEW_FILE"
echo "   Total signals: $TOTAL (errors=$ERRORS corrections=$CORRECTIONS resets=$RESETS)"
