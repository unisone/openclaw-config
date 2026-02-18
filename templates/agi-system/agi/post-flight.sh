#!/bin/bash
# AGI Post-Flight Logger - Run after completing tasks
# Usage: post-flight.sh "task description" "outcome" ["error details"]

set -e
CLAWD_DIR="${CLAWD_DIR:-/Users/danbot/clawd}"
TODAY=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%H:%M)
MEMORY_FILE="$CLAWD_DIR/memory/$TODAY.md"

TASK="${1:-unspecified task}"
OUTCOME="${2:-completed}"
ERROR_DETAILS="${3:-}"

# Ensure memory file exists
if [ ! -f "$MEMORY_FILE" ]; then
    echo "# $TODAY" > "$MEMORY_FILE"
fi

# Log the task
echo "" >> "$MEMORY_FILE"
echo "### [$TIMESTAMP] $TASK" >> "$MEMORY_FILE"
echo "- **Outcome:** $OUTCOME" >> "$MEMORY_FILE"

# If there was an error, log it
if [ -n "$ERROR_DETAILS" ]; then
    echo "- **Error:** $ERROR_DETAILS" >> "$MEMORY_FILE"
    
    # Also append to ERRORS.md
    ERRORS_FILE="$CLAWD_DIR/.learnings/ERRORS.md"
    echo "" >> "$ERRORS_FILE"
    echo "### $TODAY - $TASK" >> "$ERRORS_FILE"
    echo "**What happened:** $ERROR_DETAILS" >> "$ERRORS_FILE"
    echo "**Why it failed:** [TO BE ANALYZED]" >> "$ERRORS_FILE"
    echo "**Fix applied:** [PENDING]" >> "$ERRORS_FILE"
    echo "**Lesson:** [PENDING]" >> "$ERRORS_FILE"
fi

echo "Logged to $MEMORY_FILE"
