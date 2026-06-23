---
name: analysis-retrospective
description: Capture lessons after an analysis or data product release, including what worked, what failed, metric drift to watch, and process improvements. Use at assay Stage 12.
---

# Analysis Retrospective

Used in the assay lifecycle at: Stage 12 (shared retro)

## Quick Start

Run a retrospective, meaning a structured review after the work, to capture what should be repeated, fixed, or watched next time. Focus on decisions, data quality, metric drift, and workflow improvements.

## Context Requirements

Before proceeding, collect:

1. **Completed analysis or data product**: what shipped and when.
2. **Original spec**: question, metric definitions, and success criteria.
3. **Validation evidence**: source-of-truth checks and review score.
4. **Stakeholder outcome**: what decision was made or what workflow changed.
5. **Learning repository**: where reusable lessons should live.
6. **Action follow-up**: owners and dates for improvements.

## Context Gathering

### For Completed Work

"What work are we reviewing?

- Analysis or dashboard name.
- Date delivered.
- Stakeholders.
- Decision or recurring workflow supported.
- Final status: accepted, revised, delayed, or withdrawn."

### For Evidence

"What evidence should the retrospective consider?

- Spec receipt.
- Assumptions log.
- Validation receipt.
- Adversarial review score.
- Stakeholder feedback.
- Any defects found after delivery."

### For Learning and Follow-Up

"Where should lessons and actions go?

- Project documentation.
- Seed memory.
- Issue tracker.
- Dashboard backlog.
- Metric-drift watch list, meaning metrics that may change definition or behavior."

## Workflow

### Step 1: Validate Context

Confirm the work is complete enough to review, the original goals are available, and stakeholders have had a chance to react.

### Step 2: Compare Plan to Outcome

Review:

- Original question or dashboard purpose.
- Metric definitions.
- Methodology decisions.
- Validation results.
- Final recommendation or product behavior.
- Actual decision or usage outcome.

### Step 3: Identify What Worked

Capture reusable practices:

- Strong intake questions.
- Useful data checks.
- Clear metric definitions.
- Review steps that caught issues.
- Plain-language explanations that helped stakeholders act.

### Step 4: Identify What Failed or Slowed Work

Capture issues without blame:

- Missing source of truth.
- Late metric-definition change.
- Data freshness mismatch.
- Confusing output.
- Unclear ownership.
- Manual step that should be automated.

Frame by consequence: "Missing owner delayed validation by two days," not "ownership issue."

### Step 5: Create Follow-Up Actions

For each action, specify owner, due date, and expected outcome. Separate:

- Fix now.
- Add to backlog.
- Watch over time.
- No action, but document the lesson.

### Step 6: Capture Metric-Drift Watch

List metrics or assumptions that may drift, meaning change meaning or behavior over time. Define when to re-check them and what signal triggers review.

## Context Validation

- [ ] Original spec and validation evidence are available.
- [ ] Stakeholder outcome is known or marked pending.
- [ ] Lessons are specific enough to reuse.
- [ ] Actions have owners and dates.
- [ ] Metric-drift watch items have triggers.

## Output Template

```text
Analysis Retrospective
Generated: [timestamp]
Work reviewed: [analysis/dashboard]

## Context Summary
- Original goal: [goal]
- Delivered: [date and artifact]
- Stakeholders: [names/teams]
- Outcome: [decision/use]

## What Worked
1. [practice] - [why it helped]
2. [practice] - [why it helped]

## What Failed or Slowed Us
1. [issue] - [consequence]
2. [issue] - [consequence]

## Lessons to Keep
- [lesson]

## Follow-Up Actions
1. [action] - Owner: [owner] - Due: [date] - Expected outcome: [outcome]

## Metric-Drift Watch
- [metric/assumption] - Trigger: [signal] - Review cadence: [cadence]

## Repository Updates
- [where lesson/action was recorded]
```

