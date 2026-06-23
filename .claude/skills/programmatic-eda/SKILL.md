---
name: programmatic-eda
description: Run systematic exploratory data analysis (first-pass data inspection) to understand structure, quality, distributions, correlations, and obvious risks before analysis. Use when profiling any dataset before Stage 6 execution.
---

# Programmatic EDA

Used in the assay lifecycle at: Stage 4 (analysis)

## Quick Start

Profile a dataset before analysis so the assay does not build conclusions on broken, incomplete, or misunderstood data.

## Context Requirements

Before starting EDA (first-pass data inspection), collect:

1. **Dataset access**: File path, database connection, query, or in-memory dataframe.
2. **Business context**: What the data represents and what decision it supports.
3. **Quality thresholds**: What missingness, duplicates, or outliers are acceptable.

## Context Gathering

### If Dataset Is Not Loaded

"Please provide the dataset as a file path, upload, database query, or dataframe. I need enough access to inspect fields, rows, dates, and basic quality."

### If Business Context Is Missing

"What does this dataset represent, what business question does it support, what time period does it cover, and are there known quality issues?"

### For Quality Thresholds

"I can use default checks unless you have stricter rules: missing values above 5%, duplicates above 1%, and outliers (values far from the pattern) using IQR (middle 50% range). Should these thresholds change?"

## Workflow

### 1. Data Loading & Overview

Report:
- Row count and column count.
- Date range when a date field exists.
- Key identifier fields.
- Data types.
- Example rows.
- Whether the dataset looks like the expected business process.

### 2. Completeness Checks

Calculate missing values by column. Define null (empty or missing value) when reporting. Flag:
- Columns above the missing-value threshold.
- Required fields with any missing values.
- Missingness concentrated in a segment or time period.

### 3. Duplicate Checks

Check duplicate rows and duplicate business keys. Explain duplicate as "same record repeated." Separate harmless duplicates from duplicates that would inflate a metric.

### 4. Distribution Checks

For numeric fields, inspect:
- Minimum, maximum, mean (average value), median (middle value, ignores outliers), and percentiles (position in sorted values).
- Outliers (values far from the pattern).
- Negative values where only positive values should exist.

For categorical fields, inspect:
- Top values.
- Unexpected categories.
- Rare values that may be spelling or mapping issues.

### 5. Time Checks

When dates exist:
- Confirm the time range.
- Check gaps.
- Check sudden spikes or drops.
- Confirm timezone if it matters.
- Compare refresh timing to expected cadence.

### 6. Relationship and Correlation Checks

Check relationships only when they support the business question. Define correlation as "things moving together." Do not imply cause unless the analysis design supports it.

### 7. Visualization

Create charts that answer quality questions:
- Missingness chart.
- Distribution charts.
- Time trend.
- Segment count chart.
- Correlation heatmap when useful.

### 8. EDA Receipt for the Assay

Summarize whether the data is ready for Stage 6 execution, needs cleaning, or needs a methodology decision before results are computed.

## Context Validation

Before completing:
- [ ] Dataset access worked.
- [ ] The row counts and date range match expectations.
- [ ] Required fields are present.
- [ ] Quality issues are described by consequence.
- [ ] Open questions are listed for the operator.

## Output Template

```markdown
# Programmatic EDA Report

Dataset: [name]
Generated: [timestamp]
Business question: [question]

## Overview
- Rows: [count]
- Columns: [count]
- Date range: [range]
- Grain (one row represents): [definition]

## Quality Summary
| Check | Result | Consequence |
|---|---|---|
| Missing values (empty fields) | [result] | [effect] |
| Duplicates (same record repeated) | [result] | [effect] |
| Outliers (values far from pattern) | [result] | [effect] |
| Time gaps | [result] | [effect] |

## Key Findings
1. [finding] - [consequence for analysis]
2. [finding] - [consequence for analysis]
3. [finding] - [consequence for analysis]

## Recommended Handling
- [clean, exclude, escalate, or accept]
- [methodology decision needed, if any]

## Charts or Files Generated
- [file]
- [file]

## Ready for Stage 6?
[Yes / No / Yes with limitations] because [plain-language reason].
```

## Common Context Gaps & Solutions

**No business context**: Run only structural checks and ask what each key field means before interpreting patterns.

**No thresholds**: Use defaults and state the consequence of changing them.

**Data too large**: Profile a representative sample and note what checks still need a full-table run.

## Advanced Options

- **Automated profile script**: Save repeatable checks for recurring datasets.
- **Data quality score**: Score readiness across completeness, duplicates, freshness, and consistency.
- **Schema drift check**: Compare current fields with a prior version and flag changes.
