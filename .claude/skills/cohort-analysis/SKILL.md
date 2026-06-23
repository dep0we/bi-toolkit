---
name: cohort-analysis
description: Analyze cohorts over time for retention, revenue, behavior, and feature adoption. Use during assay execution when users or customers need to be grouped by start date, channel, plan, or another shared starting condition.
---

# Cohort Analysis

Used in the assay lifecycle at: Stage 6 (shared execution)

## Quick Start

Analyze cohorts, meaning groups tracked over time, to understand retention (who comes back), revenue durability, behavior changes, or feature adoption. Use this when the timing of a user or customer relationship matters.

## Context Requirements

1. **Dataset**: user, customer, or account event data.
2. **Cohort definition**: how to group records, such as signup month or first purchase.
3. **Retention metric**: what counts as retained or active.
4. **Time periods**: daily, weekly, monthly, or quarterly.
5. **Minimum cohort size**: smallest group worth comparing.
6. **Exclusions**: test users, employees, one-time events, or incomplete periods.

## Context Gathering

### Initial Questions

"Let's set up cohort analysis. I need:

1. What are we measuring: user retention, revenue retention, feature adoption, or another behavior?
2. How should cohorts (groups tracked over time) be defined: signup date, acquisition channel, first purchase, plan tier, or another attribute?
3. What counts as active or retained: login, purchase, feature use, revenue, or another event?
4. What time period should we use: daily, weekly, monthly, or quarterly?"

### For Dataset

"I need data with:

- User or customer ID.
- Cohort date, such as signup date.
- Activity dates, such as login or purchase date.
- Optional cohort attributes, such as channel, plan, or region.

Can you provide a file, a query, or table names so I can write the query?"

### Validation Questions

"Before calculating:

- What minimum cohort size should we show?
- How many periods should we track?
- Should current incomplete periods be excluded?
- Are test users, employees, or migrated customers in the data?"

## Workflow

### 1. Data Preparation

Validate required fields, parse dates, remove excluded records, and define the grain (one row represents). Confirm that each user or customer has one cohort assignment unless the business rule says otherwise.

### 2. Build Cohorts

Assign each record to a cohort based on the agreed definition. Examples:

- Signup month.
- First purchase month.
- Acquisition channel.
- Plan at signup.

Document the consequence of the choice. Signup cohorts explain lifecycle behavior; channel cohorts explain acquisition quality; plan cohorts explain product packaging.

### 3. Define Activity and Retention

Apply the retained or active rule. Examples:

- Logged in at least once.
- Purchased at least once.
- Generated revenue.
- Used a feature.

State the rule exactly. A stricter activity rule may make retention look worse but can better match business value.

### 4. Calculate the Cohort Matrix

Create a matrix, meaning a grid of cohorts by elapsed periods:

- Rows: cohort groups.
- Columns: period 0, 1, 2, etc.
- Values: retained count, retention percent, revenue, or adoption rate.

Use percentages for comparison and counts to show whether the group is large enough to trust.

### 5. Visualize and Compare

Use a heatmap (color grid showing high and low values) or trend lines. Highlight:

- Stronger or weaker cohorts.
- Drop-off points.
- Channel or plan differences.
- Incomplete periods.

### 6. Interpret Business Meaning

Translate patterns into action:

- Early drop-off suggests onboarding or first-value issues.
- Later drop-off suggests product fit, pricing, or service issues.
- Strong cohorts suggest channels or segments worth investing in.
- Small cohorts should be labeled as directional only.

## Context Validation

- [ ] Cohort definition is approved.
- [ ] Activity or retention rule is exact.
- [ ] Time period matches the decision.
- [ ] Minimum cohort size is set.
- [ ] Exclusions are documented.
- [ ] Incomplete periods are labeled or removed.

## Output Template

```text
Cohort Analysis
Generated: [timestamp]
Cohort definition: [grouping rule]
Retention metric: [active/retained rule]
Period: [daily/weekly/monthly]

## Context Summary
- Dataset: [source]
- Grain (one row represents): [definition]
- Exclusions: [records excluded]
- Minimum cohort size: [threshold]

## Key Findings
1. [finding] - [business consequence]
2. [finding] - [business consequence]

## Cohort Matrix
[table or heatmap reference]

## Segment Comparisons
- [segment/cohort] - [result and implication]

## Limitations and Assumptions
- [small cohorts, incomplete periods, missing data]

## Recommendations
1. [action] - [expected outcome]
2. [action] - [expected outcome]
```

