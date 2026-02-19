# 🎖️ Elite Agent Army

A collection of specialized expert agents for OpenClaw. Each agent is researched, optimized, and ready to deploy for specific tasks.

(Naming note: some older posts may use legacy names.)

## The Roster

| Agent | File | Specialty |
|-------|------|-----------|
| 🔬 | `market-researcher.md` | Intel-powered market analysis, gaps, competitors, sentiment |
| 🏗️ | `architect.md` | System design, ADRs, architecture reviews, anti-patterns |
| 🔬 | `deep-researcher.md` | PhD-level research, citations, SIFT/CRAAP methodology |
| 😈 | `devils-advocate.md` | Pre-mortems, red team, stress-testing ideas |
| 🔒 | `security-auditor.md` | OWASP Top 10, secrets detection, vulnerability scanning |
| 📋 | `project-planner.md` | WBS decomposition, estimation, dependencies |
| ✍️ | `content-writer.md` | Stripe/Linear-quality technical writing |
| 🎨 | `ux-designer.md` | Modern UI/UX, Linear/Vercel aesthetics, accessibility |

## Usage

Each agent config includes:
- **Identity & Expertise** — Specialized persona
- **System Prompt** — Copy-paste ready
- **Methodology** — How they approach problems
- **Output Formats** — Templates for deliverables
- **Spawn Commands** — Ready-to-use examples

### Example: Spawn a Security Audit

```typescript
sessions_spawn({
  task: `Security Audit: [PROJECT]
  
  Read ~/openclaw-workspace/agents/security-auditor.md for methodology.
  
  Run full security audit on [path/to/project].
  Focus on: secrets, auth, injection, dependencies.
  
  Output: ~/openclaw-workspace/research/[project]-security-audit.md`,
  label: "security-audit",
  agentId: "main"
})
```

## Philosophy

These aren't generic agents — each one is researched and configured to be **best-in-class** for their domain:

- Market Researcher uses `/intel` skill patterns
- Architect follows Martin Fowler's evolutionary architecture
- Deep Researcher uses SIFT + CRAAP source evaluation
- Devil's Advocate employs US Army Red Team methodology
- Security Auditor covers OWASP + CWE Top 25
- Content Writer has Stripe/Linear voice baked in
- UX Designer passes "The Linear Test"

## Adding New Agents

1. Research best practices for the domain
2. Find relevant skills to integrate
3. Create specialized system prompt
4. Define output format templates
5. Add ready-to-use spawn commands
6. Save to this repo

---

*Built with OpenClaw — 2026*
