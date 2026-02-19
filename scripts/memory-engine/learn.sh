#!/bin/bash
# LEARN — Overnight consolidation + insight generation
# Run: ./learn.sh
# Processes daily files, finds patterns, updates MEMORY.md, generates insights

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(cd "$SCRIPT_DIR/../.." && pwd)"
STORE="$WORKSPACE/memory/store.json"
DAILY_DIR="$WORKSPACE/memory"
MEMORY_FILE="$WORKSPACE/MEMORY.md"
CONFIG="$SCRIPT_DIR/config.json"
TODAY=$(date +%Y-%m-%d)
ARCHIVE="$DAILY_DIR/archive"

mkdir -p "$ARCHIVE"

echo "🧠 Overnight learning cycle: $TODAY"
echo "======================================="

# PHASE 1: Capture from all recent daily files not yet processed
echo ""
echo "📸 Phase 1: Capture from recent daily files"

CONSOLIDATE_DAYS=$(jq '.learn.consolidateAfterDays' "$CONFIG")
PROCESSED=0

for f in "$DAILY_DIR"/2026-*.md; do
  [ -f "$f" ] || continue
  BASENAME=$(basename "$f" .md)
  
  # Skip if already in archive marker
  if [ -f "$ARCHIVE/.processed-$BASENAME" ]; then
    continue
  fi
  
  echo "   Processing: $BASENAME"
  bash "$SCRIPT_DIR/capture.sh" "$f"
  touch "$ARCHIVE/.processed-$BASENAME"
  PROCESSED=$((PROCESSED + 1))
done

echo "   Processed $PROCESSED daily files"

# PHASE 2: Run decay
echo ""
echo "🔻 Phase 2: Decay pass"
bash "$SCRIPT_DIR/decay.sh"

# PHASE 3: Pattern detection
echo ""
echo "🔗 Phase 3: Pattern detection"

if [ -f "$STORE" ]; then
  TOTAL=$(jq '.memories | length' "$STORE")
  
  # Find frequently co-occurring topics
  echo "   Analyzing $TOTAL memories for patterns..."
  
  # Category distribution
  echo "   Category distribution:"
  jq -r '.memories | group_by(.category) | .[] | "     \(.[0].category): \(length) memories (avg score: \([.[].score] | add / length * 100 | round / 100))"' "$STORE" 2>/dev/null || echo "     (no categories yet)"
  
  # Top scored memories (potential long-term candidates)
  echo ""
  echo "   🌟 Top 5 highest-scored memories:"
  jq -r '[.memories | sort_by(-.score)][:5][] | "     [\(.score | . * 100 | round / 100)] \(.content | .[0:80])..."' "$STORE" 2>/dev/null || echo "     (none yet)"
  
  # Most accessed (behavioral patterns)
  echo ""
  echo "   🔄 Most accessed (behavioral patterns):"
  jq -r '[.memories | sort_by(-.accessCount) | .[:5]][] | "     [×\(.accessCount)] \(.content | .[0:80])..."' "$STORE" 2>/dev/null || echo "     (none yet)"
  
  # Stale memories (not accessed in > consolidate days)
  STALE=$(jq --argjson days "$CONSOLIDATE_DAYS" --arg today "$TODAY" '
    [.memories[] | 
     select(.accessCount == 0) |
     select(.score < 0.5)
    ] | length
  ' "$STORE")
  echo ""
  echo "   🧹 Stale (never recalled, low score): $STALE"
fi

# PHASE 4: Self-review (extract MISS/FIX from daily logs)
echo ""
echo "🔍 Phase 4: Self-review"
bash "$SCRIPT_DIR/self-review.sh" "$TODAY" 2>/dev/null || echo "   (self-review skipped)"

# PHASE 5: Generate insights file
echo ""
echo "💡 Phase 5: Generate insights"

INSIGHTS_FILE="$DAILY_DIR/insights-$TODAY.md"

cat > "$INSIGHTS_FILE" << EOF
# Memory Insights — $TODAY

## Store Stats
$(jq -r '
  "- Total memories: \(.memories | length)",
  "- Average score: \([.memories[].score] | if length > 0 then (add / length * 100 | round / 100) else 0 end)",
  "- Last capture: \(.meta.lastCapture // "never")",
  "- Last decay: \(.meta.lastDecay // "never")",
  "- Last learn: \(.meta.lastLearn // "never")"
' "$STORE" 2>/dev/null || echo "- No store data")

## Category Breakdown
$(jq -r '.memories | group_by(.category) | .[] | "- **\(.[0].category)**: \(length) items"' "$STORE" 2>/dev/null || echo "- No categories")

## High-Value Memories (score > 1.0)
$(jq -r '[.memories[] | select(.score > 1.0) | "- [\(.score | . * 100 | round / 100)] \(.content | .[0:100])"] | join("\n")' "$STORE" 2>/dev/null || echo "- None")

## Patterns Detected
$(jq -r '
  # Most common words across memories
  [.memories[].content | ascii_downcase | split(" ") | .[] | select(length > 4)] | 
  group_by(.) | sort_by(-length) | .[:10][] |
  "- \"\(.[0])\": appears \(length) times"
' "$STORE" 2>/dev/null || echo "- Insufficient data")

## Recommendations
- Review high-value memories for MEMORY.md promotion
- Check stale memories for relevance
- Monitor category balance
EOF

echo "   Written to: $INSIGHTS_FILE"

# Update meta
if [ -f "$STORE" ]; then
  jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '.meta.lastLearn = $ts' "$STORE" > "${STORE}.tmp" && mv "${STORE}.tmp" "$STORE"
fi

echo ""
echo "✅ Learning cycle complete"
echo "   Run 'recall.sh' to test semantic retrieval"
echo "   Run 'cat $INSIGHTS_FILE' for full analysis"
