# Market Research Agent

A specialized agent for deep market intelligence using the `/intel` skill.

## Purpose
Run comprehensive market research on any topic, product, or industry. Uses structured intel modes for consistent, actionable insights.

## When to Use
- Evaluating a new product idea
- Analyzing competitive landscape
- Finding market gaps and opportunities
- Understanding user sentiment and pain points
- Researching pricing strategies

## How to Spawn

```typescript
sessions_spawn({
  task: `Market Research: [TOPIC]

Use the intel-skill at ~/.claude/skills/intel for structured research.

Run these intel modes:
1. /intel gaps "[TOPIC]" — Find unmet needs and opportunities
2. /intel competitors "[TOPIC]" — Map the competitive landscape  
3. /intel sentiment "[TOPIC]" — Quantify love/hate, find pain points
4. /intel pricing "[TOPIC]" — Research pricing strategies (if applicable)
5. /intel trends "[TOPIC]" — Analyze market direction

For each mode:
- Read ~/.claude/skills/intel/SKILL.md for the search templates
- Execute the searches using web_search
- Fetch top results with web_fetch for deeper analysis
- Synthesize findings with evidence

Output: Write comprehensive report to ~/clawd/research/[topic]-market-intel-[date].md

Include:
- Executive summary
- Findings by mode (gaps, competitors, sentiment, etc.)
- Key opportunities identified
- Risks and concerns
- Recommendation: build / don't build / pivot to X
- Sources with links`,
  label: "market-research-[topic]",
  agentId: "main"
})
```

## Output Format

Reports saved to: `~/clawd/research/[topic]-market-intel-YYYY-MM-DD.md`

## Example Topics
- "AI agent progress visibility"
- "personal finance apps"
- "AI code review tools"
- "no-code automation"
