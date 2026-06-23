---
name: query-validation
description: SQL query review and validation for BI correctness, performance, and business logic. Use when checking query joins, filters, aggregation, source-of-truth ties, or performance before results are trusted.
---

# Query Validation

Used in the assay lifecycle at: Stage 7 (shared)

## Quick Start

Review SQL queries for correctness, performance, and business logic before results enter a validation receipt. SQL is structured query language (database question language).

## Context Requirements

1. **SQL query**: the exact query or transformation to validate.
2. **Database type**: PostgreSQL, MySQL, Snowflake, BigQuery, Redshift, or other system.
3. **Schema information**: relevant tables, columns, keys, and grain (what one row represents).
4. **Business logic**: what the query should calculate and how the metric is defined.
5. **Performance context**: expected row counts, runtime, cost, or dashboard refresh needs.

## Context Gathering

### For Query Input

"Please provide:
1. The SQL query to validate.
2. The database system.
3. What the query is supposed to calculate.
4. The decision or dashboard this result supports."

### For Schema

"To validate joins and column references, I need table schemas.

Choose the fastest option:
- Quick: list only tables and columns used in the query.
- Better: include primary keys (row's unique identifier), foreign keys (columns linking to another table), and table grain.
- Best: include row counts and source-of-truth (official system for the number) expectations."

### For Business Logic

"Please define:
- Numerator (top number in a rate).
- Denominator (bottom number in a rate).
- Date range and timezone.
- Filters and exclusions.
- Expected totals or benchmark numbers."

## Workflow

### Step 1: Validate Context

Confirm:
- [ ] Query and database type are available.
- [ ] Tables and key columns are known.
- [ ] Metric definition is clear.
- [ ] Expected output shape is known.
- [ ] Performance expectations are stated or not relevant.

### Step 2: Review Correctness

Check:
- Column names and table names exist.
- Join keys match table grain.
- Join type consequence is clear: inner join (keeps rows matching both tables), left join (keeps all rows from left table), full join (keeps rows from both tables).
- Filters do not accidentally remove needed rows.
- Dates use the correct timezone and inclusive/exclusive boundaries.
- Aggregation (rolling rows into totals) matches the metric definition.
- Nulls (blank values) and duplicates are handled intentionally.

### Step 3: Review Business Logic

Verify:
- Numerator and denominator match the spec.
- Segments (groups that behave similarly) are defined consistently.
- Cohorts (groups tracked over time) use the right starting event.
- Source-of-truth tie-outs are planned or already performed.
- Output fields match downstream dashboard or report needs.

### Step 4: Review Performance and Maintainability

Check:
- Query scans only needed data.
- Filters are applied early when safe.
- Expensive joins are justified.
- Names and comments help future reviewers.
- Re-running the query is idempotent (safe to re-run without duplicates).

### Step 5: Report Findings

Classify each finding:
- **Blocker**: likely changes the answer or breaks the gate.
- **Important**: could mislead or slow recurring use.
- **Optional**: improves readability or cost without changing the result.

## Context Validation

Before completing:

- [ ] Validation covers query syntax, logic, joins, filters, aggregation, and source-of-truth tie-out.
- [ ] Any unverified assumption is labeled.
- [ ] Findings are framed by consequence.
- [ ] No jargon is left undefined.

## Output Template

```markdown
Query Validation Report
Generated: [timestamp]

## Context Summary
- Query purpose:
- Database:
- Tables reviewed:
- Metric definition:
- Source-of-truth:

## Methodology
[How syntax, logic, joins, filters, aggregation, and performance were checked]

## Key Findings
1. **[Blocker/Important/Optional]**: [Issue] - [How it could change the answer]
2. **[Blocker/Important/Optional]**: [Issue] - [How it could affect delivery]

## Detailed Analysis
| Area | Status | Evidence | Consequence |
| --- | --- | --- | --- |
| Syntax |  |  |  |
| Joins |  |  |  |
| Filters |  |  |  |
| Aggregation |  |  |  |
| Business logic |  |  |  |
| Performance |  |  |  |

## Recommendations
1. [Required query change] - [Expected outcome]
2. [Validation check] - [Expected outcome]

## Limitations & Assumptions
- [Missing schema, data, or expected result]
- [Assumption that needs owner confirmation]

## Next Steps
1. [Apply fix or confirm assumption]
2. [Re-run validation or tie-out]
```
