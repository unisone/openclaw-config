# Session Management Suite

Operational scripts to monitor, clean up, and report on OpenClaw session health.

## Included Scripts

- `session-watchdog.sh` — autonomous lifecycle manager (purges stale/maxed ephemeral sessions, warns on risky usage)
- `session-metrics.sh` — JSON snapshot of session counts, staleness, and token-usage distribution
- `session-ops-weekly-report.sh` — appends a weekly markdown report and prints a compact JSON summary
- `session-cleanup.sh` — manual emergency cleanup for dead/stuck sessions
- `session-store-hygiene.sh` — removes orphaned store entries and compacts JSON output

## Environment Variables

All scripts support safe defaults and can be overridden:

- `OPENCLAW_HOME` (default: `$HOME/.openclaw`)
- `OPENCLAW_WORKSPACE` (default: `$HOME/.openclaw/workspace`)
- `OPENCLAW_SESSION_DIR` (default: `$OPENCLAW_HOME/agents/main/sessions`)

## Usage

Run from this folder or by full path.

```bash
bash session-watchdog.sh
bash session-metrics.sh
bash session-ops-weekly-report.sh
bash session-cleanup.sh
bash session-store-hygiene.sh
```

You can also pass a custom store path:

```bash
bash session-watchdog.sh /path/to/sessions.json
```

## Recommended Cron Jobs

```bash
openclaw cron add "session-watchdog" \
  --command "bash ${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}/scripts/session-management/session-watchdog.sh" \
  --schedule "*/30 * * * *" \
  --delivery.channel "YOUR_OPS_CHANNEL_ID"

openclaw cron add "session-ops-weekly" \
  --command "bash ${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}/scripts/session-management/session-ops-weekly-report.sh" \
  --schedule "0 0 * * 0" \
  --delivery.channel "YOUR_OPS_CHANNEL_ID"
```

## Notes

- `session-watchdog.sh` writes a rolling log to `$OPENCLAW_WORKSPACE/memory/watchdog-log.md`.
- `session-ops-weekly-report.sh` writes to `$OPENCLAW_WORKSPACE/memory/session-ops-weekly.md`.
- `session-store-hygiene.sh` creates a timestamped backup before writing.
