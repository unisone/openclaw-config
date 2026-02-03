#!/bin/bash
# DECAY — Daily relevance scoring + noise reduction
# Run: ./decay.sh
# Applies exponential decay to memory scores, archives low-scorers

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(cd "$SCRIPT_DIR/../.." && pwd)"
STORE="$WORKSPACE/memory/store.json"
ARCHIVE="$WORKSPACE/memory/archive"
TODAY=$(date +%Y-%m-%d)
CONFIG="$SCRIPT_DIR/config.json"

if [ ! -f "$STORE" ]; then
  echo "No store found. Run capture first."
  exit 0
fi

mkdir -p "$ARCHIVE"

HALF_LIFE=$(jq '.decay.halfLifeDays' "$CONFIG")
MIN_SCORE=$(jq '.decay.minScore' "$CONFIG")
TOTAL=$(jq '.memories | length' "$STORE")

echo "🔻 Decay pass: $TOTAL memories (half-life: ${HALF_LIFE}d, floor: $MIN_SCORE)"

# Calculate decay factor: score * 0.5^(days_since_access / half_life)
# Using jq for the math
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
NOW_EPOCH=$(date +%s)

# Apply decay to each memory based on days since last access
jq --argjson halfLife "$HALF_LIFE" \
   --argjson minScore "$MIN_SCORE" \
   --argjson now "$NOW_EPOCH" \
   --arg today "$TODAY" \
   '
   # Category weights
   .memories = [.memories[] | 
     # Calculate days since last accessed
     (.lastAccessed | split("T")[0] | split("-") | 
      (.[0] | tonumber) * 365 + (.[1] | tonumber) * 30 + (.[2] | tonumber)) as $accessDay |
     ($today | split("-") | 
      (.[0] | tonumber) * 365 + (.[1] | tonumber) * 30 + (.[2] | tonumber)) as $todayDay |
     ($todayDay - $accessDay) as $daysSince |
     
     # Exponential decay approximation: score * (1 - ln2/halfLife)^days
     # Using iterative halving: each halfLife period halves the score
     (if $daysSince > 0 then
       ($daysSince / $halfLife) as $periods |
       .score * (if $periods >= 4 then 0.0625
                 elif $periods >= 3 then 0.125
                 elif $periods >= 2 then 0.25
                 elif $periods >= 1 then 0.5
                 elif $periods >= 0.5 then 0.7
                 elif $periods > 0 then 0.85
                 else 1 end)
     else
       .score
     end) as $newScore |
     
     # Apply category boost (corrections and decisions decay slower)
     (if .category == "correction" then ($newScore * 1.5)
      elif .category == "decision" then ($newScore * 1.3)
      elif .category == "preference" then ($newScore * 1.2)
      elif .category == "person" then ($newScore * 1.4)
      else $newScore
      end) as $boostedScore |
     
     # Access count boost (frequently recalled = more important)
     (if .accessCount > 5 then ($boostedScore * 1.2)
      elif .accessCount > 2 then ($boostedScore * 1.1)
      else $boostedScore
      end) as $finalScore |
     
     .score = ([$finalScore, $minScore] | max) |
     
     # Cap at 2.0 max
     .score = ([.score, 2.0] | min)
   ] |
   .meta.lastDecay = $today
   ' "$STORE" > "${STORE}.tmp" && mv "${STORE}.tmp" "$STORE"

# Archive memories below threshold
BELOW=$(jq --argjson min "$MIN_SCORE" '[.memories[] | select(.score <= ($min * 1.5))] | length' "$STORE")
ARCHIVED=0

if [ "$BELOW" -gt 0 ]; then
  # Move low-score memories to archive
  jq --argjson min "$MIN_SCORE" \
     '[.memories[] | select(.score <= ($min * 1.5))]' "$STORE" > "$ARCHIVE/decayed-$TODAY.json"
  
  # Remove from active store
  jq --argjson min "$MIN_SCORE" \
     '.memories = [.memories[] | select(.score > ($min * 1.5))]' "$STORE" > "${STORE}.tmp" && mv "${STORE}.tmp" "$STORE"
  
  ARCHIVED=$(jq 'length' "$ARCHIVE/decayed-$TODAY.json")
  echo "   📦 Archived $ARCHIVED low-relevance memories"
fi

REMAINING=$(jq '.memories | length' "$STORE")
AVG_SCORE=$(jq '[.memories[].score] | if length > 0 then (add / length * 100 | round / 100) else 0 end' "$STORE")

echo "   ✅ Decay complete: $REMAINING active (avg score: $AVG_SCORE), $ARCHIVED archived"
