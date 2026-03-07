# Agent Architecture v2 — Narrow Agents, Clear Intent

*Created: 2026-03-01 | Trigger: Riley Brown's narrow agent thesis + Alex's directive*

## Principle
Every agent is a focused employee with one job, clear KPIs, and explicit boundaries.
Main is the orchestrator — it delegates, it doesn't do.

## Agent Roster (8 agents)

### 1. 🦞 `main` — The Orchestrator
- **Role:** Interactive assistant, delegation hub, self-improvement
- **Model:** Opus 4.6
- **Cron jobs:** 7 (briefing, consolidation, self-improvement, memory)
- **Channels:** All (front door)
- **Identity:** Dan — Alex's primary interface

### 2. 🐦 `dan-twitter` — X/Twitter Specialist
- **Role:** Mentions, reply drafts, niche scanning, content scheduling, research
- **Model:** Sonnet 4.5
- **Cron jobs:** 6 (unchanged)
- **Channel:** #twitter only
- **Constraint:** Draft-only, no posting

### 3. 📸 `dan-insta` — Instagram Specialist
- **Role:** Content drafting, visual pipeline, niche scanning, creative intel
- **Model:** Sonnet 4.5
- **Cron jobs:** 5 (unchanged)
- **Channel:** #insta only
- **Constraint:** Draft-only, no posting

### 4. 📝 `dan-content` — Content Strategy Coordinator (NEW)
- **Role:** Cross-platform intel, LinkedIn drafts, content feedback loops, portfolio
- **Model:** Sonnet 4.5
- **Cron jobs:** 7 (moved from main)
- **Channel:** #twitter, #insta (read), #content (if created)
- **Owns:** morning-intel, afternoon-scan, content-drafts (Mon/Wed/Fri), feedback loop, portfolio

### 5. 🔧 `dan-ops` — Infrastructure & Reliability
- **Role:** All infra: backups, session hygiene, health monitoring, security, updates
- **Model:** Sonnet 4.5
- **Cron jobs:** 14 (5 existing + 9 from main)
- **Channel:** #ops, #security
- **Constraint:** No browser, no TTS, no canvas

### 6. 💻 `dan-coder` — Software Engineer
- **Role:** Code tasks, PR reviews, repo work (on-demand spawn)
- **Model:** Sonnet 4.5
- **Cron jobs:** 0 (spawn-only)
- **Constraint:** No messaging (output via files/return)

### 7. 🔬 `dan-research` — Deep Research
- **Role:** Long-form research, competitive analysis, market research (on-demand)
- **Model:** Sonnet 4.5
- **Cron jobs:** 0 (spawn-only)
- **Constraint:** No messaging (output via files/return)

### 8. ✍️ `writer` — Long-form Writer
- **Role:** Blog posts, documentation, long-form content (on-demand)
- **Model:** Opus 4.6 (quality matters here)
- **Cron jobs:** 0 (spawn-only)
- **Constraint:** No cron/gateway access

## Cron Job Distribution

### main (7 jobs) — down from 23
| Job | Schedule | Purpose |
|-----|----------|---------|
| daily-briefing | 7:45am daily | Morning briefing → #briefing |
| nightly-consolidation | 3am daily | Memory consolidation + git |
| weekly-release-reminder | Tue 9am | System event reminder |
| agi-self-improvement | Sun 4am | Self-review + rule extraction |
| weekly-memory-prune | Sun 10am | Memory file cleanup |
| linkedin-token-expiry | One-shot Mar 21 | Token expiry warning |
| poly-market-scan | 8x daily | Polymarket scanner → #poly |

### dan-content (7 jobs) — NEW
| Job | Schedule | Purpose |
|-----|----------|---------|
| morning-intel-gather | 6:45am daily | Raw intel collection |
| afternoon-content-scan | 3:10pm weekdays | Breaking news catch-up |
| content-draft-monday | Mon 7am | LinkedIn draft |
| content-draft-wednesday | Wed 7am | LinkedIn draft |
| content-draft-friday | Fri 7am | LinkedIn draft |
| content-feedback-loop | Sun 7pm | Weekly performance review |
| portfolio-auto-update | Fri 4pm | Portfolio-worthy achievements |

### dan-ops (14 jobs) — up from 5
| Job | Schedule | Purpose |
|-----|----------|---------|
| agent-swarm-monitor | */30 8-23 | Agent health checks |
| session-compactor | Every 4h | Context window management |
| feedback-collector | Every 6h | Cron performance data |
| token-scrubber | Every 12h | Credential leak detection |
| daily-git-backup | 11:02pm | Git bundle backup |
| system-health-monitor | 9am daily | Gateway/disk/cron health |
| session-hygiene-daily | 4:15am daily | Session store cleanup |
| daily-git-backup-clawd | 11:08pm | Clawd workspace backup |
| workflows-repo-sync | 11:18pm | Workflow sync |
| state-backup-push | 11:25pm | State → GitHub backup |
| openclaw-update-check | Wed 4am | Version check |
| session-cleanup-weekly | Sun 3:30am | Purge old session files |
| session-ops-weekly | Sun 4:45am | Weekly ops report |
| feedback-analytics | Sun 5am | Weekly analytics |

### dan-twitter (6 jobs) — unchanged
### dan-insta (5 jobs) — unchanged

## Inter-Agent Data Contracts

Each agent writes to its own output directory. No shared files.

```
workspace/
├── agents/
│   ├── content/output/     ← dan-content writes here
│   │   ├── daily-intel.md
│   │   └── content-ideas.md
│   ├── twitter/output/     ← dan-twitter writes here
│   │   ├── reply-drafts/
│   │   └── content-ideas.md
│   └── instagram/output/   ← dan-insta writes here
│       ├── content-ideas.md
│       └── pending-brief.json
```

Cross-agent reads are allowed (read from other agent's output/).
Only the owning agent writes to its output directory.

## Success Metrics per Agent
- **main:** Response time, delegation accuracy, memory quality
- **dan-twitter:** Reply drafts approved/rejected ratio, follower growth correlation
- **dan-insta:** Content published rate, engagement correlation
- **dan-content:** Intel quality (items used vs gathered), draft approval rate
- **dan-ops:** Uptime, error detection speed, false positive rate
