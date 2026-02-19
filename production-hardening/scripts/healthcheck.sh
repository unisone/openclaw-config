#!/bin/bash
# Community-validated health monitoring

ALERT_EMAIL="your-email@example.com"
GATEWAY_PORT=18789

# Check gateway
if ! curl -sf http://127.0.0.1:$GATEWAY_PORT/_health > /dev/null 2>&1; then
  echo "❌ Gateway down at $(date)" | mail -s "OpenClaw Gateway DOWN" $ALERT_EMAIL

  # Auto-restart
  openclaw gateway stop
  sleep 2
  openclaw gateway install
  exit 1
fi

# Check disk
DISK_USAGE=$(df -h ~/.openclaw | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 85 ]; then
  echo "⚠️ Disk usage: ${DISK_USAGE}% at $(date)" | mail -s "OpenClaw Disk Warning" $ALERT_EMAIL
fi

# Check backup age
LATEST_BACKUP=$(find ~/.openclaw/backups/daily -name "*.tar.gz" -type f -exec stat -f "%m %N" {} \; 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
if [ -n "$LATEST_BACKUP" ]; then
  BACKUP_AGE_HOURS=$(( ($(date +%s) - $(stat -f %m "$LATEST_BACKUP")) / 3600 ))
  if [ "$BACKUP_AGE_HOURS" -gt 36 ]; then
    echo "⚠️ Backup age: ${BACKUP_AGE_HOURS}h at $(date)" | mail -s "OpenClaw Backup Stale" $ALERT_EMAIL
  fi
fi

echo "✅ Health check OK at $(date)"
