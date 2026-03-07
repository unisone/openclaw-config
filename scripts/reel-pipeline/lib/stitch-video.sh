#!/bin/bash
# stitch-video.sh — Assemble beat frames into a reel video with Ken Burns + crossfades
#
# Usage: ./stitch-video.sh <workdir>
# Reads: <workdir>/manifest.json
# Output: <workdir>/reel-silent.mp4

set -euo pipefail

WORKDIR="${1:?Usage: stitch-video.sh <workdir>}"
MANIFEST="${WORKDIR}/manifest.json"

if [[ ! -f "$MANIFEST" ]]; then
  echo "ERROR: No manifest.json in ${WORKDIR}" >&2
  exit 1
fi

echo "=== Generating Ken Burns clips ==="

# Use Python to orchestrate ffmpeg calls (avoids bash quoting nightmares)
python3 - "$WORKDIR" "$MANIFEST" <<'PYEOF'
import json
import subprocess
import sys
from pathlib import Path

workdir = Path(sys.argv[1])
manifest_path = sys.argv[2]

with open(manifest_path) as f:
    manifest = json.load(f)

frames = manifest["frames"]
fps = 30

# Step 1: Generate Ken Burns clips for each frame
clips = []
for i, frame in enumerate(frames):
    frame_path = frame["path"]
    duration = frame["duration"]
    clip_path = str(workdir / f"clip_{i+1:03d}.mp4")
    num_frames = duration * fps

    # Alternate zoom direction for variety
    if i % 2 == 0:
        # Slow zoom in
        zoom_expr = "min(zoom+0.0008,1.08)"
    else:
        # Slow zoom out
        zoom_expr = "if(eq(on,1),1.08,max(zoom-0.0008,1.0))"

    vf = (
        f"scale=1200:2133,"
        f"zoompan=z='{zoom_expr}':"
        f"d={num_frames}:"
        f"x='iw/2-(iw/zoom/2)':"
        f"y='ih/2-(ih/zoom/2)':"
        f"s=1080x1920:fps={fps},"
        f"format=yuv420p"
    )

    cmd = [
        "ffmpeg", "-y", "-loop", "1", "-i", frame_path,
        "-vf", vf,
        "-t", str(duration),
        "-c:v", "libx264", "-preset", "fast", "-crf", "20",
        clip_path,
    ]

    result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
    if result.returncode != 0:
        print(f"  ✗ clip_{i+1:03d} FAILED: {result.stderr[-200:]}", file=sys.stderr)
        sys.exit(1)

    clips.append({"path": clip_path, "duration": duration})
    print(f"  ✓ clip_{i+1:03d}.mp4 ({duration}s)")

# Step 2: Concatenate with crossfade transitions
print("\n=== Adding crossfade transitions ===")

FADE_DUR = 0.3

if len(clips) == 1:
    import shutil
    shutil.copy(clips[0]["path"], str(workdir / "reel-silent.mp4"))
elif len(clips) == 2:
    offset = clips[0]["duration"] - FADE_DUR
    cmd = [
        "ffmpeg", "-y",
        "-i", clips[0]["path"], "-i", clips[1]["path"],
        "-filter_complex",
        f"[0:v][1:v]xfade=transition=fade:duration={FADE_DUR}:offset={offset:.2f}[v]",
        "-map", "[v]", "-c:v", "libx264", "-preset", "fast", "-crf", "20",
        str(workdir / "reel-silent.mp4"),
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
    if result.returncode != 0:
        print(f"  ✗ Crossfade FAILED: {result.stderr[-300:]}", file=sys.stderr)
        sys.exit(1)
else:
    # Multi-clip crossfade chain
    inputs = []
    for c in clips:
        inputs.extend(["-i", c["path"]])

    # Build xfade filter chain
    # Calculate offsets: each offset = cumulative duration - cumulative fades
    filter_parts = []
    cumulative = 0.0

    for i in range(len(clips) - 1):
        offset = cumulative + clips[i]["duration"] - FADE_DUR
        cumulative = offset  # next segment starts at offset (after fade overlap)

        if i == 0:
            in_label = "[0:v]"
        else:
            in_label = f"[v{i}]"

        if i == len(clips) - 2:
            out_label = "[v]"
        else:
            out_label = f"[v{i+1}]"

        filter_parts.append(
            f"{in_label}[{i+1}:v]xfade=transition=fade:duration={FADE_DUR}:offset={offset:.2f}{out_label}"
        )

    filter_complex = ";".join(filter_parts)

    cmd = [
        "ffmpeg", "-y",
        *inputs,
        "-filter_complex", filter_complex,
        "-map", "[v]", "-c:v", "libx264", "-preset", "fast", "-crf", "20",
        str(workdir / "reel-silent.mp4"),
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    if result.returncode != 0:
        print(f"  ✗ Crossfade FAILED: {result.stderr[-300:]}", file=sys.stderr)
        sys.exit(1)

# Verify output
output = workdir / "reel-silent.mp4"
if output.exists():
    probe = subprocess.run(
        ["ffprobe", "-v", "quiet", "-show_entries", "format=duration", "-of", "csv=p=0", str(output)],
        capture_output=True, text=True,
    )
    duration = probe.stdout.strip()
    size = output.stat().st_size
    size_mb = size / (1024 * 1024)
    print(f"\n=== Done ===")
    print(f"Output: {output} ({size_mb:.1f}MB, {duration}s)")
else:
    print("ERROR: reel-silent.mp4 not generated", file=sys.stderr)
    sys.exit(1)
PYEOF
