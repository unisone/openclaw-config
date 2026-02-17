#!/bin/bash
# Community-validated log rotation
# Max size: 10MB, Keep: 3 files

LOG_DIR="$HOME/.openclaw/logs"
ARCHIVE_DIR="$LOG_DIR/archive"
MAX_SIZE_MB=10

mkdir -p "$ARCHIVE_DIR"

for log in gateway.log gateway.err.log; do
  if [ ! -f "$LOG_DIR/$log" ]; then continue; fi

  SIZE_MB=$(du -m "$LOG_DIR/$log" | cut -f1)

  if [ "$SIZE_MB" -gt "$MAX_SIZE_MB" ]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    gzip -c "$LOG_DIR/$log" > "$ARCHIVE_DIR/${log%.log}_$TIMESTAMP.log.gz"
    > "$LOG_DIR/$log"
    echo "✅ Rotated $log ($SIZE_MB MB) at $(date)"
  fi
done

# Keep only 3 most recent per log
for log in gateway gateway_err; do
  ls -t "$ARCHIVE_DIR/${log}_"*.log.gz 2>/dev/null | tail -n +4 | xargs rm -f
done
