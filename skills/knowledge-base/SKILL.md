---
name: knowledge-base
description: Capture, organize, and retrieve operational knowledge + saved web content in a local `knowledge/` directory indexed by QMD. Use for “save this link”, “add to KB”, “remember this”, or “search KB”.
metadata:
  {
    "openclaw": {
      "emoji": "📚",
      "requires": { "bins": ["qmd"] }
    }
  }
---

# Knowledge Base

Two overlapping functions:

1. **Operational knowledge** — tool quirks, API gotchas, runbooks, decision rationale
2. **URL/content archive** — save articles, YouTube transcripts, PDFs, threads

Everything lives in `knowledge/` and is indexed by **QMD** for fast keyword + semantic search.

## Routing

- ✅ Use when the user says: **“save this”**, **“add to KB”**, **“remember this”**, **“document this”**, **“search KB”**.
- ❌ Don’t use for simple web-page extraction if the user just wants the answer now → use `web_fetch` directly.

## Quick start

### 1) Create the directory scaffold (recommended)

Copy templates into your OpenClaw workspace:

```bash
rsync -av templates/knowledge/ ~/.openclaw/workspace/knowledge/
```

### 2) Ingest a URL

From your workspace root:

```bash
python3 skills/knowledge-base/scripts/ingest.py "https://example.com/article"
python3 skills/knowledge-base/scripts/ingest.py "https://youtube.com/watch?v=..."
python3 skills/knowledge-base/scripts/ingest.py "https://example.com/file.pdf"
```

Optional metadata (skip LLM calls):

```bash
python3 skills/knowledge-base/scripts/ingest.py "<URL>" \
  --title "Readable Title" \
  --tags "rag,openclaw,workflows" \
  --summary "Why this is worth saving"
```

### 3) Search

```bash
# keyword
qmd search "meta ads" -c knowledge

# semantic
qmd vsearch "how do we authenticate jira" -c knowledge

# best quality (hybrid + rerank, if enabled)
qmd query "slack block streaming" -c knowledge
```

## Notes / Dependencies

- Works with **no extra installs** for basic HTML pages (urllib fallback).
- Better extraction if you install `trafilatura`.
- YouTube transcripts: tries `youtube-transcript-api`, falls back to `yt-dlp` if available.
- PDF text extraction: uses `pdftotext` (Poppler).

Keep secrets out of the KB. For credentials, store them in a password manager / keychain and write **where to find them**, not the values.
