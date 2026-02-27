---
title: "OpenClaw Cron Patterns"
category: workflows
tags: [openclaw, cron, automation, heartbeat, agents, config]
date: 2026-02-17
source: "STATE.md, memory/2026-02-16.md, HEARTBEAT.md"
tldr: "Crons are agentTurn jobs in openclaw config. Model: claude-sonnet-4-5. Timeout ≥120s. Use `cron list` to audit. Heartbeat runs every 1h, configured active hours."
---

# OpenClaw Cron Patterns

## TL;DR
Crons are defined in the openclaw config as `agentTurn` jobs. All enabled crons use `anthropic/claude-sonnet-4-5`. Heartbeat runs every hour during configured active hours. Check `cron list` during heartbeat to catch errors.

## Context
OpenClaw has a built-in cron scheduler. We use it for: daily memory consolidation, session watchdog, X radar, Instagram post scheduling, and self-improvement scans. Common failure modes: timeouts, model mismatches after config changes.

## Details

### Current Cron Stack

| Job | Schedule | Purpose |
|-----|----------|---------|
| `heartbeat` | Every 1h, configured active hours | Proactive checks, alerts, memory maintenance |
| `nightly-consolidation` | 03:00 ET daily | Memory flush, git backup, session cleanup |
| `session-watchdog` | Every 30min | Kill stale/full sessions before they block |
| `x-radar` | Every 2h | Trend scan, draft reactive X content |
| `content-draft-friday` | Fri AM | Weekly content batch draft |
| `agi-self-improvement` | Weekly | Audit sessions, search for OpenClaw skill updates |
| `openclaw-community-scan` | Weekly | Check openclaw/openclaw issues/PRs |
| `workflows-repo-sync` | Weekly | Sync shared workflows repo |
| `memory-capture` | Every 6h | `python3 scripts/taskrunner/runner.py memory_capture` |

### Config Pattern

```yaml
# In openclaw config (via gateway config.set or UI)
crons:
  - id: my-cron-job
    kind: agentTurn          # always agentTurn for AI-driven jobs
    enabled: true
    schedule: "0 * * * *"   # cron syntax (hourly)
    model: anthropic/claude-sonnet-4-5  # ALWAYS Sonnet for crons
    timeout: 120             # seconds — be generous, network calls add up
    prompt: |
      You are running a scheduled check. Do X, then Y, then Z.
      Report results to your ops channel (YOUR_OPS_CHANNEL_ID).
```

### Key Config Values

```
Main model: anthropic/claude-opus-4-6
Subagents:  anthropic/claude-sonnet-4-5
Heartbeat:  anthropic/claude-sonnet-4-5
Crons:      anthropic/claude-sonnet-4-5  ← all 28 enabled agentTurn jobs
Fallback:   openai-codex/gpt-5.3-codex → gpt-5.2
```

### Heartbeat Rules (from HEARTBEAT.md)

```
- Run: openclaw heartbeat (triggered by config schedule)
- Checks: daily memory file, pending alerts, cron health, memory capture, STATE.md maintenance
- Quiet hours: outside your configured active hours — stay silent unless urgent
- If all clear: reply HEARTBEAT_OK (no Slack message needed)
- If alerts: post to your ops channel (YOUR_OPS_CHANNEL_ID)
- Never do deep work in a heartbeat — keep it fast
```

### Cron Health Check

```bash
# During heartbeat — check for errors
cron list

# Look for: lastStatus: "error" on enabled jobs
# Known problematic jobs (as of Feb 2026):
#   - content-draft-friday  (cooldown issue)
#   - x-radar               (occasional timeout)
#   - workflows-repo-sync   (timeout — needs bump to 180s)
#   - openclaw-community-scan (timeout — needs bump)
```

### Session Watchdog Script

```bash
# Run manually if sessions accumulate
bash ${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}/scripts/session-management/session-watchdog.sh

# Pattern: kills sessions at >95% context, preserves active ones
# Runs automatically every 30min via cron
```

## Gotchas

- **After any config update**, all cron model fields may reset to old values — re-audit with `cron list` and look for non-Sonnet models
- **Timeout too low** is the #1 cron failure cause. 120s minimum, 240s for anything doing web search or LLM calls
- **`agi-self-improvement`** is known to need 240→300s timeout (hasn't been bumped yet as of Feb 17)
- Session compaction bug (#14143): sessions can hit 100% and stop responding — watchdog cron is the mitigation
- `systemEvent` jobs don't need a model field — skip those when doing model audits

## Notes

- OpenClaw config managed via `gateway config.set` or direct config file
- Team crons can post to project channels; ops crons should post to your ops channel (YOUR_OPS_CHANNEL_ID)
- Issue tracking: [openclaw/openclaw #14143](https://github.com/openclaw/openclaw/issues/14143) — compaction never triggers
