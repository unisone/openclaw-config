# Reel Generation Pipeline

Automated Instagram Reel generation from text briefs.

## Architecture

```
ig-content-scheduler (cron)     → writes JSON brief
        ↓
ig-visual-generator (cron)      → reads brief, calls pipeline
        ↓
generate-reel.sh                → orchestrates pipeline
    ├── generate-frames.py      → AI backgrounds + text overlays
    ├── stitch-video.sh         → Ken Burns + crossfade via ffmpeg
    └── add-audio.sh            → TTS voiceover (sag/OpenAI)
        ↓
reel-final.mp4                  → posted to Slack #insta
```

## Usage

```bash
# Generate reel from brief
./generate-reel.sh brief.json

# Skip AI backgrounds (use gradients)
./generate-reel.sh brief.json --no-ai

# Skip TTS voiceover
./generate-reel.sh brief.json --no-tts

# Both
./generate-reel.sh brief.json --no-ai --no-tts
```

## Brief Schema

```json
{
  "topic": "Anthropic acquires Vercept",
  "format": "reel",
  "beats": [
    {
      "text": "Anthropic acquired Vercept.",
      "duration": 3,
      "style": "hook",
      "bg_prompt": "dark server room, blue lights, volumetric fog"
    },
    {
      "text": "Computer-use agents.\nClick, type, navigate UIs.",
      "duration": 4,
      "style": "body"
    }
  ],
  "voiceover_script": "Full narration script for TTS",
  "caption": "Caption for Instagram post",
  "hashtags": ["#aiagents", "#anthropic"],
  "cta": "Comment VERCEPT"
}
```

### Beat Styles
- `hook` — Large bold white text (88px InterDisplay-Black)
- `body` — Medium bold white text (64px InterDisplay-Bold)
- `accent` — Large blue text (72px InterDisplay-Black)
- `cta` — Medium teal text (58px InterDisplay-Bold)

### Background Options
- **AI generated** (default): OpenAI gpt-image-1 backgrounds, darkened for text readability
- **Gradient fallback**: Auto-generated dark gradients if API unavailable
- Custom `bg_prompt` per beat for thematic backgrounds

## Dependencies

- Python 3 + Pillow (`pip3 install Pillow`)
- ffmpeg 6+ (`brew install ffmpeg`)
- OpenAI API key (for AI backgrounds + TTS)
- sag (optional, for ElevenLabs TTS)

## Cost

- **AI backgrounds**: ~$0.03-0.05/image × 4-5 = $0.12-0.25/reel
- **TTS** (OpenAI): ~$0.01-0.02/reel
- **Gradient mode**: $0.00/reel
- **Total**: $0.00-0.27/reel (well within $1.00 budget)

## Output

Each run creates a timestamped directory in `output/`:
```
output/20260226-120000-anthropic-acquires-vercept/
├── brief.json          # Input brief
├── manifest.json       # Frame manifest with paths + durations
├── bg_cache_*.png      # Cached AI backgrounds
├── beat_001.png        # Beat frames
├── beat_002.png
├── clip_*.mp4          # Ken Burns clips
├── reel-silent.mp4     # Video without audio
├── voiceover.mp3       # TTS audio
├── reel-final.mp4      # ✅ Final output
└── result.json         # Machine-readable result
```
