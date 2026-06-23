---
name: analysis-assumptions-log
description: Track assumptions, methodology decisions, alternatives, validation plans, and risk for analytical work. Use when documenting trade-offs, building an audit trail, or preparing Stage 2 and Stage 11 assay receipts.
---

# Analysis Assumptions Log

Used in the assay lifecycle at: Stage 2 (shared spec) and Stage 11 (shared documentation)

## Quick Start

Document every meaningful assumption, decision, and trade-off in the analysis. An assumption is something treated as true without full proof. A decision is a choice made among possible methods or definitions. The log makes the work reproducible and shows which choices could change the result.

## Context Requirements

Before logging assumptions, collect:

1. **Analysis context**: objective, stakeholder, and decision being informed.
2. **Assumptions made**: explicit and hidden assumptions.
3. **Decision points**: where choices were made.
4. **Rationale**: why each assumption or decision was accepted.
5. **Impact assessment**: what changes if it is wrong.
6. **Validation plan**: how important assumptions will be checked.

## Context Gathering

### For Analysis Context

"What analysis are we documenting?

- Objective.
- Stakeholders.
- Decision being informed.
- Timeline.
- Stakes: money, headcount, customer impact, strategy, or routine reporting."

### For Assumptions

"Let's list assumptions by category:

- Data assumptions: completeness, missing values, sample coverage, outliers.
- Business logic assumptions: metric definitions, segments, time windows.
- Statistical assumptions: distribution (shape of values), independence (records do not influence each other), stationarity (pattern stays broadly stable).
- Technical assumptions: data freshness, pipeline limits, processing constraints."

### For Decision Points

"Where did we make a choice that could change the result?

- Include or exclude data.
- Choose a metric definition.
- Handle missing values.
- Set thresholds.
- Pick a method.
- Define segments.
- Choose the time period.

For each choice, document the alternative not chosen and the consequence."

### For Impact

"What happens if this assumption is wrong?

- Best case.
- Most likely case.
- Worst case.
- Cost to validate.
- Cost if wrong.

This tells us which assumptions must be validated before delivery."

## Workflow

### Step 1: Create the Log Structure

For each assumption, capture:

- ID.
- Category.
- Assumption.
- Rationale.
- Confidence (how sure we are).
- Impact if wrong.
- Validation plan.
- Status.

For each decision, capture:

- Decision point.
- Chosen option.
- Alternatives considered.
- Rationale.
- Trade-offs.
- Consequence for the result.

### Step 2: Log Data and Business Assumptions

Start with assumptions that can change numbers:

- Data covers the right population.
- Missing values have a known meaning.
- Test or employee records are excluded.
- The metric definition is stakeholder-approved.
- The selected time window matches the decision.

### Step 3: Log Methodology Decisions

Document method choices in plain language. Example:

- "Use median (middle value, ignores outliers) instead of mean (average, sensitive to extremes) because a few very large accounts would overstate the typical customer."
- "Use 30-day churn (no activity for 30 days) because it matches billing review cadence."

### Step 4: Identify Critical Assumptions

Flag assumptions that are both low confidence and high impact. These become validation priorities and may block delivery if unresolved.

### Step 5: Validate and Update

As work proceeds, update each assumption with evidence:

- Confirmed.
- Partially confirmed.
- Disproved.
- Accepted risk, with operator-approved reason.

Do not remove disproved assumptions; preserve the audit trail and document what changed.

### Step 6: Generate Risk Assessment

Summarize:

- Total assumptions.
- Unvalidated assumptions.
- Critical unvalidated assumptions.
- Top risks.
- What must be checked before Stage 9 delivery.

### Step 7: Generate Documentation

Export the log as a readable markdown document and, when helpful, structured JSON for downstream checks.

## Context Validation

- [ ] All major assumption categories are covered.
- [ ] Rationales are specific, not "seems reasonable."
- [ ] Alternatives are documented for material decisions.
- [ ] Impact assessments explain what changes if wrong.
- [ ] Critical assumptions have validation plans.
- [ ] Validation status is current.

## Output Template

```text
# Assumptions Log: [analysis name]

Analyst: [name/team]
Created: [date]
Last updated: [date]
Decision supported: [decision]

## Summary
- Total assumptions: [count]
- Total decisions: [count]
- Validated: [count]/[count]
- Critical unvalidated: [count]

## Assumptions
### [category]
**#[id]: [assumption]**
- Rationale: [why accepted]
- Confidence: [high/medium/low]
- Impact if wrong: [business consequence]
- Validation plan: [how to check]
- Status: [active/confirmed/partially confirmed/disproved/accepted risk]

## Key Decisions
**Decision #[id]: [decision point]**
- Chosen: [choice]
- Alternatives considered: [alternatives]
- Rationale: [why]
- Trade-offs: [what this improves and what it risks]

## Risk Assessment
- Overall risk: [low/medium/high]
- Top risks: [items]
- Required validation before delivery: [items]

## Open Questions
- [question]
```

## Common Scenarios

- Starting analysis: create the log before computing results.
- Peer review: challenge vague rationales and missing alternatives.
- Unexpected results: identify which assumption may have failed.
- Audit or reproducibility need: provide the full trail of choices and evidence.

