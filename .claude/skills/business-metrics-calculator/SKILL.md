---
name: business-metrics-calculator
description: Calculate and define standard business metrics for SaaS, e-commerce, marketplace, product, and finance contexts. Use when assay Stage 2 needs metric definitions or Stage 6 needs metric calculation.
---

# Business Metrics Calculator

Used in the assay lifecycle at: Stage 2 (shared spec)

## Quick Start

Calculate business metrics with clear definitions, documented source data, and validation against source of truth. A metric should never be just a number; it should include what it means, how it is calculated, what decisions it supports, and what can make it misleading.

## Context Requirements

Before calculating metrics, collect:

1. **Business model**: SaaS, e-commerce, marketplace, product, media, or blended.
2. **Raw data**: underlying records used for calculation.
3. **Metric definitions**: the agreed meaning and formula.
4. **Time period**: single period, rolling period, or time series.
5. **Segmentation**: customer type, plan, channel, region, or product.
6. **Source of truth**: trusted report or system for reconciliation.
7. **Metric catalog**: shared metric definition file.

## Context Gathering

### For Business Model

"What type of business are we calculating metrics for?

- SaaS or subscription: MRR (monthly recurring subscription revenue), ARR (annual recurring subscription revenue), churn (customers or revenue lost), LTV (customer lifetime value), CAC (cost to acquire customer).
- E-commerce: GMV (gross merchandise value), AOV (average order value), CAC, ROAS (return on ad spend).
- Marketplace: take rate, liquidity, GMV.
- Product/app: DAU (daily active users), MAU (monthly active users), retention (users who return), engagement.
- Media/content: CPM (cost per thousand impressions), viewability, engagement."

### For Raw Data

"I need the underlying data and its grain (one row represents). Examples:

```text
customer_id | plan_type | mrr | start_date | end_date | status
order_id    | customer_id | order_date | order_value | items
user_id     | date | sessions | event_count
```

What format is your data in, and which system is source of truth?"

### For Metric Definitions

"Do you already have standard definitions?

- If yes, share the metric glossary or dashboard definition.
- If no, I will propose a standard definition and mark it for approval.

Common choices that change numbers:
- Churn: customer churn or revenue churn.
- MRR: include or exclude one-time fees.
- LTV: simple average or cohort-based estimate.
- CAC: include sales costs, marketing costs, or both."

### For Time Period

"Which period should be calculated?

- Single period.
- Monthly time series.
- Trailing 12 months.
- Cohort-based, meaning grouped by start period.

The period should match the decision. A monthly board metric and a daily operations metric should not use the same time bucket by default."

## Workflow

### Step 1: Load and Validate Data

Confirm row counts, date ranges, missing values, duplicate IDs, currency, and status values. Stop if critical fields are missing or if source-of-truth reconciliation is impossible.

### Step 2: Select Metric Definitions

Choose definitions and document consequences:

- MRR: recurring monthly revenue; excluding one-time fees avoids overstating repeatable revenue.
- ARR: annualized recurring revenue; useful for scale, not cash timing.
- Churn: lost customers or lost revenue; customer churn and revenue churn can tell different stories.
- ARPU: average revenue per user; sensitive to customer mix.
- LTV: expected lifetime value; depends heavily on churn assumptions.
- CAC: cost to acquire customer; scope changes comparability.

Before accepting a definition, check the living metric catalog:

```bash
bash .claude/workflows/metric-store.sh check <metric-name> <proposed-definition>
```

Use `match` definitions directly. For `not-found`, ask the operator whether to
add the metric. For `differs`, flag drift, meaning definitions have split across
analyses, and treat it as a methodology fork before calculating.

### Step 3: Calculate Core Metrics

For SaaS/subscription, calculate:

- MRR and ARR.
- New, expansion, contraction, and churned MRR.
- Customer count.
- Customer churn rate.
- Revenue churn rate.
- Net revenue retention, meaning revenue kept after loss and expansion.
- ARPU, LTV, CAC, LTV:CAC ratio, and payback period.

For e-commerce or marketplace, calculate the relevant order, customer, take-rate, acquisition, and repeat-purchase metrics using the same definition discipline.

### Step 4: Segment and Compare

Break down metrics by agreed segments only when the segment can drive action. Show segment size alongside the metric so small groups are not overinterpreted.

### Step 5: Build Time Series or Cohort View

If the decision depends on movement over time, calculate a time series. If customer quality over starting period matters, use cohort analysis, meaning groups tracked over time.

### Step 6: Benchmark Carefully

Use benchmarks (outside comparison points) only as context. State whether the benchmark matches company stage, market, geography, and business model. A mismatched benchmark can create the wrong target.

### Step 7: Reconcile and Explain

Tie key totals to source of truth. Explain any variance by amount and percentage. If the metric cannot reconcile within tolerance, mark it as not ready for delivery.
When the operator approves a new or updated metric, write it to the catalog:

```bash
bash .claude/workflows/metric-store.sh add <metric-name> <definition> <source-of-truth> <owner> <format> [notes]
```

## Context Validation

- [ ] Required data fields are present.
- [ ] Metric definitions are approved or marked as proposed.
- [ ] Approved definitions are checked against or written to `metric-catalog.json`.
- [ ] Time period matches the decision.
- [ ] Segments are actionable and large enough.
- [ ] Source-of-truth reconciliation is possible.
- [ ] Limitations and assumptions are documented.

## Output Template

```text
Business Metrics Report
Generated: [timestamp]
Business model: [model]
Period: [period]
Source of truth: [system/report]

## Definitions
- [metric]: [plain definition], [formula], [included/excluded records]

## Revenue Metrics
- MRR (monthly recurring subscription revenue): [value]
- ARR (annual recurring subscription revenue): [value]
- New / expansion / churned revenue: [values]

## Customer Metrics
- Total customers: [value]
- New customers: [value]
- Churned customers: [value]
- Churn rate (customers or revenue lost): [value]

## Unit Economics
- CAC (cost to acquire customer): [value]
- LTV (customer lifetime value): [value]
- LTV:CAC: [value and interpretation]
- Payback period: [months]

## Segment Results
- [segment]: [metric values and implication]

## Benchmark Context
- [benchmark] - [whether comparable]

## Reconciliation
- Source-of-truth value: [value]
- Calculated value: [value]
- Variance: [amount and percent]
- Status: [pass/fail/explain]

## Key Insights
1. [finding] - [business consequence]

## Recommendations
1. [action] - [expected outcome]

## Limitations and Assumptions
- [assumption or data gap]
```

## Common Scenarios

- Board metrics: calculate core metrics, compare to prior periods, reconcile, and summarize movement.
- Validate calculations: compare current method to approved definitions and document gaps.
- Unit economics: calculate LTV, CAC, payback, and acquisition efficiency.
- Segment metrics: compare actionable customer groups and avoid overreading small samples.
- Track over time: build monthly history and identify inflection points.
