#!/bin/bash
# Session store hygiene
# - Remove entries pointing to missing session transcript files
# - Compact JSON formatting (to reduce diff/noise)
# - Keep a timestamped backup before any write

set -euo pipefail

OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
OPENCLAW_SESSION_DIR="${OPENCLAW_SESSION_DIR:-$OPENCLAW_HOME/agents/main/sessions}"
STORE="${1:-$OPENCLAW_SESSION_DIR/sessions.json}"
SESSIONS_DIR="$(dirname "$STORE")"
TS="$(date +%Y%m%d%H%M%S)"
BACKUP="$STORE.bak.$TS"

if [ ! -f "$STORE" ]; then
  echo "{\"error\":\"store_not_found\",\"store\":\"$STORE\"}"
  exit 1
fi

cp -p "$STORE" "$BACKUP"

export STORE

python3 - <<'PY'
import json, os, time
from pathlib import Path

store_path = Path(os.environ.get('STORE', os.path.expanduser('~/.openclaw/agents/main/sessions/sessions.json')))
sessions_dir = store_path.parent

data = json.loads(store_path.read_text())

removed = []
kept = {}
for key, entry in data.items():
    if not isinstance(entry, dict):
        kept[key] = entry
        continue
    sf = entry.get('sessionFile')
    if sf:
        p = Path(sf).expanduser()
        if not p.exists():
            removed.append({'key': key, 'sessionFile': sf})
            continue
    kept[key] = entry

store_path.write_text(json.dumps(kept, sort_keys=True, separators=(',', ':')) + "\n")

out = {
  'ok': True,
  'before': len(data),
  'after': len(kept),
  'removed_count': len(removed),
  'removed': removed[:50],
}
print(json.dumps(out))
PY
