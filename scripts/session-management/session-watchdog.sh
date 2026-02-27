#!/bin/bash
# Session Lifecycle Manager — Fully Autonomous
# Detects bloated/stuck/stale sessions and fixes them WITHOUT human intervention.
# 
# Strategy:
#   1. PURGE maxed sessions (≥95% usage) → remove from store, backup transcript
#   2. PURGE stale cron run sessions (>4h old) → same
#   3. PURGE stale thread sessions (>3h idle) → same
#   4. PURGE any session >24h old with >80% usage → same
#   5. LOG remaining high-usage sessions (>70%) as warnings
#
# OpenClaw creates fresh sessions when purged keys next receive messages.
# Memory flush (configured in compaction.memoryFlush) saves context pre-compaction.
# Daily reset at 4AM catches anything this misses.
#
# Usage: bash session-watchdog.sh [sessions.json path]
# Output: JSON report to stdout

set -euo pipefail

OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
OPENCLAW_WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
OPENCLAW_SESSION_DIR="${OPENCLAW_SESSION_DIR:-$OPENCLAW_HOME/agents/main/sessions}"

STORE="${1:-$OPENCLAW_SESSION_DIR/sessions.json}"
SESSIONS_DIR="$(dirname "$STORE")"
BACKUP_DIR="$SESSIONS_DIR/purged"
NOW_MS=$(python3 -c "import time; print(int(time.time()*1000))")
LOG_FILE="$OPENCLAW_WORKSPACE/memory/watchdog-log.md"

[ ! -f "$STORE" ] && echo '{"error":"Store not found"}' && exit 1

mkdir -p "$BACKUP_DIR"

# The Python block reads these via os.environ; export so args/vars are honored.
export STORE NOW_MS LOG_FILE OPENCLAW_WORKSPACE

python3 << 'PYTHON_SCRIPT'
import json, os, sys, time
from pathlib import Path

STORE = os.environ.get("STORE", os.path.expanduser("~/.openclaw/agents/main/sessions/sessions.json"))
SESSIONS_DIR = os.path.dirname(STORE)
BACKUP_DIR = os.path.join(SESSIONS_DIR, "purged")
NOW_MS = int(os.environ.get("NOW_MS", int(time.time() * 1000)))
OPENCLAW_WORKSPACE = os.environ.get("OPENCLAW_WORKSPACE", os.path.expanduser("~/.openclaw/workspace"))
LOG_FILE = os.environ.get("LOG_FILE", os.path.join(OPENCLAW_WORKSPACE, "memory/watchdog-log.md"))

HOUR_MS = 3600 * 1000
MIN_MS = 60 * 1000

# Thresholds
# Keep "purge" aggressive only for truly-maxed/stale sessions. Prefer compaction for valuable
# main/group sessions that are just getting large.
MAXED_THRESHOLD = 0.97        # ≥97% = maxed, purge immediately
HIGH_THRESHOLD = 0.90         # ≥90% = high risk (purge only when stale, or when cron parent)
WARN_THRESHOLD = 0.80         # ≥80% = warning

# Age thresholds for different session types
CRON_RUN_MAX_AGE_H = 4              # Cron run sessions: purge after 4h
THREAD_IDLE_MAX_H = 6               # Thread sessions: purge after 6h idle
ZERO_TOKEN_THREAD_MAX_AGE_H = 12    # Thread sessions with 0 token data: purge after 12h (session-sprawl GC)
STALE_SESSION_MAX_H = 24 * 7        # Any session: purge if >7d old
HIGH_USAGE_MAX_AGE_H = 24           # Sessions >90%: purge if >24h old (except cron parents)

with open(STORE) as f:
    store = json.load(f)

before_count = len(store)
purged = []
warnings = []
healthy = 0

to_remove = []

