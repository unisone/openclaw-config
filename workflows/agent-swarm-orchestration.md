# Agent Swarm Orchestration — Pro Setup

*Last updated: 2026-02-23*
*Inspired by community swarm setups, then extended for OpenClaw operations.*

## Architecture

```
The operator (human)
  ↓ task description
Your orchestrator agent (OpenClaw orchestrator)
  ├── 🧠 Smart Router → picks best agent + model per task
  ├── 📊 Learning Loop → tracks what works, improves over time
  ├── 🔍 Proactive Scanner → finds work before you ask
  │
  ├── spawn-agent.sh → tmux + worktree isolation
  │   ├── Codex (backend, bugs, refactors, tests)
  │   ├── Claude Code (frontend, docs, fast tasks)
  │   └── Gemini (design specs → Claude implementation)
  │
  ├── check-agents.sh → deterministic monitoring (no AI tokens)
  │   ├── tmux alive?
  │   ├── PR created?
  │   ├── CI passing?
  │   ├── Auto-respawn on failure (max 3 attempts)
  │   └── 🧠 Auto-log outcomes to learning DB
  │
  ├── review-pr.sh → triple AI review
  │   ├── Codex: logic, edge cases, race conditions
  │   ├── Claude: code quality, patterns, test coverage
  │   ├── Gemini: security, scalability, performance
  │   └── Screenshot gate: UI PRs must include before/after
  │
  └── cleanup.sh → worktree + branch garbage collection
```

## Key Innovations (vs baseline swarm setups)

### 1. Learning Loop (`learning/`)
Every task outcome gets logged automatically:
- Task type classification (bugfix, feature, frontend, backend, etc.)
- Agent + model used, duration, retry count
- File categories changed
- Success/failure with notes

This builds `patterns.json` — a growing knowledge base:
- Per-model stats (tasks, first-try success rate, avg duration)
- Per-task-type stats (which agent performs best for each type)
- Successful prompt patterns (size, structure, what was included)

**The router uses this data.** After 3+ tasks of a type, it overrides keyword rules with actual performance data.

### 2. Smart Model Routing (`route-task.sh`)
Decision order:
1. **Learning data** — If we have ≥3 outcomes for this task type, use the best performer
2. **Keyword rules** — Match description against routing table:
   - Backend/API/DB/auth → Codex (thorough reasoning)
   - Frontend/UI/components → Claude (faster, better at component work)
   - Bugs → Codex (best at edge cases)
   - Docs → Claude (cleaner prose)
3. **Default** → Codex (the workhorse)

### 3. Proactive Scanning (`scanning/`)
Finds work without being asked:
- **TODO/FIXME scan** — Greps registered repos for actionable items
- **Changelog scan** — Finds unreleased commits needing documentation
- **CI health check** — Alerts if main branch CI is failing
- **Stale branch detection** — Flags merged branches to clean up

### 4. Screenshot Gate
UI PRs (touching .tsx/.jsx/.vue/.svelte/.css) without screenshots get an automated comment requesting before/after images. Cuts review time dramatically.

## File Structure

```
.clawdbot/
├── config.json              # Master config (repos, models, safety)
├── active-tasks.json        # Live task registry
├── README.md
├── scripts/
│   ├── spawn-agent.sh       # Create worktree + launch agent in tmux
│   ├── check-agents.sh      # Deterministic health monitor
│   ├── review-pr.sh         # Triple AI code review
│   ├── route-task.sh        # Smart model routing
│   ├── status.sh            # Quick overview
│   └── cleanup.sh           # Garbage collection
├── learning/
│   ├── patterns.json        # Growing knowledge base
│   ├── outcomes.json        # Raw outcome log
│   └── log-outcome.sh       # Record + classify outcomes
├── scanning/
│   ├── scan-todos.sh        # Find TODOs/FIXMEs
│   ├── scan-git-changelog.sh # Find unreleased changes
│   ├── scan-proactive.sh    # Master scanner
│   └── last-scan.json       # Latest scan results
├── prompts/                  # Generated prompt files (per-task)
└── logs/                     # Agent terminal logs (per-task)
```

## Usage

### Spawn an agent (auto-routed)
```bash
.clawdbot/scripts/spawn-agent.sh example-web-app feat/dark-mode "Add dark mode toggle"
# 🧠 Auto-routed: claude (claude-opus-4.5) — frontend task
```

### Spawn with specific agent
```bash
.clawdbot/scripts/spawn-agent.sh example-api-service fix/auth-bug "Fix JWT refresh race condition" codex
```

### Check all agents
```bash
.clawdbot/scripts/check-agents.sh
```

### Run proactive scan
```bash
.clawdbot/scripts/../scanning/scan-proactive.sh
```

### View status
```bash
.clawdbot/scripts/status.sh
```

### Redirect a running agent
```bash
tmux send-keys -t clawdbot-<task-id> "Stop. Focus on the API layer first." Enter
```

## Cron Integration

- `agent-swarm-monitor` — runs `check-agents.sh` every 10 min during configured active hours
- Proactive scan can be added as daily cron for morning task discovery

## Safety Rails
- `neverAutoMerge: true` — Human always reviews before merge
- `maxConcurrentAgents: 4` — Prevents resource exhaustion
- `isolateWorktrees: true` — Each agent in its own directory
- `maxRetries: 3` — Capped respawn attempts
- Quiet hours: outside your configured active hours (no notifications)
