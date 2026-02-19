# Context Overflow Prevention

## The Problem

Context pruning clears tool outputs after 15 minutes. Memory flush triggers at ~86% capacity (~172K tokens on a 200K window). Heavy operations can blow through context before you realize it.

## The Rule

**Any task involving 3+ browser actions, web fetches, or large exec outputs MUST be spawned as a sub-agent.**

The main session is for orchestration, not execution.

## When to Spawn Sub-Agents

| Trigger | Action |
|---------|--------|
| Browser automation (job applications, form filling, multi-page scraping) | ALWAYS sub-agent |
| Bulk web research (fetching 3+ URLs) | Sub-agent with `maxChars` limits |
| Large exec output (logs, file listings, API responses) | Pipe through `head`/`tail`, use `--limit` |
| `web_fetch` calls | ALWAYS use `maxChars: 4000` unless you need more |
| Gateway config reads | Don't dump full config into context. Use `jq` to extract specific fields |

## The Math

- Sub-agent: Fresh 200K window
- Main session: Shared, accumulating, precious

**When in doubt, spawn.** A sub-agent gets a clean slate. The main chat keeps breathing.

## Real-Time Logging

Context can evaporate without warning. Write important context immediately.

| Event | Action |
|-------|--------|
| Key decision made | → Write to `memory/YYYY-MM-DD.md` NOW |
| Important user preference learned | → Write NOW |
| Complex multi-step task started | → Log the plan NOW |
| Task completed | → Log outcome NOW |
| Error or correction | → Log lesson NOW |

**Anti-pattern:** "I'll remember to write this later" → YOU WON'T. Context evaporates.

**Pattern:** Make the file write part of completing the action, not a separate step.

## Config for Compaction Safety

```json5
{
  agents: {
    defaults: {
      compaction: {
        mode: "safeguard",
        reserveTokensFloor: 20000,
        maxHistoryShare: 0.65,
        memoryFlush: {
          enabled: true,
          softThresholdTokens: 8000,
          prompt: "MEMORY FLUSH: Session approaching compaction..."
        }
      },
      contextPruning: {
        mode: "cache-ttl",
        ttl: "15m",
        keepLastAssistants: 5,
        minPrunableToolChars: 30000
      }
    }
  }
}
```

## Monitoring

Watch for:
- Sessions taking 60+ seconds per response (context bloat)
- Memory flush prompts firing (you're at 86% capacity)
- Tool results being pruned (check logs for "pruned" messages)
