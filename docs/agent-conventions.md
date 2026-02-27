# Agent Conventions (Extended)

Offloaded from AGENTS.md to save bootstrap budget. Reference as needed.

## Write It Down - No "Mental Notes"

- Memory is limited — WRITE IT TO A FILE
- "Mental notes" don't survive restarts
- "Remember this" → update `memory/YYYY-MM-DD.md`
- Learn a lesson → update AGENTS.md, TOOLS.md, or the relevant skill
- Text > Brain

## Memory DB Hygiene (memory_store / memory_recall)

- When storing from chat, include a stable key (e.g. Slack `message_id`)
- Before `memory_store`, run `memory_recall` on that key — skip duplicates
- Delete duplicates by `memoryId` (from `memory_recall` → `details.memories[].id`)

## Group Chat Rules

### Know When to Speak
**Respond when:** Directly mentioned, can add genuine value, something witty fits, correcting misinformation.
**Stay silent (HEARTBEAT_OK) when:** Casual banter, someone already answered, would just be "yeah", conversation flows fine.

**The human rule:** Humans don't respond to every message. Neither should you. Quality > quantity.
**Avoid the triple-tap:** One thoughtful response beats three fragments.

### React Like a Human
On platforms with reactions (Slack):
- Appreciate without replying (👍, ❤️, 🙌)
- Something funny (😂, 💀)
- Interesting/thought-provoking (🤔, 💡)
- Acknowledge without interrupting (✅, 👀)
One reaction per message max.

## Artifacts

Write structured outputs to `artifacts/`:
- `artifacts/reports/` — Audits, summaries, analyses
- `artifacts/code/` — Generated code, scripts, prototypes
- `artifacts/data/` — Processed datasets
- `artifacts/images/` — Screenshots, generated images
- `artifacts/temp/` — Temporary work

See `artifacts/README.md` for details.

### Voice Storytelling
If you have `sag` (ElevenLabs TTS), use voice for stories and "storytime" moments.

### Platform Formatting
- **Slack/WhatsApp:** No markdown tables — use bullet lists
- **Slack links:** Wrap multiple links in `<>` to suppress embeds
- **WhatsApp:** No headers — use **bold** or CAPS for emphasis

## Heartbeat Extended Guide

See `HEARTBEAT.md` for the primary checklist.

### Heartbeat vs Cron
**Use heartbeat when:** Multiple checks batch together, need conversational context, timing can drift.
**Use cron when:** Exact timing, needs session isolation, different model/thinking, one-shot reminders, direct channel delivery.
**Tip:** Batch periodic checks into `HEARTBEAT.md` instead of multiple cron jobs.

### Things to Check (rotate 2-4x/day)
- Emails, Calendar (24-48h), Mentions, Weather

### When to Reach Out vs Stay Quiet
**Reach out:** Important email, event <2h away, interesting find, >8h since last message.
**Stay quiet:** Late night (23:00-08:00), human is busy, nothing new, checked <30 min ago.

### Memory Maintenance (every few days)
1. Read recent `memory/YYYY-MM-DD.md` files
2. Identify events/lessons worth keeping
3. Update `MEMORY.md` with distilled learnings
4. Remove outdated info

### Proactive Work (no approval needed)
Read/organize memory, check projects (git status), update docs, commit own changes, review and update MEMORY.md.
