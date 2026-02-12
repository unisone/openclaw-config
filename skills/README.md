# Skill Routing Overrides

Workspace-level SKILL.md overrides that improve skill selection in overlapping domains.

## Problem

OpenClaw's bundled skills often have brief descriptions without negative routing examples. When multiple skills cover similar domains (email, notes, transcription), the model can pick the wrong one.

## Solution

These overrides copy the bundled SKILL.md verbatim and add:
1. **Improved `description:` frontmatter** — single-line with "Don't use for..." guidance
2. **`## Routing` section** — explicit negative examples for disambiguation

Workspace skills override bundled ones, so OpenClaw sees the improved descriptions at routing time.

## Domains Covered

| Domain | Skills | Routing Logic |
|--------|--------|---------------|
| Email | `gog`, `himalaya` | gog = Gmail/Google Workspace; himalaya = IMAP/SMTP |
| Notes | `apple-notes`, `bear-notes`, `obsidian`, `notion` | Each has distinct use case + "Don't use for..." the others |
| Transcription | `openai-whisper`, `openai-whisper-api` | Local CLI vs cloud API |
| Messaging | `imsg` | Fallback for iMessage; prefer bluebubbles if available |
| Code | `coding-agent` | Multi-step coding agent sessions; not for simple exec commands |
| Summarize | `summarize` | URLs/podcasts/files; not for simple HTML (use web_fetch) |

## Impact

OpenAI's engineering blog cited Glean seeing a **20% skill misfire reduction** after adding negative examples. Same principle applies here.

## Maintenance

These overrides mask bundled skill updates. When OpenClaw ships improved descriptions upstream, delete the corresponding override to fall back to the bundled version.

Upstream issue: https://github.com/openclaw/openclaw/issues/14748
