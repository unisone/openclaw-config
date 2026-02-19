#!/usr/bin/env python3
"""Knowledge Base URL Ingestion Script

Usage:
  python3 ingest.py <URL> [--tags tag1,tag2] [--title "..."] [--summary "..."] [--workspace PATH] [--dry-run]

- Extracts readable content from a URL (article / YouTube / PDF / thread)
- Generates metadata (title/slug/summary/tags) via OpenAI or Anthropic if available
- Saves a markdown file into: <workspace>/knowledge/YYYY-MM-DD-slug.md
- Triggers `qmd update -c knowledge` if QMD is installed

Privacy:
  This script writes only to your local workspace. Do not ingest secrets.
"""

import argparse
import json
import os
import re
import sys
import subprocess
import urllib.parse
import urllib.request
from datetime import date
from pathlib import Path
from shutil import which


# ── Workspace resolution ─────────────────────────────────────────────────────

def default_workspace() -> Path:
    # Prefer explicit env. Fall back to OpenClaw default.
    env = os.environ.get("OPENCLAW_WORKSPACE")
    if env:
        return Path(env).expanduser()
    return (Path.home() / ".openclaw" / "workspace").expanduser()


# ── URL type detection ───────────────────────────────────────────────────────

def detect_type(url: str) -> str:
    u = url.lower()
    if any(h in u for h in ["youtube.com/watch", "youtu.be/", "youtube.com/shorts/"]):
        return "youtube"
    if any(h in u for h in ["twitter.com/", "x.com/"]):
        return "tweet"
    if u.endswith(".pdf") or "filetype=pdf" in u:
        return "pdf"
    if any(h in u for h in ["reddit.com/r/", "news.ycombinator.com"]):
        return "thread"
    return "article"


# ── Content extraction ───────────────────────────────────────────────────────

def extract_youtube_id(url: str) -> str | None:
    patterns = [
        r"(?:youtube\.com/watch\?v=|youtu\.be/|youtube\.com/embed/)([a-zA-Z0-9_-]{11})",
        r"youtube\.com/shorts/([a-zA-Z0-9_-]{11})",
    ]
    for p in patterns:
        m = re.search(p, url)
        if m:
            return m.group(1)
    return None


def fetch_youtube_transcript(url: str) -> str:
    video_id = extract_youtube_id(url)
    if not video_id:
        raise RuntimeError(f"Could not extract YouTube video ID from {url}")

    # 1) youtube-transcript-api (best, no downloads)
    try:
        from youtube_transcript_api import YouTubeTranscriptApi

        api = YouTubeTranscriptApi()
        result = api.fetch(video_id)
        lines: list[str] = []
        for s in result.snippets:
            ts = int(s.start)
            mm, ss = divmod(ts, 60)
            hh, mm = divmod(mm, 60)
            timestamp = f"[{hh:02d}:{mm:02d}:{ss:02d}]" if hh else f"[{mm:02d}:{ss:02d}]"
            lines.append(f"{timestamp} {s.text}")
        if lines:
            return "\n".join(lines)
    except Exception as e:
        print(f"[warn] youtube-transcript-api failed: {e}", file=sys.stderr)

    # 2) yt-dlp fallback (auto subtitles)
    ytdlp = which("yt-dlp")
    if not ytdlp:
        raise RuntimeError("No transcript available (youtube-transcript-api failed and yt-dlp not found)")

    import tempfile

    with tempfile.TemporaryDirectory() as tmpdir:
        result = subprocess.run(
            [
                ytdlp,
                "--skip-download",
                "--write-auto-sub",
                "--sub-lang",
                "en",
                "--sub-format",
                "vtt",
                "-o",
                f"{tmpdir}/%(id)s.%(ext)s",
                url,
            ],
            capture_output=True,
            text=True,
            timeout=45,
        )
        if result.returncode != 0:
            raise RuntimeError(f"yt-dlp failed: {result.stderr.strip()[:400]}")

        vtt_files = list(Path(tmpdir).glob("*.vtt"))
        if not vtt_files:
            raise RuntimeError("yt-dlp produced no .vtt subtitles")

        raw = vtt_files[0].read_text(errors="replace")
        lines: list[str] = []
        for line in raw.splitlines():
            line = line.strip()
            if (
                not line
                or line.startswith("WEBVTT")
                or line.startswith("Kind:")
                or line.startswith("Language:")
                or line.startswith("NOTE")
                or re.match(r"^\d+$", line)
                or re.match(r"^\d{2}:\d{2}", line)
            ):
                continue
            line = re.sub(r"<[^>]+>", "", line)
            if line and (not lines or lines[-1] != line):
                lines.append(line)

        if not lines:
            raise RuntimeError("Subtitle file contained no usable text")
        return "\n".join(lines)


