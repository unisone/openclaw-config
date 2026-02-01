# Context Overflow Prevention - Comprehensive Findings

## Executive Summary

Context overflow errors are a critical issue in Clawdbot/Moltbot sessions that perform heavy tool use. The 200K token context window fills rapidly with large tool results, causing sessions to fail with "Context overflow: prompt too large for the model" errors that leak into Discord.

Based on comprehensive research of GitHub issues, documentation, and recent fixes, this document provides:
- Root cause analysis
- All available configuration options
- Community workarounds and upstream fixes
- Recommended configuration changes
- Architecture patterns for prevention

## Root Causes Identified

### 1. Gateway Tool Schema Bloat (Primary Cause)
**Issue #2254/#1808**: The gateway tool returns massive JSON responses (396KB+ per call) containing the entire Clawdbot configuration schema. These are stored in session `.jsonl` files and never pruned.

**Naming note (Jan 2026):** Clawdbot → Moltbot → OpenClaw. If you see old paths in this doc, translate to OpenClaw equivalents.

**Evidence**:
- Sessions with only 35 Telegram messages grow to 2.9MB
- Single gateway tool result: 396,263 characters
- Session files hitting 208,467 tokens (exceeding 200K limit)

### 2. Compaction Failure Loop
**Issue #3154**: When context overflow occurs, auto-compaction itself fails because the prompt is already too large for summarization.

**Error Pattern**:
```
Auto-compaction failed: Context overflow: Summarization failed: 400
{"message":"prompt is too long: 208467 tokens > 200000 maximum"}
```

### 3. Tool Result Accumulation
Long-running sessions accumulate large tool outputs (browser snapshots, exec results, file reads) faster than pruning can handle.

### 4. Ineffective Context Pruning
Current `contextPruning` mode `cache-ttl` not working properly in recent versions (2026.1.14-1), despite documentation claiming it's default.

## Current Configuration Analysis

### What's Already Done (Good)
- `reserveTokensFloor: 60000` - Good safety margin
- `softThresholdTokens: 4000` - Reasonable flush trigger
- `contextPruning: cache-ttl mode, 3m TTL, tool-targeted` - Correctly configured
- `softTrim: 3000 chars, hardClear enabled` - Appropriate truncation
- `keepLastAssistants: 2` - Minimal recent context preservation

### Missing/Insufficient
- **No per-tool output limits** - Tools can still return massive payloads
- **No proactive session splitting** - Heavy tasks continue in main session
- **No emergency recovery** - When compaction fails, session dies

## Available Configuration Options

### 1. Compaction Settings
```json
{
  "agents": {
    "defaults": {
      "compaction": {
        "mode": "safeguard",
        "memoryFlush": {
          "enabled": true,
          "softThresholdTokens": 4000,
          "prompt": "Write important session state to memory files before compaction",
          "systemPrompt": "NO_REPLY - Save critical context to disk"
        }
      }
    }
  }
}
```

### 2. Session Pruning (Enhanced)
```json
{
  "agents": {
    "defaults": {
      "contextPruning": {
        "mode": "cache-ttl",
        "ttl": "3m",
        "keepLastAssistants": 2,
        "softTrimRatio": 0.3,
        "hardClearRatio": 0.5,
        "minPrunableToolChars": 20000,
        "softTrim": {
          "maxChars": 2000,
          "headChars": 750,
          "tailChars": 750
        },
        "hardClear": {
          "enabled": true,
          "placeholder": "[Large tool result cleared - available in session history]"
        },
        "tools": {
          "allow": ["exec", "Read", "web_fetch", "browser", "web_search"],
          "deny": ["*image*"]
        }
      }
    }
  }
}
```

### 3. Context Window Overrides
```json
{
  "agents": {
    "defaults": {
      "contextTokens": 180000
    }
  },
  "models": {
    "providers": {
      "anthropic": {
        "models": [{
          "id": "claude-opus-4-5",
          "contextWindow": 180000,
          "maxTokens": 8192
        }]
      }
    }
  }
}
```

### 4. Enhanced Reserve Tokens
```json
{
  "compaction": {
    "enabled": true,
    "reserveTokens": 80000,
    "keepRecentTokens": 15000
  }
}
```

## Upstream Fixes Found

### 1. Auto-Compact on Overflow (Fixed in 2026.1.24)
**PR #1627**: "Agents: auto-compact on context overflow prompt errors before failing."

This addresses the compaction failure loop by attempting compaction before complete failure.

### 2. Context Usage Visibility (Requested)
**Issue #2597**: Proposes adding `context=X%` to Runtime line so agents can proactively manage state.

### 3. Session Recovery Mechanism (Proposed)
**Issue #3154**: Suggests automatic session truncation when overflow occurs.

## Community Workarounds

### 1. Manual Session Management
```bash
# Backup corrupted session
mv ~/.openclaw/agents/main/sessions/SESSION_ID.jsonl SESSION_ID.jsonl.overflow-backup  # (legacy: ~/.clawdbot/agents/...)

# Gateway creates fresh session on next message
```

### 2. Gateway Tool Result Limiting
Users report manually editing gateway tool responses to exclude large schema data.

### 3. Frequent Manual Compaction
Using `/compact` command before sessions grow too large.

## Recommended Additional Changes

