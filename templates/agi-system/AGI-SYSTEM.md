# AGI System Documentation

*Intelligence augmentation system for OpenClaw agents — structured reasoning, self-improvement, and verification.*

## Overview

The AGI system provides structured reasoning, self-improvement, and verification capabilities through:
1. **Enforced protocols** in AGENTS.md
2. **Automated scripts** in scripts/agi/
3. **Scheduled crons** for continuous learning
4. **Memory infrastructure** for persistence

## Components

### 1. Protocol Layer (AGENTS.md)

**Pre-Flight Checklist** — Before any non-trivial response:
- [ ] memory_recall(query relevant to request)
- [ ] Scan available_skills for matches
- [ ] Check .learnings/ERRORS.md for recent mistakes
- [ ] If complex: activate THINKING.md protocol
- [ ] If major decision: consider Council of the Wise

**Post-Flight Checklist** — After completing any task:
- [ ] Log outcome to memory/YYYY-MM-DD.md
- [ ] If error → append to .learnings/ERRORS.md
- [ ] If correction → extract rule, update AGENTS.md
- [ ] If new preference → update USER.md or MEMORY.md

**Skill Routing Matrix** — 20+ task types mapped to specific skills

### 2. Scripts (scripts/agi/)

| Script | Purpose | Usage |
|--------|---------|-------|
| `pre-flight.sh` | Load context before complex tasks | Run at session start or before major work |
| `post-flight.sh` | Log task outcomes | `post-flight.sh "task" "outcome" ["error"]` |
| `learn.sh` | Analyze errors, propose rules | Run nightly or after corrections |
| `extract-corrections.sh` | Find corrections in memory | Run to surface patterns |
| `verify.sh` | Verification sub-agent template | Reference for spawning verifiers |
| `council.sh` | Council of the Wise template | Reference for multi-perspective analysis |
| `first-principles.sh` | First principles template | Reference for ground-up thinking |
| `personas.sh` | Quick reasoning personas reference | Reference for perspective switching |

### 3. Crons

| Cron | Schedule | Purpose |
|------|----------|---------|
| `memory-engine-nightly` | 3 AM daily | Run memory engine + AGI learn cycle |
| `agi-self-improvement` | 4 AM Sunday | Weekly deep analysis, rule proposals |

### 4. Memory Infrastructure

| File | Purpose |
|------|---------|
| `memory/self-review.md` | Recent lessons to check on session start |
| `.learnings/ERRORS.md` | Error log with root cause analysis |
| `.learnings/LEARNINGS.md` | Extracted learnings and patterns |
| `.learnings/analysis-*.md` | Daily analysis outputs |
| `THINKING.md` | Structured reasoning protocol |

## Reasoning Protocols

### THINKING.md Protocol (for complex questions)
1. Problem decomposition
2. Multiple hypotheses
3. Adversarial self-check
4. Confidence calibration
5. Output with reasoning

### Council of the Wise (for major decisions)
Spawn 3-4 sub-agents with perspectives:
- **Skeptic** — Find flaws
- **Advocate** — Strengthen the idea
- **Pragmatist** — Focus on execution
- **Historian** — Learn from precedent

### First Principles (when stuck)
1. State problem clearly
2. Identify assumptions
3. Break to fundamentals
4. Question each assumption
5. Rebuild from atoms

### Reasoning Personas (for thorough analysis)
Cycle: Pattern Hunter → Gonzo → Devil's Advocate → Integrator

## Self-Improvement Loop

```
Daily:
├── Log errors/corrections immediately
├── Update memory files continuously
└── Run post-flight after tasks

Nightly (3 AM):
├── memory-engine learn.sh
├── AGI learn.sh
├── extract-corrections.sh
└── Update self-review.md

Weekly (Sunday 4 AM):
├── Deep error analysis
├── Pattern extraction
├── Rule proposals
├── AGENTS.md updates
└── Metrics report
```

## Confidence Calibration

Before finalizing important responses:
- **HIGH (>90%)**: Verified, tested, or from authoritative source
- **MEDIUM (60-90%)**: Reasonable inference, may need verification
- **LOW (<60%)**: Speculative, flag clearly

## Self-Improvement Triggers

| Trigger | Action |
|---------|--------|
| "No, that's wrong..." | Extract rule → AGENTS.md |
| "Actually..." | Log correction → .learnings/ |
| "Always do X" / "Never do Y" | Add to relevant section |
| Task failed | Root cause → ERRORS.md |
| Same mistake twice | MANDATORY: Add explicit rule |

---

*Last updated: 2026-02-05*
