<p align="center">
  <img src="docs/assets/openclaw-config-cover.png" alt="openclaw-config" width="600" />
</p>

<h1 align="center">openclaw-config</h1>

<p align="center">
  Production-tested configs, scripts, and workspace templates for <a href="https://github.com/openclaw/openclaw">OpenClaw</a>.<br />
  Not an SDK — just copyable building blocks from a real daily-driver setup.<br />
  <strong>Release v2026.02.27</strong> • Compatible with OpenClaw 2026.2.24+
</p>

<p align="center">
  <a href="https://github.com/YOUR_USERNAME/openclaw-config/releases/latest">
    <img src="https://img.shields.io/github/v/release/YOUR_USERNAME/openclaw-config?style=flat-square&color=blue" alt="Latest Release" />
  </a>
  <a href="https://github.com/YOUR_USERNAME/openclaw-config/stargazers">
    <img src="https://img.shields.io/github/stars/YOUR_USERNAME/openclaw-config?style=flat-square&color=yellow" alt="GitHub Stars" />
  </a>
  <a href="https://github.com/YOUR_USERNAME/openclaw-config/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/YOUR_USERNAME/openclaw-config?style=flat-square&color=green&v=2" alt="MIT License" />
  </a>
  <a href="https://github.com/YOUR_USERNAME/openclaw-config/commits/main">
    <img src="https://img.shields.io/github/last-commit/YOUR_USERNAME/openclaw-config?style=flat-square&color=orange" alt="Last Commit" />
  </a>
</p>

<p align="center">
  <a href="#-new-production-hardening-guide">🚀 Production Hardening</a> •
  <a href="#whats-new-in-v20260227">What's New</a> •
  <a href="#session-management-suite">Session Management</a> •
  <a href="#model-change-safety-rules">Model Safety</a> •
  <a href="#agent-swarm-orchestration">Agent Swarm</a> •
  <a href="#quickstart">Quickstart</a> •
  <a href="#whats-included">What's Included</a> •
  <a href="#gateway-config-snippets">Configs</a> •
  <a href="#skill-routing-overrides">Skills</a> •
  <a href="#workspace-templates">Templates</a> •
  <a href="#contributing">Contributing</a>
</p>

---

## Production Hardening Guide

**Harden your OpenClaw setup for production in 30 minutes.**

Based on critical GitHub issues and community findings, this guide addresses security and reliability gaps in default OpenClaw installations.

### 🔥 What It Fixes

