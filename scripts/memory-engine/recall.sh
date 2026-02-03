#!/bin/bash
# RECALL — Semantic context loading at session start
# Run: ./recall.sh "context query or topic"
# Returns top-scored memories relevant to the current context

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(cd "$SCRIPT_DIR/../.." && pwd)"
STORE="$WORKSPACE/memory/store.json"
CONFIG="$SCRIPT_DIR/config.json"

if [ ! -f "$STORE" ]; then
  echo "No memory store. Nothing to recall."
  exit 0
fi

QUERY="${1:-}"
MAX_RESULTS=$(jq '.recall.maxResults' "$CONFIG")
MIN_RELEVANCE=$(jq '.recall.minRelevance' "$CONFIG")

TOTAL=$(jq '.memories | length' "$STORE")

if [ "$TOTAL" -eq 0 ]; then
  echo "Memory store is empty."
  exit 0
fi

echo "🔍 Recalling from $TOTAL memories..."

if [ -z "$QUERY" ]; then
  # No query — return top scored memories (general recall)
  echo "   Mode: top-scored (no context query)"
  jq -r --argjson max "$MAX_RESULTS" '
    [.memories | sort_by(-.score) | .[:$max][] |
     "[\(.score | . * 100 | round / 100)] [\(.category)] \(.content)"
    ] | join("\n")
  ' "$STORE"
else
  # Query-based — simple keyword matching + score weighting
  echo "   Mode: semantic (query: $QUERY)"
  
  # Split query into keywords
  KEYWORDS=$(echo "$QUERY" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' '\n' | sort -u | tr '\n' '|' | sed 's/|$//')
  
  if [ -z "$KEYWORDS" ]; then
    echo "   No valid keywords in query."
    exit 0
  fi
  
  # Score each memory: base score + keyword match bonus
  TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  
  jq -r --arg keywords "$KEYWORDS" \
         --argjson max "$MAX_RESULTS" \
         --arg ts "$TIMESTAMP" '
    # Count keyword matches in content
    [.memories[] |
      (.content | ascii_downcase) as $lower |
      ($keywords | split("|")) as $kws |
      ([$kws[] | select(. != "") | select($lower | contains(.))] | length) as $matches |
      select($matches > 0) |
      {
        content: .content,
        score: .score,
        category: .category,
        matches: $matches,
        relevance: (.score * (1 + ($matches * 0.5))),
        source: .source
      }
    ] | sort_by(-.relevance) | .[:$max][] |
    "[\(.relevance | . * 100 | round / 100)] [\(.category)] \(.content)"
  ' "$STORE"
  
  # Boost access count for recalled memories
  jq --arg keywords "$KEYWORDS" \
     --arg ts "$TIMESTAMP" '
    .memories = [.memories[] |
      (.content | ascii_downcase) as $lower |
      ($keywords | split("|")) as $kws |
      ([$kws[] | select(. != "") | select($lower | contains(.))] | length) as $matches |
      if $matches > 0 then
        .accessCount += 1 |
        .lastAccessed = $ts |
        .score = ([.score + 0.1, 2.0] | min)
      else . end
    ]
  ' "$STORE" > "${STORE}.tmp" && mv "${STORE}.tmp" "$STORE"
fi

echo ""
echo "   ✅ Recall complete"
