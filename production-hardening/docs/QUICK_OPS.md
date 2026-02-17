# OpenClaw Quick Operations Reference

## 🚀 Daily Operations

### Check Status
```bash
openclaw channels status
openclaw doctor
tail -20 ~/.openclaw/logs/gateway.log
```

### Restart Gateway
```bash
openclaw gateway stop
openclaw gateway install
```

### View Logs
```bash
# Real-time log watching
tail -f ~/.openclaw/logs/gateway.log

# Error logs
tail -50 ~/.openclaw/logs/gateway.err.log | grep -i error

# Search logs
grep "whatsapp" ~/.openclaw/logs/gateway.log | tail -20
```

---

## 🔧 Troubleshooting

### Gateway Won't Start
```bash
# Kill stale processes
ps aux | grep openclaw-gateway | grep -v grep | awk '{print $2}' | xargs kill

# Check port
lsof -i :18789

# Restart fresh
openclaw gateway stop
sleep 2
openclaw gateway install
```

### WhatsApp Disconnected
```bash
# Re-login
openclaw channels login

# Check status
openclaw channels status | grep WhatsApp
```

### Slack Not Responding
```bash
# Check connection
openclaw channels status | grep Slack

# Restart gateway
openclaw gateway stop && openclaw gateway install

# Check Slack app tokens in .env
grep SLACK ~/.openclaw/.env
```

### High Memory Usage
```bash
# Check session count
grep -c "session" ~/.openclaw/agents/main/sessions/sessions.json

# Archive old sessions (manual)
mv ~/.openclaw/agents/main/sessions/sessions.json \
   ~/.openclaw/agents/main/sessions/sessions_$(date +%Y%m%d).json.bak

# Create fresh sessions file
echo '{}' > ~/.openclaw/agents/main/sessions/sessions.json

# Restart
openclaw gateway stop && openclaw gateway install
```

---

## 📊 Monitoring Commands

### System Health
```bash
# Gateway process
ps aux | grep openclaw-gateway | grep -v grep

# Port listening
lsof -i :18789

# Memory usage
ps aux | grep openclaw-gateway | awk '{print $6/1024 "MB"}'

# Disk usage
du -sh ~/.openclaw
```

### Log Analysis
```bash
# Error count in last hour
tail -1000 ~/.openclaw/logs/gateway.err.log | wc -l

# Recent errors
grep -i error ~/.openclaw/logs/gateway.err.log | tail -20

# Connection issues
grep -i "disconnect\|timeout\|failed" ~/.openclaw/logs/gateway.log | tail -20
```

---

## 🔐 Security Operations

### Rotate Secrets
```bash
# 1. Update .env with new keys
nano ~/.openclaw/.env

# 2. Restart gateway
openclaw gateway stop && openclaw gateway install

# 3. Verify
openclaw channels status
```

### Backup Config
```bash
# Manual backup
BACKUP_DIR=~/.openclaw/backups/manual_$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR
cp ~/.openclaw/openclaw.json $BACKUP_DIR/
cp ~/.openclaw/.env $BACKUP_DIR/
cp ~/Library/LaunchAgents/ai.openclaw.gateway.plist $BACKUP_DIR/
echo "✅ Backup created: $BACKUP_DIR"
```

### Restore from Backup
```bash
# 1. Stop gateway
openclaw gateway stop

# 2. Restore files
RESTORE_FROM=~/.openclaw/backups/20260217_190000  # Use actual backup dir
cp $RESTORE_FROM/openclaw.json ~/.openclaw/
cp $RESTORE_FROM/.env ~/.openclaw/
cp $RESTORE_FROM/ai.openclaw.gateway.plist ~/Library/LaunchAgents/

# 3. Restart
openclaw gateway install
```

---

## 🛠️ Maintenance

### Clean Up Logs
```bash
# Archive old logs
mkdir -p ~/.openclaw/logs/archive
gzip -c ~/.openclaw/logs/gateway.log > ~/.openclaw/logs/archive/gateway_$(date +%Y%m%d).log.gz
gzip -c ~/.openclaw/logs/gateway.err.log > ~/.openclaw/logs/archive/gateway_err_$(date +%Y%m%d).log.gz

# Truncate
> ~/.openclaw/logs/gateway.log
> ~/.openclaw/logs/gateway.err.log

# Restart gateway to pick up fresh logs
openclaw gateway stop && openclaw gateway install
```

### Update OpenClaw
```bash
# Check version
openclaw --version

# Update
npm update -g openclaw

# Verify
openclaw --version

# Restart
openclaw gateway stop && openclaw gateway install
```

---

## 🚨 Emergency Procedures

### Complete Reset
```bash
# 1. Backup everything first!
EMERGENCY_BACKUP=~/.openclaw/backups/emergency_$(date +%Y%m%d_%H%M%S)
mkdir -p $EMERGENCY_BACKUP
cp -r ~/.openclaw/* $EMERGENCY_BACKUP/

# 2. Stop gateway
openclaw gateway stop

# 3. Clear sessions
echo '{}' > ~/.openclaw/agents/main/sessions/sessions.json

# 4. Truncate logs
> ~/.openclaw/logs/gateway.log
> ~/.openclaw/logs/gateway.err.log

# 5. Restart
openclaw gateway install

# 6. Re-login channels if needed
openclaw channels login
```

### Gateway Completely Dead
```bash
# 1. Unload LaunchAgent
launchctl bootout gui/$UID ~/Library/LaunchAgents/ai.openclaw.gateway.plist

# 2. Kill processes
pkill -f openclaw-gateway

# 3. Reinstall
openclaw gateway install

# 4. Verify
openclaw channels status
```

---

## 📞 Quick Help

**Config**: `~/.openclaw/openclaw.json`
**Secrets**: `~/.openclaw/.env`
**Logs**: `~/.openclaw/logs/`
**LaunchAgent**: `~/Library/LaunchAgents/ai.openclaw.gateway.plist`
**Sessions**: `~/.openclaw/agents/main/sessions/sessions.json`

**Docs**: https://docs.openclaw.ai
**Support**: https://github.com/openclaw/openclaw/issues
