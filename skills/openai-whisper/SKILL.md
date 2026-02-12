---
name: openai-whisper
description: Local speech-to-text with the Whisper CLI (no API key); Don't use if you need cloud transcription with no local model; prefer openai-whisper-api.
homepage: https://openai.com/research/whisper
metadata:
  {
    "openclaw":
      {
        "emoji": "🎙️",
        "requires": { "bins": ["whisper"] },
        "install":
          [
            {
              "id": "brew",
              "kind": "brew",
              "formula": "openai-whisper",
              "bins": ["whisper"],
              "label": "Install OpenAI Whisper (brew)",
            },
          ],
      },
  }
---

# Whisper (CLI)

Use `whisper` to transcribe audio locally.

## Routing

- ❌ Don't use if you need cloud transcription (no local model / no local compute).
- ✅ Prefer `openai-whisper-api` for cloud transcription.

Quick start

- `whisper /path/audio.mp3 --model medium --output_format txt --output_dir .`
- `whisper /path/audio.m4a --task translate --output_format srt`

Notes

- Models download to `~/.cache/whisper` on first run.
- `--model` defaults to `turbo` on this install.
- Use smaller models for speed, larger for accuracy.
