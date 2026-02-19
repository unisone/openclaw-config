# HEARTBEAT.md — Proactive Checks

## Quick Checks (every heartbeat)

### 1. Daily Memory File
- Does `memory/YYYY-MM-DD.md` exist for today?
- If not: create it with a timestamp header.

### 2. Pending Alerts
- Check `scripts/taskrunner/alerts/pending.json` (or wherever you store alerts)
- If alerts exist: post them to your ops channel, then clear the file

### 3. Cron Health (lightweight)
- Run: `openclaw cron list` and check for any `lastStatus: "error"` on enabled jobs
- If failures found: report briefly in response

### 4. Memory Capture
- Run your memory capture task (if configured)
- Example: `python3 ~/.openclaw/workspace/scripts/taskrunner/runner.py memory_capture`
- This ensures today's context is being captured

### 5. STATE.md Maintenance
- Read `STATE.md` — check for stale entries (>24h old)
- Move completed (⚪ DONE) items to `memory/YYYY-MM-DD.md`
- Remove entries older than 24h (they're already in daily notes)
- Verify file is under 3KB — if over, prune oldest entries
- Update timestamps on any active items that are still relevant

### 6. Self-Improvement (rotate, 1-2x per week)
- Review recent sessions for patterns: repeated failures, slow workflows, missing capabilities
- Search for new OpenClaw skills (if you have a skill registry or ClawHub access)
- Check the openclaw/openclaw repo for relevant issues/PRs
- Draft improvement proposals in `artifacts/reports/improvements-YYYY-MM-DD.md`
- Post summary to your ops channel if anything significant found

## Rules
- If ALL checks pass and no alerts: reply HEARTBEAT_OK
- If something needs attention: report it briefly, spawn sub-agent only for complex issues
- Never do deep work in a heartbeat — keep it fast
- Respect quiet hours (configured in your heartbeat.activeHours setting)
