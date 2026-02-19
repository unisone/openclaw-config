# CLAUDE.md — openclaw-config

Public reference repo for OpenClaw configuration patterns.

## Stack
- JSON5 config files
- Markdown documentation
- No build step, no tests

## Conventions
- Config examples go in `config/` directory
- Each config file is self-documented with inline comments
- README.md is the primary docs — keep it updated when adding configs
- Conventional commits: `feat:`, `fix:`, `docs:`

## What this repo is
Production-tested OpenClaw configuration snippets (compaction, model aliases, feature unlocks), workspace templates (AGENTS.md, SOUL.md, HEARTBEAT.md), task automation (taskrunner), and operational docs (context overflow, agent memory research). NOT a full config dump — curated examples only. No secrets, no API keys, ever.

## Recent Major Additions (Feb 11, 2026)
- **Templates overhaul**: AGENTS.md expanded to 220+ lines with heartbeat system, group chat etiquette, memory maintenance
- **Python Task Runner**: Replaces fragile shell scripts with proper error handling, retry logic, locking
- **Research docs**: session-context-overflow-fix.md (operational guide), agent-system-research.md (4500+ word research report)
