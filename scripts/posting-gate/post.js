#!/usr/bin/env node

/**
 * Social Media Posting Script
 * 
 * This script lives OUTSIDE the agent's normal workflow.
 * It's called by Lobster workflows AFTER human approval.
 * Credentials are read from ~/.config/ (outside agent workspace).
 * 
 * Usage:
 *   node post.js --platform x --content "Hello world"
 *   node post.js --platform x --content "Reply text" --reply-to "https://x.com/user/status/123"
 *   node post.js --platform linkedin --content "Post text"
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Parse args
const args = process.argv.slice(2);
function getArg(name) {
  const idx = args.indexOf(`--${name}`);
  return idx >= 0 ? args[idx + 1] : null;
}

const platform = getArg('platform');
const content = getArg('content');
const replyTo = getArg('reply-to');

if (!platform || !content) {
  console.error('Usage: node post.js --platform <x|linkedin> --content "text" [--reply-to URL]');
  process.exit(1);
}

// Audit log
const logDir = path.join(__dirname, 'logs');
if (!fs.existsSync(logDir)) fs.mkdirSync(logDir, { recursive: true });

const logEntry = {
  timestamp: new Date().toISOString(),
  platform,
  content: content.substring(0, 200),
  replyTo: replyTo || null,
  status: 'pending'
};

async function postToX(text, replyToUrl) {
  // Try bird CLI first (uses Chrome cookies)
  try {
    let cmd = `bird post "${text.replace(/"/g, '\\"')}"`;
    if (replyToUrl) {
      // Extract tweet ID from URL
      const tweetId = replyToUrl.split('/').pop().split('?')[0];
      cmd = `bird reply ${tweetId} "${text.replace(/"/g, '\\"')}"`;
    }
    const result = execSync(cmd, { encoding: 'utf8', timeout: 30000 });
    return { success: true, method: 'bird-cli', result: result.trim() };
  } catch (e) {
    console.error('Bird CLI failed:', e.message);
  }

  // Try X API OAuth
  try {
    const credsPath = path.join(process.env.HOME, '.config/x-api/credentials.json');
    if (fs.existsSync(credsPath)) {
      const creds = JSON.parse(fs.readFileSync(credsPath, 'utf8'));
      // OAuth posting logic here (to be implemented when keys work)
      return { success: false, method: 'x-api', error: 'OAuth keys need regeneration — see #dev thread' };
    }
  } catch (e) {
    console.error('X API failed:', e.message);
  }

  return { success: false, error: 'All posting methods failed. Manual post required.' };
}

async function postToLinkedIn(text) {
  try {
    const tokenPath = path.join(process.env.HOME, '.linkedin-mcp/tokens_default.json');
    if (!fs.existsSync(tokenPath)) {
      return { success: false, error: 'LinkedIn tokens not found' };
    }
    const tokens = JSON.parse(fs.readFileSync(tokenPath, 'utf8'));
    const accessToken = tokens.accessToken;

    // ⚠️ Do NOT hardcode your LinkedIn URN in a public repo.
    // Set it in your environment (or load from a private secrets manager):
    //   export LINKEDIN_PERSON_URN="urn:li:person:..."
    const personUrn = process.env.LINKEDIN_PERSON_URN;
    if (!personUrn) {
      return { success: false, error: 'Missing LINKEDIN_PERSON_URN (e.g. urn:li:person:...)' };
    }

    const payload = JSON.stringify({
      author: personUrn,
      lifecycleState: 'PUBLISHED',
      specificContent: {
        'com.linkedin.ugc.ShareContent': {
          shareCommentary: { text },
          shareMediaCategory: 'NONE'
        }
      },
      visibility: { 'com.linkedin.ugc.MemberNetworkVisibility': 'PUBLIC' }
    });

    const result = execSync(`curl -s -X POST "https://api.linkedin.com/v2/ugcPosts" \
      -H "Authorization: Bearer ${accessToken}" \
      -H "Content-Type: application/json" \
      -H "X-Restli-Protocol-Version: 2.0.0" \
      -d '${payload.replace(/'/g, "'\\''")}'`, 
      { encoding: 'utf8', timeout: 30000 }
    );
    
    const parsed = JSON.parse(result);
    if (parsed.id) {
      return { success: true, method: 'linkedin-api', postId: parsed.id };
    }
    return { success: false, method: 'linkedin-api', error: result };
  } catch (e) {
    return { success: false, error: e.message };
  }
}

async function main() {
  let result;
  
  switch (platform) {
    case 'x':
    case 'twitter':
      result = await postToX(content, replyTo);
      break;
    case 'linkedin':
      result = await postToLinkedIn(content);
      break;
    default:
      result = { success: false, error: `Unknown platform: ${platform}` };
  }

  // Log result
  logEntry.status = result.success ? 'posted' : 'failed';
  logEntry.result = result;
  
  const logFile = path.join(logDir, `${new Date().toISOString().split('T')[0]}.json`);
  let logs = [];
  if (fs.existsSync(logFile)) {
    logs = JSON.parse(fs.readFileSync(logFile, 'utf8'));
  }
  logs.push(logEntry);
  fs.writeFileSync(logFile, JSON.stringify(logs, null, 2));

  // Output for Lobster
  console.log(JSON.stringify(result));
  process.exit(result.success ? 0 : 1);
}

main();
