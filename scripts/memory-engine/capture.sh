#!/bin/bash
# CAPTURE — Extract structured memories from session transcripts
# Run: ./capture.sh [session_log_path]
# Extracts facts, preferences, decisions, corrections into store.json

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(cd "$SCRIPT_DIR/../.." && pwd)"
STORE="$WORKSPACE/memory/store.json"
DAILY_DIR="$WORKSPACE/memory"
TODAY=$(date +%Y-%m-%d)
CONFIG="$SCRIPT_DIR/config.json"

# Initialize store if needed
if [ ! -f "$STORE" ]; then
  echo '{"memories": [], "meta": {"created": "'$TODAY'", "lastCapture": null, "lastDecay": null, "lastLearn": null}}' > "$STORE"
fi

# Source can be a session log or today's daily file
SOURCE="${1:-$DAILY_DIR/$TODAY.md}"

if [ ! -f "$SOURCE" ]; then
  echo "No source found: $SOURCE"
  exit 0
fi

echo "📸 Capturing from: $SOURCE"
echo "   Store: $STORE"

# Extract candidate memories using pattern matching
# Categories: fact, preference, decision, insight, todo, correction, person, project

TEMP=$(mktemp)

# Facts — statements with "is", "has", "uses", specific details
grep -iE "(name is|lives in|works at|uses |prefers |timezone|email|github|twitter|linkedin|phone)" "$SOURCE" 2>/dev/null | head -20 >> "$TEMP" || true

# Preferences — "likes", "wants", "prefers", "always", "never"
grep -iE "(likes? |loves? |hates? |prefers? |wants? |always |never |favorite)" "$SOURCE" 2>/dev/null | head -20 >> "$TEMP" || true

# Decisions — "decided", "going with", "let's do", "approved"
grep -iE "(decided|going with|let's (do|go|use)|approved|confirmed|chose|picked|selected)" "$SOURCE" 2>/dev/null | head -20 >> "$TEMP" || true

# Corrections — "actually", "no,", "wrong", "not X, Y"
grep -iE "(actually[, ]|^no[, ]|that's wrong|not .+, .+|correction:|fix:|should be)" "$SOURCE" 2>/dev/null | head -10 >> "$TEMP" || true

# Todos — "todo", "need to", "should", "remind me"
grep -iE "(todo|need to|should |remind me|don't forget|follow up|next step)" "$SOURCE" 2>/dev/null | head -10 >> "$TEMP" || true

# Project mentions — repo names, tech stack, URLs
grep -iE "(repo:|github\.com|vercel\.app|stack:|deployed|launched|shipped|published)" "$SOURCE" 2>/dev/null | head -10 >> "$TEMP" || true

CANDIDATE_COUNT=$(wc -l < "$TEMP" | tr -d ' ')
echo "   Found $CANDIDATE_COUNT candidate memories"

if [ "$CANDIDATE_COUNT" -eq 0 ]; then
  rm "$TEMP"
  echo "   Nothing to capture."
  exit 0
fi

# Deduplicate against existing store
EXISTING_COUNT=$(jq '.memories | length' "$STORE")
echo "   Existing memories: $EXISTING_COUNT"

# Add new memories with metadata
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
NEW_COUNT=0

while IFS= read -r line; do
  # Skip empty lines and very short ones
  [ ${#line} -lt 10 ] && continue
  
  # Clean the line
  CLEAN=$(echo "$line" | sed 's/^[[:space:]]*[-*#>]*[[:space:]]*//' | sed 's/[[:space:]]*$//')
  [ ${#CLEAN} -lt 10 ] && continue
  
  # Check for near-duplicate (exact match on first 50 chars)
  PREFIX=$(echo "$CLEAN" | cut -c1-50)
  DUPE=$(jq --arg p "$PREFIX" '[.memories[].content | startswith($p)] | any' "$STORE" 2>/dev/null || echo "false")
  
  if [ "$DUPE" = "false" ]; then
    # Detect category from content
    CAT="fact"  # default fallback
    LOWER=$(echo "$CLEAN" | tr '[:upper:]' '[:lower:]')
    
    if echo "$LOWER" | grep -qiE "(don't|dont|never |always |wrong|fix:|mistake|correction:|should be|that's wrong|actually[, ])"; then
      CAT="correction"
    elif echo "$LOWER" | grep -qiE "(decided|chose|approved|rejected|switched to|going with|let's (do|go|use)|confirmed|picked|selected)"; then
      CAT="decision"
    elif echo "$LOWER" | grep -qiE "(prefers?|likes?[[:space:]]|dislikes?|wants?[[:space:]]|hates?|values?[[:space:]]|loves?[[:space:]]|favorite)"; then
      CAT="preference"
    elif echo "$LOWER" | grep -qiE "(todo|\\[ \\]|still need|pending|awaiting|need to|remind me|don't forget|follow up|next step)"; then
      CAT="todo"
    elif echo "$LOWER" | grep -qiE "(repo:|stack:|built[[:space:]]|shipped|deployed|pr[[:space:]]#|pr[[:space:]][0-9]|github\.com|vercel\.app|launched|published)"; then
      CAT="project"
    elif echo "$LOWER" | grep -qiE "(@[a-z]|username|contact|email:|twitter:|github:|linkedin:|phone:)" || echo "$CLEAN" | grep -qE "([A-Z][a-z]+ [A-Z][a-z]+)"; then
      CAT="people"
    elif echo "$LOWER" | grep -qiE "(learned|realized|key insight|important:|note:|takeaway|pattern:)"; then
      CAT="insight"
    fi

    # Add to store with initial score of 1.0
    jq --arg content "$CLEAN" \
       --arg ts "$TIMESTAMP" \
       --arg source "$(basename "$SOURCE")" \
       --arg cat "$CAT" \
       '.memories += [{"content": $content, "score": 1.0, "created": $ts, "lastAccessed": $ts, "source": $source, "category": $cat, "accessCount": 0}]' \
       "$STORE" > "${STORE}.tmp" && mv "${STORE}.tmp" "$STORE"
    NEW_COUNT=$((NEW_COUNT + 1))
  fi
done < "$TEMP"

# Update meta
jq --arg ts "$TIMESTAMP" '.meta.lastCapture = $ts' "$STORE" > "${STORE}.tmp" && mv "${STORE}.tmp" "$STORE"

rm "$TEMP"
TOTAL=$(jq '.memories | length' "$STORE")
echo "   ✅ Captured $NEW_COUNT new memories (total: $TOTAL)"
