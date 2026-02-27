#!/bin/bash
# AGI Learning Script - Analyzes errors and generates rule proposals
# Run nightly or manually after significant corrections

set -e
CLAWD_DIR="${CLAWD_DIR:-$HOME/clawd}"
TODAY=$(date +%Y-%m-%d)
OUTPUT="$CLAWD_DIR/.learnings/analysis-$TODAY.md"

echo "# Learning Analysis - $TODAY" > "$OUTPUT"
echo "" >> "$OUTPUT"

# 1. Analyze ERRORS.md for patterns
echo "## Error Patterns" >> "$OUTPUT"
if [ -f "$CLAWD_DIR/.learnings/ERRORS.md" ]; then
    # Extract unique error types
    grep "^### " "$CLAWD_DIR/.learnings/ERRORS.md" | sort | uniq -c | sort -rn >> "$OUTPUT"
fi
echo "" >> "$OUTPUT"

# 2. Check for repeated mistakes (same pattern twice = mandatory rule)
echo "## Repeated Mistakes (MANDATORY RULES NEEDED)" >> "$OUTPUT"
if [ -f "$CLAWD_DIR/.learnings/ERRORS.md" ]; then
    # Find lessons that appear multiple times
    grep "Lesson:" "$CLAWD_DIR/.learnings/ERRORS.md" | sort | uniq -d >> "$OUTPUT" || echo "None found" >> "$OUTPUT"
fi
echo "" >> "$OUTPUT"

# 3. Extract correction keywords from recent memory
echo "## Recent Correction Keywords" >> "$OUTPUT"
for file in "$CLAWD_DIR"/memory/2026-02-0*.md; do
    if [ -f "$file" ]; then
        grep -oE "(never|always|don't|should|must|required)" "$file" 2>/dev/null | sort | uniq -c | sort -rn | head -10 >> "$OUTPUT" || true
    fi
done
echo "" >> "$OUTPUT"

# 4. Generate rule proposals
echo "## Proposed Rules for AGENTS.md" >> "$OUTPUT"
echo "" >> "$OUTPUT"
echo "Based on analysis, consider adding:" >> "$OUTPUT"
echo "" >> "$OUTPUT"

# Check for common anti-patterns
if grep -q "half-ass" "$CLAWD_DIR/.learnings/ERRORS.md" 2>/dev/null; then
    echo "- [ ] **Research completeness rule**: Never present research as complete without checking all specified sources" >> "$OUTPUT"
fi

if grep -q "generic\|zero value" "$CLAWD_DIR/.learnings/ERRORS.md" 2>/dev/null; then
    echo "- [ ] **Value density rule**: Every piece of content must contain specific, actionable information" >> "$OUTPUT"
fi

if grep -q "premature\|without evidence" "$CLAWD_DIR/.learnings/ERRORS.md" 2>/dev/null; then
    echo "- [ ] **Evidence-first rule**: Never recommend solutions without concrete supporting evidence" >> "$OUTPUT"
fi

if grep -q "memory\|forgot\|context" "$CLAWD_DIR/.learnings/ERRORS.md" 2>/dev/null; then
    echo "- [ ] **Memory-first rule**: Always search memory before answering questions about past events" >> "$OUTPUT"
fi

echo "" >> "$OUTPUT"
echo "## Self-Review Items" >> "$OUTPUT"
echo "Copy high-priority items to memory/self-review.md:" >> "$OUTPUT"
grep -h "Lesson:" "$CLAWD_DIR/.learnings/ERRORS.md" 2>/dev/null | tail -5 >> "$OUTPUT" || echo "None" >> "$OUTPUT"

echo ""
echo "Analysis complete: $OUTPUT"
cat "$OUTPUT"
