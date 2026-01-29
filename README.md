# moltbot-config

> Production configs, memory scripts, and workspace templates for [Moltbot](https://github.com/moltbot/moltbot) — built from real daily usage, not theory.

Every file in this repo is running in production right now. If it's here, it works.

---

## Why This Exists

Moltbot ships with sane defaults, but the default setup has gaps:

- **Memory is flat files** — no scoring, no decay, no pattern detection
- **No self-correction loop** — the agent repeats the same mistakes across sessions
- **Compaction is lossy** — important context vanishes when the window fills up
- **Config docs are scattered** — hard to know which settings actually matter

This repo fixes all of that with tested scripts and configs you can drop into any Moltbot workspace.

---

## Quickstart

```bash
# Clone into your Moltbot workspace
git clone https://github.com/unisone/moltbot-config.git
cp -r moltbot-config/scripts/memory-engine/ /path/to/workspace/scripts/memory-engine/
cp -r moltbot-config/templates/* /path/to/workspace/
cp -r moltbot-config/agents/ /path/to/workspace/agents/
cp -r moltbot-config/config/ /path/to/workspace/docs/config-examples/

# Make scripts executable
chmod +x /path/to/workspace/scripts/memory-engine/*.sh

# Run your first capture
bash scripts/memory-engine/capture.sh

# Test recall
bash scripts/memory-engine/recall.sh "your query here"
```

---

## What's Inside

```
moltbot-config/
├── scripts/memory-engine/    # Memory scoring, decay, self-review
│   ├── capture.sh            # Extract structured memories from logs
│   ├── decay.sh              # Time-decay + frequency boost scoring
│   ├── learn.sh              # Nightly: capture → decay → self-review → insights
│   ├── recall.sh             # Context-aware pre-load at session start
│   ├── self-review.sh        # Extract MISS/FIX pairs from actual errors
│   └── config.json           # Tuning parameters
├── templates/                # Workspace bootstrap files
│   ├── AGENTS.md             # Operating instructions + memory protocol
│   ├── SOUL.md               # Persona, tone, anti-slop rules
│   ├── HEARTBEAT.md          # Proactive checks + self-review on boot
│   ├── IDENTITY.md           # Agent name/emoji/vibe
│   └── USER.md               # User profile template
├── agents/                   # Multi-agent personas
│   ├── architect.md          # System design + architecture
│   ├── content-writer.md     # Writing with voice, not slop
│   ├── deep-researcher.md    # Thorough multi-source research
│   ├── devils-advocate.md    # Challenge assumptions
│   ├── market-researcher.md  # Competitive analysis
│   ├── project-planner.md    # Scoping + task breakdown
│   ├── security-auditor.md   # Threat modeling + hardening
│   └── ux-designer.md        # Interface + experience design
└── config/                   # Gateway config snippets (JSON5)
    ├── compaction-and-pruning.json5
    ├── memory-search.json5
    ├── model-aliases-and-fallbacks.json5
    └── discord-setup.json5
```

---

## Memory Engine

The default Moltbot memory is append-only markdown files. This engine adds scoring, decay, pattern detection, and self-correction on top.

```
┌─────────────────────────────────────────────────────────┐
│                    MEMORY ENGINE                         │
├──────────┬──────────┬──────────────┬────────────────────┤
│ CAPTURE  │  RECALL  │    DECAY     │      LEARN         │
│ (live)   │ (boot)   │  (daily)     │   (nightly)        │
├──────────┼──────────┼──────────────┼────────────────────┤
│ Extract  │ Keyword  │ Score by     │ Consolidate →      │
│ facts,   │ weighted │ relevance,   │ self-review →      │
│ prefs,   │ search   │ frequency,   │ pattern detect →   │
│ decisions│ to pre-  │ recency      │ generate insights  │
│ from     │ load     │              │                    │
│ daily    │ relevant │ Archive low  │ MISS/FIX pairs     │
│ logs     │ on boot  │ scorers      │ from real errors   │
└──────────┴──────────┴──────────────┴────────────────────┘
                          │
                    memory/store.json
```

### Self-Review System

Most "self-improvement" approaches tell the LLM to reflect on its mistakes. The problem: **vague self-reflection is just confabulation**. The model invents plausible-sounding self-critique that may not reflect real problems.

Our approach: **extract MISS/FIX pairs from actual logged errors.**

```bash
$ bash scripts/memory-engine/self-review.sh 2026-01-29

🔍 Self-review: 2026-01-29
   Daily file: 115 lines
   Signals: errors=15 corrections=1 resets=3
   ✅ Review entry written
```

Output in `memory/self-review.md`:
```
## 2026-01-29

**Errors detected: 15**
- MISS: context overflow error leaked to user channel
- MISS: compaction triggered with wrong softThresholdTokens

**Corrections: 1**
- FIX: reset softThresholdTokens to docs default (4000)

**Tags:**
- [reliability] Multiple errors — check tooling stability
- [stability] Multiple resets — investigate root cause
```

On boot, the agent reads `self-review.md` and double-checks when current work overlaps a past MISS tag. Real signal, not vibes.

### Setup

```bash
# Copy to your workspace
cp -r scripts/memory-engine/ ~/clawd/scripts/memory-engine/
chmod +x ~/clawd/scripts/memory-engine/*.sh

# Run the full nightly cycle manually
bash ~/clawd/scripts/memory-engine/learn.sh

# Or set up a Moltbot cron job (runs at 3 AM daily)
# The learn.sh script chains: capture → decay → self-review → insights
```

Add to your `HEARTBEAT.md`:
```markdown
### Self-Review (session start + nightly)
- [ ] On boot: read `memory/self-review.md` — check recent MISS/FIX entries
- [ ] Nightly (via learn.sh): auto-extracts errors from daily log
- [ ] If current task overlaps a MISS tag, double-check before responding
```

---

## Gateway Config Snippets

Drop these into your `~/.clawdbot/moltbot.json`. Each file is standalone — use what you need.

### Compaction & Pruning
The most impactful settings for context management. Key insight: `reserveTokensFloor` controls when compaction triggers. `softThresholdTokens` controls when pre-compaction memory flush fires — keep it at the docs default (4000), not higher.

### Model Aliases & Fallbacks
Switch models with `/model opus` or `/model grok`. Fallbacks ensure you don't error out when your primary provider is down.

### Memory Search
Vector-powered semantic search over your memory files. Uses OpenAI embeddings by default (cheapest option).

### Discord Setup
Production Discord config with idle session management (7-day reset instead of daily).

---

## Workspace Templates

The `templates/` folder contains ready-to-use workspace files. Copy them to `~/clawd/` and customize.

Key features:
- **AGENTS.md** — Memory search protocol, self-review integration, file-over-memory philosophy
- **SOUL.md** — Anti-slop rules that actually work (no "delve", no sycophantic openers, no em dash addiction)
- **HEARTBEAT.md** — Structured proactive checks with memory engine integration
- **USER.md** — Template for teaching your agent about you

---

## Agent Personas

Pre-built personas for multi-agent workflows (Council of the Wise pattern, sub-agent spawning):

| Persona | Use Case |
|---------|----------|
| **Architect** | System design, tech stack decisions, scalability |
| **Content Writer** | Writing with authentic voice, not AI slop |
| **Deep Researcher** | Multi-source research with citations |
| **Devil's Advocate** | Challenge assumptions, find blind spots |
| **Market Researcher** | Competitive analysis, market sizing |
| **Project Planner** | Scoping, task breakdown, timeline estimation |
| **Security Auditor** | Threat modeling, config hardening, key rotation |
| **UX Designer** | Interface design, user flows, accessibility |

---

## Config Philosophy

1. **Docs defaults unless there's a reason** — don't change settings you don't understand
2. **Files over memory** — write it down; "mental notes" don't survive sessions
3. **Signal over vibes** — self-review from actual errors, not vague introspection
4. **Compaction-aware** — save important state to disk before the context window fills up
5. **Test before sharing** — everything here is running in production

---

## Example Output

After running the nightly `learn.sh` cycle, the engine generates `memory/insights.md`. Here's what a real one looks like:

```markdown
## Insights — 2026-01-30

- User prefers concise responses — avoid lengthy explanations unless asked
- Project "homelab" referenced 8 times this week — likely active focus area
- Correction pattern: agent keeps using deprecated API endpoint for notifications
- Decision logged: switched from OpenAI embeddings to local model for cost savings
- Person "Alex" mentioned in 3 separate contexts — may need a dedicated memory entry
- Recurring preference: no emoji in technical docs, emoji OK in casual chat
```

---

No tests yet — contributions welcome.

---

## Contributing

PRs welcome. If you've built a config, script, or template that improved your Moltbot setup, share it.

Rules:
- Must be tested in a real Moltbot workspace
- No personal data (API keys, usernames, emails)
- Include comments explaining *why*, not just *what*

## License

MIT
