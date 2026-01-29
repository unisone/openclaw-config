# Memory Engine

Four interconnected systems that turn flat-file memory into adaptive intelligence.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    MEMORY ENGINE                         │
├──────────┬──────────┬──────────────┬────────────────────┤
│ CAPTURE  │  RECALL  │    DECAY     │   SELF-LEARN       │
│ (live)   │ (start)  │  (daily)     │  (overnight)       │
├──────────┼──────────┼──────────────┼────────────────────┤
│ Extract  │ Semantic │ Score each   │ Consolidate daily  │
│ facts,   │ search   │ memory by    │ files → patterns   │
│ prefs,   │ against  │ relevance,   │ Update MEMORY.md   │
│ decisions│ session  │ frequency,   │ Generate insights  │
│ from     │ context  │ recency      │ Prune stale data   │
│ every    │ to load  │              │ Cross-ref across   │
│ message  │ relevant │ Archive low  │ sessions           │
│          │ context  │ scorers      │                    │
└──────────┴──────────┴──────────────┴────────────────────┘
                          │
                    memory/store.json
                    (scored memories)
```

## Files

- `capture.sh` — Extract structured memories from session logs
- `recall.sh` — Semantic pre-load at session start
- `decay.sh` — Daily relevance scoring + archival
- `learn.sh` — Overnight consolidation + insight generation
- `store.json` — Scored memory store (created at runtime)
- `config.json` — Tuning parameters

## Integration Points

- **Heartbeat** → runs decay check (lightweight)
- **Cron (daily 3AM)** → runs full learn cycle
- **Session start** → recall loads relevant context
- **Every message** → capture extracts asynchronously
