---
name: executive-summary-generator
description: Generate concise executive summaries for BI findings. Use when packaging analysis results, dashboard findings, recommendations, risks, or decision asks for leaders.
---

# Executive Summary Generator

Used in the assay lifecycle at: Stage 9 (shared)

## Quick Start

Create a short, decision-first summary. Lead with what changed, why it matters, what evidence supports it, and what decision is needed. Quantify (use numbers) when possible and define technical terms inline.

## Context Requirements

1. **Analysis results**: findings, metrics, evidence, validation status, and limitations.
2. **Audience**: executive role, knowledge level, and decision authority.
3. **Decision needed**: approve, choose, fund, stop, monitor, or escalate.
4. **Format**: email, slide, memo, dashboard note, or board update.
5. **Length**: one paragraph, one page, or structured bullets.

## Context Gathering

"To write the summary, please provide:
- The main finding in plain language.
- The metric (number stakeholders act on) and how much it changed.
- Why the change matters to money, headcount, strategy, customers, or operations.
- Validation status: source-of-truth (official system for the number) tie-out, QA checks, or remaining caveats.
- The decision or action you want from the audience.
- Required format and length."

If results are incomplete, ask what can safely be said now and what must be held until validation.

## Workflow

### Step 1: Extract Core Message

Identify:
- Situation: what triggered the analysis.
- Finding: the most decision-relevant answer.
- Evidence: the smallest number of facts needed to support it.
- Consequence: what happens if leaders act or do nothing.
- Ask: the decision, owner, and timing.

Do not bury the decision under process detail.

### Step 2: Apply Pyramid Principle

Pyramid Principle means answer first, proof points after.

Use this order:
1. Answer first.
2. Three support points at most.
3. Recommendation or decision needed.
4. Caveats that could change the decision.

Frame with consequences:
- "Approve the rollout because expected lift exceeds the threshold."
- "Do not act yet because the result has not passed validation."

### Step 3: Quantify Everything

Use numbers where they make the decision clearer:
- Absolute change and percent change.
- Baseline (normal comparison point).
- Date range.
- Population size or sample size (number of records).
- Confidence interval (likely range for true value), if relevant.
- Business impact estimate and assumptions.

If a number is not validated, label it clearly.

## Context Validation

Before finalizing:

- [ ] The first sentence states the answer or decision.
- [ ] Every number has a date range and source.
- [ ] Technical terms are defined inline.
- [ ] Caveats are decision-relevant, not generic.
- [ ] The ask is clear and owned.
- [ ] The summary does not imply validation that has not happened.

## Output Template

```markdown
Executive Summary
Generated: [timestamp]

## Headline
[One-sentence answer or decision ask]

## Situation
[What prompted the analysis and why it matters]

## Key Insights
1. **[Insight]**: [Number/evidence] - [Business consequence]
2. **[Insight]**: [Number/evidence] - [Business consequence]
3. **[Insight]**: [Number/evidence] - [Business consequence]

## Recommendation
[Action to take, owner, timing, and expected outcome]

## Decision Needed
[Approve / choose / fund / stop / monitor / escalate]

## Confidence and Caveats
- Validation status:
- Source-of-truth:
- Limitation that could change action:

## Next Steps
1. [Owner] - [Action] - [Date]
2. [Owner] - [Action] - [Date]
```

## Common Scenarios

### Scenario 1: "Condense 30-page analysis for board deck"
Use a headline, three proof points, decision ask, and caveat box.

### Scenario 2: "Weekly executive briefing"
Use changes since last period, risks, decisions needed, and owner list.

### Scenario 3: "Ad-hoc exec question"
Answer directly, include source and date range, then caveat if the data is preliminary.

### Scenario 4: "Monthly business review"
Tie metrics to targets, explain drivers, and call out decisions.

## Handling Missing Context

If the decision is missing, ask for it before drafting. If validation is missing, write a preliminary summary label and state what must be checked before sharing.

## Advanced Options

- Board-ready one-pager.
- Email-ready executive note.
- Slide headline rewrite.
- Decision memo with options and consequences.
- Risk-focused summary for high-stakes results.
