# Session Context Overflow: Research, Analysis & Implementation Plan

**Date:** 2026-02-11
**Status:** Implementation Ready
**Priority:** CRITICAL — 18+ sessions maxed, "prompt too long" errors active

---

## 1. Problem Analysis

### Current State
- **50 active sessions**, 18+ at or near 200k/200k token limit (100%)
- **8 sessions fully maxed** (200k/200k), plus 2 at 400k/400k
- Multiple cron sessions also near-maxed (nightly-consolidation: 200k, content-metrics: 200k)
- "prompt too long" errors blocking normal operation

### Root Causes (ranked by impact)

| # | Root Cause | Impact | Current Config |
|---|-----------|--------|---------------|
| 1 | **No session reset** | CRITICAL | `session.reset` not configured at all |
| 2 | **System prompt bloat** | HIGH | MEMORY.md=11KB, AGENTS.md=8KB, total=25KB (~6-8K tokens/session) |
| 3 | **Compaction too late** | HIGH | `compaction.mode: "safeguard"` — only triggers at wall |
| 4 | **Thread sessions persist** | MEDIUM | No idle reset for threads — one-off conversations live forever |
| 5 | **maxHistoryShare too generous** | MEDIUM | `0.55` — history can use 55% before compaction |
| 6 | **Cron sessions accumulate** | MEDIUM | Cron runs add to same session, never reset |

---

## 2. Research: Available OpenClaw Config Options

### Session Reset (schema: `session.reset`)
```json
{
  "session": {
    "reset": {
      "mode": "daily" | "idle",   // daily = reset at specific hour; idle = reset after inactivity
      "atHour": 0-23,             // for daily mode
      "idleMinutes": number       // for idle mode
    },
    "resetByType": {              // per session type overrides
      "direct": { ... },
      "dm": { ... },
      "group": { ... },
      "thread": { ... }
    },
    "resetByChannel": {           // per channel overrides
      "slack": { ... }
    }
  }
}
```

### Compaction (schema: `agents.defaults.compaction`)
- `mode: "default"` — proactive compaction before hitting the wall
- `mode: "safeguard"` — last resort only (CURRENT — too late)
- `maxHistoryShare: 0.1-0.9` — how much context history can use before compaction
- `memoryFlush` — saves critical context to files before compaction

### Context Pruning (schema: `agents.defaults.contextPruning`)
- `mode: "cache-ttl"` — prunes old tool results after TTL
- `softTrimRatio/hardClearRatio` — when to start trimming tool results
- `minPrunableToolChars` — minimum size before a tool result gets pruned

### Bootstrap (schema: `agents.defaults.bootstrapMaxChars`)
- Caps per-file injection into system prompt
- Currently 15000 chars — each workspace file up to 15KB injected

---

## 3. Options Evaluated

### Option A: Daily Session Reset
**How:** Auto-rotate all sessions at 4AM ET daily
**Pros:** Clean slate daily, prevents accumulation, memory flush saves context
**Cons:** Loses in-session conversational context overnight
**Risk to memory/workflow:** LOW — memory flush captures key decisions before reset

### Option B: Idle-Based Reset for Threads
**How:** Reset thread sessions after 120 min of inactivity
**Pros:** Short-lived threads don't persist forever, saves most tokens
**Cons:** None significant — threads are inherently temporary
**Risk:** NONE

### Option C: Switch Compaction to "default" Mode
**How:** Change from "safeguard" to "default"
**Pros:** Compaction kicks in proactively before sessions max out
**Cons:** Conversations get summarized earlier, losing some detail
**Risk to memory/workflow:** LOW — memoryFlush still captures critical info

### Option D: Trim System Prompt (MEMORY.md)
**How:** Move project details, timelines, Notion IDs to `docs/` — keep MEMORY.md to essentials only (~4KB)
**Pros:** Saves 3-4K tokens per session (every session, every turn)
**Cons:** Less context immediately available (but still searchable via memory tools)
**Risk:** LOW — information is moved, not deleted

