#!/bin/bash
# Community-validated backup with integrity check

BACKUP_DIR="$HOME/.openclaw/backups/daily/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Backup critical files
cp ~/.openclaw/openclaw.json "$BACKUP_DIR/"
cp ~/.openclaw/.env "$BACKUP_DIR/"

# Create compressed archive
cd "$HOME/.openclaw/backups/daily"
tar -czf "$(date +%Y%m%d).tar.gz" "$(date +%Y%m%d)"
rm -rf "$(date +%Y%m%d)"

# CRITICAL: Verify integrity (community lesson learned)
if ! tar -tzf "$(date +%Y%m%d).tar.gz" > /dev/null 2>&1; then
  echo "❌ BACKUP FAILED - integrity check failed at $(date)" | \
    mail -s "OpenClaw Backup FAILED" your-email@example.com
  exit 1
fi

# Keep 14 days
find "$HOME/.openclaw/backups/daily" -name "*.tar.gz" -mtime +14 -delete

echo "✅ Backup completed and verified at $(date)"
