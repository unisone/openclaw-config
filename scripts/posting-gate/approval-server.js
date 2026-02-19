#!/usr/bin/env node

/**
 * Discord Approval Server for AI Agent Posting Gate
 * Handles approval workflows via Discord reactions and webhooks
 */

const express = require('express');
const crypto = require('crypto');
const fs = require('fs').promises;
const path = require('path');
const { Client, GatewayIntentBits, EmbedBuilder, ActionRowBuilder, ButtonBuilder, ButtonStyle } = require('discord.js');

const PORT = process.env.APPROVAL_PORT || 18790;
const DISCORD_TOKEN = process.env.DISCORD_BOT_TOKEN; // Will read from OpenClaw config if not set
const DEV_CHANNEL_ID = 'YOUR_DISCORD_CHANNEL_ID';
const LOGS_DIR = path.join(__dirname, 'logs');
const TOKENS_FILE = path.join(__dirname, 'approval-tokens.json');

// In-memory storage for pending approvals and active tokens
const pendingApprovals = new Map(); // requestId -> approval data
const activeTokens = new Map();     // token -> metadata
const approvalHistory = [];

class ApprovalServer {
  constructor() {
    this.app = express();
    this.discord = null;
    this.setupExpress();
    this.setupDiscord();
  }

  setupExpress() {
    this.app.use(express.json());
    this.app.use(express.urlencoded({ extended: true }));

    // Health check
    this.app.get('/health', (req, res) => {
      res.json({ 
        status: 'ok', 
        approvals: pendingApprovals.size,
        tokens: activeTokens.size,
        uptime: process.uptime()
      });
    });

    // Request approval endpoint (called by restricted message tool)
    this.app.post('/request-approval', async (req, res) => {
      try {
        const approval = await this.createApprovalRequest(req.body);
        res.json({ 
          requestId: approval.id, 
          status: 'pending',
          approvalUrl: approval.discordUrl
        });
      } catch (error) {
        console.error('Failed to create approval request:', error);
        res.status(500).json({ error: 'Failed to create approval request' });
      }
    });

    // Check approval status endpoint
    this.app.get('/status/:requestId', (req, res) => {
      const { requestId } = req.params;
      const approval = pendingApprovals.get(requestId);
      
      if (!approval) {
        return res.status(404).json({ error: 'Request not found' });
      }
      
      res.json({
        requestId,
        status: approval.status,
        token: approval.token || null,
        expiresAt: approval.expiresAt || null
      });
    });

    // Webhook for Discord interactions
    this.app.post('/discord-webhook', async (req, res) => {
      try {
        await this.handleDiscordWebhook(req.body);
        res.json({ status: 'ok' });
      } catch (error) {
        console.error('Discord webhook error:', error);
        res.status(500).json({ error: 'Webhook processing failed' });
      }
    });
  }

  async setupDiscord() {
    // Read Discord token from OpenClaw config if not in env
    const discordToken = DISCORD_TOKEN || await this.getDiscordTokenFromConfig();
    
    if (!discordToken) {
      console.error('❌ Discord token not found. Set DISCORD_BOT_TOKEN or ensure OpenClaw config has Discord token.');
      process.exit(1);
    }

    this.discord = new Client({
      intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.GuildMessages,
        GatewayIntentBits.GuildMessageReactions,
        GatewayIntentBits.MessageContent
      ]
    });

    this.discord.on('ready', () => {
      console.log(`🤖 Discord bot ready as ${this.discord.user.tag}`);
    });

    this.discord.on('interactionCreate', async (interaction) => {
      if (!interaction.isButton()) return;
      await this.handleApprovalButton(interaction);
    });