for key, entry in store.items():
    total = entry.get("totalTokens", 0) or 0
    ctx = entry.get("contextTokens", 0) or 0
    updated = entry.get("updatedAt", NOW_MS)
    session_id = entry.get("sessionId", "unknown")
    age_h = (NOW_MS - updated) / HOUR_MS
    
    is_cron_run = ":cron:" in key and ":run:" in key
    is_cron_parent = ":cron:" in key and ":run:" not in key
    is_thread = ":thread:" in key
    is_subagent = ":subag" in key
    is_main = key.endswith(":main") or key == "agent:main:main"
    # Channel/group sessions are persistent — treat them like main sessions
    # Keys look like: agent:main:slack:channel:YOUR_CHANNEL_ID or agent:main:slack:group:...
    is_channel = ":channel:" in key or ":group:" in key or ":direct:" in key

    usage_pct = (total / ctx) if ctx > 0 else 0
    usage_str = f"{total}/{ctx} ({usage_pct:.0%})"

    # GC zero-token sessions (common with Slack threads / placeholders)
    if ctx == 0:
        reason = None

        # Purge age-based ephemeral sessions even if they never accumulated tokens
        if is_cron_run and age_h > CRON_RUN_MAX_AGE_H:
            reason = f"stale cron run ({age_h:.1f}h old, no tokens)"
        elif is_subagent and age_h > CRON_RUN_MAX_AGE_H:
            reason = f"stale subagent ({age_h:.1f}h old, no tokens)"
        elif is_thread and age_h > ZERO_TOKEN_THREAD_MAX_AGE_H:
            reason = f"stale thread ({age_h:.1f}h idle, no tokens)"
        elif age_h > STALE_SESSION_MAX_H:
            reason = f"stale ({age_h:.1f}h old, no tokens)"

        if reason:
            to_remove.append({"key": key, "reason": reason, "session_id": session_id, "usage": usage_str})
        else:
            healthy += 1
        continue

    reason = None
    
    # Rule 1: Maxed sessions (≥97%) — purge (except channel/DM sessions, which should compact)
    if usage_pct >= MAXED_THRESHOLD and not is_channel:
        reason = f"MAXED ({usage_str})"
    
    # Rule 1b: Maxed channel sessions — warn only (compaction handles these)
    elif usage_pct >= MAXED_THRESHOLD and is_channel:
        warnings.append({"key": key, "usage": usage_str, "age_h": round(age_h, 1), "note": "maxed channel session — needs compaction"})
        healthy += 1
        continue
    
    # Rule 2: Cron run sessions older than 4h — always purge
    elif is_cron_run and age_h > CRON_RUN_MAX_AGE_H:
        reason = f"stale cron run ({age_h:.1f}h old, {usage_str})"
    
    # Rule 3: Subagent sessions older than 4h — always purge
    elif is_subagent and age_h > CRON_RUN_MAX_AGE_H:
        reason = f"stale subagent ({age_h:.1f}h old)"
    
    # Rule 4: Thread sessions idle >3h — always purge
    elif is_thread and age_h > THREAD_IDLE_MAX_H:
        reason = f"stale thread ({age_h:.1f}h idle, {usage_str})"
    
    # Rule 5: High usage (>=90%) AND old (>=24h) — purge
    # Exception: do not purge main/group/channel/DM sessions — those should be compacted, not killed.
    elif usage_pct >= HIGH_THRESHOLD and age_h > HIGH_USAGE_MAX_AGE_H and not is_main and not is_thread and not is_channel:
        reason = f"high usage + stale ({usage_str}, {age_h:.1f}h old)"
    
    # Rule 6: Cron parent sessions >=90% — purge (they'll get fresh ones)
    elif is_cron_parent and usage_pct >= HIGH_THRESHOLD:
        reason = f"bloated cron parent ({usage_str})"
    
    # Rule 7: Any non-main, non-channel session >7d old — purge regardless
    # Channel/group/DM sessions are managed by daily reset, not the watchdog.
    elif age_h > STALE_SESSION_MAX_H and not is_main and not is_channel:
        reason = f"stale ({age_h:.1f}h old, {usage_str})"
    
    # Warning: approaching limit
    elif usage_pct >= WARN_THRESHOLD:
        warnings.append({"key": key, "usage": usage_str, "age_h": round(age_h, 1)})
        healthy += 1
        continue
    else:
        healthy += 1
        continue
    
    # Mark for removal
    to_remove.append({"key": key, "reason": reason, "session_id": session_id, "usage": usage_str})

# Execute purges
for item in to_remove:
    key = item["key"]
    session_id = item["session_id"]
    
    # Backup transcript file before removing
    transcript = os.path.join(SESSIONS_DIR, f"{session_id}.jsonl")
    if os.path.exists(transcript):
        backup = os.path.join(BACKUP_DIR, f"{session_id}.jsonl.{int(time.time())}.bak")
        try:
            os.rename(transcript, backup)
        except Exception:
            pass  # Non-critical — transcript stays but session entry removed
    
    # Remove from store
    if key in store:
        del store[key]
    
    purged.append(item)

# Write updated store
with open(STORE, "w") as f:
    json.dump(store, f, indent=2)

# Build report
report = {
    "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
    "before": before_count,
    "after": len(store),
    "purged_count": len(purged),
    "warning_count": len(warnings),
    "healthy_count": healthy,
    "purged": [{"key": p["key"], "reason": p["reason"]} for p in purged],
    "warnings": warnings
}

# Append to log file
try:
    os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
    with open(LOG_FILE, "a") as f:
        f.write(f"\n### Watchdog Run — {report['timestamp']}\n")
        if purged:
            f.write(f"**Purged {len(purged)} sessions:**\n")
            for p in purged:
                f.write(f"- `{p['key'].split(':')[-1][:20]}...` — {p['reason']}\n")
        if warnings:
            f.write(f"**{len(warnings)} warnings** (approaching limit)\n")
        if not purged and not warnings:
            f.write("All clear ✅\n")
except Exception:
    pass

# Clean up old backups (>7 days)
try:
    for f in os.listdir(BACKUP_DIR):
        fp = os.path.join(BACKUP_DIR, f)
        if os.path.isfile(fp) and (time.time() - os.path.getmtime(fp)) > 7 * 86400:
            os.remove(fp)
except Exception:
    pass

# Write alert to pending.json if purges happened
ALERTS_FILE = os.path.join(OPENCLAW_WORKSPACE, "scripts/taskrunner/alerts/pending.json")
try:
    existing = []
    if os.path.exists(ALERTS_FILE):
        with open(ALERTS_FILE) as af:
            existing = json.load(af)
    if purged:
        reasons = {}
        for p in purged:
            r = p["reason"].split("(")[0].strip()
            reasons[r] = reasons.get(r, 0) + 1
        reason_str = ", ".join(f"{v} {k.lower()}" for k, v in reasons.items())
        existing.append({
            "ts": int(time.time()),
            "source": "session-watchdog",
            "message": f"🧹 Watchdog: purged {len(purged)} session(s) ({reason_str}). {len(store)} remaining, {len(warnings)} warning(s)."
        })
        with open(ALERTS_FILE, "w") as af:
            json.dump(existing, af, indent=2)
except Exception:
    pass

print(json.dumps(report, indent=2))
PYTHON_SCRIPT
