# Model Fallback Strategy

## The Problem: Single-Provider Cascading Failures

When your primary model and all fallbacks are from the same provider, a provider outage takes down your entire agent.

### Real-World Example (Feb 2026)

**Bad configuration (Codex-only):**
```json5
{
  agents: {
    defaults: {
      model: {
        primary: "openai-codex/gpt-5.3-codex",
        fallbacks: ["openai-codex/gpt-5.2"]
      }
    }
  }
}
```

**What happened:**
- OpenAI had a rate-limiting incident
- Primary model failed → tried fallback
- Fallback also failed (same provider)
- Agent became completely unavailable
- No graceful degradation

**Duration:** 4+ hours of downtime because the entire fallback chain was single-provider.

## The Solution: Cross-Provider Fallbacks

Configure fallbacks across multiple providers to ensure at least one remains available during outages.

### Recommended Configuration

```json5
{
  agents: {
    defaults: {
      model: {
        primary: "anthropic/claude-opus-4-5",      // Primary: Anthropic
        fallbacks: [
          "anthropic/claude-sonnet-4-5",           // Fallback 1: Anthropic (cheaper)
          "openai-codex/gpt-5.2"                   // Fallback 2: OpenAI (different provider)
        ]
      }
    }
  }
}
```

**Why this works:**
1. Anthropic outage? Falls back to OpenAI
2. OpenAI outage? Primary Anthropic model still works
3. Rate limit on primary? Tries cheaper Anthropic model first, then OpenAI

### Multi-Provider Strategy

For maximum reliability, consider a three-provider strategy:

```json5
{
  agents: {
    defaults: {
      model: {
        primary: "anthropic/claude-opus-4-5",
        fallbacks: [
          "openai-codex/gpt-5.2",              // Provider 2
          "opencode/kimi-k2.5-free"            // Provider 3 (free tier, always available)
        ]
      }
    }
  }
}
```

**Trade-offs:**
- **Reliability:** 3 providers = very low chance of total outage
- **Cost:** Free tier fallback prevents runaway costs during outages
- **Quality:** Degraded quality on fallback is better than no service

## Subagent Models

Subagents handle parallel, lower-stakes work (research, data gathering, draft generation). They benefit from cheap/fast models with robust fallbacks.

### Recommended Subagent Configuration

```json5
{
  agents: {
    defaults: {
      subagents: {
        model: {
          primary: "opencode/kimi-k2.5-free",      // Free tier for cost control
          fallbacks: [
            "anthropic/claude-sonnet-4-5",         // Fast paid model
            "openai-codex/gpt-5.2"                 // Different provider
          ]
        }
      }
    }
  }
}
```

**Why this works:**
- Free tier primary keeps subagent costs near zero
- Paid fallbacks ensure work doesn't block on free tier limits
- Cross-provider ensures subagents survive outages

## Alias Collisions: Lessons Learned

### The Problem

**Bad configuration:**
```json5
models: {
  "anthropic/claude-opus-4-5": { alias: "opus" },
  "anthropic/claude-opus-4-6": { alias: "opus" }  // COLLISION!
}
```

**What happened:**
- Both models mapped to the same `"opus"` alias
- `/model opus` switched to an unexpected model
- Fallback chains broke because model resolution was ambiguous
- Debugging took hours because the collision wasn't obvious

### The Solution: Unique Aliases

```json5
models: {
  "anthropic/claude-opus-4-5": { alias: "opus" },
  "anthropic/claude-opus-4-6": { alias: "opus46" },  // Unique alias
  "anthropic/claude-sonnet-4-5": { alias: "sonnet" }
}
```

**Best practices:**
- One alias per model
- Version numbers in aliases for clarity (`opus46` = Opus 4.6)
- Document aliases in comments
- Test with `/model <alias>` before committing config

## Testing Your Fallback Chain

### Manual Test

```bash
# Temporarily break your primary model to test fallbacks
# (use a non-existent model ID)
openclaw config set agents.defaults.model.primary "anthropic/invalid-model-test"

# Start a test conversation
openclaw chat

# Should automatically fall back to next model in chain
# Check logs to verify fallback triggered:
openclaw gateway logs | grep "fallback"

# Restore original config
openclaw config set agents.defaults.model.primary "anthropic/claude-opus-4-5"
```

### Automated Test (Future)

```python
# scripts/test_fallback_chain.py (example)
import subprocess
import json

def test_fallbacks():
    """Test that fallback chain works by simulating failures."""
    config = json.loads(subprocess.check_output(["openclaw", "config", "get"]))
    
    primary = config["agents"]["defaults"]["model"]["primary"]
    fallbacks = config["agents"]["defaults"]["model"]["fallbacks"]
    
    print(f"Primary: {primary}")
    print(f"Fallbacks: {fallbacks}")
    
    # Extract providers
    providers = [m.split("/")[0] for m in [primary] + fallbacks]
    unique_providers = set(providers)
    
    if len(unique_providers) == 1:
        print("❌ FAIL: All models use the same provider!")
        print(f"   Provider: {providers[0]}")
        print("   Recommendation: Add fallbacks from different providers")
        return False
    
    print(f"✅ PASS: Using {len(unique_providers)} providers:")
    for provider in unique_providers:
        print(f"   - {provider}")
    
    return True

if __name__ == "__main__":
    test_fallbacks()
```

## Cost Management

Cross-provider fallbacks can increase costs during outages. Mitigate this with:

### 1. Free Tier Fallbacks

```json5
fallbacks: [
  "anthropic/claude-sonnet-4-5",    // Paid model (try first)
  "opencode/kimi-k2.5-free"         // Free model (last resort)
]
```

### 2. Rate Limiting

```json5
{
  agents: {
    defaults: {
      rateLimit: {
        requests: 100,
        windowSeconds: 60
      }
    }
  }
}
```

### 3. Fallback Budgets

```json5
{
  agents: {
    defaults: {
      model: {
        primary: "anthropic/claude-opus-4-5",
        fallbacks: [
          { 
            model: "openai-codex/gpt-5.2",
            maxCostPerDay: 50.00  // Stop using this fallback after $50/day
          }
        ]
      }
    }
  }
}
```

*(Note: `maxCostPerDay` is a hypothetical feature — check OpenClaw docs for actual budget controls)*

## Monitoring Fallback Health

### Check Recent Fallback Usage

```bash
# View recent model usage
openclaw stats --models --last 24h

# Look for fallback activations in logs
openclaw gateway logs | grep -i "fallback"
```

### Alert on Excessive Fallbacks

If your primary model is constantly failing and triggering fallbacks, you likely have a misconfiguration or need to switch providers.

**Red flags:**
- >10% of requests use fallbacks
- Same fallback triggered repeatedly (provider-wide outage)
- Fallback chain exhausted (all models failed)

## Summary

### ✅ Do This
- Use fallbacks from **multiple providers**
- Test your fallback chain before production
- Use free-tier models as last-resort fallbacks
- Keep aliases unique and documented

### ❌ Don't Do This
- Single-provider fallback chains
- Reusing the same alias for multiple models
- No fallbacks at all
- Expensive models without budget controls

### Example Production Config

See [config/model-aliases-and-fallbacks.json5](../config/model-aliases-and-fallbacks.json5) for a complete, production-tested configuration.

## See Also

- [OpenClaw Model Configuration Docs](https://github.com/openclaw/openclaw/blob/main/docs/models.md)
- [Provider Status Pages](https://status.anthropic.com, https://status.openai.com)
- [config/model-aliases-and-fallbacks.json5](../config/model-aliases-and-fallbacks.json5)
