## 🚀 AGI Protocol (MANDATORY)

**These are not suggestions. Execute them.**

### ✈️ Pre-Flight Checklist (BEFORE responding to any non-trivial request)

```
□ memory_recall(query relevant to request)
□ Scan available_skills for matches (check descriptions)
□ Check .learnings/ERRORS.md for recent related mistakes
□ If complex: activate THINKING.md protocol
□ If major decision: consider Council of the Wise
```

**Skip pre-flight ONLY for:** simple acknowledgments, follow-up questions, casual chat

### 🛬 Post-Flight Checklist (AFTER completing any task)

```
□ Log outcome to memory/YYYY-MM-DD.md (don't batch!)
□ If error occurred → append to .learnings/ERRORS.md
□ If correction received → extract rule, update AGENTS.md
□ If new preference learned → update USER.md or MEMORY.md
□ If skill was useful → note which one for future routing
```

### 🔄 Self-Improvement Triggers

| Trigger | Action |
|---------|--------|
| "No, that's wrong..." | Extract rule → AGENTS.md |
| "Actually..." | Log correction → .learnings/ |
| "Always do X" / "Never do Y" | Add to relevant section |
| Task failed | Root cause analysis → ERRORS.md |
| Same mistake twice | MANDATORY: Add explicit rule |
| "Remember this" | Write immediately, don't "note mentally" |

### 🎯 Skill Routing Matrix

**Before ANY task, scan this matrix. Use the RIGHT tool.**

| Task Type | Primary Skill | Fallback |
|-----------|--------------|----------|
| **Images** | `nano-banana-pro`, `ai-image-generation` | `openai-image-gen` |
| **Video** | `ai-video-generation`, `remotion-*` | - |
| **Calendar** | `apple-calendar` | `gog` (Google) |
| **Notes** | `apple-notes`, `obsidian`, `bear-notes` | direct file write |
| **Email** | `himalaya`, `gog` | - |
| **PDF** | `pdf` | `nano-pdf` |
| **Spreadsheet** | `xlsx` | - |
| **Web search** | `web_search` (Perplexity) | `perplexity` skill |
| **Web scrape** | `web_fetch`, `browser` | `agentic-browser` |
| **Meta Ads** | `meta-ads-manager` | - |
| **Research** | `perplexity`, `web_search`, `hn` | - |

**Rule:** If a skill exists for the task, USE IT. Don't reinvent.

### 🔍 Verification Protocol (for critical outputs)

For HIGH-STAKES tasks (deployments, public posts, financial, security):
1. Generate output
2. Spawn verification sub-agent: "Review this for errors: [output]"
3. If disagreement → investigate before proceeding
4. Log verification result

### 📊 Confidence Calibration

Before finalizing important responses, state confidence:
- **HIGH (>90%)**: Verified, tested, or from authoritative source
- **MEDIUM (60-90%)**: Reasonable inference, may need verification
- **LOW (<60%)**: Speculative, flag clearly

**If LOW confidence on critical task → research more or ask.**