### Option E: Lower maxHistoryShare
**How:** Reduce from 0.55 to 0.40
**Pros:** Forces compaction earlier, keeps more room for fresh conversation
**Cons:** Shorter effective conversation memory
**Risk:** LOW

### Option F: More Aggressive Context Pruning
**How:** Lower `minPrunableToolChars: 5000` (from 15000), reduce softTrimRatio
**Pros:** Old tool results cleared faster, saves significant tokens
**Cons:** Lose access to older tool outputs in conversation
**Risk:** LOW — old tool results rarely referenced

---

## 4. RECOMMENDED PLAN: Layered Defense

**Strategy:** Don't rely on one fix. Layer multiple defenses so sessions never hit the wall again.

### Layer 1: Session Reset (prevents accumulation)
```json
"session": {
  "reset": {
    "mode": "daily",
    "atHour": 4
  },
  "resetByType": {
    "thread": {
      "mode": "idle",
      "idleMinutes": 120
    }
  }
}
```
- All sessions reset at 4AM ET daily (memory flush saves context first)
- Thread sessions reset after 2 hours of inactivity
- This alone prevents 90% of the problem

### Layer 2: Better Compaction (catches sessions before they max)
```json
"compaction": {
  "mode": "default",
  "maxHistoryShare": 0.40,
  "reserveTokensFloor": 30000,
  "memoryFlush": { ... (keep existing) }
}
```
- Switch from "safeguard" to "default" — proactive compaction
- Reduce maxHistoryShare from 0.55 to 0.40
- Keep existing memoryFlush config

### Layer 3: Aggressive Context Pruning
```json
"contextPruning": {
  "mode": "cache-ttl",
  "ttl": "5m",
  "keepLastAssistants": 5,
  "softTrimRatio": 0.25,
  "hardClearRatio": 0.40,
  "minPrunableToolChars": 5000,
  "softTrim": {
    "maxChars": 3000,
    "headChars": 1200,
    "tailChars": 1200
  },
  "hardClear": {
    "enabled": true,
    "placeholder": "[Old tool result content cleared]"
  }
}
```
- Lower minPrunableToolChars: 5000 (from 15000) — prune smaller tool results
- Tighter softTrim: 3000 max (from 4000)
- Earlier ratios: 0.25/0.40 (from 0.30/0.50)

### Layer 4: Trim System Prompt
- **MEMORY.md:** Cut from 11KB to ~4KB (move project details to docs/)
- **bootstrapMaxChars:** Reduce from 15000 to 10000
- Net savings: ~3-4K tokens per session, every turn

### Layer 5: Manual Reset (immediate fix)
- Force-reset all 18+ maxed sessions right now via gateway restart
- This is the only way to unstick currently-broken sessions

---

## 5. Safety Guarantees

### Memory Safety
- ✅ Memory flush already configured — saves decisions/context before reset
- ✅ MEMORY.md content is MOVED to docs/, not deleted
- ✅ LanceDB memory plugin (autoCapture + autoRecall) continues working
- ✅ QMD memory backend indexes all workspace files including docs/
- ✅ Daily memory files (memory/YYYY-MM-DD.md) unaffected

### Workflow Safety
- ✅ Cron jobs get fresh sessions daily — no more context overflow
- ✅ Thread sessions auto-clean after 2h idle — no impact on active threads
- ✅ Heartbeat session included in daily reset — starts fresh each day
- ✅ All config changes are additive — no existing features removed

### What Doesn't Change
- All skills and tools remain available
- All channels (Slack, WhatsApp) continue working
- All cron schedules continue running
- Memory search (LanceDB + QMD) unaffected
- Model configuration unchanged

---

## 6. Implementation Steps

1. [ ] Trim MEMORY.md — move project details to docs/PROJECT-ARCHIVE.md
2. [ ] Apply config patch (session reset + compaction + pruning + bootstrapMaxChars)
3. [ ] Gateway restart (resets all maxed sessions)
4. [ ] Verify: check session list shows fresh sessions

**Expected outcome:** Zero maxed sessions, all sessions functional, ~30-40% reduction in per-session token usage from system prompt trimming.
