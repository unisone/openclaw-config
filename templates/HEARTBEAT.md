# HEARTBEAT.md

## Proactive Checks (rotate through, 2-4x daily)

### Priority Checks
- [ ] Check recent memory files for context continuity
- [ ] Any pending sub-agent tasks to follow up on?

### Periodic (every few hours)
- [ ] Calendar — check for upcoming events in next 24h
- [ ] Review ~/Projects for any uncommitted work
- [ ] Check if any PRs need attention

### Daily (once, morning preferred)
- [ ] Update MEMORY.md with significant learnings
- [ ] Review memory/YYYY-MM-DD.md for patterns

### Memory Engine (every heartbeat)
- [ ] Run `bash scripts/memory-engine/capture.sh` on today's daily file
- [ ] If store.json has >200 memories, run `bash scripts/memory-engine/decay.sh`
- [ ] On session start, run `bash scripts/memory-engine/recall.sh "current context"`

### Self-Review (session start + nightly)
- [ ] On boot: read `memory/self-review.md` — check recent MISS/FIX entries for patterns to avoid
- [ ] Nightly (via learn.sh): auto-extracts errors, corrections, and resets from today's daily log
- [ ] If a current task overlaps a recent MISS tag, double-check before responding

## When to Reach Out
- Important project updates or email needing attention
- Upcoming calendar event (<2h away)
- Something interesting discovered
- It's been >8h since last interaction (and not night)

## Quiet Hours
- 23:00-08:00 unless urgent
- If human seems busy, stay quiet
