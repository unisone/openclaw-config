#!/bin/bash
# Council of the Wise - Multi-perspective analysis
# Usage: council.sh "decision/idea to analyze"

cat << 'EOF'
=== COUNCIL OF THE WISE TEMPLATE ===

For major decisions, spawn 3-4 sub-agents with different perspectives:

## Perspective 1: The Skeptic
{
  "task": "SKEPTIC ANALYSIS\n\nAnalyze this decision/idea as a skeptic. Your job is to find flaws:\n\n[DECISION]\n\n1. What could go wrong?\n2. What are we assuming that might be false?\n3. What are the hidden costs?\n4. Who would disagree and why?\n5. What's the worst case scenario?\n\nBe harsh but constructive.",
  "model": "opencode/kimi-k2.5-free",
  "thinking": "high"
}

## Perspective 2: The Advocate  
{
  "task": "ADVOCATE ANALYSIS\n\nAnalyze this decision/idea as an advocate. Your job is to strengthen it:\n\n[DECISION]\n\n1. What are the strongest arguments FOR this?\n2. What opportunities does it unlock?\n3. How could we make it even better?\n4. What similar things have succeeded?\n5. What's the best case scenario?\n\nBe optimistic but grounded.",
  "model": "opencode/kimi-k2.5-free", 
  "thinking": "high"
}

## Perspective 3: The Pragmatist
{
  "task": "PRAGMATIST ANALYSIS\n\nAnalyze this decision/idea as a pragmatist. Focus on execution:\n\n[DECISION]\n\n1. What's the minimum viable version?\n2. What are the concrete next steps?\n3. What resources do we actually have?\n4. What's the timeline look like?\n5. What's the 80/20 here?\n\nBe practical and specific.",
  "model": "opencode/kimi-k2.5-free",
  "thinking": "high"
}

## Perspective 4: The Historian (optional)
{
  "task": "HISTORIAN ANALYSIS\n\nAnalyze this decision/idea through precedent:\n\n[DECISION]\n\n1. What similar decisions have been made before?\n2. What worked and what didn't?\n3. What patterns from history apply?\n4. What would experts in this domain say?\n5. What lessons should we carry forward?\n\nBe informed and contextual.",
  "model": "opencode/kimi-k2.5-free",
  "thinking": "high"
}

=== After all perspectives, synthesize ===

Read all 3-4 responses and create:
1. **Consensus points** — What do all perspectives agree on?
2. **Key tensions** — Where do they disagree?
3. **Synthesis** — Integrated recommendation
4. **Risk-adjusted decision** — Final call with mitigations

=== END TEMPLATE ===
EOF
