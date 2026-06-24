---
name: metric-reconciliation
description: Compare metrics across sources, explain discrepancies, and produce reconciliation evidence. Use when dashboard, warehouse, finance, product, or migrated-system numbers do not match or must be validated before delivery.
---

# Metric Reconciliation

Used in the assay lifecycle at: Stage 7 (shared; also Stage 10 data product refresh)

## Quick Start

Compare the same metric across two or more sources, identify differences, explain likely causes, and decide whether the result is safe to use.

## Context Requirements

Collect:

1. **Data sources**: The systems, exports, dashboards, or queries to compare.
2. **Metric definitions**: How each source calculates the metric.
3. **Expected variance**: Variance means gap between compared numbers; define what gap is acceptable.
4. **Time period**: Date range to reconcile.
5. **Join keys**: Join key means field used to match records.
6. **Metric catalog entry**: the approved shared definition.

## Context Gathering

### For Data Sources

"Please provide each source: system name, export or query, metric shown, and owner. I need the source-of-truth (official system for this metric) if one exists."

### For Metric Definitions

"How does each source calculate the metric? Include filters, dates, statuses, timezone, refunds, exclusions, and whether the data is transaction-level or already summarized."

### For Expected Variance

"What difference is acceptable before we investigate? For financial metrics, the threshold is usually tighter than behavioral metrics. I will show the consequence of the threshold."

### For Time Period

"What date range should be reconciled, and do the sources refresh on the same schedule?"

### For Join Keys

"How should records match across sources: total only, by date, by account, by transaction ID, or by date plus entity?"

## Workflow

### Step 1: Load Data from Each Source

Record:
- Source name.
- Query or file used.
- Row count.
- Date range.
- Refresh timing.
- Owner.

Pause if a source is missing or the date ranges do not overlap.

### Step 2: Standardize Formats

Make the sources comparable:
- Convert date fields to the same timezone.
- Convert metric fields to numeric values.
- Normalize IDs.
- Drop or flag nulls (empty values).
- Preserve original columns for audit.

### Step 3: Aggregate at Comparison Level

Choose the comparison level by consequence:
- **Total comparison**: Fast, but cannot identify exact missing records.
- **Date comparison**: Good for refresh or timing issues.
- **Entity comparison**: Finds account or customer differences.
- **Transaction comparison**: Best for financial audit, requires matching IDs.

Before comparing values, check that the metric definition being reconciled
matches the living metric catalog:

```bash
bash .claude/workflows/metric-store.sh check <metric-name> <definition-being-reconciled>
```

If it differs, report the definition split before judging the numbers. A value
can fail reconciliation because the calculation changed, not because the data is
wrong.

### Step 4: Join and Compare

Use a full comparison so records present in only one source are visible. Calculate:
- Difference.
- Absolute difference.
- Percent difference.
- Status: match, minor variance, significant variance.

### Step 5: Analyze Discrepancies

Investigate:
- Largest differences.
- Repeating date or segment patterns.
- One source consistently higher.
- Recent periods affected by refresh lag.
- Missing or extra records.
- Definition mismatches.

### Step 6: Drill Down

For the largest discrepancies:
- Compare record counts.
- Compare IDs.
- Compare statuses and dates.
- Identify records present in one source but not another.
- Tie each root cause to a fix or accepted difference.

### Step 7: Generate Reconciliation Report

Report whether the metric is safe to use. If not, state exactly what blocks use and what action would unblock it.

## Context Validation

Before closing:
- [ ] All sources are available.
- [ ] Metric definitions are documented.
- [ ] Metric definitions match the catalog or drift is called out.
- [ ] Time periods align or the mismatch is explained.
- [ ] Acceptable variance is defined.
- [ ] The source-of-truth is named.
- [ ] Differences are explained by consequence.

## Output Template

```markdown
# Metric Reconciliation Report

Metric: [metric]
Period: [date range]
Generated: [timestamp]

## Sources Compared
| Source | Owner | Definition | Refresh timing |
|---|---|---|---|
| [source] | [owner] | [definition] | [timing] |

## Summary
| Source | Value |
|---|---:|
| [source 1] | [value] |
| [source 2] | [value] |

- Difference: [amount]
- Variance (gap between compared numbers): [percent]
- Threshold: [acceptable gap]
- Status: [within threshold / investigate / blocked]

## Breakdown
| Period or key | Source 1 | Source 2 | Difference | Status |
|---|---:|---:|---:|---|
| [key] | [value] | [value] | [diff] | [status] |

## Root Cause Analysis
1. [cause] - [evidence] - [business consequence]
2. [cause] - [evidence] - [business consequence]

## Recommendation
- Use metric? [yes/no/yes with limitation]
- Fix needed: [action]
- Owner: [owner]
- Due: [date]

## Files Generated
- [detailed comparison]
- [discrepancies only]
- [receipt or report]
```

## Common Scenarios

**Dashboard differs from report**: Compare underlying queries and explain which filters, dates, or refresh timing cause the gap.

**Migration validation**: Compare old and new systems by transaction ID and document missing or changed records.

**Month-end financial check**: Use a strict threshold and investigate every material difference.

**Recurring dashboard refresh**: Run a lighter reconciliation each refresh and block if variance exceeds threshold.

## Advanced Options

- **Automated monitoring**: Run daily and alert when the variance threshold is crossed.
- **Multi-source matrix**: Compare more than two sources.
- **Trend reconciliation**: Show whether differences are improving or worsening.
- **Root-cause classification**: Categorize timing, missing data, calculation difference, and access issues.
