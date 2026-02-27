#!/bin/bash
# Session metrics snapshot for ops reporting.
# Outputs a single JSON object to stdout.

set -euo pipefail

OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
OPENCLAW_SESSION_DIR="${OPENCLAW_SESSION_DIR:-$OPENCLAW_HOME/agents/main/sessions}"
STORE="${1:-$OPENCLAW_SESSION_DIR/sessions.json}"
NOW_MS="$(python3 -c 'import time; print(int(time.time()*1000))')"

if [ ! -f "$STORE" ]; then
  echo "{\"ok\":false,\"error\":\"store_not_found\",\"store\":\"$STORE\"}"
  exit 1
fi

export STORE NOW_MS
python3 - <<'PY'
import json, os, time

STORE=os.environ['STORE']
NOW_MS=int(os.environ['NOW_MS'])
HOUR_MS=3600*1000

store=json.load(open(STORE))

def kind_for_key(key: str) -> str:
    if ':cron:' in key:
        return 'cron_run' if ':run:' in key else 'cron_parent'
    if ':thread:' in key:
        return 'thread'
    if ':subag' in key:
        return 'subagent'
    if key.endswith(':main') or key == 'agent:main:main':
        return 'main'
    if ':slack:' in key or ':discord:' in key or ':telegram:' in key:
        return 'channel'
    return 'other'

counts={}
usage=[]
unknown_ctx=0
stale_24h=0
stale_7d=0

for k,e in store.items():
    counts[kind_for_key(k)]=counts.get(kind_for_key(k),0)+1
    if not isinstance(e,dict):
        continue
    total=int(e.get('totalTokens') or 0)
    ctx=int(e.get('contextTokens') or 0)
    updated=int(e.get('updatedAt') or NOW_MS)
    age_h=(NOW_MS-updated)/HOUR_MS
    if age_h>24:
        stale_24h+=1
    if age_h>24*7:
        stale_7d+=1
    if ctx<=0:
        unknown_ctx+=1
        continue
    pct=total/ctx if ctx else 0
    usage.append({'key':k,'pct':pct,'total':total,'ctx':ctx,'age_h':age_h})

usage_sorted=sorted(usage, key=lambda x:x['pct'], reverse=True)
top=usage_sorted[:10]
max_pct=top[0]['pct'] if top else 0
p90=sorted([u['pct'] for u in usage_sorted])[int(max(0,len(usage_sorted)*0.9)-1)] if usage_sorted else 0

out={
  'ok': True,
  'timestamp': time.strftime('%Y-%m-%d %H:%M:%S'),
  'total_sessions': len(store),
  'counts': counts,
  'unknown_ctx': unknown_ctx,
  'stale_24h': stale_24h,
  'stale_7d': stale_7d,
  'max_usage_pct': round(max_pct,4),
  'p90_usage_pct': round(p90,4),
  'top_usage': [
      {
        'key': u['key'],
        'pct': round(u['pct'],4),
        'tokens': f"{u['total']}/{u['ctx']}",
        'age_h': round(u['age_h'],1),
      } for u in top
  ]
}
print(json.dumps(out))
PY