### 1. Immediate Fixes

#### A. Reduce Gateway Tool Verbosity
```json
{
  "tools": {
    "gateway": {
      "maxSchemaDepth": 2,
      "excludeSchemaExamples": true,
      "compactResponses": true
    }
  }
}
```

#### B. Aggressive Tool Result Limits
```json
{
  "agents": {
    "defaults": {
      "contextPruning": {
        "mode": "cache-ttl",
        "ttl": "2m",
        "softTrim": {
          "maxChars": 1500,
          "headChars": 500,
          "tailChars": 500
        },
        "minPrunableToolChars": 10000,
        "hardClearRatio": 0.3
      }
    }
  }
}
```

#### C. Proactive Compaction
```json
{
  "agents": {
    "defaults": {
      "compaction": {
        "mode": "safeguard",
        "memoryFlush": {
          "enabled": true,
          "softThresholdTokens": 2000
        }
      }
    }
  },
  "compaction": {
    "reserveTokens": 100000,
    "keepRecentTokens": 10000
  }
}
```

### 2. Architecture Patterns for Prevention

#### A. Sub-Agent Spawning for Heavy Tasks
```javascript
// Detect heavy operations
if (contextUsage > 60) {
  // Spawn sub-agent for browser automation
  const subAgent = await spawnAgent({
    type: 'browser-automation',
    task: 'web-scraping',
    maxTokens: 50000
  });
  
  // Return summary to main session
  return subAgent.getSummary();
}
```

#### B. Task-Specific Session Routing
```json
{
  "agents": {
    "list": [
      {
        "id": "main",
        "workspace": "~/clawd",
        "maxContextTokens": 100000
      },
      {
        "id": "browser-heavy",
        "workspace": "~/clawd/browser-sessions",
        "contextPruning": {
          "mode": "cache-ttl",
          "ttl": "1m"
        }
      },
      {
        "id": "exec-heavy",
        "workspace": "~/clawd/exec-sessions",
        "contextPruning": {
          "mode": "cache-ttl",
          "ttl": "30s"
        }
      }
    ]
  },
  "bindings": [
    {
      "match": { "toolPattern": "browser*" },
      "route": { "agent": "browser-heavy" }
    },
    {
      "match": { "toolPattern": "exec*" },
      "route": { "agent": "exec-heavy" }
    }
  ]
}
```

#### C. Automatic Session Splitting
```json
{
  "agents": {
    "defaults": {
      "sessionLimits": {
        "maxTokens": 150000,
        "autoSplit": true,
        "splitStrategy": "preserve-recent",
        "preserveMessages": 10
      }
    }
  }
}
```

### 3. Per-Tool Output Limits

#### A. Browser Tool Limits
```json
{
  "tools": {
    "browser": {
      "maxSnapshotSize": 20000,
      "compressOutput": true,
      "screenshotMode": "thumbnail"
    }
  }
}
```

#### B. Exec Tool Limits
```json
{
  "tools": {
    "exec": {
      "maxOutputSize": 10000,
      "truncateMode": "tail",
      "compressRepeatedLines": true
    }
  }
}
```

#### C. Web Fetch Limits
```json
{
  "tools": {
    "web_fetch": {
      "maxChars": 15000,
      "extractMode": "text",
      "aggressiveTruncation": true
    }
  }
}
```

## Implementation Priority

### Phase 1: Immediate (Deploy Today)
1. Reduce gateway tool verbosity
2. More aggressive context pruning (2m TTL, smaller soft trim)
3. Increase reserve tokens to 100K
4. Enable proactive memory flush at 2K soft threshold

### Phase 2: Short-term (This Week)
1. Implement per-tool output limits
2. Add automatic session splitting for heavy tasks
3. Create dedicated sub-agents for browser/exec work

### Phase 3: Long-term (Monitor & Iterate)
1. Context usage percentage in Runtime line
2. Intelligent task routing based on operation type
3. Predictive session splitting based on tool usage patterns

## Monitoring & Alerts

### Key Metrics to Track
- Session file sizes (alert >500KB)
- Context token usage (alert >150K)
- Compaction failure rates
- Tool result sizes by type

### Recommended Monitoring
```json
{
  "monitoring": {
    "sessionSizeAlerts": {
      "warningThresholdMB": 0.5,
      "criticalThresholdMB": 1.0
    },
    "contextUsageAlerts": {
      "warningThresholdTokens": 150000,
      "criticalThresholdTokens": 180000
    },
    "compactionFailureAlerts": true,
    "toolResultSizeTracking": {
      "enabled": true,
      "alertThresholdChars": 50000
    }
  }
}
```

## Conclusion

Context overflow is solvable through a combination of:
1. **Aggressive pruning** - Shorter TTL, smaller limits
2. **Proactive compaction** - Earlier triggers, better reserve margins  
3. **Tool result limits** - Prevent large payloads from entering context
4. **Session architecture** - Split heavy work into sub-agents
5. **Gateway optimization** - Reduce schema verbosity

The upcoming 2026.1.24+ releases include critical fixes for auto-compaction on overflow. Combined with the recommended configuration changes, this should eliminate most context overflow scenarios while maintaining functionality.

**Next Steps**: Deploy Phase 1 changes immediately, monitor metrics, and iterate based on real-world usage patterns.