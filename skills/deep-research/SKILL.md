---
name: deep-research
description: Multi-step web research with source tracking and cited findings; Don't use for quick single-question lookups (use web_search) or things in local knowledge (use knowledge-base).
metadata:
  {
    "openclaw":
      { "emoji": "🔎", "requires": {} },
  }
---

# deep-research

Structured, multi-step web research for questions that need more than one search.

## Routing

- ❌ Don't use for quick factual lookups ("what's the capital of...") — use `web_search`.
- ❌ Don't use for the user's own data or notes — use `knowledge-base`.
- ✅ Do use when the question needs synthesis across multiple sources, comparison of options, or current information on a fast-moving topic.

## Setup

No API key required — works with the agent's built-in web search and fetch tools.

## Process

### 1. Plan the research

Before searching, write a brief plan:

- **Question** — restate what the user actually wants to know
- **Sub-questions** — break it into 2-5 searchable pieces
- **Source types** — what would settle each sub-question? (official docs, reviews, benchmarks, forum threads, news)

Share the plan if the question is ambiguous; otherwise proceed.

### 2. Search in rounds

Run 2-4 rounds of searches, refining queries based on what each round finds:

- Round 1: broad queries to map the landscape
- Round 2: targeted queries on the most promising leads
- Round 3+: fill gaps, verify contested claims

Track every source consulted: URL, title, and what it contributed.

### 3. Verify contested claims

When sources disagree (prices, dates, specs, "best" rankings):

- Prefer primary sources (official docs, the vendor's own pages) over aggregators
- Check publication dates — stale sources are the #1 cause of wrong research
- If it can't be resolved, say so and present both claims with their sources

### 4. Synthesize with citations

Structure the findings:

```markdown
## <Question>

**Bottom line:** <1-2 sentence answer>

### Findings
- <finding> [source](url)
- ...

### Trade-offs / open questions
- ...

### Sources
1. [title](url) — what it contributed
2. ...
```

Rules:

- **Every factual claim gets a citation.** No citation, no claim.
- **Lead with the answer**, then the evidence. Nobody reads a research dump
  to find the conclusion at the end.
- **Date-stamp time-sensitive findings** ("as of September 2026").
- **Say what you couldn't find.** A gap disclosed beats a gap papered over.

## Quality bar

A good deep-research result:

- Answers the actual question, not a adjacent easier one
- Cites primary sources where they exist
- Acknowledges uncertainty instead of picking a confident-sounding side
- Is skimmable: bottom line first, details on demand
