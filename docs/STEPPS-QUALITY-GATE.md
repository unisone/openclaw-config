# STEPPS Quality Gate (50-point)

Use this before any public draft is sent to Slack.
If score < 40/50, rewrite. Do not ship.

## Scoring rubric (0-10 each)

### 1) Social Currency
Does this make the reader look smart for sharing it?
- 0-3: Generic, obvious, no edge
- 4-6: Some edge, still broad
- 7-8: Strong operator signal
- 9-10: Distinct insight people want to quote

### 2) Triggers
Is there a clear trigger that makes this memorable/repeatable?
- 0-3: Forgettable
- 4-6: Mild hook
- 7-8: Sticky phrase/mechanism
- 9-10: Instantly memorable framing

### 3) Emotion
Does it create a real emotional response (surprise, tension, relief, urgency)?
- 0-3: Flat
- 4-6: Light interest
- 7-8: Clear emotional pull
- 9-10: High emotional charge without clickbait

### 4) Public
Is the takeaway visible and easy to signal publicly?
- 0-3: Abstract/private
- 4-6: Some visible value
- 7-8: Easy to repeat/share
- 9-10: Highly portable social proof

### 5) Practical Value
Is there a concrete takeaway someone can use today?
- 0-3: Vague advice
- 4-6: Partly actionable
- 7-8: Clear next step/checklist/tool
- 9-10: Immediate, specific, high-utility action

## Pass rules
- **Default pass:** 40/50+
- **Hard fail:** any category below 6
- **If fail:** rewrite once, rescore, then post only if pass

## Output requirement in drafts
Include:
- `STEPPS_SCORE: X/50`
- Category breakdown in short form: `Sx Tx Ex Px Vx`

Example:
`STEPPS_SCORE: 43/50 (S8 T9 E8 P8 V10)`

## Score Tracking (mandatory)
After scoring any draft, append one JSON line to `memory/stepps-tracking.jsonl`:
```json
{"ts":"<ISO-8601>","agent":"<agent-id>","type":"<reply|original|thread|reel|carousel|linkedin>","score":<total>,"breakdown":"Sx Tx Ex Px Vx","passed":<true|false>}
```
This feeds the biweekly calibration loop (see `docs/STEPPS-CALIBRATION.md`).

## Calibration
Thresholds auto-adjust based on 2-week rolling performance. See `docs/STEPPS-CALIBRATION.md` for rules. Current defaults are the floor — agents performing consistently above 46/50 get tightened thresholds.