def fetch_youtube_title(url: str) -> str | None:
    ytdlp = which("yt-dlp")
    if not ytdlp:
        return None
    try:
        result = subprocess.run([ytdlp, "--skip-download", "--print", "%(title)s", url], capture_output=True, text=True, timeout=15)
        t = result.stdout.strip()
        return t or None
    except Exception:
        return None


def fetch_pdf_content(url: str) -> str:
    import tempfile

    headers = {"User-Agent": "Mozilla/5.0"}
    req = urllib.request.Request(url, headers=headers)

    with tempfile.NamedTemporaryFile(suffix=".pdf", delete=False) as tmp:
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                tmp.write(resp.read())
            tmp_path = tmp.name
        except Exception as e:
            raise RuntimeError(f"Failed to download PDF: {e}") from e

    try:
        pdftotext = which("pdftotext")
        if not pdftotext:
            raise RuntimeError("pdftotext not found (install Poppler)")

        result = subprocess.run([pdftotext, "-layout", tmp_path, "-"], capture_output=True, text=True, timeout=45)
        text = result.stdout.strip()
        if not text:
            raise RuntimeError("pdftotext produced no output")
        return text[:50_000]
    finally:
        Path(tmp_path).unlink(missing_ok=True)


def fetch_content(url: str) -> str:
    url_type = detect_type(url)

    if url_type == "youtube":
        return fetch_youtube_transcript(url)
    if url_type == "pdf":
        return fetch_pdf_content(url)

    # 1) trafilatura (best extraction)
    try:
        import trafilatura

        downloaded = trafilatura.fetch_url(url)
        if downloaded:
            result = trafilatura.extract(
                downloaded,
                include_comments=False,
                include_tables=True,
                output_format="markdown",
            )
            if result and len(result) > 100:
                return result
    except ImportError:
        pass

    # 2) urllib fallback — raw HTML → strip tags (good enough for many pages)
    headers = {
        "User-Agent": "Mozilla/5.0",
        "Accept": "text/html,application/xhtml+xml,*/*;q=0.9",
        "Accept-Language": "en-US,en;q=0.9",
    }
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
    except Exception as e:
        raise RuntimeError(f"Failed to fetch {url}: {e}") from e

    raw = re.sub(r"<(script|style)[^>]*>.*?</\\1>", " ", raw, flags=re.DOTALL | re.IGNORECASE)
    raw = re.sub(r"<[^>]+>", " ", raw)
    raw = re.sub(r"\s{3,}", "\n\n", raw)
    return raw.strip()[:40_000]


# ── Metadata generation ─────────────────────────────────────────────────────

def generate_metadata(url: str, content: str, url_type: str, hint_tags: list[str]) -> dict:
    prompt = f"""You are a knowledge base archivist. Given a URL and extracted content, produce a JSON object with these exact keys:
- title: string, clean title-case, ≤80 chars
- slug: string, 3-6 lowercase words joined by hyphens
- summary: string, 2-3 sentences: what it is + why it matters
- tags: array of 3-8 lowercase strings
- type: one of article | youtube | tweet | pdf | thread | other

URL: {url}
Detected type: {url_type}
{'Hint tags: ' + ', '.join(hint_tags) if hint_tags else ''}

Content (first 3000 chars):
{content[:3000]}

Respond with ONLY valid JSON (no markdown fences, no extra text)."""

    # Prefer OpenAI if available, then Anthropic.
    for provider in ("openai", "anthropic"):
        try:
            if provider == "openai":
                from openai import OpenAI

                client = OpenAI()
                resp = client.chat.completions.create(
                    model=os.environ.get("KB_OPENAI_MODEL", "gpt-4.1-mini"),
                    max_tokens=512,
                    messages=[{"role": "user", "content": prompt}],
                )
                raw = resp.choices[0].message.content.strip()
            else:
                import anthropic

                client = anthropic.Anthropic()
                msg = client.messages.create(
                    model=os.environ.get("KB_ANTHROPIC_MODEL", "claude-haiku-4-5"),
                    max_tokens=512,
                    messages=[{"role": "user", "content": prompt}],
                )
                raw = msg.content[0].text.strip()

            raw = re.sub(r"^```(?:json)?\s*|\s*```$", "", raw, flags=re.DOTALL)
            return json.loads(raw)
        except ImportError:
            continue
        except Exception as e:
            print(f"[warn] {provider} metadata generation failed: {e}", file=sys.stderr)

    # Heuristic fallback
    heading_match = re.search(r"^#{1,3}\s+(.+)$", content, re.MULTILINE)
    if heading_match:
        title = heading_match.group(1).strip()
    else:
        path_parts = [p for p in urllib.parse.urlparse(url).path.split("/") if p]
        title = path_parts[-1].replace("-", " ").replace("_", " ").title() if path_parts else "Untitled"
    title = re.sub(r"\s+", " ", title)[:80]

    slug_words = re.sub(r"[^a-z0-9\s]", "", title.lower()).split()
    slug = "-".join(slug_words[:6]) or "untitled"

    plain = re.sub(r"[#*`>\[\]_]+", "", content)
    plain = re.sub(r"\s+", " ", plain).strip()
    sentences = re.split(r"(?<=[.!?])\s+", plain)
    summary = (" ".join(sentences[:2])[:300] if sentences else f"Content from {url}").strip()

    tags = hint_tags[:] if hint_tags else [url_type, "web"]

    return {"title": title, "slug": slug, "summary": summary, "tags": tags, "type": url_type}


