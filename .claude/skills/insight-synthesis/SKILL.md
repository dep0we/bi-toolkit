---
name: insight-synthesis
description: Turn analysis findings into clear, actionable insights tied to business decisions. Use when converting results, patterns, anomalies, or statistical findings into stakeholder-ready conclusions and recommendations.
---

# Insight Synthesis

Used in the assay lifecycle at: Stage 9 (shared)

## Quick Start

Convert raw results into clear insights that explain what happened, why it matters, what action it supports, and how sure we are.

## Context Requirements

Collect:

1. **Analysis findings**: Metrics, patterns, trends, anomalies, and test results.
2. **Business context**: Goals, priorities, constraints, and current decisions.
3. **Audience**: Who will act and what they need to decide.
4. **Decision framework**: The choices the findings should inform.
5. **Constraints**: Limits, caveats, and confidence (how sure evidence supports answer).

## Context Gathering

### For Findings

"Share the analysis results: key metrics, trends, comparisons, anomalies, and any test results. If you mention statistical significance (unlikely to be random noise), include the practical size of the effect too."

### For Business Context

"What business goal or risk does this analysis connect to? I need this so the insight explains consequence, not just movement in a number."

### For Audience

"Who will act on this: executives, product, marketing, operations, finance, or a mixed group? I will tune the framing to the decision they control."

### For Decision Framework

"What decision should this support: approve, pause, prioritize, investigate, invest, or change a process?"

## Workflow

### Step 1: Structure Findings

For each finding, capture:
- Finding type: trend, comparison, correlation (things moving together), anomaly, or test result.
- Metric affected.
- Value or size of the change.
- Time period and segment.
- Evidence source.
- Confidence (how sure evidence supports answer).

### Step 2: Connect to Business Impact

For each finding, answer:
- **So what?** What business result is affected?
- **Why might this be happening?** State as a hypothesis (possible explanation to test) unless proven.
- **Now what?** What action or decision follows?

Avoid insight claims that only restate a metric. Every insight must name a consequence.

### Step 3: Apply the Insight Framework

Use this structure:
1. **Finding**: What the data shows.
2. **Meaning**: Why it matters to the business.
3. **Action**: What the audience can do.
4. **Expected outcome**: What should change if action works.
5. **Confidence**: How sure the evidence is.

### Step 4: Prioritize Insights

Rank by:
- Business impact.
- Urgency.
- Confidence.
- Actionability.
- Risk of doing nothing.

When impact and confidence conflict, say the consequence. Example: "High impact but low confidence means investigate before acting."

### Step 5: Generate Executive Summary

Write a short summary that:
- Leads with the decision consequence.
- Includes the top 3-5 insights.
- States what should happen next.
- Names limitations plainly.

## Context Validation

Before presenting:
- [ ] Findings are factually accurate.
- [ ] Business impact is realistic.
- [ ] Recommendations are actionable.
- [ ] Confidence levels are honest.
- [ ] The audience and decision are explicit.

## Output Template

```markdown
# Key Insights: [analysis name]

## Bottom Line
[One to three sentences: what changed, why it matters, and what decision follows.]

## Insight 1: [plain-language title]

**Finding:** [what the data shows]

**So What:** [business consequence]

**Why:** [possible cause; label as hypothesis if not proven]

**Now What:** [recommended action]

**Expected Outcome:** [measurable result]

**Confidence (how sure evidence supports answer):** [low/medium/high and why]

## Other Priority Insights
1. [finding] - [consequence] - [action]
2. [finding] - [consequence] - [action]
3. [finding] - [consequence] - [action]

## Limitations
- [what the analysis cannot prove]
- [what validation would improve confidence]

## Next Steps
1. [action owner or follow-up]
2. [validation or monitoring step]
```

## Common Scenarios

**Turn analysis into an executive summary**: Extract the top 3-5 insights, lead with business consequence, and keep details in an appendix.

**Explain why stakeholders should care**: Connect metrics to goals, dollars, customers, time, or risk.

**Too many findings**: Group related findings, prioritize by consequence, and move low-impact items to appendix.

**Findings conflict**: State what is known, what is uncertain, and what validation would decide between explanations.

## Advanced Options

- **Insight scoring**: Weight impact, confidence, and actionability.
- **Insight library**: Save recurring insight patterns.
- **Outcome tracking**: Track whether an insight led to action and results.
