#!/bin/bash
# AGI Verification Template - Spawns a verification sub-agent
# Usage: verify.sh "output to verify" "verification criteria"

cat << 'EOF'
=== VERIFICATION SUB-AGENT TEMPLATE ===

Use sessions_spawn with this task format:

{
  "task": "VERIFICATION TASK

Review the following output for errors, inconsistencies, and quality issues:

---
[PASTE OUTPUT TO VERIFY]
---

## Verification Checklist
1. **Factual accuracy** — Are all claims verifiable?
2. **Completeness** — Does it address all requirements?
3. **Consistency** — No internal contradictions?
4. **Quality** — Meets professional standards?
5. **Risk check** — Any potential issues if published/deployed?

## Output Format
VERDICT: PASS | FAIL | NEEDS_REVISION

If FAIL or NEEDS_REVISION:
- Issue 1: [description]
- Issue 2: [description]
- Suggested fixes: [specific changes]

If PASS:
- Confidence: HIGH | MEDIUM
- Notes: [any observations]
",
  "model": "opencode/kimi-k2.5-free",
  "thinking": "high",
  "cleanup": "delete"
}

=== END TEMPLATE ===
EOF
