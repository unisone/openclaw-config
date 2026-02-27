#!/bin/bash
# Weekly session ops report
# - Collect metrics + watchdog output
# - Append a stable markdown entry to memory/session-ops-weekly.md
# - Print a one-line JSON summary to stdout for callers

set -euo pipefail

OPENCLAW_WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEM_DIR="$OPENCLAW_WORKSPACE/memory"
OUT_MD="$MEM_DIR/session-ops-weekly.md"

mkdir -p "$MEM_DIR"

METRICS_JSON="$(bash "$SCRIPT_DIR/session-metrics.sh")"
WATCHDOG_JSON="$(bash "$SCRIPT_DIR/session-watchdog.sh")"

export OUT_MD
export METRICS_JSON
export WATCHDOG_JSON

# Build report fields in python (avoid jq dependency).
python3 - <<'PY'
import json, os, time

metrics=json.loads(os.environ['METRICS_JSON'])
watchdog=json.loads(os.environ['WATCHDOG_JSON'])

now_local=time.strftime('%Y-%m-%d %H:%M:%S')

# Prepare markdown block
counts=metrics.get('counts',{})
top=metrics.get('top_usage',[])[:3]

lines=[]
lines.append(f"\n## {now_local} (local)\n")
lines.append(f"- total_sessions: {metrics.get('total_sessions')}\n")
lines.append(f"- counts: {json.dumps(counts, sort_keys=True)}\n")
lines.append(f"- max_usage_pct: {metrics.get('max_usage_pct')}\n")
lines.append(f"- p90_usage_pct: {metrics.get('p90_usage_pct')}\n")
lines.append(f"- purged_count: {watchdog.get('purged_count')}\n")
lines.append(f"- warning_count: {watchdog.get('warning_count')}\n")
lines.append("- top_3_high_usage_sessions:\n")
if not top:
    lines.append("  (none)\n")
else:
    for i,u in enumerate(top,1):
        lines.append(f"  {i}) {u.get('key')} — {u.get('pct')} ({u.get('tokens')})\n")

out_md=os.environ['OUT_MD']
# Ensure header exists
if not os.path.exists(out_md):
    with open(out_md,'w') as f:
        f.write('# Session Ops — Weekly Report Log\n')
with open(out_md,'a') as f:
    f.writelines(lines)

summary={
  'ok': True,
  'total': metrics.get('total_sessions'),
  'max': metrics.get('max_usage_pct'),
  'p90': metrics.get('p90_usage_pct'),
  'purged': watchdog.get('purged_count'),
  'warnings': watchdog.get('warning_count'),
}
print(json.dumps(summary))
PY
