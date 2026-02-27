# HEARTBEAT.md — Proactive Checks

## Quick Checks (every heartbeat)

### 1. Daily Memory File
- Does `memory/YYYY-MM-DD.md` exist for today?
- If not: create it with a timestamp header.

### 2. Pending Alerts
- Check `scripts/taskrunner/alerts/pending.json`
- If alerts exist: **Use the `slack` skill** to post them to your ops channel, then clear the file

### 3. Memory Capture
- Run: `python3 $OPENCLAW_WORKSPACE/scripts/taskrunner/runner.py memory_capture`
- This ensures today's context is being captured

### 4. STATE.md Maintenance
- Read `STATE.md` — check for stale entries (>24h old)
- Move completed (⚪ DONE) items to `memory/YYYY-MM-DD.md`
- Remove entries older than 24h (they're already in daily notes)
- Verify file is under 3KB — if over, prune oldest entries
- Update timestamps on any active items that are still relevant

## Rules
- If ALL checks pass and no alerts: reply HEARTBEAT_OK
- **NEVER post heartbeat results to any Slack channel.** Dedicated cron jobs handle monitoring.
- Never do deep work in a heartbeat — keep it fast
- Respect your configured active hours
