# Skill Routing Improvements (Shell + Skills + Compaction)
**Date:** 2026-02-12  
**Context:** Sprint to improve OpenClaw skill routing based on OpenAI guidance: https://developers.openai.com/blog/skills-shell-tips

---

## 1) Research Summary

### OpenAI: “Write descriptions like routing logic”
Key takeaways from the OpenAI post:
- Skill *description* is the routing boundary: it should answer **when to use** / **when not to use** / **outputs + success criteria**.
- Add **negative examples** (“Don’t call this skill when…”) to reduce misfires.
- Put templates/examples **inside** skills (cheap when unused).
- For determinism, say explicitly: **“Use the <skill> skill.”**
- Treat **skills + networking** as high risk; design containment.
- Use an artifacts handoff boundary (OpenAI: `/mnt/data`).

### OpenClaw: constraints and best practices (docs.openclaw.ai)
OpenClaw skills are AgentSkills-compatible skill folders loaded from:
- Bundled skills (system) 
- `~/.openclaw/skills` (managed/local)
- `<workspace>/skills` (highest precedence)

Important implementation constraint from OpenClaw docs:
- **SKILL.md YAML frontmatter is parsed as single-line keys.**
  - Keep `description:` as a **single line**.
  - Keep `metadata:` as a **single-line JSON object**.

References:
- https://docs.openclaw.ai/tools/skills
- https://docs.openclaw.ai/tools/skills-config
- https://docs.openclaw.ai/tools/clawhub

### Research limitation
`web_search` could not be used because Brave Search API key is not configured.
Manual action: configure `BRAVE_API_KEY` (see docs: https://docs.openclaw.ai/tools/web).

---

## 2) Audit Summary

### Scope
- **System-installed skills:** 52 (read-only; under `/opt/homebrew/lib/node_modules/openclaw/skills/`)
- **User skill folders:** 3 (editable; under `~/.openclaw/skills/`, one is a symlink)

### Inventory artifacts (full scan)
- `artifacts/reports/skill-inventory-2026-02-12.csv`
- `artifacts/reports/skill-inventory-2026-02-12.md`

### Key routing overlaps (where negative examples matter most)
- **Email:** `gog` (Gmail/Workspace) vs `himalaya` (IMAP/SMTP general)
- **Notes:** `apple-notes` vs `bear-notes` vs `obsidian` vs `notion`
- **Summarization/extraction:** `summarize` skill vs `web_fetch` tool
- **Code execution:** `coding-agent` skill vs direct `exec`
- **iMessage:** `bluebubbles` vs `imsg`

### Findings
- Most skills have a helpful imperative description, but **few contain explicit “Use when / Don’t use when” routing blocks**.
- **Negative examples are effectively absent** across system skills.
- A few skills have ambiguous boundaries in overlapping domains.

---

## 3) Implemented Improvements (Editable / user-owned)

### 3.1 Artifact directory convention
Created local artifact handoff directory (OpenAI `/mnt/data` analogue):
- `artifacts/` with subfolders `reports/`, `code/`, `data/`, `images/`, `temp/`
- `artifacts/README.md` documents the convention and usage.

### 3.2 Workspace documentation update
Updated:
- `AGENTS.md` — now explicitly references the `artifacts/` convention.

### 3.3 User skill description improvements
Updated (frontmatter descriptions kept **single-line** for OpenClaw parser compatibility):
- `~/.openclaw/skills/linearis/SKILL.md`
  - Added explicit **Use when / Don’t use** routing guidance and success criteria to `description:`.
- `~/.openclaw/skills/find-skills` (symlink target: `~/.agents/skills/find-skills/SKILL.md`)
  - Clarified that it targets the **skills.sh / `npx skills` ecosystem**, not ClawHub.
  - Added explicit **Don’t use** guidance (use `clawhub` for OpenClaw-native skills).

### 3.4 Determinism via explicit skill invocation
Updated:
- `HEARTBEAT.md` — added explicit “Use the X skill” directives where appropriate (Slack posting, ClawHub search, GitHub checks).

---

## 4) Recommendations (System skills = upstream only)

These require upstream updates (ClawHub / OpenClaw bundled skills).

### Highest-impact routing fixes
1. **`canvas` skill**: description is empty → add routing description.
2. **Email boundary**: add explicit negatives:
   - `gog`: “Don’t use for non-Gmail accounts → use himalaya.”
   - `himalaya`: “Don’t use for Gmail/Workspace → use gog.”
3. **Notes boundary**: add “Don’t use when…” among `apple-notes`, `bear-notes`, `obsidian`, `notion`.
4. **Summarize vs web_fetch**:
   - `summarize`: “Don’t use for simple HTML extraction → use web_fetch.”
5. **coding-agent vs exec**:
   - `coding-agent`: “Don’t use for simple shell commands → use exec.”

### How to implement within OpenClaw constraints
Because `description:` must be one line, encode routing like:
> description: Do X. Use when A/B/C; Don’t use when D/E (prefer <other skill/tool>). Success: <observable outcome>.

Also add a short **Negative examples** section in the skill body (SKILL.md) where multi-line is fine.

---

## 5) What still needs manual action

- Configure Brave Search (`web_search`) by setting `BRAVE_API_KEY` so future routing research can use web_search extensively.
- Create upstream PR(s) / issues for system skill routing fixes (canvas description + overlap “Don’t use when…” guidance).

---

## Appendix: Related artifacts
- `artifacts/reports/skill-audit-2026-02-12.md` — qualitative overlap + recommendations
- `artifacts/reports/skill-inventory-2026-02-12.csv` — machine-readable scan
