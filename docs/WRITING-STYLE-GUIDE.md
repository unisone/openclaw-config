# Writing Style Guide — Anti-Slop Rules

*Applies to ALL content drafting: X/Twitter, LinkedIn, Instagram captions, any public copy.*
*Last updated: 2026-02-18 | Source: research + Alex directive*

---

## The Problem

AI-generated content has a signature bundle of habits that readers detect instantly — not from one bad word, but from all of them showing up together. Surface polish with nothing underneath. People scroll past it. Algorithms demote it. It kills trust.

## Banned Patterns (hard rules)

### Words & Phrases — Never Use
| Banned | Why |
|--------|-----|
| delve, dive into, unpack | Post-ChatGPT flags — usage up 400%+ since 2022 |
| landscape, realm, ecosystem | Vague filler that means nothing |
| harness, leverage (as verb) | Consultant speak |
| game-changer, groundbreaking | Unearned superlatives |
| streamline, optimize, elevate | Corporate jargon |
| compelling, robust, seamless | RLHF-reward words — raters liked them, humans don't |
| multifaceted, nuanced | Academic filler |
| underscore, underscore the importance | AI tell |
| it's worth noting, importantly | Hedge filler |
| at the end of the day | Cliché closer |
| in today's fast-paced world | The #1 AI opener |
| as AI continues to evolve | Close second |

### Structural Patterns — Kill On Sight
| Pattern | Fix |
|---------|-----|
| Em dashes (—) everywhere | Use periods. Restructure. One per post MAX if natural. |
| "Here's the thing:" / "But here's what most people miss:" | Just say the thing. Drop the windup. |
| "Translation:" bridges | Delete entirely |
| "It's not about X — it's about Y" | Cut the setup, just state Y |
| Snappy triads ("Fast, efficient, reliable") | Pick one. Develop it. |
| Emoji bullet lists (✅ 📊 💡) | Prose or bare line breaks |
| Arrow-led lists (→) | Same — prose or plain dashes |
| Parallel structure on autopilot | Break symmetry. Uneven is human. |
| 3 equal-sized paragraphs | Vary length wildly. Some 1 line, some 4. |
| "In this post, we'll explore…" | Meta-narration. Just say the content. |
| Mid-sentence rhetorical questions ("The solution? It's simpler than you think.") | State the solution. |
| "Something shifted." / "Everything changed." | Unearned profundity. Cut. |
| Bolding random words for emphasis | Bold only if it would survive a copyedit |
| Perfect grammar, zero contractions | Use contractions. Use fragments. Lowercase OK. |

### Cadence Rules
- **Vary sentence length aggressively.** Short. Then a longer one that develops the idea and adds the detail that makes it real. Fragment. Back to medium.
- **No uniform paragraph sizes.** If every paragraph is 3 sentences, rewrite.
- **One idea per post/paragraph.** Don't list-ify. Develop.

## The Target Voice

**Sounds like:** Someone's work log got accidentally published. Specific, opinionated, a little rough. Typed between tasks.

**Does NOT sound like:** A content mill, a LinkedIn influencer, a TED talk, a consultant deck, or a helpful assistant.

### Voice Checklist (every draft must pass)
- [ ] Would a human actually type this between meetings?
- [ ] Is there a specific number, tool name, or failure mode?
- [ ] Is the rhythm irregular (short + long + fragment)?
- [ ] Zero banned words/phrases from the list above?
- [ ] No more than 1 em dash in the whole piece?
- [ ] Does it start mid-thought (not with a setup/windup)?
- [ ] Could you read it aloud without cringing?

## STEPPS Quality Gate (mandatory)

Read: `docs/STEPPS-QUALITY-GATE.md`

- Score every public draft before sending it to Slack.
- **Pass threshold: 40/50 minimum**
- **Hard fail:** any category below 6
- If it fails, rewrite once and rescore before posting.
- Include this line in draft output:
  - `STEPPS_SCORE: X/50 (Sx Tx Ex Px Vx)`

## Context Engineering > Prompt Engineering

The fix isn't "please sound human." The fix is feeding real material:
- **Real numbers** from actual systems (37 crons, 3 failing, 66% success rate)
- **Real tool names** (not "AI tools" — specific: OpenClaw, bird CLI, cron jobs)
- **Real failure modes** (not "challenges" — specific: silent timeout, rate limit cascade)
- **Real opinions** (commit to a take, be wrong if needed, but be something)

## Before/After Examples

### ❌ AI Slop
```
Here's the thing about AI agents in production — most companies are just scratching the surface. 🚀

The landscape is evolving rapidly, and it's worth noting that:
→ Monitoring is essential
→ Fallbacks are crucial  
→ Testing is non-negotiable

Translation: if you're not building robust systems, you're building fragile ones. It's not about having AI — it's about having AI that works.
```

### ✅ Human
```
ran my agent system for a month. 37 cron jobs. finally built a log parser to see what was actually happening.

3 jobs were silently failing. had no idea.
5 more were creeping toward their timeout limits.
the "content" category had a 66% success rate while ops was at 100%.

the model wasn't the problem. I just never looked.
```

### ❌ AI Slop
```
In today's fast-paced AI landscape, AGENTS.md has become a game-changer for developers looking to harness the power of autonomous systems.

Here are 5 compelling reasons to invest in your agent configuration:
1. ✅ Better alignment
2. ✅ Improved reliability  
3. ✅ Enhanced safety
...
```

### ✅ Human
```
your AGENTS.md is probably a horoscope.

"be helpful. be concise. use good judgment."

that's not config. the ones that actually change behavior read like constraints:
- what tools are off-limits
- what's irreversible (needs a human)
- what happens when the agent burns through its budget

less personality, more policy.
```

---

*This guide is referenced by all content-drafting cron jobs and agent configs. Update when patterns shift.*
