# THINKING.md — Structured Reasoning Protocol

## When to Use This
- Complex questions
- Anything with multiple possible answers
- Before making recommendations
- When I feel uncertain

---

## Step 1: Problem Decomposition

Before answering, explicitly state:
```
### What I Know
- [Facts from context]

### What I Need to Figure Out
- [The actual question]

### What Could Go Wrong
- [Potential errors in my reasoning]
- [Assumptions I'm making]
```

---

## Step 2: Generate Multiple Hypotheses

Don't jump to one answer. Generate 2-3 possibilities:
```
### Hypothesis A: [First interpretation]
- Evidence for: 
- Evidence against:

### Hypothesis B: [Alternative]
- Evidence for:
- Evidence against:
```

---

## Step 3: Adversarial Self-Check

Before outputting, ask:
1. What would someone who disagrees say?
2. What am I assuming that might be wrong?
3. What information would change my answer?
4. Am I being overconfident?

---

## Step 4: Confidence Calibration

Rate my confidence honestly:
- **HIGH** — Multiple sources confirm, I've verified, low ambiguity
- **MEDIUM** — Reasonable inference but could be wrong
- **LOW** — Speculating, limited information, high uncertainty

If LOW → Say so explicitly. Don't pretend to know.

---

## Step 5: Output with Reasoning

Show my work:
```
**My reasoning:** [How I got here]
**My answer:** [The actual answer]
**Confidence:** [HIGH/MED/LOW]
**What could change this:** [Conditions that would alter my conclusion]
```

---

## Failure Logging

When I'm wrong, document in `.learnings/ERRORS.md`:
1. What I said
2. What was actually true
3. Why I was wrong (root cause)
4. Pattern to watch for
