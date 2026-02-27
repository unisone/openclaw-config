# Model Change Rules — MANDATORY CHECKLIST

## The Thinking Block Signature Problem
Anthropic thinking blocks contain cryptographic signatures tied to the SPECIFIC model that generated them. A thinking block from Opus 4-6 CANNOT be validated by Sonnet 4-5 (or any other model). Sending session history with mismatched thinking signatures causes:
```
LLM request rejected: messages.X.content.Y: Invalid `signature` in `thinking` block
```

## BEFORE Changing Any Model

### ✅ Pre-Change Checklist
1. **Identify all contexts where the model runs** — primary, heartbeat, fallback, subagent, cron jobs
2. **Check if thinking is enabled** (`thinkingDefault`, per-job `thinking` settings)
3. **If thinking is ON: the new model MUST match the primary model family** for any context that shares sessions (heartbeat, main session fallbacks)
4. **Isolated sessions (cron, subagents) can use different models** — they start fresh each run

### ✅ Session Impact
- **Same-session contexts** (heartbeat + primary): MUST use same Anthropic model
- **Fallback chain**: Put non-Anthropic models (OpenAI, OpenCode) BEFORE Anthropic alternatives
- **After model change**: Compact or reset any session that has thinking blocks from the OLD model

### ✅ Post-Change Verification
1. Check logs for "Invalid signature" errors within 1 hour
2. Verify heartbeat completes successfully
3. Verify all Slack channels respond to messages

## NEVER DO
- ❌ Change heartbeat model to a different Anthropic model than primary
- ❌ Put a different Anthropic model as first fallback when thinking is enabled
- ❌ Change models without checking for active sessions with thinking blocks
- ❌ Assume `includeReasoning: false` strips OLD thinking blocks from history (it only prevents NEW ones)

## Safe Configurations
```
Primary: anthropic/claude-opus-4-6 (thinking: high)
Heartbeat: anthropic/claude-opus-4-6 (same model!)
Fallbacks: [openai-codex/X, openai-codex/Y, anthropic/sonnet, opencode/kimi]
           (non-Anthropic first!)
Subagents: anthropic/claude-sonnet-4-5 (OK - isolated sessions)
Cron jobs: anthropic/claude-sonnet-4-5 (OK - isolated sessions)
```

*Created: 2026-02-19 after 22+ "Invalid signature" errors over 2 days*
