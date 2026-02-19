# AGI System Setup

Complete intelligence augmentation system for OpenClaw agents.

## Overview

The AGI system provides:
- Enforced pre/post flight protocols
- Automated learning and self-improvement
- Multi-perspective reasoning (Council of the Wise)
- Skill routing optimization
- Confidence calibration

## Installation

### 1. Create Scripts Directory

```bash
mkdir -p ~/openclaw-workspace/scripts/agi
```

### 2. Copy AGI Scripts

See the scripts in the main workspace:
- `pre-flight.sh` — Context loading before tasks
- `post-flight.sh` — Outcome logging
- `learn.sh` — Pattern analysis and rule proposals
- `extract-corrections.sh` — Surface corrections from memory
- `verify.sh` — Verification sub-agent template
- `council.sh` — Multi-perspective analysis template
- `first-principles.sh` — Ground-up decomposition
- `personas.sh` — Reasoning personas quick-reference

### 3. Create Memory Infrastructure

```bash
mkdir -p ~/openclaw-workspace/.learnings
touch ~/openclaw-workspace/.learnings/ERRORS.md
touch ~/openclaw-workspace/.learnings/LEARNINGS.md
touch ~/openclaw-workspace/memory/self-review.md
touch ~/openclaw-workspace/THINKING.md
```

### 4. Add AGENTS.md Protocols

Add to your AGENTS.md:

```markdown
## 🚀 AGI Protocol (MANDATORY)

### ✈️ Pre-Flight Checklist (BEFORE responding to any non-trivial request)
- [ ] memory_recall(query relevant to request)
- [ ] Scan available_skills for matches
- [ ] Check .learnings/ERRORS.md for recent mistakes
- [ ] If complex: activate THINKING.md protocol
- [ ] If major decision: consider Council of the Wise

### 🛬 Post-Flight Checklist (AFTER completing any task)
- [ ] Log outcome to memory/YYYY-MM-DD.md
- [ ] If error → append to .learnings/ERRORS.md
- [ ] If correction → extract rule, update AGENTS.md
- [ ] If new preference → update USER.md or MEMORY.md
```

### 5. Set Up Crons

**Weekly Self-Improvement (Sunday 4AM):**
```json
{
  "name": "agi-self-improvement",
  "schedule": {"kind": "cron", "expr": "0 4 * * 0", "tz": "America/New_York"},
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "AGI Self-Improvement Cycle. Run learn.sh, analyze errors, propose AGENTS.md updates.",
    "thinking": "high"
  }
}
```

**Nightly Learning (3AM):**
Update your memory-engine-nightly cron to also run:
```bash
bash ~/openclaw-workspace/scripts/agi/learn.sh
bash ~/openclaw-workspace/scripts/agi/extract-corrections.sh
```

## Skill Routing Matrix

Add to AGENTS.md:

| Task Type | Primary Skill | Fallback |
|-----------|--------------|----------|
| Images | nano-banana-pro | openai-image-gen |
| Calendar | apple-calendar | gog |
| Notes | apple-notes, obsidian | file write |
| Email | himalaya, gog | - |
| PDF | pdf | nano-pdf |
| Web search | web_search | perplexity |
| X/Twitter | bird | browser |
| GitHub | github (gh CLI) | direct API |

## Confidence Calibration

Before finalizing important responses:
- **HIGH (>90%)**: Verified, tested, from authoritative source
- **MEDIUM (60-90%)**: Reasonable inference, may need verification  
- **LOW (<60%)**: Speculative, flag clearly

## Self-Review File

Create `memory/self-review.md`:

```markdown
# Self-Review — Recent Lessons

## 🔴 CRITICAL (Check before every response)
1. Verify before claiming
2. Research-first
3. Memory search before "remember when..."
4. Approval gate for public actions

## 🟡 RECENT MISSES
- [Date]: [What went wrong]

## 🟢 RECENT WINS
- [Pattern that worked]
```

---

*Part of OpenClaw Config collection*
