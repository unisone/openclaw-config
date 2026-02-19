# Task Runner Quick Reference

## Run a Task

```bash
python3 ~/.openclaw/workspace/scripts/taskrunner/runner.py <task_name>
```

## Available Tasks

| Task | Description | Typical Usage |
|------|-------------|---------------|
| `memory_capture` | Extract from daily files → store.json | Heartbeat, 2-4x/day |
| `memory_consolidate` | Prune old/duplicates from store.json | Cron, daily at 3 AM |
| `system_health` | Check gateway/disk/cron status | Heartbeat, on-demand |

## Common Commands

```bash
# Capture today's memories
python3 runner.py memory_capture

# Clean up memory store
python3 runner.py memory_consolidate

# Check system health
python3 runner.py system_health

# Dry run (no writes)
python3 runner.py memory_consolidate --dry-run

# Run all tests
python3 test_all.py
```

## Heartbeat Integration

When heartbeat runs, it should:

1. Check if `memory/YYYY-MM-DD.md` exists (create if not)
2. Read `alerts/pending.json` (post to Slack if exists, then clear)
3. Run `memory_capture` to extract today's context
4. Check cron health (lightweight)

## Check Logs

```bash
# View all task runs
cat logs/tasks.jsonl

# Latest run
tail -1 logs/tasks.jsonl | python3 -m json.tool

# Failed runs only
grep '"success": false' logs/tasks.jsonl

# Memory capture runs
grep 'memory_capture' logs/tasks.jsonl
```

## Alert System

Tasks write alerts to `alerts/pending.json`:
```json
[
  {
    "task": "system_health",
    "timestamp": "2026-02-10T20:00:00",
    "level": "warning",
    "message": "Disk 86% full"
  }
]
```

Heartbeat reads this file, posts to Slack, then deletes it.

## Exit Codes

- `0` — Success
- `1` — Error (logged to tasks.jsonl)
- `2` — Locked (another instance running)

## File Locations

- Runner: `~/.openclaw/workspace/scripts/taskrunner/runner.py`
- Tasks: `~/.openclaw/workspace/scripts/taskrunner/tasks/*.py`
- Logs: `~/.openclaw/workspace/scripts/taskrunner/logs/tasks.jsonl`
- Alerts: `~/.openclaw/workspace/scripts/taskrunner/alerts/pending.json`
- Memory store: `~/.openclaw/workspace/memory/store.json`
- Daily files: `~/.openclaw/workspace/memory/YYYY-MM-DD.md`

## Adding New Tasks

1. Create `tasks/your_task.py`
2. Class name: `YourTaskTask` (PascalCase + "Task")
3. Inherit from `Task` base class
4. Implement: `name`, `description`, `run()`
5. Add to `test_all.py`

See README.md for detailed examples.
