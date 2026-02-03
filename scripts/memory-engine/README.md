# Memory Engine

4-stage adaptive memory for OpenClaw agents.

## Stats (Production)
- **252 memories** across 7 categories
- **Category weights:** corrections 2.0x, decisions 1.8x, people 1.6x, preferences 1.5x, facts 1.0x, todos 0.8x
- **Decay:** 14-day half-life, nightly at 3AM
- **MEMORY.md:** 67 lines (curated essentials only)

## Scripts

| Script | Purpose | When |
|--------|---------|------|
| `capture.sh` | Extract memories from daily files | Every heartbeat |
| `recall.sh` | Keyword-weighted retrieval | On demand |
| `decay.sh` | Time-based relevance decay | Nightly 3AM |
| `learn.sh` | Pattern detection + promotion | Nightly after decay |
| `self-review.sh` | Error/correction extraction | Nightly |

## Quick Start

```bash
# 1. Create structure
mkdir -p ~/clawd/memory/archive
touch ~/clawd/MEMORY.md

# 2. Copy scripts
cp -r scripts/memory-engine ~/clawd/scripts/

# 3. Initialize store
./capture.sh

# 4. Set up cron (or use OpenClaw cron)
# 0 3 * * * cd ~/clawd && ./scripts/memory-engine/decay.sh && ./scripts/memory-engine/learn.sh
```

## Config

See `config.json` for category weights and decay settings.

## How It Works

1. **Capture** — Scans daily logs, extracts structured memories with categories
2. **Recall** — Searches with keyword + category weighting (corrections surface first)
3. **Decay** — Memories lose relevance over time (14-day half-life)
4. **Learn** — Promotes repeated corrections to permanent rules

This solves "context rot" — old info naturally fades, important info (recalled frequently) stays fresh.
