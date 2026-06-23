---
name: segmentation-analysis
description: Segment customers, users, products, or accounts into meaningful groups for BI analysis. Use when creating personas, finding behavior groups, profiling churn risk, or comparing business outcomes by segment.
---

# Segmentation Analysis

Used in the assay lifecycle at: Stage 6 (analysis; inferred execution skill)

## Quick Start

Use this skill to group records into meaningful segments (groups that behave similarly) and explain what each group means for business action. Do not create segments until the metric, population, and action are clear.

## Context Requirements

1. **User data**: records to segment, with identifiers, behavior, value, and time fields.
2. **Segmentation approach**: rule-based, behavioral, value-based, demographic, or clustering (grouping similar records together).
3. **Key variables**: fields that should drive grouping and fields reserved for validation.
4. **Business context**: what action will change by segment.
5. **Validation**: how to test that segments are stable, useful, and not misleading.

## Context Gathering

### For User Data

"Please provide:
- One row per user/account/product or the table grain (what one row represents).
- Candidate fields such as spend, activity, tenure, product use, churn, channel, geography, or plan.
- Date range and refresh cadence.
- Missing-value rules and source-of-truth (official system for the number)."

### For Segmentation Approach

"Which approach fits the consequence?
- Rule-based: easiest to explain and use in operations.
- Value-based: focuses on revenue or margin impact.
- Behavioral: groups based on actions taken.
- Clustering (grouping similar records together): finds patterns when rules are unclear, but needs extra explanation."

### For Key Variables

"Which fields should define the segments, and which should only evaluate them?

Example: use purchase frequency and spend to build groups; use churn later to see whether the groups matter."

### For Business Context

"What will change by segment?
- Marketing message.
- Sales prioritization.
- Product experience.
- Retention outreach.
- Dashboard reporting.

If no action changes, segmentation may add noise rather than value."

### For Validation

"How should we judge whether the segments are useful?
- Clear size: not too tiny to act on.
- Clear difference: groups behave differently.
- Stability: groups do not swing randomly.
- Actionability: each group has a practical next step."

## Workflow

### Step 1: Load and Explore Data

Check:
- Row count and unique IDs.
- Missing values.
- Outliers (unusual values that distort results).
- Date coverage and refresh timing.
- Whether the population matches the spec.

### Step 2: Select and Prepare Segmentation Variables

Choose variables that represent behavior or value. Remove fields that leak the outcome you want to evaluate. Standardize (put values on comparable scales) only when the method needs it, and explain the consequence: "Without standardizing, high-dollar fields may dominate the grouping."

### Step 3: Determine the Number of Segments

Compare options by usefulness:
- Too few segments hide important differences.
- Too many segments are hard to explain and operate.
- Use statistical checks as support, not as the decision by themselves.

Define silhouette score (how separated the groups are) if used.

### Step 4: Create Segments

Build the groups using the selected method:
- Rule-based thresholds for transparent operations.
- K-means (clustering around shared group centers) when numeric behavior patterns matter.
- Hierarchical clustering (nested groups based on similarity) when relationships between groups matter.

Record the method, inputs, and random seed (repeatability setting) so results can be reproduced.

### Step 5: Profile Each Segment

For each segment, report:
- Size and share of population.
- Key behaviors and value.
- Outcome differences.
- Representative profile.
- Risk or opportunity.

### Step 6: Name and Interpret Segments

Give each segment a plain name based on behavior, not judgment. Good names explain action: "High-value repeat buyers" is clearer than "Cluster 2."

### Step 7: Visualize Segments

Use:
- Bar charts for size and value.
- Heatmaps (color table showing intensity) for profile differences.
- Scatter plots for two-variable separation.
- Tables for operational handoff.

### Step 8: Generate Actionable Insights

For each segment, state:
- What is different.
- Why it matters.
- What action to take.
- What metric will show whether the action worked.

### Step 9: Create Segment Strategy Matrix

Create a matrix with segment, profile, opportunity, risk, recommended action, owner, and measurement plan.

## Context Validation

Before finalizing:

- [ ] Population and grain match the question.
- [ ] Variables are appropriate and explainable.
- [ ] Segment count is justified by business usefulness.
- [ ] Segments are validated for size, difference, stability, and actionability.
- [ ] Technical terms are defined inline.

## Output Template

```markdown
Segmentation Analysis
Generated: [timestamp]

## Context Summary
- Population:
- Date range:
- Segmentation approach:
- Business action:
- Validation method:

## Methodology
[Variables, preparation, method, segment-count choice, and validation checks]

## Key Findings
1. **Segment [Name]**: [Profile] - [Recommended action]
2. **Segment [Name]**: [Profile] - [Recommended action]
3. **Validation**: [Evidence] - [Why segments are safe or unsafe to use]

## Detailed Analysis
| Segment | Size | Defining traits | Outcome difference | Recommended action |
| --- | --- | --- | --- | --- |

## Recommendations
1. [Action by segment] - [Expected outcome]
2. [Measurement plan] - [Expected outcome]

## Limitations & Assumptions
- [Data or method limitation]
- [Operational caveat]

## Next Steps
1. [Stakeholder review]
2. [Dashboard, campaign, or model handoff]
```

## Common Scenarios

### Scenario 1: "Who are our best customers?"
Use value and engagement fields, then validate with retention or margin.

### Scenario 2: "Create personas for product team"
Prioritize behavior and need-state variables over demographics alone.

### Scenario 3: "Why is churn high? Which users are at risk?"
Build or compare segments, then explain churn (customers leaving) by group.

### Scenario 4: "Validate existing segmentation"
Check size, stability, outcome difference, and actionability.

### Scenario 5: "Personalize marketing by customer type"
Require a clear action and measurement plan for each segment.

## Handling Missing Context

If no action changes by segment, ask whether this should be a descriptive analysis instead. If variables are missing, propose a minimum viable segmentation and label limitations.

## Advanced Options

- Segment validation scorecard.
- Segment naming workshop.
- Cluster comparison.
- Operational handoff table.
- Refresh plan for recurring dashboards.
