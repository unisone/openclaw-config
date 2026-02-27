#!/bin/bash
# Extract corrections and learnings from recent conversations
# Scans memory files for correction patterns and outputs structured learning

set -e
CLAWD_DIR="${CLAWD_DIR:-$HOME/clawd}"
OUTPUT_FILE="$CLAWD_DIR/.learnings/extracted-$(date +%Y-%m-%d).md"

echo "# Extracted Corrections - $(date +%Y-%m-%d)" > "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Patterns that indicate corrections
PATTERNS="no,? that's wrong|actually|I meant|not what I asked|wrong|mistake|correction|should be|instead of|don't do|never do|always do"

echo "## From Memory Files" >> "$OUTPUT_FILE"
for file in "$CLAWD_DIR"/memory/2026-02-*.md; do
    if [ -f "$file" ]; then
        MATCHES=$(grep -i -E "$PATTERNS" "$file" 2>/dev/null || true)
        if [ -n "$MATCHES" ]; then
            echo "" >> "$OUTPUT_FILE"
            echo "### $(basename "$file")" >> "$OUTPUT_FILE"
            echo "$MATCHES" >> "$OUTPUT_FILE"
        fi
    fi
done

echo "" >> "$OUTPUT_FILE"
echo "## Pattern Analysis" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Count patterns
echo "### Frequency" >> "$OUTPUT_FILE"
for pattern in "wrong" "actually" "mistake" "correction" "should be"; do
    COUNT=$(grep -ri "$pattern" "$CLAWD_DIR/memory/2026-02-"*.md 2>/dev/null | wc -l | tr -d ' ')
    echo "- $pattern: $COUNT occurrences" >> "$OUTPUT_FILE"
done

echo "" >> "$OUTPUT_FILE"
echo "## Suggested Rules" >> "$OUTPUT_FILE"
echo "[To be filled by analysis]" >> "$OUTPUT_FILE"

echo "Extracted to $OUTPUT_FILE"
cat "$OUTPUT_FILE"
