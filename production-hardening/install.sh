#!/bin/bash
# OpenClaw Production Hardening - Automated Installer
# Version: 2026.02.17
# Maintainers: openclaw-config contributors

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  OpenClaw Production Hardening Installer                    ║"
echo "║  Version: 2026.02.17                                         ║"
echo "║  Maintainers: openclaw-config contributors                             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if running in ~/.openclaw
if [ "$(pwd)" != "$HOME/.openclaw" ]; then
  echo -e "${RED}Error: Must run from ~/.openclaw directory${NC}"
  echo "Run: cd ~/.openclaw && ./install.sh"
  exit 1
fi

# Backup current config
BACKUP_DIR="$HOME/.openclaw/backups/production-hardening-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo -e "${YELLOW}Creating backup: $BACKUP_DIR${NC}"
cp openclaw.json "$BACKUP_DIR/" 2>/dev/null || true
cp .env "$BACKUP_DIR/" 2>/dev/null || true
cp ~/Library/LaunchAgents/ai.openclaw.gateway.plist "$BACKUP_DIR/" 2>/dev/null || true
echo -e "${GREEN}✅ Backup created${NC}"
echo ""

# Download scripts
echo -e "${YELLOW}Downloading production scripts...${NC}"
REPO_URL="https://raw.githubusercontent.com/unisone/openclaw-config/main/production-hardening"

mkdir -p scripts

curl -sL "$REPO_URL/scripts/rotate-logs.sh" -o scripts/rotate-logs.sh
curl -sL "$REPO_URL/scripts/backup-config.sh" -o scripts/backup-config.sh
curl -sL "$REPO_URL/scripts/healthcheck.sh" -o scripts/healthcheck.sh

chmod +x scripts/*.sh
echo -e "${GREEN}✅ Scripts installed${NC}"
echo ""

# Download LaunchAgent template
echo -e "${YELLOW}Downloading LaunchAgent template...${NC}"
curl -sL "$REPO_URL/config/launchagent.plist" -o /tmp/launchagent.plist.template
echo -e "${GREEN}✅ Template downloaded${NC}"
echo ""

# Prompt for manual steps
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  MANUAL STEPS REQUIRED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1️⃣  Remove secrets from openclaw.json"
echo "   See: $REPO_URL/README.md#critical-finding-1"
echo ""
echo "2️⃣  Update LaunchAgent plist"
echo "   Template: /tmp/launchagent.plist.template"
echo "   Target: ~/Library/LaunchAgents/ai.openclaw.gateway.plist"
echo ""
echo "3️⃣  Install cron jobs"
echo "   Run: (crontab -l 2>/dev/null; cat <<EOF"
echo "   0 */3 * * * \$HOME/.openclaw/scripts/rotate-logs.sh >> \$HOME/.openclaw/logs/rotation.log 2>&1"
echo "   0 2 * * * /usr/bin/env PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin \$HOME/.openclaw/scripts/backup-config.sh >> \$HOME/.openclaw/logs/backup.log 2>&1"
echo "   */5 * * * * \$HOME/.openclaw/scripts/healthcheck.sh >> \$HOME/.openclaw/logs/health.log 2>&1"
echo "   EOF"
echo "   ) | crontab -"
echo ""
echo "4️⃣  Harden permissions"
echo "   chmod 700 ~/.openclaw"
echo "   chmod 600 ~/.openclaw/.env"
echo ""
echo "5️⃣  Initialize git tracking"
echo "   git init"
echo "   curl -sL $REPO_URL/config/gitignore.template -o .gitignore"
echo "   git add openclaw.json .gitignore"
echo "   git commit -m 'baseline production config'"
echo ""
echo "6️⃣  Restart gateway"
echo "   openclaw gateway stop && openclaw gateway install"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "For detailed instructions, see:"
echo "  https://github.com/unisone/openclaw-config/tree/main/production-hardening"
echo ""
