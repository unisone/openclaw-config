# v2026.02.27 — Session Management + Model Safety + Agent Swarm

Compatible with **OpenClaw 2026.2.24+**.

## Highlights

## 1) Session Management Suite (headline)
Added `scripts/session-management/` with production-ready session lifecycle tooling:

- `session-watchdog.sh` — autonomous cleanup for stale/maxed sessions
- `session-metrics.sh` — structured metrics snapshot (usage, staleness, counts)
- `session-ops-weekly-report.sh` — recurring markdown + JSON ops summary
- `session-cleanup.sh` — manual emergency cleanup utility
- `session-store-hygiene.sh` — orphan cleanup + compacted store writes
- `README.md` for setup, env vars, and cron examples

All scripts are sanitized and portable:
- `OPENCLAW_HOME`
- `OPENCLAW_WORKSPACE`
- `OPENCLAW_SESSION_DIR`
- `YOUR_OPS_CHANNEL_ID` placeholder for delivery channels

## 2) Model Change Safety Rules (critical ops doc)
Added `docs/model-change-safety-rules.md`.

Covers:
- Anthropic thinking-signature compatibility constraints
- Safe model change checklist before/after updates
- Shared-session vs isolated-session rules
- Verification steps to detect signature errors quickly

## 3) Agent Swarm Orchestration (reference architecture)
Added `workflows/agent-swarm-orchestration.md`.

Includes:
- Router + learning-loop patterns
- Multi-agent spawn/monitor/review lifecycle
- Safety rails, retries, and review gates
- Generic operator/orchestrator language (no personal references)

## 4) Cron Patterns (production scheduling reference)
Added `workflows/openclaw-cron-patterns.md`.

Includes:
- `agentTurn` cron structure and defaults
- Timeout/schedule guidance
- Heartbeat and cron health patterns
- Sanitized paths and channel placeholders

## 5) Agent Conventions (group chat behavior guide)
Added `docs/agent-conventions.md`.

Includes:
- Group participation rules
- Memory hygiene guidance
- Formatting and artifacts conventions
- Heartbeat behavior boundaries

## 6) Refined Workspace Templates
Updated templates with current lean versions:

- `templates/AGENTS.md`
  - generic model-change safety wording
  - no personal references
- `templates/HEARTBEAT.md`
  - ops channel generalized to `your ops channel`
  - path generalized to `$OPENCLAW_WORKSPACE`
  - active hours generalized to `your configured active hours`
- `templates/SOUL.md`
  - current generic version

## Safety / Privacy

This release removes personal identifiers and credential-like references from new operational docs/scripts.

- no real names
- no personal email addresses
- no personal filesystem paths
- no real Slack channel IDs
- placeholders used where needed
