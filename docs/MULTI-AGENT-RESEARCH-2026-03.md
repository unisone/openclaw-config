# Multi-Agent OpenClaw Research — March 2026

## Sources Analyzed
1. **Shubham Saboo (TheUnwindAI)** — 6 agents, Mac Mini M4, content/research pipeline
2. **PHY's Council (Reddit)** — 3 agents, Telegram group, quality gate system
3. **Riley Brown** — 200hr testing, narrow agent thesis
4. **RemoteOpenClaw** — deployment service, 40% of clients use multi-agent
5. **EastonDev** — 3-layer isolation architecture (work/personal/sandbox)
6. **Jung-Hua Liu** — academic multimodal multi-agent architecture proposal
7. **IDIOGEN/Jarvis guide** — commercial setup service, 4+ client deployments
8. **DEV.to** — deterministic multi-agent dev pipeline

---

## Best-In-Class Setup: Shubham Saboo (6 agents)

**The Gold Standard** — most detailed, production-tested:
- Monica (Chief of Staff/main), Dwight (Research), Kelly (X/Twitter), Rachel (LinkedIn), Ross (Engineering), Pam (Newsletter)
- TV character personalities — "30 seasons of character development for free" from LLM training data
- Sequential cron: Dwight (research) runs FIRST at 6am, then Kelly/Rachel/Pam consume his `intel/DAILY-INTEL.md`
- File-based coordination — "The coordination IS the filesystem. Files don't crash, don't have auth issues, don't need rate limiting."
- Structured data in JSON (source of truth), human-readable markdown (for agents)
- Memory: daily logs + curated MEMORY.md, agents distill during heartbeats
- Quality: agents learn preferences over time via memory files

**Key Insight:** "I tried one agent for everything. It produced mediocre everything. Context filled up. Quality degraded. One agent couldn't hold six jobs in its head."

---

## Key Patterns Across All Sources

### 1. Sequential Cron Dependencies
Research agent ALWAYS runs first. Content agents consume its output.
Saboo: Dwight → Kelly + Rachel + Pam (staggered by 15-30min)
**Our gap:** dan-content morning-intel (6:45am) → dan-twitter x-content-scheduler (7am) = only 15min gap. Should be 30min+.

### 2. Quality Gate System (STEPPS)
PHY's Council uses a 50-point rubric:
- Social Currency (0-10), Triggers (0-10), Emotion (0-10), Public (0-10), Practical Value (0-10), Stories (0-10)
- Threshold: ≥40 to post, 35-39 get enrichment questions, <35 suggest different angle
- Result: 100% success rate, 0 spam flags
**Our gap:** We have anti-slop word lists but no quantified scoring.

### 3. Agent Personalities From Fiction
Saboo names agents after TV characters (Friends, The Office). The model already "knows" these characters.
- Dwight Schrute = thorough, intense, dead serious → perfect for research
- Monica Geller = organized, exacting, standards → perfect for orchestration
**Our setup:** All agents are "Dan" — functional but less personality differentiation.

### 4. Three Is The Sweet Spot (for small teams)
RemoteOpenClaw: "3 agents is the sweet spot for teams under 10. Only add a 4th if clearly distinct use case."
But we're a single-human operation with 8 agents, which is more like Saboo's 6-agent setup.
The difference: Saboo has 6 distinct *content roles*. We have 8 but some overlap.

### 5. Model Cost Optimization
RemoteOpenClaw: "Opus for complex research/writing, Sonnet for routine status updates"
Saboo: All agents on same model (Claude)
**Our approach:** Opus for main + writer, Sonnet for everything else. Could push ops/coder jobs to cheaper models (GPT-5.2 already used for some).

### 6. File-Based Coordination > Message Queues
Universal consensus: filesystem coordination beats APIs/message queues for agent-to-agent data sharing.
"No middleware. No integration layer. Dwight writes a file. Kelly reads a file."
**We're already doing this.** The v2 output directories formalize it.

### 7. Weekly Agent Review
RemoteOpenClaw: "Every week, spend 5 minutes reviewing each agent's memory file and scheduled task output."
**Our gap:** We have content-feedback-loop (weekly) but no systematic per-agent review.

---

## Comparison: Our Setup vs Best Practices

| Pattern | Best Practice | Our v2 | Status |
|---------|--------------|--------|--------|
| Narrow agents | ✅ (Riley, Saboo) | ✅ 8 agents, focused roles | ✅ Good |
| Sequential cron | ✅ (Saboo) | ⚠️ 15min gap | ⚠️ Needs tuning |
| Quality gates | ✅ (PHY, 50pt rubric) | ❌ Word-level only | ❌ Gap |
| Agent personalities | ✅ (Saboo, TV chars) | ⚠️ All "Dan" | ⚠️ Could improve |
| File coordination | ✅ (all sources) | ✅ Output directories | ✅ Good |
| Tool isolation | ✅ (RemoteOC) | ✅ Deny lists per agent | ✅ Exceeds most |
| Ops monitoring agent | ❌ (most don't have) | ✅ dan-ops | ✅ Ahead |
| Memory architecture | ✅ (Saboo) | ✅ Daily logs + MEMORY.md | ✅ Good |
| Model per role | ✅ (RemoteOC) | ✅ Opus/Sonnet split | ✅ Good |
| Weekly review | ✅ (RemoteOC) | ⚠️ Content only | ⚠️ Expand |
| Draft-only enforcement | ❌ (most honor-system) | ✅ Tool-level deny | ✅ Best-in-class |

---

## Action Items (priority order)

1. **Add quality gate scoring** — Implement STEPPS or similar rubric for all content drafts
2. **Increase cron gap** — Move morning-intel to 6:30am OR twitter/insta schedulers to 7:30am+
3. **Weekly agent review cron** — New dan-ops job: review all agent outputs, memory quality, error rates
4. **Consider agent personality names** — Optional but compelling (Saboo's best practice)
5. **Formalize cron dependency chain** in docs — Research → Content → Platform agents
