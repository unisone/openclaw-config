# Task Runner

A lightweight Python-based task runner for agent automation tasks.

## Architecture

- **`runner.py`** — Task dispatcher with retry logic, locking, and structured logging
- **`tasks/base.py`** — Base class for all tasks
- **`tasks/*.py`** — Individual task implementations
- **`logs/tasks.jsonl`** — JSON lines log of all task executions
- **`alerts/pending.json`** — Pending alerts for heartbeat to pick up

## Usage

### Run a Task

```bash
python3 runner.py <task_name>
# Or with absolute path:
python3 ~/.openclaw/workspace/scripts/taskrunner/runner.py <task_name>
```

### Dry Run Mode

```bash
python3 runner.py <task_name> --dry-run
```

In dry-run mode, tasks will execute their logic but skip any write operations.

### Examples

```bash
# Capture memories from daily files
python3 runner.py memory_capture

# Consolidate memory store (prune old/duplicates)
python3 runner.py memory_consolidate

# Run system health check
python3 runner.py system_health

# Dry run memory consolidation
python3 runner.py memory_consolidate --dry-run
```

## Available Tasks

### `memory_capture`
Extract key facts, decisions, and preferences from today's and yesterday's daily memory files (`memory/YYYY-MM-DD.md`). Automatically deduplicates against existing memory store.

**Patterns matched:**
- Headers (`##`, `###`)
- Bold items (`- **text**`)
- Markers: `TODO`, `DECISION`, `BLOCKER`, `ACTION`, `NOTE`
- Important bullets (containing keywords like "decided", "completed", "learned", etc.)

**Outputs:** Appends new memories to `memory/store.json`

### `memory_consolidate`
Prune old, low-importance, and duplicate entries from memory store.

**Pruning rules:**
- Entries >14 days old with importance <0.3
- Duplicates (>90% word overlap via Jaccard similarity)

**Outputs:** Updated `memory/store.json` (creates `.bak` backup)

### `system_health`
Quick system health check.

**Checks:**
- OpenClaw gateway (http://localhost:18789)
- Disk space (warns at 80%, critical at 90%)
- Cron job failures (`openclaw cron list`)

**Outputs:** Structured health report + alerts for issues

## Features

### Locking
Tasks use lockfiles (`/tmp/taskrunner-{taskname}.lock`) to prevent concurrent runs of the same task.

### Retry with Exponential Backoff
Failed tasks automatically retry up to 3 times with exponential backoff (2^attempt seconds).

### Structured Logging
All task executions log to `logs/tasks.jsonl` in JSON lines format:

```json
{
  "task": "memory_capture",
  "timestamp": "2026-02-10T20:30:00.123456",
  "success": true,
  "duration_seconds": 1.234,
  "message": "Captured 12 new memories from 2 files",
  "items_extracted": 45,
  "items_added": 12,
  "items_skipped": 33
}
```

### Alerting
Tasks can generate alerts via `self.alert(message, level)`. Alerts are written to `alerts/pending.json` for the heartbeat to pick up and post to Slack.

## Exit Codes

- `0` — Success
- `1` — Error
- `2` — Locked (task already running)

## Creating New Tasks

1. Create `tasks/your_task_name.py`
2. Inherit from `Task` base class
3. Implement `name`, `description`, and `run()` methods
4. Task class name must be `YourTaskNameTask` (PascalCase + "Task" suffix)

**Example:**

```python
from .base import Task
from typing import Any, Dict

class MyCustomTask(Task):
    @property
    def name(self) -> str:
        return "my_custom"
    
    @property
    def description(self) -> str:
        return "Does something custom"
    
    def run(self) -> Dict[str, Any]:
        # Your logic here
        self.log("Doing custom work")
        
        # Optional: create alert
        if something_bad:
            self.alert("Something went wrong!", level="error")
        
        return {
            "success": True,
            "message": "Custom task completed",
            # ... any other data
        }
```

## Testing

Run all tasks in dry-run mode:

```bash
python3 test_all.py
```

## Integration with Agent System

### Heartbeat
The heartbeat (`HEARTBEAT.md`) runs `memory_capture` periodically and checks `alerts/pending.json` for issues to report.

### Cron Jobs
Tasks can be scheduled via OpenClaw cron:

```bash
# Daily memory consolidation at 3 AM
openclaw cron add \
  --name "memory-consolidate-daily" \
  --schedule "0 3 * * *" \
  --command "python3 ~/.openclaw/workspace/scripts/taskrunner/runner.py memory_consolidate"
```

## Requirements

- Python 3.14+
- No external dependencies (stdlib only)
- macOS (uses `fcntl` for locking)
- OpenClaw CLI (for cron health checks)

## File Locations

Default workspace location: `~/.openclaw/workspace`

- Task runner: `~/.openclaw/workspace/scripts/taskrunner/`
- Memory store: `~/.openclaw/workspace/memory/store.json`
- Daily files: `~/.openclaw/workspace/memory/YYYY-MM-DD.md`
- Logs: `~/.openclaw/workspace/scripts/taskrunner/logs/`
- Alerts: `~/.openclaw/workspace/scripts/taskrunner/alerts/`
