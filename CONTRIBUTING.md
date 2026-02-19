# Contributing

Thanks for contributing — this repo stays useful only if it stays **clean, practical, and safe to copy**.

## What belongs here

- Config snippets that are broadly useful (and don’t assume your private setup)
- Scripts that are workspace-local and don’t require hidden secrets
- Templates that help new workspaces get productive fast
- Docs that explain *why* something works (root cause + tradeoffs), not just “do X”

## What does NOT belong here

- API keys, tokens, cookie DBs, auth headers
- Personal identifiers (emails, phone numbers, addresses)
- Logs, transcripts, screenshots containing private data
- “Look what I did” examples without re-usable instructions

## Before you open a PR

1. **Run it in a real workspace**
   - If it’s a script: run it end-to-end and confirm the output files are sane
   - If it’s config: confirm OpenClaw starts and behaves as expected

2. **Sanity-check for secrets**
   - `git grep -nE '(api[_-]?key|token|secret|auth_token|ct0|bearer|password)'`

3. Keep changes small
   - If you’re adding a “system”, add a short `docs/` explainer and keep the code minimal

## Style

- Prefer plain bash over exotic dependencies
- Comments should explain intent/tradeoffs
- Avoid hype claims; make statements that a new user can verify

## Commit style

Conventional commits preferred:

- `docs: ...`
- `feat: ...`
- `fix: ...`
- `chore: ...`
