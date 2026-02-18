# Production Hardening - Step-by-Step Implementation

**Est. Time**: 60 minutes
**Difficulty**: Intermediate
**Reversible**: Yes (automated backups + git)

---

## Pre-Flight Checklist

- [ ] OpenClaw 2026.2.14+ installed
- [ ] macOS with LaunchAgent
- [ ] Git installed
- [ ] 60 minutes available
- [ ] Backup exists (or will be created automatically)

---

## Phase 1: Secret Management (10 min) 🚨 CRITICAL

### Step 1.1: Create Backup
```bash
BACKUP_DIR="$HOME/.openclaw/backups/manual-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp ~/.openclaw/openclaw.json "$BACKUP_DIR/"
cp ~/.openclaw/.env "$BACKUP_DIR/"
cp ~/Library/LaunchAgents/ai.openclaw.gateway.plist "$BACKUP_DIR/"
echo "✅ Backup: $BACKUP_DIR"
```

### Step 1.2: Verify .env Has All Secrets
```bash
# Check which secrets are missing
grep -E "BRAVE|PERPLEXITY|TALK|SKILL|NOTION|OPENAI" ~/.openclaw/.env
```

**If any are missing**, extract from `openclaw.json` and add to `.env`:
```bash
# Example:
echo "BRAVE_API_KEY=your-key-here" >> ~/.openclaw/.env
```

### Step 1.3: Remove Secrets from openclaw.json

**Edit** `~/.openclaw/openclaw.json`:

#### Remove env.vars
```json
// BEFORE
"env": {
  "vars": {
    "BRAVE_API_KEY": "BSAbmRO-...",
    "PERPLEXITY_API_KEY": "pplx-..."
  }
}

// AFTER
"env": {
  "vars": {}
}
```

#### Remove talk.apiKey
```json
// BEFORE
"talk": {
  "apiKey": "sk_..."
}

// AFTER
"talk": {}
```

#### Remove skill API keys
```json
// BEFORE
"skills": {
  "entries": {
    "nano-banana-pro": { "apiKey": "sk-..." },
    "notion": { "apiKey": "ntn_..." }
  }
}

// AFTER
"skills": {
  "entries": {
    "nano-banana-pro": {},
    "notion": {}
  }
}
```

**⚠️ Exception**: Keep `memory-lancedb.config.embedding.apiKey` (plugin schema requirement)

### Step 1.4: Harden Permissions
```bash
chmod 700 ~/.openclaw
chmod 600 ~/.openclaw/.env
ls -ld ~/.openclaw        # Should show: drwx------
ls -la ~/.openclaw/.env   # Should show: -rw-------
```

---

## Phase 2: LaunchAgent Hardening (5 min) ⚠️ HIGH

### Step 2.1: Update LaunchAgent Plist
```bash
# Download template
curl -sL https://raw.githubusercontent.com/unisone/openclaw-config/main/production-hardening/config/launchagent.plist \
  -o /tmp/launchagent.plist

# Replace YOUR_USERNAME with your actual username
sed -i '' "s/YOUR_USERNAME/$(whoami)/g" /tmp/launchagent.plist

# Copy to LaunchAgents
cp /tmp/launchagent.plist ~/Library/LaunchAgents/ai.openclaw.gateway.plist
```

**Key changes**:
- `ThrottleInterval: 5` (fast crash recovery)
- `ExitTimeOut: 20` (graceful shutdown)
- `ProcessType: Background` (proper priority)
- No hardcoded secrets

---

## Phase 3: Log Rotation (10 min) ⚠️ MEDIUM

### Step 3.1: Install Script
```bash
mkdir -p ~/.openclaw/scripts

curl -sL https://raw.githubusercontent.com/unisone/openclaw-config/main/production-hardening/scripts/rotate-logs.sh \
  -o ~/.openclaw/scripts/rotate-logs.sh

chmod +x ~/.openclaw/scripts/rotate-logs.sh
```

