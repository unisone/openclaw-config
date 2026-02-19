# 🔒 AI Agent Posting Approval Gate

## Overview

Technical safeguard system that makes it **physically impossible** for the AI agent to post to social media without explicit human approval.

**Naming note:** Some tooling (e.g. the Lobster CLI package name) may still carry an older package name even though the runtime is OpenClaw.

This gate uses the Lobster workflow engine with approval checkpoints.

## Architecture

```
Agent wants to post → Lobster workflow starts → APPROVAL GATE (pauses) → Human approves → Post executes
```

The agent calls a Lobster pipeline. Lobster halts at the `approve` step and returns a `resumeToken`. The post only executes after a human explicitly approves via:
- `lobster resume --token <token> --approve yes` (CLI)
- `/approve <id>` in Discord (when forwarding is enabled)

## How It Works

1. **Agent drafts** content in the normal conversation
2. **Agent calls** the Lobster `social-post` workflow
3. **Lobster pauses** at the approval gate — returns preview + resume token
4. **Human reviews** the draft in Discord
5. **Human approves** → Lobster resumes → `post.js` executes with credentials
6. **Audit log** records everything to `logs/YYYY-MM-DD.json`

## Security Properties

- ✅ **Infrastructure-level enforcement** — Lobster runtime controls execution, not the agent
- ✅ **Credential isolation** — API keys in `~/.config/` (outside agent workspace `~/openclaw-workspace`)
- ✅ **Resume tokens** — cryptographic tokens required to continue past approval gate
- ✅ **Audit trail** — every post attempt logged with timestamp, content, result
- ✅ **Platform extensible** — X, LinkedIn, any future platform
- ✅ **Native OpenClaw integration** — uses Lobster workflows, not custom middleware

## Files

| File | Purpose |
|------|---------|
| `post.js` | Posting script with credential access (X API, LinkedIn API) |
| `../workflows/social-post.lobster` | Lobster workflow with approval gate |
| `logs/` | Audit trail (auto-created) |

## Usage

### Via Lobster CLI (testing)
```bash
# Start the workflow — will pause at approval
lobster run --mode tool \
  'exec --json --shell "echo {\"platform\":\"x\",\"content\":\"Hello world\"}" | approve --preview-from-stdin --prompt "Post this?"'

# Approve and continue
lobster resume --token <resumeToken> --approve yes
```

### Via OpenClaw Agent
The agent calls the Lobster tool with the `social-post` workflow. Approval is forwarded to Discord.

## Credential Locations (outside agent workspace)

- **X/Twitter:** `~/.config/x-api/credentials.json`
- **LinkedIn:** `~/.linkedin-mcp/tokens_default.json`

The agent at `~/openclaw-workspace` cannot access these directly. Only `post.js` (called by Lobster after approval) reads them.

## Audit Logs

All posting attempts are logged to `logs/YYYY-MM-DD.json`:
```json
{
  "timestamp": "2026-01-30T17:45:00.000Z",
  "platform": "x",
  "content": "Post preview...",
  "replyTo": null,
  "status": "posted",
  "result": { "success": true, "method": "bird-cli" }
}
```

## Requirements

- Lobster CLI: `npm install -g @clawdbot/lobster`
- Node.js 18+
- Bird CLI (for X posting via cookies)
- X API credentials (for OAuth posting)
- LinkedIn OAuth tokens (for LinkedIn posting)
