#!/bin/bash
# generate-reel.sh — Main reel generation pipeline
#
# Usage: ./generate-reel.sh <brief.json> [--no-ai] [--no-tts]
# Output: Reel video + manifest in output/<timestamp>/
#
# Pipeline:
#   1. Read JSON brief
#   2. Generate beat frames (AI backgrounds + text overlays)
#   3. Stitch into video with Ken Burns + crossfades
#   4. Add TTS voiceover (optional)
#   5. Output final reel

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"
OUTPUT_BASE="${SCRIPT_DIR}/output"

BRIEF="${1:?Usage: generate-reel.sh <brief.json> [--no-ai] [--no-tts]}"
NO_AI=""
TTS=""

# Parse optional flags
for arg in "${@:2}"; do
  case "$arg" in
    --no-ai) NO_AI="--no-ai" ;;
    --tts) TTS="--tts" ;;
  esac
done

if [[ ! -f "$BRIEF" ]]; then
  echo "ERROR: Brief not found: ${BRIEF}" >&2
  exit 1
fi

# Create timestamped working directory
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
TOPIC_SLUG=$(python3 -c "
import json, re
with open('${BRIEF}') as f:
    b = json.load(f)
slug = re.sub(r'[^a-z0-9]+', '-', b.get('topic', 'untitled').lower())[:40].strip('-')
print(slug)
")
WORKDIR="${OUTPUT_BASE}/${TIMESTAMP}-${TOPIC_SLUG}"
mkdir -p "$WORKDIR"

# Copy brief to working directory
cp "$BRIEF" "${WORKDIR}/brief.json"

echo "╔══════════════════════════════════════════╗"
echo "║      REEL GENERATION PIPELINE            ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Brief:   ${BRIEF}"
echo "Output:  ${WORKDIR}"
echo "AI BGs:  $([ -z "$NO_AI" ] && echo 'enabled' || echo 'disabled')"
echo "TTS:     $([ -n "$TTS" ] && echo 'enabled' || echo 'off (text-only)')"
echo ""

# ── Step 1: Generate frames ──
echo "━━━ STEP 1: Generate beat frames ━━━"
FRAMES_ARGS="--brief ${WORKDIR}/brief.json --outdir ${WORKDIR}"
if [[ -n "$NO_AI" ]]; then
  FRAMES_ARGS="$FRAMES_ARGS --no-ai"
fi
python3 "${LIB_DIR}/generate-frames.py" $FRAMES_ARGS
echo ""

# ── Step 2: Stitch video ──
echo "━━━ STEP 2: Stitch video ━━━"
chmod +x "${LIB_DIR}/stitch-video.sh"
bash "${LIB_DIR}/stitch-video.sh" "$WORKDIR"
echo ""

# ── Step 3: Add audio ──
echo "━━━ STEP 3: Add audio ━━━"
chmod +x "${LIB_DIR}/add-audio.sh"
if [[ -n "$TTS" ]]; then
  bash "${LIB_DIR}/add-audio.sh" "$WORKDIR" "--tts"
else
  bash "${LIB_DIR}/add-audio.sh" "$WORKDIR"
fi
echo ""

# ── Step 4: Summary ──
FINAL="${WORKDIR}/reel-final.mp4"
if [[ -f "$FINAL" ]]; then
  DURATION=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$FINAL")
  SIZE=$(ls -lh "$FINAL" | awk '{print $5}')

  echo "╔══════════════════════════════════════════╗"
  echo "║      ✓ REEL GENERATED                    ║"
  echo "╚══════════════════════════════════════════╝"
  echo ""
  echo "  File:     ${FINAL}"
  echo "  Duration: ${DURATION}s"
  echo "  Size:     ${SIZE}"
  echo ""

  # Write result metadata for cron pickup
  python3 -c "
import json
result = {
    'status': 'success',
    'file': '${FINAL}',
    'duration': float('${DURATION}'),
    'size': '${SIZE}',
    'workdir': '${WORKDIR}',
}
with open('${WORKDIR}/result.json', 'w') as f:
    json.dump(result, f, indent=2)
# Also write to a well-known latest path
with open('${OUTPUT_BASE}/latest-result.json', 'w') as f:
    json.dump(result, f, indent=2)
"
else
  echo "ERROR: Pipeline failed — no final video" >&2
  python3 -c "
import json
result = {'status': 'error', 'workdir': '${WORKDIR}'}
with open('${WORKDIR}/result.json', 'w') as f:
    json.dump(result, f, indent=2)
with open('${OUTPUT_BASE}/latest-result.json', 'w') as f:
    json.dump(result, f, indent=2)
"
  exit 1
fi
