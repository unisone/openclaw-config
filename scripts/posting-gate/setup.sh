#!/bin/bash

# AI Agent Posting Approval Gate - Setup Script
# Installs and configures the technical safeguard system

set -e

echo "🔒 Setting up AI Agent Posting Approval Gate..."
echo ""

# Check if we're in the right directory
if [[ ! -f "package.json" ]]; then
    echo "❌ Error: Must run from ~/clawd/scripts/posting-gate directory"
    exit 1
fi

# Check if OpenClaw config exists (with legacy fallbacks)
CONFIG_CANDIDATES=(
  "$HOME/.openclaw/openclaw.json"
  "$HOME/.clawdbot/clawdbot.json"
  "$HOME/.clawdbot/moltbot.json"
)

CONFIG_PATH=""
for p in "${CONFIG_CANDIDATES[@]}"; do
  if [[ -f "$p" ]]; then CONFIG_PATH="$p"; break; fi
done

if [[ -z "$CONFIG_PATH" ]]; then
    echo "❌ Error: OpenClaw configuration not found. Looked for:"
    printf '   - %s\n' "${CONFIG_CANDIDATES[@]}"
    echo "   Make sure OpenClaw is installed and configured first."
    exit 1
fi

# Check if Node.js is available
if ! command -v node &> /dev/null; then
    echo "❌ Error: Node.js not found. Please install Node.js first."
    exit 1
fi

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Backup current OpenClaw config
echo "📄 Backing up OpenClaw configuration ($CONFIG_PATH)..."
cp "$CONFIG_PATH" "$CONFIG_PATH.backup.$(date +%s)"

# Install gateway restrictions
echo "⚙️  Installing gateway restrictions..."
node install-restrictions.js

if [[ $? -ne 0 ]]; then
    echo "❌ Failed to install restrictions. Check the error above."
    exit 1
fi

# Create logs directory
mkdir -p logs

# Create systemd service file (optional)
if command -v systemctl &> /dev/null; then
    echo "🔧 Creating systemd service file..."
    cat > /tmp/clawdbot-approval-gate.service << EOF
[Unit]
Description=OpenClaw Posting Approval Gate
After=network.target

[Service]
Type=simple
User=$(whoami)
WorkingDirectory=$(pwd)
ExecStart=$(which node) approval-server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

    if sudo cp /tmp/clawdbot-approval-gate.service /etc/systemd/system/ 2>/dev/null; then
        sudo systemctl daemon-reload
        echo "✅ Systemd service created. To enable:"
        echo "   sudo systemctl enable clawdbot-approval-gate"
        echo "   sudo systemctl start clawdbot-approval-gate"
    else
        echo "⚠️  Could not create systemd service (no sudo access)"
    fi
fi

# Test the installation
echo ""
echo "🧪 Testing installation..."
node test-system.js

if [[ $? -eq 0 ]]; then
    echo ""
    echo "✅ Installation complete! The AI agent posting approval gate is now active."
    echo ""
    echo "🚀 Next steps:"
    echo "   1. Restart OpenClaw gateway: openclaw gateway restart"
    echo "   2. Start approval server: npm start"
    echo "   3. Test posting: echo 'test' | node approved-message-tool.js --target twitter"
    echo ""
    echo "📋 Management commands:"
    echo "   npm run status     - Check approval server status"
    echo "   npm run logs       - View approval logs"
    echo "   npm test          - Run test suite"
    echo ""
    echo "🔒 Security: It is now physically impossible for the AI agent to post"
    echo "   to social media without explicit human approval via Discord reactions."
else
    echo ""
    echo "❌ Installation test failed. Please check the errors above."
    exit 1
fi