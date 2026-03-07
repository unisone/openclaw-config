# Agent Architecture v2 — Migration Complete

*Migrated: 2026-03-01 18:48 EST*

## Final Cron Job Distribution

| Agent | Before | After | Delta |
|-------|--------|-------|-------|
| main | 23 | 7 | -16 |
| dan-content (NEW) | 0 | 7 | +7 |
| dan-ops | 5 | 14 | +9 |
| dan-twitter | 6 | 6 | 0 |
| dan-insta | 5 | 5 | 0 |
| **Total** | **39** | **39** | **0** |

## What Changed
1. Created `dan-content` agent — content strategy coordinator
2. Moved 7 content jobs from main → dan-content
3. Moved 9 infra jobs from main → dan-ops
4. Upgraded all 8 AGENT.md files with identity, KPIs, constraints, escalation rules
5. Created inter-agent output directories (agents/{content,twitter,instagram,ops}/output/)
6. Documented architecture in docs/AGENT-ARCHITECTURE-V2.md

## main Now Owns (7 jobs)
- daily-briefing, nightly-consolidation, weekly-release-reminder
- agi-self-improvement, weekly-memory-prune
- linkedin-token-expiry-warning, poly-market-scan

## Idle Agents (spawn-only, now with proper profiles)
- dan-coder: Software engineer with coding standards
- dan-research: Deep research specialist
- writer: Long-form writer on Opus 4.6
