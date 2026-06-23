---
name: ab-test-analysis
description: Analyze A/B test results and experiment designs for BI decisions. Use when checking test setup, sample split, conversion lift, statistical confidence, guardrail metrics, or rollout recommendations.
---

# A/B Test Analysis

Used in the assay lifecycle at: Stage 6 (analysis; inferred execution skill)

## Quick Start

Use this skill to decide whether a test result is strong enough to act on. A/B test means comparing two versions. Explain statistical terms inline and separate "looks better" from "safe to ship."

## Context Requirements

1. **Test design**: variants, randomization level (how users are assigned variants), exposure rules, start/end dates, and hypothesis (expected outcome to test).
2. **Test data**: summary stats, user-level data, or daily aggregates.
3. **Metrics**: primary metric, secondary metrics, and guardrail metrics (must-not-get-worse measures).
4. **Test parameters**: minimum detectable effect (smallest lift worth acting on), significance level (acceptable chance of false win), power (chance to detect real effect), and decision threshold.
5. **Sample ratio**: expected and actual traffic split.

## Context Gathering

### For Test Design

"Please provide:
- What changed between control and treatment.
- Randomization level (how users are assigned variants): user, account, session, or page view.
- Start and end dates.
- Eligibility rules.
- Hypothesis (what improvement you expected and why)."

### For Test Data

"Please provide one format:
- Summary stats: users, conversions, revenue by variant.
- User-level data: user ID, variant, outcome, revenue, and dates.
- Daily aggregates: date, variant, users, conversions, and guardrail metrics."

### For Metrics

"What is the primary decision metric?

Also list:
- Secondary metrics for context.
- Guardrail metrics (must-not-get-worse measures), such as error rate, page load time, refunds, or support tickets."

### For Test Parameters

"Should we use standard parameters unless your team requires others?
- Significance level (acceptable chance of false win).
- Power (chance to detect real effect).
- Minimum detectable effect: smallest lift worth acting on.

State the consequence: stricter settings reduce false wins but need more data."

### For Sample Ratio

"What traffic split was intended?
- 50/50, 90/10, or another split.
- I will check sample ratio mismatch (traffic split looks technically broken) before interpreting results."

## Workflow

### Step 1: Load and Validate Test Data

Check:
- Variants are correctly labeled.
- Users are counted once at the right randomization level (how users are assigned variants).
- Date range matches the test window.
- Missing or duplicate records are explained.
- Exposure rules match the design.

### Step 2: Sample Ratio Mismatch Check

Compare actual traffic split to expected split. If sample ratio mismatch (traffic split looks technically broken) appears, pause interpretation because the test may not be randomized correctly.

### Step 3: Calculate Metrics by Variant

For each variant:
- Sample size (number of users or units).
- Success count.
- Rate or average.
- Absolute difference.
- Relative lift.
- Confidence interval (likely range for true value).

### Step 4: Statistical Significance Test

Choose the right test for the metric:
- Two-proportion test for conversion rates.
- T-test (test that compares group averages) for roughly normal averages.
- Nonparametric test (compares ordered values, not averages) when outliers dominate.

Report p-value (chance result is just noise) and the practical effect size. Explain whether the result is statistically significant (unlikely to be random noise) and whether it is large enough to matter.

### Step 5: Power Analysis

Check whether the test had enough sample size to detect the minimum effect. Low power (low chance to detect real effect) means an inconclusive result may still hide a meaningful change.

### Step 6: Guardrail Metrics Check

Confirm treatment did not harm guardrails. A primary metric win can still fail if errors, refunds, latency, or support issues worsened.

### Step 7: Visualize Results

Use visuals that show:
- Variant performance with confidence intervals.
- Daily trend to detect launch issues.
- Guardrail status.
- Cumulative results only if sequential-read risk is explained.

### Step 8: Generate Decision Recommendation

Recommend:
- Ship.
- Do not ship.
- Keep testing.
- Re-run with a fixed design.
- Segment follow-up.

Tie the recommendation to consequence, not jargon.

## Context Validation

Before finalizing:

- [ ] Randomization and sample ratio are checked.
- [ ] Primary metric and guardrails are defined.
- [ ] Test choice matches metric type.
- [ ] Statistical and practical significance are separated.
- [ ] Limitations are clear.
- [ ] Recommendation states what action is safe.

## Output Template

```markdown
A/B Test Analysis
Generated: [timestamp]

## Context Summary
- Test:
- Variants:
- Date range:
- Primary metric:
- Guardrails:
- Intended traffic split:

## Methodology
[Data checks, statistical test, power check, and guardrail review]

## Key Findings
1. **Primary Result**: [Lift and confidence] - [Decision consequence]
2. **Guardrails**: [Status] - [Decision consequence]
3. **Test Quality**: [Randomization/sample check] - [Trust consequence]

## Detailed Analysis
| Variant | Sample size | Metric value | Difference | Confidence interval |
| --- | --- | --- | --- | --- |

## Recommendations
1. [Ship / do not ship / keep testing / rerun] - [Expected outcome]
2. [Follow-up analysis] - [Why it matters]

## Limitations & Assumptions
- [Sample size, design, seasonality, or data caveat]
- [Metric limitation]

## Next Steps
1. [Decision owner] - [Action]
2. [Analyst/data owner] - [Validation or monitoring action]
```

## Common Scenarios

### Scenario 1: "Should we ship this new feature?"
Require primary metric, guardrails, and test-quality checks before recommending rollout.

### Scenario 2: "Test is inconclusive after 2 weeks"
Check power and minimum detectable effect before declaring no impact.

### Scenario 3: "Validate test design before launching"
Review randomization, sample size, guardrails, and decision rule.

### Scenario 4: "Multiple variants to compare"
Adjust for multiple comparisons (more chances for false alarms) or define one primary comparison.

### Scenario 5: "Test shows improvement but stakeholders skeptical"
Separate statistical confidence, practical business impact, and validation evidence.

## Handling Missing Context

If design details are missing, do not overstate the result. If only summary stats are available, report which checks cannot be performed and how that affects trust.

## Advanced Options

- Pre-launch test design review.
- Sample size estimate.
- Guardrail dashboard.
- Segment-level experiment readout.
- Rollout monitoring plan.
