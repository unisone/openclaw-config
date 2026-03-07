#!/bin/bash
# add-audio.sh — Optionally add TTS voiceover to silent reel
#
# Usage: ./add-audio.sh <workdir> [--tts]
# Default: copies silent video as final (text-only mode)
# --tts: generates voiceover and merges
#
# Reads: <workdir>/manifest.json, <workdir>/reel-silent.mp4
# Output: <workdir>/reel-final.mp4

set -euo pipefail

WORKDIR="${1:?Usage: add-audio.sh <workdir> [--tts]}"
ENABLE_TTS="${2:-}"

MANIFEST="${WORKDIR}/manifest.json"
SILENT_VIDEO="${WORKDIR}/reel-silent.mp4"

if [[ ! -f "$SILENT_VIDEO" ]]; then
  echo "ERROR: No reel-silent.mp4 in ${WORKDIR}" >&2
  exit 1
fi

# Default: text-only (no voiceover)
if [[ "$ENABLE_TTS" != "--tts" ]]; then
  echo "=== Text-only mode (no voiceover) ==="
  cp "$SILENT_VIDEO" "${WORKDIR}/reel-final.mp4"
  FINAL_DUR=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "${WORKDIR}/reel-final.mp4")
  echo "Output: ${WORKDIR}/reel-final.mp4 (${FINAL_DUR}s, silent)"
  exit 0
fi

# ── TTS mode ──
VO_SCRIPT=$(python3 -c "
import json
with open('${MANIFEST}') as f:
    m = json.load(f)
print(m.get('brief', {}).get('voiceover_script', ''))
")

if [[ -z "$VO_SCRIPT" ]]; then
  echo "=== No voiceover_script in brief, copying silent ==="
  cp "$SILENT_VIDEO" "${WORKDIR}/reel-final.mp4"
  exit 0
fi

VIDEO_DURATION=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$SILENT_VIDEO")
VO_FILE="${WORKDIR}/voiceover.mp3"

if [[ ! -f "$VO_FILE" ]]; then
  echo "=== Generating TTS voiceover ==="

  OPENAI_KEY="${OPENAI_API_KEY:-}"
  if [[ -z "$OPENAI_KEY" ]]; then
    OPENAI_KEY=$(security find-generic-password -s "openai-api-key" -a "openai" -w 2>/dev/null || true)
  fi

  if [[ -n "$OPENAI_KEY" ]]; then
    echo "  Using OpenAI TTS (onyx voice)..."
    # Write script to temp file to avoid shell escaping issues
    SCRIPT_FILE="${WORKDIR}/vo_script.txt"
    echo "$VO_SCRIPT" > "$SCRIPT_FILE"

    python3 -c "
import json, urllib.request
script = open('${SCRIPT_FILE}').read().strip()
payload = json.dumps({
    'model': 'tts-1',
    'input': script,
    'voice': 'onyx',
    'response_format': 'mp3',
    'speed': 1.05,
}).encode()
req = urllib.request.Request(
    'https://api.openai.com/v1/audio/speech',
    data=payload,
    headers={
        'Authorization': 'Bearer ${OPENAI_KEY}',
        'Content-Type': 'application/json',
    },
)
with urllib.request.urlopen(req, timeout=30) as resp:
    with open('${VO_FILE}', 'wb') as f:
        f.write(resp.read())
print('  ✓ TTS generated')
" 2>&1 || echo "  ⚠ TTS generation failed"
  else
    echo "  ⚠ No API key for TTS"
  fi
fi

# Merge audio + video
if [[ -f "$VO_FILE" ]] && [[ $(stat -f%z "$VO_FILE" 2>/dev/null || stat -c%s "$VO_FILE") -gt 1000 ]]; then
  echo "=== Merging audio + video ==="
  VO_DUR=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$VO_FILE")
  FINAL_DUR=$(python3 -c "print(min(${VIDEO_DURATION}, ${VO_DUR}))")

  ffmpeg -y \
    -i "$SILENT_VIDEO" -i "$VO_FILE" \
    -map 0:v -map 1:a \
    -c:v copy -c:a aac -b:a 192k \
    -t "$FINAL_DUR" -movflags +faststart \
    "${WORKDIR}/reel-final.mp4" 2>/dev/null

  echo "  ✓ Merged (${FINAL_DUR}s)"
else
  echo "=== TTS failed, using silent video ==="
  cp "$SILENT_VIDEO" "${WORKDIR}/reel-final.mp4"
fi

echo "Output: ${WORKDIR}/reel-final.mp4"