### Step 3.2: Add to Cron
```bash
(crontab -l 2>/dev/null | grep -v "rotate-logs.sh"; \
  echo "0 */3 * * * \$HOME/.openclaw/scripts/rotate-logs.sh >> \$HOME/.openclaw/logs/rotation.log 2>&1") | crontab -
```

### Step 3.3: Verify
```bash
crontab -l | grep rotate-logs
```

---

## Phase 4: Backup Automation (15 min) ⚠️ HIGH

### Step 4.1: Install Script
```bash
curl -sL https://raw.githubusercontent.com/unisone/openclaw-config/main/production-hardening/scripts/backup-config.sh \
  -o ~/.openclaw/scripts/backup-config.sh

chmod +x ~/.openclaw/scripts/backup-config.sh
```

### Step 4.2: Customize Email (Optional)
```bash
# Edit script to change email
sed -i '' 's/your-email@example.com/YOUR-EMAIL@example.com/g' ~/.openclaw/scripts/backup-config.sh
```

### Step 4.3: Add to Cron (with explicit PATH)
```bash
(crontab -l 2>/dev/null | grep -v "backup-config.sh"; \
  echo "0 2 * * * /usr/bin/env PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin \$HOME/.openclaw/scripts/backup-config.sh >> \$HOME/.openclaw/logs/backup.log 2>&1") | crontab -
```

### Step 4.4: Test Backup
```bash
~/.openclaw/scripts/backup-config.sh
ls -la ~/.openclaw/backups/daily/
```

---

## Phase 5: Health Monitoring (15 min) ⚠️ MEDIUM

### Step 5.1: Install Script
```bash
curl -sL https://raw.githubusercontent.com/unisone/openclaw-config/main/production-hardening/scripts/healthcheck.sh \
  -o ~/.openclaw/scripts/healthcheck.sh

chmod +x ~/.openclaw/scripts/healthcheck.sh
```

### Step 5.2: Customize Email (Optional)
```bash
sed -i '' 's/your-email@example.com/YOUR-EMAIL@example.com/g' ~/.openclaw/scripts/healthcheck.sh
```

### Step 5.3: Add to Cron
```bash
(crontab -l 2>/dev/null | grep -v "healthcheck.sh"; \
  echo "*/5 * * * * \$HOME/.openclaw/scripts/healthcheck.sh >> \$HOME/.openclaw/logs/health.log 2>&1") | crontab -
```

### Step 5.4: Test Health Check
```bash
~/.openclaw/scripts/healthcheck.sh
tail ~/.openclaw/logs/health.log
```

---

## Phase 6: Git Version Control (5 min) ✅ RECOMMENDED

### Step 6.1: Initialize Repository
```bash
cd ~/.openclaw
git init
```

### Step 6.2: Add .gitignore
```bash
curl -sL https://raw.githubusercontent.com/unisone/openclaw-config/main/production-hardening/config/gitignore.template \
  -o .gitignore
```

### Step 6.3: Initial Commit
```bash
git add openclaw.json .gitignore
git commit -m "baseline production config (unisone/openclaw-config v2026.02.17)"
git tag "production-$(date +%Y%m%d)"
```

---

## Phase 7: Restart & Validate (5 min) ✅ VERIFY

### Step 7.1: Validate Config
```bash
openclaw doctor --fix
```

**Expected**: No errors, config valid

### Step 7.2: Restart Gateway
```bash
openclaw gateway stop
sleep 2
openclaw gateway install
```

### Step 7.3: Verify Channels
```bash
sleep 5
openclaw channels status
```

**Expected**:
- WhatsApp: `running, connected`
- Slack: `running, connected`

### Step 7.4: Check Logs
```bash
tail -30 ~/.openclaw/logs/gateway.log
```

**Expected**: No errors, gateway started successfully

---

## Post-Implementation Checklist