    await this.discord.login(discordToken);
  }

  async getDiscordTokenFromConfig() {
    const candidates = [
      path.join(process.env.HOME, '.openclaw', 'openclaw.json'),
      path.join(process.env.HOME, '.openclaw', 'openclaw.json'),
      path.join(process.env.HOME, '.openclaw', 'openclaw.json'),
    ];

    for (const configPath of candidates) {
      try {
        const configData = await fs.readFile(configPath, 'utf8');
        const config = JSON.parse(configData);
        const token = config.channels?.discord?.token;
        if (token) return token;
      } catch (error) {
        // keep trying
      }
    }

    console.warn('Could not read Discord token from OpenClaw config (tried: ' + candidates.join(', ') + ')');
    return null;
  }

  async createApprovalRequest(data) {
    const requestId = crypto.randomUUID();
    const expiresAt = Date.now() + (5 * 60 * 1000); // 5 minutes
    
    const approval = {
      id: requestId,
      platform: data.platform || 'unknown',
      action: data.action || 'post',
      content: data.content || '',
      target: data.target || '',
      requestedAt: Date.now(),
      expiresAt,
      status: 'pending',
      discordMessageId: null
    };

    // Create Discord approval message
    const embed = new EmbedBuilder()
      .setTitle('🔒 Posting Approval Required')
      .setDescription(`Agent wants to ${approval.action} to **${approval.platform}**`)
      .addFields(
        { name: '📝 Content', value: approval.content || 'No content', inline: false },
        { name: '🎯 Target', value: approval.target || 'Default', inline: true },
        { name: '⏰ Expires', value: `<t:${Math.floor(expiresAt / 1000)}:R>`, inline: true }
      )
      .setColor(0xFFA500) // Orange for pending
      .setTimestamp();

    const buttons = new ActionRowBuilder()
      .addComponents(
        new ButtonBuilder()
          .setCustomId(`approve_${requestId}`)
          .setLabel('✅ Approve')
          .setStyle(ButtonStyle.Success),
        new ButtonBuilder()
          .setCustomId(`deny_${requestId}`)
          .setLabel('❌ Deny')
          .setStyle(ButtonStyle.Danger)
      );

    const channel = await this.discord.channels.fetch(DEV_CHANNEL_ID);
    const message = await channel.send({ 
      embeds: [embed], 
      components: [buttons]
    });

    approval.discordMessageId = message.id;
    approval.discordUrl = message.url;
    pendingApprovals.set(requestId, approval);

    // Set cleanup timer
    setTimeout(() => {
      if (pendingApprovals.has(requestId)) {
        this.expireApproval(requestId);
      }
    }, 5 * 60 * 1000);

    await this.logApproval(approval, 'REQUESTED');
    
    console.log(`📋 Approval request ${requestId} created for ${approval.platform}`);
    
    return approval;
  }

  async handleApprovalButton(interaction) {
    const [action, requestId] = interaction.customId.split('_');
    const approval = pendingApprovals.get(requestId);
    
    if (!approval) {
      await interaction.reply({ 
        content: '❌ Approval request not found or expired', 
        ephemeral: true 
      });
      return;
    }

    if (approval.status !== 'pending') {
      await interaction.reply({ 
        content: `❌ Request already ${approval.status}`, 
        ephemeral: true 
      });
      return;
    }

    if (action === 'approve') {
      await this.approveRequest(requestId, interaction.user.id);
      await interaction.reply({ 
        content: '✅ Posting approved! Agent can now proceed.', 
        ephemeral: true 
      });
    } else if (action === 'deny') {
      await this.denyRequest(requestId, interaction.user.id);
      await interaction.reply({ 
        content: '❌ Posting denied.', 
        ephemeral: true 
      });
    }

    // Update Discord message
    await this.updateDiscordMessage(approval);
  }

  async approveRequest(requestId, approvedBy) {
    const approval = pendingApprovals.get(requestId);
    if (!approval) return;

    const token = crypto.randomBytes(32).toString('hex');
    const expiresAt = Date.now() + (5 * 60 * 1000); // 5 minutes

    approval.status = 'approved';
    approval.approvedBy = approvedBy;
    approval.approvedAt = Date.now();
    approval.token = token;
    approval.tokenExpiresAt = expiresAt;

    activeTokens.set(token, {
      requestId,
      platform: approval.platform,
      action: approval.action,
      expiresAt,
      used: false
    });

    // Auto-cleanup token
    setTimeout(() => {
      if (activeTokens.has(token)) {
        activeTokens.delete(token);
        console.log(`🧹 Token ${token.slice(0, 8)}... expired`);
      }
    }, 5 * 60 * 1000);

    await this.logApproval(approval, 'APPROVED');
    console.log(`✅ Approval ${requestId} approved by ${approvedBy}, token: ${token.slice(0, 8)}...`);
  }

  async denyRequest(requestId, deniedBy) {
    const approval = pendingApprovals.get(requestId);
    if (!approval) return;

    approval.status = 'denied';
    approval.deniedBy = deniedBy;
    approval.deniedAt = Date.now();

    await this.logApproval(approval, 'DENIED');
    console.log(`❌ Approval ${requestId} denied by ${deniedBy}`);
  }

  async expireApproval(requestId) {
    const approval = pendingApprovals.get(requestId);
    if (!approval || approval.status !== 'pending') return;

    approval.status = 'expired';
    approval.expiredAt = Date.now();

    await this.updateDiscordMessage(approval);
    await this.logApproval(approval, 'EXPIRED');
    console.log(`⏰ Approval ${requestId} expired`);
  }

  async updateDiscordMessage(approval) {
    try {
      const channel = await this.discord.channels.fetch(DEV_CHANNEL_ID);
      const message = await channel.messages.fetch(approval.discordMessageId);
      
      const embed = message.embeds[0];
      embed.color = approval.status === 'approved' ? 0x00FF00 : 
                   approval.status === 'denied' ? 0xFF0000 : 0x808080;
      
      embed.fields.push({
        name: '📊 Status',
        value: approval.status.toUpperCase(),
        inline: true
      });

      await message.edit({ embeds: [embed], components: [] });
    } catch (error) {
      console.error('Failed to update Discord message:', error);
    }
  }

  // Validate approval token (called by message tool)
  validateToken(token, platform, action) {
    const tokenData = activeTokens.get(token);
    
    if (!tokenData) {
      return { valid: false, reason: 'Token not found' };
    }
    
    if (tokenData.used) {
      return { valid: false, reason: 'Token already used' };
    }
    
    if (Date.now() > tokenData.expiresAt) {
      activeTokens.delete(token);
      return { valid: false, reason: 'Token expired' };
    }
    
    if (tokenData.platform !== platform || tokenData.action !== action) {
      return { valid: false, reason: 'Token scope mismatch' };
    }
    
    // Mark as used
    tokenData.used = true;
    tokenData.usedAt = Date.now();
    
    // Clean up after use
    setTimeout(() => activeTokens.delete(token), 30000); // Keep for 30s for logging
    
    return { valid: true, tokenData };
  }

  async logApproval(approval, event) {
    await fs.mkdir(LOGS_DIR, { recursive: true });
    
    const logEntry = {
      timestamp: new Date().toISOString(),
      event,
      requestId: approval.id,
      platform: approval.platform,
      action: approval.action,
      content: approval.content?.slice(0, 100) + (approval.content?.length > 100 ? '...' : ''),
      approvedBy: approval.approvedBy,
      deniedBy: approval.deniedBy,
      token: approval.token?.slice(0, 8) + (approval.token ? '...' : '')
    };
    
    const logFile = path.join(LOGS_DIR, `approvals-${new Date().toISOString().slice(0, 10)}.jsonl`);
    await fs.appendFile(logFile, JSON.stringify(logEntry) + '\n');
    
    approvalHistory.push(logEntry);
    if (approvalHistory.length > 1000) {
      approvalHistory.shift(); // Keep last 1000 entries in memory
    }
  }

  async start() {
    await fs.mkdir(LOGS_DIR, { recursive: true });
    
    this.app.listen(PORT, () => {
      console.log(`🔒 Approval server running on port ${PORT}`);
      console.log(`📋 Health check: http://localhost:${PORT}/health`);
      console.log(`🤖 Discord approvals in channel: ${DEV_CHANNEL_ID}`);
    });
  }
}

// API for message tool integration
const approvalServer = new ApprovalServer();

// Export validation function for message tool
function validateApprovalToken(token, platform, action) {
  return approvalServer.validateToken(token, platform, action);
}

// Start server if run directly
if (require.main === module) {
  approvalServer.start().catch(console.error);
}

module.exports = { ApprovalServer, validateApprovalToken };