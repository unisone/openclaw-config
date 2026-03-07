# STEPPS Calibration Loop

*Auto-adjusts quality thresholds based on actual agent performance. Runs biweekly.*

## How It Works

### Score Tracking
Every content-producing agent appends a line to `memory/stepps-tracking.jsonl` after scoring a draft:
```json
{"ts":"2026-03-02T13:00:00Z","agent":"dan-twitter","type":"reply","score":43,"breakdown":"S8 T9 E8 P8 V10","passed":true}
```

Fields:
- `ts` — ISO timestamp
- `agent` — agent id (dan-twitter, dan-insta, dan-content)
- `type` — draft type (reply, original, thread, reel, carousel, linkedin)
- `score` — total STEPPS score (0-50)
- `breakdown` — category shorthand
- `passed` — did it pass the current gate?

### Calibration Rules (biweekly)

The calibration job reads the last 14 days of `stepps-tracking.jsonl` and computes:

1. **Per-agent average score** (mean of all `score` values)
2. **Per-agent pass rate** (% of `passed: true`)
3. **Per-agent category floor** (min score per STEPPS category across all drafts)
4. **Cross-agent comparison** (which agent is strongest/weakest)

### Threshold Adjustment Logic

| Condition | Action |
|-----------|--------|
| Agent avg ≥ 46/50 for 2 consecutive periods | Raise pass threshold to 42/50 for that agent |
| Agent avg ≥ 48/50 for 2 consecutive periods | Raise pass threshold to 44/50 for that agent |
| Agent avg < 41/50 | Flag for prompt review — quality is slipping |
| Agent pass rate < 80% | Flag for prompt review — too many rewrites |
| Any category avg < 7 across agent | Flag specific weakness (e.g., "dan-twitter weak on Emotion") |
| All agents avg ≥ 46/50 for 2 consecutive periods | Raise global default from 40 → 42 |

### Threshold Ceiling
Never auto-raise above 46/50 — that leaves room for legitimate creativity. Above 46 is manual-only.

### Output
- Update `memory/stepps-calibration.md` with latest period results
- Post scorecard to Slack #ops
- If threshold changes: update `docs/STEPPS-QUALITY-GATE.md` directly and note the change

## Current Thresholds

| Agent | Pass Threshold | Category Floor | Since |
|-------|---------------|----------------|-------|
| Global default | 40/50 | 6 | 2026-03-02 |
| dan-twitter | 40/50 | 6 | 2026-03-02 |
| dan-insta | 40/50 | 6 | 2026-03-02 |
| dan-content | 40/50 | 6 | 2026-03-02 |

*Thresholds auto-adjust via calibration. Manual overrides noted with reason.*