### Immediate Verification
- [ ] `openclaw doctor` passes
- [ ] WhatsApp connected
- [ ] Slack connected
- [ ] No secrets in `openclaw.json` (except memory-lancedb)
- [ ] All secrets in `.env` (chmod 600)
- [ ] Directory permissions: 700
- [ ] Git repository initialized
- [ ] 3 cron jobs added

### Verify Cron Jobs
```bash
crontab -l
```

**Expected** (3 jobs):
```
0 */3 * * * ... rotate-logs.sh
0 2 * * * ... backup-config.sh
*/5 * * * * ... healthcheck.sh
```

### Verify Scripts
```bash
ls -la ~/.openclaw/scripts/
```

**Expected** (3 files, all executable):
```
-rwxr-xr-x rotate-logs.sh
-rwxr-xr-x backup-config.sh
-rwxr-xr-x healthcheck.sh
```

---

## Troubleshooting

### Config Validation Fails
```bash
# Check which fields are invalid
openclaw doctor

# Restore from backup if needed
cp $BACKUP_DIR/openclaw.json ~/.openclaw/
openclaw gateway stop && openclaw gateway install
```

### Channels Won't Connect
```bash
# Check if secrets are loaded
grep -E "SLACK|WHATSAPP" ~/.openclaw/.env

# Verify .env permissions
ls -la ~/.openclaw/.env  # Must be -rw------- (600)

# Re-login channels
openclaw channels login
```

### Cron Jobs Not Running
```bash
# Check cron syntax
crontab -l

# Test scripts manually
~/.openclaw/scripts/rotate-logs.sh
~/.openclaw/scripts/backup-config.sh
~/.openclaw/scripts/healthcheck.sh

# Check logs
tail ~/.openclaw/logs/rotation.log
tail ~/.openclaw/logs/backup.log
tail ~/.openclaw/logs/health.log
```

---

## Rollback Procedure

### Quick Rollback
```bash
# Restore from backup
BACKUP_DIR="$HOME/.openclaw/backups/manual-20260217_..."  # Use your backup dir
cp $BACKUP_DIR/openclaw.json ~/.openclaw/
cp $BACKUP_DIR/.env ~/.openclaw/
cp $BACKUP_DIR/ai.openclaw.gateway.plist ~/Library/LaunchAgents/

# Restart
openclaw gateway stop && openclaw gateway install
```

### Git Rollback
```bash
cd ~/.openclaw
git log --oneline
git checkout <previous-commit> openclaw.json
openclaw gateway stop && openclaw gateway install
```

---

## Next Steps

### Optional: External Monitoring
Sign up for [UptimeRobot](https://uptimerobot.com) (free):
1. Create account
2. Add monitor: `http://127.0.0.1:18789`
3. Set alert email
4. **Note**: Requires SSH tunnel or public IP

### Optional: Security Audit
```bash
openclaw security audit --deep
```

### Optional: Session Cleanup
```bash
# Current: 53 sessions
# Archive old ones if needed
mv ~/.openclaw/agents/main/sessions/sessions.json \
   ~/.openclaw/agents/main/sessions/sessions_$(date +%Y%m%d).json.bak

echo '{}' > ~/.openclaw/agents/main/sessions/sessions.json
openclaw gateway stop && openclaw gateway install
```

---

## Success Criteria

You've successfully completed production hardening when:

✅ Security
- No secrets in `openclaw.json` (except memory-lancedb)
- All secrets in `.env` with 600 permissions
- Directory has 700 permissions

✅ Reliability
- LaunchAgent has ThrottleInterval=5, ExitTimeOut=20, ProcessType=Background
- Gateway restarts in 5s after crash (not 5min)

✅ Monitoring
- Health check runs every 5 minutes
- Auto-restart on gateway failure
- Alerts configured (email or external)

✅ Operations
- Logs rotate at 10MB (max 30MB total)
- Daily backups with integrity verification
- Git tracking for config rollback

---

**Congratulations!** Your OpenClaw setup is now production-grade. 🦞🚀

**Questions?** Open an issue: https://github.com/unisone/openclaw-config/issues
