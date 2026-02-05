# Diagnosis Protocol

Before recommending workarounds for resource limits, tool failures, or missing capabilities:

## The 3-Step Check

1. **Check what's configured** — Read the actual config first
2. **Ask "is there a better tool available?"** — Don't patch around problems when the solution already exists
3. **Verify claims before making them** — Don't assume, check

## Anti-Patterns

### ❌ Wrong: Jump to workarounds
```
User: Web search is slow
Agent: "Add delays between requests to avoid rate limits"
```

### ✅ Right: Diagnose first
```
User: Web search is slow
Agent: *checks config* → sees Brave free tier → notes Perplexity is configured
Agent: "You have Perplexity configured but using Brave. Perplexity has no rate limits with your paid key. Switching..."
```

## Real Example

We hit 435 Brave rate limit errors in one day. The "obvious" fix was adding delays between requests. But:

1. **Check config** → Found Perplexity API key was already configured
2. **Better tool available?** → Yes, Perplexity has no rate limits with paid subscription
3. **Verify** → Confirmed key was valid

Fix: One config change from `provider: "brave"` to `provider: "perplexity"`. No workarounds needed.

## When This Applies

- Rate limiting issues → Check if paid tier is available
- Memory loss → Check if memory plugin is enabled/configured
- Tool failures → Check if alternative tools exist
- Permission errors → Check if elevated exec is configured
- Slow responses → Check model config, fallbacks, thinking level

## The Mindset

**Don't fight the framework.** OpenClaw probably has a solution. Check docs, config, and source before inventing workarounds.
