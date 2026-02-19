#!/usr/bin/env node

/**
 * Approval-Gated Message Tool
 * Replacement for standard message tool that requires approval for social posting
 */

const axios = require('axios');
const crypto = require('crypto');

const APPROVAL_SERVER_URL = 'http://localhost:18790';
const RESTRICTED_PLATFORMS = ['twitter', 'x', 'linkedin', 'facebook', 'instagram', 'tiktok'];
const DISCORD_DEV_CHANNEL = 'YOUR_DISCORD_CHANNEL_ID';

class ApprovedMessageTool {
  constructor() {
    this.pendingRequests = new Map();
  }

  /**
   * Main entry point for message sending
   * Checks if approval is needed and handles the workflow
   */
  async send(params) {
    const { target, message, action = 'send', platform } = params;
    
    // Determine platform from target or explicit platform param
    const detectedPlatform = this.detectPlatform(target, platform);
    
    // Check if this platform requires approval
    if (this.requiresApproval(detectedPlatform, action)) {
      return await this.handleApprovalFlow(params, detectedPlatform);
    }
    
    // Non-restricted platforms can proceed normally
    return await this.sendDirect(params);
  }

  detectPlatform(target, explicitPlatform) {
    if (explicitPlatform) return explicitPlatform.toLowerCase();
    
    const targetLower = (target || '').toLowerCase();
    
    // Platform detection logic
    if (targetLower.includes('twitter') || targetLower.includes('x.com')) return 'twitter';
    if (targetLower.includes('linkedin')) return 'linkedin';
    if (targetLower.includes('facebook')) return 'facebook';
    if (targetLower.includes('instagram')) return 'instagram';
    if (targetLower.includes('tiktok')) return 'tiktok';
    if (targetLower.includes('discord')) return 'discord';
    
    return 'unknown';
  }

  requiresApproval(platform, action) {
    // Posting actions to restricted platforms require approval
    const postingActions = ['send', 'post', 'tweet', 'share', 'publish'];
    return RESTRICTED_PLATFORMS.includes(platform) && postingActions.includes(action);
  }

  async handleApprovalFlow(params, platform) {
    const { message, target, action, approvalToken } = params;
    
    // If approval token provided, validate and proceed
    if (approvalToken) {
      const validation = await this.validateApprovalToken(approvalToken, platform, action);
      
      if (validation.valid) {
        console.log(`✅ Approval token valid, proceeding with ${action} to ${platform}`);
        return await this.sendDirect(params);
      } else {
        throw new Error(`Invalid approval token: ${validation.reason}`);
      }
    }
    
    // No token provided, request approval
    console.log(`🔒 Posting to ${platform} requires approval, requesting...`);
    
    const approvalRequest = await this.requestApproval({
      platform,
      action,
      content: message,
      target
    });
    
    // Draft to Discord while waiting for approval
    await this.draftToDiscord({
      originalParams: params,
      platform,
      approvalRequest
    });
    
    return {
      status: 'approval_required',
      requestId: approvalRequest.requestId,
      message: `Posting to ${platform} requires approval. Draft sent to Discord for review.`,
      approvalUrl: approvalRequest.approvalUrl
    };
  }

  async requestApproval(data) {
    try {
      const response = await axios.post(`${APPROVAL_SERVER_URL}/request-approval`, data, {
        timeout: 10000
      });
      
      return response.data;
    } catch (error) {
      console.error('Failed to request approval:', error.message);
      throw new Error('Approval system unavailable. Posting blocked for safety.');
    }
  }

  async validateApprovalToken(token, platform, action) {
    try {
      // Direct validation with approval server
      const { validateApprovalToken } = require('./approval-server.js');
      return validateApprovalToken(token, platform, action);
    } catch (error) {
      console.error('Token validation failed:', error.message);
      return { valid: false, reason: 'Validation system error' };
    }
  }

  async draftToDiscord(data) {
    const { originalParams, platform, approvalRequest } = data;
    const { message, target } = originalParams;
    
    const draftMessage = `📋 **POSTING APPROVAL REQUIRED**
    
**Platform:** ${platform.toUpperCase()}
**Target:** ${target}
**Action:** ${originalParams.action || 'post'}

**Content:**
\`\`\`
${message}
\`\`\`

**Request ID:** ${approvalRequest.requestId}
**Status:** Pending approval
**Approval URL:** ${approvalRequest.approvalUrl}

React with ✅ to approve or ❌ to deny.`;

    try {
      // Use standard message tool for Discord (not restricted)
      return await this.sendDirect({
        action: 'send',
        target: DISCORD_DEV_CHANNEL,
        message: draftMessage,
        platform: 'discord'
      });
    } catch (error) {
      console.error('Failed to draft to Discord:', error.message);
      throw new Error('Could not send approval request to Discord');
    }
  }

  async sendDirect(params) {
    // This would normally call the actual message tool/API
    // For now, we'll simulate the behavior
    console.log(`📤 Sending message directly:`, {
      target: params.target,
      platform: params.platform || 'detected',
      action: params.action || 'send',
      messageLength: params.message?.length || 0
    });
    
    // In real implementation, this would:
    // 1. Load appropriate credentials for platform
    // 2. Call platform API (X, LinkedIn, etc.)
    // 3. Handle response and errors
    
    return {
      status: 'sent',
      platform: params.platform,
      messageId: `msg_${Date.now()}`,
      timestamp: new Date().toISOString()
    };
  }

  /**
   * Retry posting with approval token
   * Called when human approves the request
   */
  async retryWithApproval(requestId, token) {
    const request = this.pendingRequests.get(requestId);
    if (!request) {
      throw new Error('Request not found');
    }
    
    // Add approval token and retry
    const paramsWithToken = {
      ...request.params,
      approvalToken: token
    };
    
    const result = await this.send(paramsWithToken);
    this.pendingRequests.delete(requestId);
    
    return result;
  }

  /**
   * Check status of approval request
   */
  async checkApprovalStatus(requestId) {
    try {
      const response = await axios.get(`${APPROVAL_SERVER_URL}/status/${requestId}`);
      return response.data;
    } catch (error) {
      console.error('Failed to check approval status:', error.message);
      return { status: 'error', error: error.message };
    }
  }
}

// CLI interface
if (require.main === module) {
  const args = process.argv.slice(2);
  const tool = new ApprovedMessageTool();
  
  // Parse command line arguments
  const params = {};
  for (let i = 0; i < args.length; i += 2) {
    const key = args[i].replace(/^--/, '');
    const value = args[i + 1];
    params[key] = value;
  }
  
  if (!params.message) {
    // Read from stdin if no message provided
    process.stdin.setEncoding('utf8');
    let inputData = '';
    process.stdin.on('data', (chunk) => {
      inputData += chunk;
    });
    process.stdin.on('end', async () => {
      params.message = inputData.trim();
      try {
        const result = await tool.send(params);
        console.log(JSON.stringify(result, null, 2));
      } catch (error) {
        console.error('Error:', error.message);
        process.exit(1);
      }
    });
  } else {
    // Use provided message
    tool.send(params)
      .then(result => {
        console.log(JSON.stringify(result, null, 2));
      })
      .catch(error => {
        console.error('Error:', error.message);
        process.exit(1);
      });
  }
}

module.exports = ApprovedMessageTool;