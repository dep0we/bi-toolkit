---
name: root-cause-investigation
description: Investigate metric changes and anomalies in BI data. Use when a metric unexpectedly changes, performance drops, results look volatile, or stakeholders need the drivers behind a business movement.
---

# Root Cause Investigation

Used in the assay lifecycle at: Stage 6 (analysis; inferred execution skill)

## Quick Start

Use this skill to explain why a metric changed. First confirm the change is real, then drill into dimensions (ways to group data), events, and hypotheses (possible explanations) until the evidence supports a clear business explanation.

## Context Requirements

1. **The metric**: what changed, by how much, and why it matters.
2. **Time context**: when the change started, whether it was sudden or gradual, and the comparison period.
3. **Historical data**: enough history to define baseline (normal comparison point for change) and variance (normal ups and downs).
4. **Drill-down dimensions**: geography, product, channel, platform, customer type, or other slices.
5. **Known events**: launches, campaigns, incidents, policy changes, seasonality, or external events.

## Context Gathering

### For The Metric

"Tell me about the metric change:
- Metric name and definition.
- Current value and prior value.
- Absolute and percentage change.
- When it started.
- Why the change matters to the business."

### For Historical Data

"Please provide history before and after the change:
- Daily or weekly values.
- At least 2-3 times the investigation period if available.
- Source-of-truth (official system for the number).
- Any known data pipeline or reporting changes."

### For Drill-Down Dimensions

"Which ways can we slice the metric?
- Geography.
- Product or category.
- Customer segment (group that behaves similarly).
- Cohort (group tracked over time).
- Channel.
- Platform.
- Time of day or day of week."

### For Known Events

"What happened near the change?
- Product releases.
- Marketing campaigns.
- Pricing or policy changes.
- Data pipeline changes.
- Incidents or outages.
- External market events."

### For Baseline Expectations

"What is normal for this metric?
- Historical average.
- Expected growth rate.
- Acceptable variance (normal ups and downs).
- Seasonal pattern."

## Workflow

### Step 1: Validate the Change

Confirm:
- The metric definition did not change.
- The source data is complete.
- The change is larger than normal variance.
- The date and comparison period are correct.

Use z-score (distance from normal behavior) if helpful, and define it when shown.

### Step 2: Visualize the Trend

Create a timeline with:
- Current value.
- Baseline.
- Change date.
- Known events.
- Confidence or data-quality notes where needed.

### Step 3: Systematic Drill-Down

Slice the metric across available dimensions. For each slice, compare before versus after and calculate contribution to total change. Avoid chasing the largest percentage change if the group is too small to matter.

### Step 4: Hypothesis Testing

List possible explanations and test each one:
- Expected pattern if true.
- Evidence that supports it.
- Evidence that contradicts it.
- Data still needed.

Hypothesis means possible explanation.

### Step 5: Correlation Analysis

Check whether related measures moved together. Correlation (two measures moving together) does not prove causation (one thing caused another), so use it as evidence, not proof.

### Step 6: Identify Root Cause

Classify the explanation:
- Confirmed cause: evidence directly supports it.
- Likely driver: evidence points strongly but not completely.
- Contributing factor: explains part of the change.
- Ruled out: evidence does not support it.
- Unknown: not enough evidence.

### Step 7: Generate Investigation Report

Summarize:
- What changed.
- What caused or likely drove it.
- Which groups contributed most.
- What action to take.
- What to monitor next.
- What remains uncertain.

## Context Validation

Before finalizing:

- [ ] Change is validated against baseline and data quality.
- [ ] Drill-down dimensions are checked systematically.
- [ ] Known events are compared to timing.
- [ ] Cause is not overstated beyond evidence.
- [ ] Recommendation follows from the driver found.

## Output Template

```markdown
Root Cause Investigation
Generated: [timestamp]

## Context Summary
- Metric:
- Change:
- Date range:
- Baseline:
- Source-of-truth:

## Methodology
[Change validation, trend review, drill-downs, hypothesis tests, and evidence checks]

## Key Findings
1. **Change Confirmed**: [Evidence] - [Business consequence]
2. **Likely Driver**: [Driver] - [How much it explains]
3. **Action Needed**: [Action] - [Expected outcome]

## Detailed Analysis
### Trend
[Baseline, current period, and timing]

### Drill-Down Results
| Dimension | Before | After | Change | Contribution | Interpretation |
| --- | --- | --- | --- | --- | --- |

### Hypothesis Review
| Hypothesis | Evidence For | Evidence Against | Verdict |
| --- | --- | --- | --- |

## Recommendations
1. [Action] - [Expected outcome]
2. [Monitoring step] - [Expected outcome]

## Limitations & Assumptions
- [Missing data or uncertainty]
- [Causal limitation]

## Next Steps
1. [Owner] - [Action]
2. [Owner] - [Monitor or validate]
```

## Common Scenarios

### Scenario 1: "Conversion rate suddenly dropped"
Validate tracking, then drill by channel, device, page, and release timing.

### Scenario 2: "Revenue is down but we do not know why"
Break revenue into volume, price, mix, refunds, and customer segments.

### Scenario 3: "Metric improved but team does not trust it"
Check source changes, data completeness, and whether one slice drives the improvement.

### Scenario 4: "Weekly metric is volatile"
Separate normal variance from real changes and consider smoothing (reducing short-term noise).

### Scenario 5: "Metric plateaued after growing"
Compare acquisition, activation, retention, and capacity constraints.

## Handling Missing Context

If history is missing, state that baseline confidence is limited. If drill-down dimensions are missing, identify the minimum slices needed before claiming cause.

## Advanced Options

- Driver tree.
- Event timeline.
- Anomaly scorecard.
- Segment-level contribution analysis.
- Monitoring plan after fix.