| Issue | Impact | Fix |
|-------|--------|-----|
| **Secrets in config** | Credential theft, API key exposure | Move all secrets to `.env` |
| **${VAR} syntax broken** | Secrets resolve to plaintext on config writes ([#9627](https://github.com/openclaw/openclaw/issues/9627)) | Remove placeholders completely |
| **API keys leak to LLMs** | Keys sent to providers in error logs ([#11202](https://github.com/openclaw/openclaw/issues/11202)) | .env-only approach |
| **Slow crash recovery** | Exponential backoff causes extended downtime ([#4632](https://github.com/openclaw/openclaw/issues/4632)) | `ThrottleInterval: 5` |

### 📊 Default Install vs Hardened

| Metric | Default | Hardened | Improvement |
|--------|---------|----------|-------------|
| **Secrets** | Keys in plaintext | All in `.env` (chmod 600) | 100% elimination |
| **Crash Recovery** | 10s-5min | 5s flat | 60x faster |
| **Config Rollback** | 30+ min | 10 seconds | 180x faster |
| **Failure Detection** | Hours | ~5 minutes | 48x faster |
| **Disk Usage (1yr)** | ~300MB | ~30MB | 90% reduction |

### 🚀 Get Started

```bash
cd ~/.openclaw
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/openclaw-config/main/production-hardening/install.sh
chmod +x install.sh
./install.sh
```

**📖 Full Guide**: [production-hardening/README.md](./production-hardening/README.md)
**📝 Release Notes**: [RELEASE-v2026.02.27.md](./RELEASE-v2026.02.27.md)
**🔍 Research**: [production-hardening/RESEARCH.md](./production-hardening/RESEARCH.md)

---

## What's New in v2026.02.27

- **Session Management Suite** added under `scripts/session-management/`:
  - `session-watchdog.sh`
  - `session-metrics.sh`
  - `session-ops-weekly-report.sh`
  - `session-cleanup.sh`
  - `session-store-hygiene.sh`
- **Model Change Safety Rules** added: `docs/model-change-safety-rules.md`
- **Agent Swarm Orchestration** guide added: `workflows/agent-swarm-orchestration.md`
- **OpenClaw Cron Patterns** reference added: `workflows/openclaw-cron-patterns.md`
- **Agent Conventions** added: `docs/agent-conventions.md`
- **Refined templates** updated: `templates/AGENTS.md`, `templates/HEARTBEAT.md`, `templates/SOUL.md`

## Session Management Suite

A production-focused lifecycle toolkit for session stability and context hygiene.

- **Autonomous watchdog** for stale/maxed session cleanup
- **Metrics snapshots** for monitoring and alerting
- **Weekly ops reporting** to persistent markdown logs
- **Manual cleanup + store hygiene** scripts for incident response

📄 Docs: [`scripts/session-management/README.md`](./scripts/session-management/README.md)

## Model Change Safety Rules

A hard safety checklist for switching models without breaking active sessions (especially Anthropic thinking-signature compatibility).

- Pre-change checklist (contexts, thinking mode, fallback ordering)
- Session-impact rules for shared vs isolated sessions
- Post-change verification steps to catch signature errors early

📄 Docs: [`docs/model-change-safety-rules.md`](./docs/model-change-safety-rules.md)

## Agent Swarm Orchestration

Reference architecture for running multi-agent work with routing, monitoring, review gates, and cleanup loops.

- Smart routing + learning loop
- Deterministic health checks + auto-respawn policies
- Triple-review model and UI screenshot gate
- Paired workflow docs for scheduling and cron operations

📄 Orchestration: [`workflows/agent-swarm-orchestration.md`](./workflows/agent-swarm-orchestration.md)  
📄 Cron patterns: [`workflows/openclaw-cron-patterns.md`](./workflows/openclaw-cron-patterns.md)

---

## Quickstart

Pick what you need. Most people start with **templates** or **templates + task runner**.

```bash
# Clone
git clone https://github.com/YOUR_USERNAME/openclaw-config.git
cd openclaw-config

# Copy templates into your workspace
rsync -av templates/ ~/.openclaw/workspace/

# (Optional) Copy the task runner
rsync -av scripts/taskrunner/ ~/.openclaw/workspace/scripts/taskrunner/

# (Optional) Copy skill routing overrides
rsync -av skills/ ~/.openclaw/workspace/skills/
```

> **Note:** Replace `~/.openclaw/workspace/` with your actual workspace path if different.

---

## What's Included

| Directory | Description |
|-----------|-------------|
| **`production-hardening/`** ⭐ | Complete production hardening suite — security fixes, LaunchAgent config, log rotation, backups, health monitoring |
| `templates/` | Workspace bootstrap files — `AGENTS.md`, `SOUL.md`, `STATE.md`, `HEARTBEAT.md`, `IDENTITY.md`, `USER.md`, `artifacts/` |
| `skills/` | Workspace-level SKILL.md overrides that reduce misfires in overlapping domains |
| `config/` | Gateway config snippets (JSON5) — compaction, pruning, model fallbacks, memory, search, Slack |
| `scripts/memory-engine/` | Shell-based memory lifecycle: capture → recall → decay → learn + self-review |
| **`scripts/session-management/`** ⭐ | Session lifecycle suite: watchdog, metrics, weekly ops report, cleanup, and store hygiene |
| `scripts/taskrunner/` | Python task automation with retry logic, file locking, structured logging |
| `agents/` | Multi-agent persona prompts (researcher, architect, security auditor, etc.) |
| `docs/` | Operational guides — context overflow, model-change safety rules, agent conventions, memory research, skill routing, Slack migration, model fallback strategy |
| `content-pipeline/` | Optional cron-driven content workflow: draft → approve → post → metrics |

---

## Workspace Templates

The `templates/` directory provides a complete workspace scaffold:

- **`AGENTS.md`** — Session boot sequence, memory hierarchy, group chat etiquette, heartbeat system, artifact conventions (~220 lines of battle-tested instructions)
- **`SOUL.md`** — Agent personality and philosophy. Opinionated by design — edit to match your style.
- **`STATE.md`** — Live working context (max 3KB). Survives compaction and session resets. Priority markers: 🔴 ACTIVE / 🟡 WAITING / ⚪ DONE
- **`HEARTBEAT.md`** — Proactive check template: STATE maintenance, cron health, inbox/calendar rotation, self-improvement
- **`IDENTITY.md`** — Agent identity (name, emoji, avatar, history)
- **`USER.md`** — About the human (preferences, projects, context)
- **`artifacts/`** — Structured output directory: `reports/`, `code/`, `data/`, `images/`, `temp/`

---

## Skill Routing Overrides

OpenClaw's bundled skills sometimes collide in overlapping domains. These workspace-level overrides add **"Don't use for..."** negative examples to improve routing accuracy.

| Domain | Skills | Routing Logic |
|--------|--------|---------------|
| Email | `gog`, `himalaya` | gog → Gmail/Google Workspace · himalaya → IMAP/SMTP |
| Notes | `apple-notes`, `bear-notes`, `obsidian`, `notion` | Each gets explicit boundaries against the others |
| Transcription | `openai-whisper`, `openai-whisper-api` | Local CLI vs cloud API |
| Messaging | `imsg` | Fallback iMessage CLI; prefer bluebubbles if available |
| Code | `coding-agent` | Multi-step coding sessions; not for simple shell commands |
| Summarize | `summarize` | URLs/podcasts/files; not for simple HTML extraction |

Based on OpenAI's [Shell + Skills + Compaction](https://openai.com) guidance — Glean reported **20% misfire reduction** after adding negative examples.

> Overrides mask bundled updates. When OpenClaw ships improved descriptions upstream, delete the override to fall back. Tracked in [openclaw/openclaw#14748](https://github.com/openclaw/openclaw/issues/14748).

---

## Gateway Config Snippets

Production-tested config examples in `config/*.json5`. **Merge into your config — don't replace.**

### Essential

| Config | What It Does |
|--------|-------------|
| `compaction-and-pruning.json5` | Highest-impact stability settings (reserve tokens, soft thresholds) |
| `context-overflow-prevention.json5` | Defensive settings for heavy tool use |
| `model-aliases-and-fallbacks.json5` | Cross-provider fallbacks (Opus → Sonnet → GPT) to prevent cascading failures |
| `memory-search.json5` | Semantic search over workspace memory files |
| `slack-setup.json5` | Slack configuration (socket mode, allowlist policies, session sprawl prevention) |

### Power User

| Config | What It Does |
|--------|-------------|
| `pro-optimization.json5` | Maximum capability without sacrificing stability — longer sessions, faster recovery, aggressive caching |
| `feature-unlocks.json5` | Enable production-ready features that ship disabled by default — auto-analysis, link fetch, typing indicator, heartbeats |
| `memory-lancedb-setup.json5` | LanceDB + OpenAI embeddings for long-term memory |
| `web-search-perplexity.json5` | Perplexity search (no rate limits with paid key) |

```bash
# Apply configs, then restart
openclaw gateway restart
```

> **Tip:** Apply `pro-optimization` first, run for a few days, then add `feature-unlocks`. Changing everything at once makes debugging harder.

---

## Documentation

### Production Hardening

Complete production deployment guide in `production-hardening/`:

| Doc | What It Covers |
|-----|---------------|
| **`README.md`** | Quick start, what's fixed, metrics, validation |
| **`IMPLEMENTATION.md`** | Step-by-step guide (7 phases, 60 minutes) |
| **`DECISION_MATRIX.md`** | 13K+ word analysis — 8 issues, alternatives, before/after metrics |
| **`RESEARCH.md`** | Community research findings and GitHub issues |
| **`docs/QUICK_OPS.md`** | Daily operations reference |

### Operational Guides

Key operational guides in `docs/`:

| Doc | What It Covers |
|-----|---------------|
| `agent-system-research.md` | Memory systems research (4500+ words) — SQLite+vector, tiered memory, consolidation |
| `session-context-overflow-fix.md` | Context overflow prevention strategies and settings |
| `skill-routing-improvements.md` | Skill routing audit + negative examples to reduce misfires |
| `slack-migration-notes.md` | Slack `dmPolicy` → `dm.policy` migration in OpenClaw 2026.2.14 |
| `model-fallback-strategy.md` | Why cross-provider fallbacks prevent cascading failures |
| `diagnosis-protocol.md` | Systematic troubleshooting for agent issues |
| `content-strategy/` | Content framework, image specs, posting guidelines |

---

## Scripts

### Memory Engine (`scripts/memory-engine/`)

Shell-based memory lifecycle: `capture.sh` → `recall.sh` → `decay.sh` → `learn.sh`

- Nightly learning extracts errors, corrections, and insights from daily logs
- Self-review system (MISS/FIX tags) prevents repeated mistakes
- See `scripts/memory-engine/README.md` for setup

### Task Runner (`scripts/taskrunner/`)

Python-based task automation — replacement for fragile shell scripts:

- Retry logic with exponential backoff
- File locking (no concurrent runs)
- Structured JSON logging (`logs/tasks.jsonl`)
- Alert system for heartbeat integration (`alerts/pending.json`)
- Example tasks: `memory_capture`, `memory_consolidate`, `system_health`

```bash
python3 ~/.openclaw/workspace/scripts/taskrunner/runner.py memory_capture
```

---

## Agents

Drop-in persona prompts for `sessions_spawn` in `agents/`:

- `deep-researcher.md` — Multi-source research with citation
- `architect.md` — System design and technical architecture
- `security-auditor.md` — Security review and hardening
- `content-writer.md` — Content drafting with voice/tone consistency
- `ux-designer.md` — UX review and design recommendations
- `market-researcher.md` — Market analysis and competitive intelligence
- `project-planner.md` — Project breakdown and timeline estimation
- `devils-advocate.md` — Structured counterarguments

---

## Repo Layout

```
openclaw-config/
├── agents/                      # Multi-agent persona prompts
├── config/                      # Gateway config snippets (JSON5)
├── content-pipeline/            # Optional: cron-driven content workflow
├── docs/
│   ├── agent-system-research.md           # Memory systems research (4500+ words)
│   ├── session-context-overflow-fix.md    # Context overflow prevention
│   ├── skill-routing-improvements.md      # Skill routing audit + improvements
│   └── content-strategy/                  # Content framework + specs
├── production-hardening/        # Production deployment suite
│   ├── README.md                # Quick start and overview
│   ├── IMPLEMENTATION.md        # Step-by-step guide
│   ├── DECISION_MATRIX.md       # Detailed analysis (13K+ words)
│   ├── RESEARCH.md              # Community research findings
│   ├── install.sh               # Automated installer
│   ├── scripts/
│   │   ├── rotate-logs.sh       # Log rotation
│   │   ├── backup-config.sh     # Daily backups
│   │   └── healthcheck.sh       # Health monitoring
│   ├── config/
│   │   ├── launchagent.plist    # Production LaunchAgent
│   │   └── gitignore.template   # Secure .gitignore
│   └── docs/
│       └── QUICK_OPS.md         # Daily operations reference
├── scripts/
│   ├── memory-engine/           # Shell-based capture/recall/decay/learn
│   └── taskrunner/              # Python task automation
├── skills/                      # Workspace-level SKILL.md routing overrides
├── templates/                   # Workspace bootstrap files
│   └── artifacts/               # Structured output directory convention
└── workflows/                   # Operational references + optional Lobster workflows
```

---

## Safety & Privacy

These files are meant to be copied into your workspace. Treat them like production config:

- **Never commit secrets** — API keys, tokens, cookie databases
- **Review before copying** — some templates contain placeholder values
- **Fork responsibly** — no personal data, no logs

See [SECURITY.md](./SECURITY.md) for reporting vulnerabilities.

---

## Contributing

PRs welcome. Requirements:

- Must be tested in a real OpenClaw workspace
- No personal data (keys, usernames, emails, logs)
- Explain *why* a setting exists, not just what it does

See [CONTRIBUTING.md](./CONTRIBUTING.md).

---

## License

[MIT](./LICENSE)
