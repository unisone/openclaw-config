#!/usr/bin/env node

/**
 * Install posting restrictions in OpenClaw gateway configuration
 * This makes it physically impossible to post to social media without approval
 */

const fs = require('fs');
const path = require('path');
const os = require('os');

// OpenClaw config path (Jan 2026+). Keep legacy fallbacks for older installs.
const CONFIG_PATHS = [
  path.join(os.homedir(), '.openclaw', 'openclaw.json'),
  path.join(os.homedir(), '.clawdbot', 'clawdbot.json'),
  path.join(os.homedir(), '.clawdbot', 'moltbot.json'),
];

function resolveConfigPath() {
  for (const p of CONFIG_PATHS) {
    if (fs.existsSync(p)) return p;
  }
  return CONFIG_PATHS[0];
}

const CONFIG_PATH = resolveConfigPath();
const BACKUP_PATH = CONFIG_PATH + '.backup.' + Date.now();

// Platforms that require approval for posting
const RESTRICTED_PLATFORMS = [
  'twitter', 'x', 'linkedin', 'facebook', 'instagram', 'tiktok'
];

function loadConfig() {
  if (!fs.existsSync(CONFIG_PATH)) {
    console.error('❌ OpenClaw config not found. Looked for:', CONFIG_PATHS.join(', '));
    process.exit(1);
  }
  
  try {
    const configData = fs.readFileSync(CONFIG_PATH, 'utf8');
    return JSON.parse(configData);
  } catch (error) {
    console.error('❌ Failed to parse OpenClaw config:', error.message);
    process.exit(1);
  }
}

function backupConfig() {
  console.log('📄 Creating backup:', BACKUP_PATH);
  fs.copyFileSync(CONFIG_PATH, BACKUP_PATH);
  return BACKUP_PATH;
}

function installRestrictions(config) {
  // Ensure tools section exists
  if (!config.tools) {
    config.tools = {};
  }

  // Add posting restrictions
  config.tools.posting = {
    enabled: true,
    restrictions: {
      mode: "approval-required",
      platforms: RESTRICTED_PLATFORMS,
      approvalServer: {
        enabled: true,
        port: 18790,
        discordChannelId: "1466528903815499997", // #dev channel
        tokenTtl: 300, // 5 minutes
        maxRetries: 3
      }
    }
  };

  // Modify memory trim to specifically deny message tool for social platforms
  if (!config.agents) config.agents = {};
  if (!config.agents.defaults) config.agents.defaults = {};
  if (!config.agents.defaults.memory) config.agents.defaults.memory = {};
  if (!config.agents.defaults.memory.trim) config.agents.defaults.memory.trim = {};
  if (!config.agents.defaults.memory.trim.tools) config.agents.defaults.memory.trim.tools = {};
  
  // Add approval-gated message tool
  const tools = config.agents.defaults.memory.trim.tools;
  if (!tools.allow) tools.allow = [];
  if (!tools.deny) tools.deny = [];
  
  // Remove message from allow list if present
  tools.allow = tools.allow.filter(tool => tool !== 'message');
  
  // Add message to deny list (will be replaced with approval-gated version)
  if (!tools.deny.includes('message')) {
    tools.deny.push('message');
  }
  
  // Add approval-gated message variant
  if (!tools.allow.includes('message_approved')) {
    tools.allow.push('message_approved');
  }

  return config;
}

function saveConfig(config) {
  try {
    const configData = JSON.stringify(config, null, 2);
    fs.writeFileSync(CONFIG_PATH, configData);
    console.log('✅ Posting restrictions installed successfully');
  } catch (error) {
    console.error('❌ Failed to save config:', error.message);
    process.exit(1);
  }
}

function validateInstallation(config) {
  const issues = [];
  
  if (!config.tools?.posting?.enabled) {
    issues.push('Posting restrictions not enabled');
  }
  
  if (!config.tools?.posting?.restrictions?.platforms?.includes('twitter')) {
    issues.push('Twitter not in restricted platforms');
  }
  
  const tools = config.agents?.defaults?.memory?.trim?.tools;
  if (!tools?.deny?.includes('message')) {
    issues.push('Message tool not denied');
  }
  
  if (!tools?.allow?.includes('message_approved')) {
    issues.push('Approved message tool not allowed');
  }
  
  if (issues.length > 0) {
    console.error('❌ Installation validation failed:');
    issues.forEach(issue => console.error(`  - ${issue}`));
    return false;
  }
  
  return true;
}

function main() {
  console.log('🔒 Installing AI Agent Posting Approval Gate...\n');
  
  // Load and backup current config
  const config = loadConfig();
  const backupPath = backupConfig();
  
  console.log('⚙️  Installing restrictions...');
  
  try {
    const updatedConfig = installRestrictions(config);
    
    // Validate before saving
    if (!validateInstallation(updatedConfig)) {
      console.error('\n❌ Installation failed validation. Config not modified.');
      process.exit(1);
    }
    
    saveConfig(updatedConfig);
    
    console.log('\n✅ Posting restrictions installed successfully!');
    console.log('📄 Backup saved to:', backupPath);
    console.log('\n🚀 Next steps:');
    console.log('   1. Restart OpenClaw gateway: openclaw gateway restart');
    console.log('   2. Start approval server: node approval-server.js');
    console.log('   3. Test by attempting a post via your OpenClaw message tool');
    
  } catch (error) {
    console.error('❌ Installation failed:', error.message);
    console.log('📄 Restoring from backup...');
    fs.copyFileSync(backupPath, CONFIG_PATH);
    console.log('✅ Config restored');
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = { installRestrictions, validateInstallation };