# ── Deduplication ───────────────────────────────────────────────────────────

def find_existing(kb_dir: Path, url: str) -> Path | None:
    for md in kb_dir.rglob("*.md"):
        try:
            text = md.read_text(errors="replace")
        except Exception:
            continue
        if f"url: {url}" in text or f'url: "{url}"' in text:
            return md
    return None


# ── Markdown rendering ──────────────────────────────────────────────────────

def build_markdown(url: str, meta: dict, content: str) -> str:
    today = date.today().isoformat()
    title = meta.get("title") or "Untitled"
    tags = meta.get("tags") or []
    tags_yaml = "[" + ", ".join(tags) + "]"
    summary = (meta.get("summary") or "").replace('"', "'")
    url_type = meta.get("type") or "article"

    body = content[:50_000]

    return f"""---
title: \"{title}\"
url: {url}
type: {url_type}
tags: {tags_yaml}
saved: {today}
summary: \"{summary}\"
---

# {title}

> **Source:** {url}  \
> **Saved:** {today}  \
> **Summary:** {meta.get('summary','')}

---

{body}
"""


def trigger_qmd_update(collection: str):
    qmd = which("qmd")
    if not qmd:
        return
    try:
        subprocess.run([qmd, "update", "-c", collection], capture_output=True, timeout=45)
    except Exception:
        pass


def main() -> int:
    ap = argparse.ArgumentParser(description="Ingest a URL into a QMD-indexed knowledge base")
    ap.add_argument("url", help="URL to ingest")
    ap.add_argument("--tags", default="", help="Comma-separated hint tags")
    ap.add_argument("--title", default="", help="Pre-set title (skips LLM)")
    ap.add_argument("--summary", default="", help="Pre-set summary (skips LLM)")
    ap.add_argument("--workspace", default="", help="Override workspace path")
    ap.add_argument("--collection", default="knowledge", help="QMD collection name")
    ap.add_argument("--dry-run", action="store_true", help="Print result without writing")
    args = ap.parse_args()

    url = args.url.strip()
    hint_tags = [t.strip() for t in args.tags.split(",") if t.strip()]

    parsed = urllib.parse.urlparse(url)
    if not parsed.scheme or not parsed.netloc:
        print(f"ERROR: Invalid URL: {url}", file=sys.stderr)
        return 1

    workspace = Path(args.workspace).expanduser() if args.workspace else default_workspace()
    kb_dir = workspace / "knowledge"
    kb_dir.mkdir(parents=True, exist_ok=True)

    existing = find_existing(kb_dir, url)
    if existing:
        try:
            rel = existing.relative_to(workspace)
        except Exception:
            rel = existing
        print(f"ALREADY_SAVED: {rel}")
        return 0

    url_type = detect_type(url)
    print(f"Fetching ({url_type}): {url}", file=sys.stderr)

    content = fetch_content(url)

    # Prefer real YouTube title if we can grab it
    if url_type == "youtube" and not args.title:
        yt_title = fetch_youtube_title(url)
        if yt_title:
            args.title = yt_title

    if args.title and hint_tags:
        slug_words = re.sub(r"[^a-z0-9\s]", "", args.title.lower()).split()
        meta = {
            "title": args.title,
            "slug": "-".join(slug_words[:6]) or "untitled",
            "summary": args.summary or f"Content from {url}",
            "tags": hint_tags,
            "type": url_type,
        }
    else:
        meta = generate_metadata(url, content, url_type, hint_tags)

    filename = f"{date.today().isoformat()}-{meta.get('slug','untitled')}.md"
    filepath = kb_dir / filename
    md = build_markdown(url, meta, content)

    if args.dry_run:
        print("=== DRY RUN ===")
        print(f"Would write: {filepath}")
        print(md[:1200])
        return 0

    filepath.write_text(md, encoding="utf-8")
    print(f"SAVED: {filepath}")

    trigger_qmd_update(args.collection)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
