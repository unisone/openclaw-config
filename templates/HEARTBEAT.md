# HEARTBEAT.md — Proactive Checks

## Quick Checks (every heartbeat)

### 1. Daily Memory File
- Does `memory/YYYY-MM-DD.md` exist for today?
- If not: create it with a timestamp header.

### 2. Cron Health (lightweight)
- Run: `openclaw cron list` and check for any `lastStatus: "error"` on enabled jobs
- If failures found: report briefly in response

### 3. Inbox / Calendar (rotate)
- Check for urgent unread emails
- Any calendar events in the next 2 hours?

## Rules
- If ALL checks pass and no alerts: reply HEARTBEAT_OK
- If something needs attention: report it briefly, spawn sub-agent for complex issues
- Never do deep work in a heartbeat — keep it fast
- Respect quiet hours (23:00-08:00)
