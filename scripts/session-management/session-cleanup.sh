#!/bin/bash
# Session cleanup — removes dead/stuck sessions from the store
# Removes: stuck (100% capacity), cron runs >12h, subagents >6h, threads >6h, anything >3 days
# Keeps: main channel sessions, active DMs, recent sessions

set -euo pipefail

OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
OPENCLAW_SESSION_DIR="${OPENCLAW_SESSION_DIR:-$OPENCLAW_HOME/agents/main/sessions}"
STORE="${1:-$OPENCLAW_SESSION_DIR/sessions.json}"
NOW_MS=$(python3 -c "import time; print(int(time.time()*1000))")

[ ! -f "$STORE" ] && echo "❌ Store not found: $STORE" && exit 1

python3 -c "
import json
STORE = '$STORE'
NOW_MS = $NOW_MS
HOUR_MS = 3600 * 1000

with open(STORE) as f:
    store = json.load(f)

before = len(store)
to_remove = []
for key, entry in store.items():
    total = entry.get('totalTokens', 0) or 0
    ctx = entry.get('contextTokens', 0) or 0
    updated = entry.get('updatedAt', NOW_MS)
    age_h = (NOW_MS - updated) / HOUR_MS
    if total > 0 and ctx > 0 and total >= ctx:
        to_remove.append(key)
    elif ':cron:' in key and age_h > 12:
        to_remove.append(key)
    elif ':subag' in key and age_h > 6:
        to_remove.append(key)
    elif ':thread:' in key and age_h > 6:
        to_remove.append(key)
    elif age_h > 72:
        to_remove.append(key)

for key in to_remove:
    del store[key]

with open(STORE, 'w') as f:
    json.dump(store, f, indent=2)

print(f'{before} → {len(store)} sessions ({len(to_remove)} removed)')
"
