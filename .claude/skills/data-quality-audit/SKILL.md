---
name: data-quality-audit
description: Audit data quality against business rules, schemas, relationships, and source-of-truth expectations. Use when profiling data, validating pipeline outputs, or preparing assay validation receipts.
---

# Data Quality Audit

Used in the assay lifecycle at: Stage 4 (analysis profile data) and Stage 7 (shared validation)

## Quick Start

Assess whether data is fit for the analysis or dashboard. Data quality means the data is complete, accurate, consistent, timely, and tied to source of truth. Findings should say what business decision may be affected, not just which field failed.

## Context Requirements

Before auditing, collect:

1. **Schema relationships**: how tables connect.
2. **Business rules by entity**: what values should be allowed.
3. **Acceptable error rates**: how much bad data is tolerable.
4. **Critical fields**: fields that can block delivery if wrong.
5. **Source of truth**: trusted system for key metrics.
6. **Freshness expectations**: how recent data must be.

## Context Gathering

### For Schema Relationships

"To audit data quality, I need to understand how the tables connect:

- Main tables and what one row represents.
- Primary keys, meaning unique row identifiers.
- Foreign keys, meaning fields that link to another table.
- Expected one-to-one or one-to-many relationships.
- Any known many-to-many joins, which can multiply rows."

### For Business Rules

"What rules should the data obey?

- Required fields.
- Allowed values.
- Date rules, such as close date cannot be before open date.
- Metric rules, such as revenue cannot be negative unless it is a refund.
- Segment rules, such as customer tier must match contract terms."

### For Error Tolerance

"Which errors block delivery?

- Critical: a wrong value changes a decision-driving number.
- Important: should be fixed, but result can proceed with a note.
- Minor: tracked for cleanup, not blocking.

What error rate is acceptable for each category?"

## Workflow

### Step 1: Validate Context

Confirm the audit scope, expected outputs, business rules, and source-of-truth checks. If the objective is unclear, ask what decision the data will support.

### Step 2: Profile the Data

Run basic profiling:

- Row counts.
- Distinct counts.
- Missing values.
- Duplicate keys.
- Date ranges.
- Value ranges.
- Unexpected categories.

Explain each issue by consequence. A missing optional description may be harmless; a missing customer ID may break reconciliation.

### Step 3: Check Schema and Relationships

Validate:

- Primary-key uniqueness.
- Foreign-key coverage.
- Join row counts before and after joins.
- Orphan records, meaning rows with no matching parent.
- Duplicate joins that can overcount.

### Step 4: Check Business Rules

Apply entity-level rules:

- Required fields are present.
- Values are in allowed ranges.
- Status transitions make sense.
- Dates follow expected order.
- Financial signs and currencies are consistent.

### Step 5: Reconcile to Source of Truth

Compare key counts and metrics to trusted reports or systems. Record tolerance, difference, and explanation. If reconciliation fails on a decision-driving metric, mark it as blocking for Stage 7.

### Step 6: Synthesize Findings

Prioritize by business impact:

- Blocker: do not execute or deliver until resolved.
- Review: proceed only with documented limitation.
- Monitor: note for follow-up.

### Step 7: Iterate Based on Feedback

After initial findings, refine checks, inspect root causes, and update the validation receipt when issues are resolved or accepted.

## Context Validation

- [ ] Scope and objective are clear.
- [ ] Critical fields are identified.
- [ ] Business rules are available or explicitly assumed.
- [ ] Source-of-truth checks are defined.
- [ ] Error tolerances are known.
- [ ] No contradictions in provided definitions.

## Output Template

```text
Data Quality Audit
Generated: [timestamp]
Dataset or pipeline: [name]
Decision supported: [decision]

## Context Summary
- Tables checked: [tables]
- Source of truth: [system/report]
- Critical fields: [fields]
- Error tolerance: [rules]

## Methodology
[Checks performed and why they matter]

## Key Findings
1. [severity]: [issue] - [decision consequence]
2. [severity]: [issue] - [decision consequence]

## Detailed Checks
- Completeness (missing data): [result]
- Uniqueness (duplicate keys): [result]
- Validity (allowed values): [result]
- Relationships (table links): [result]
- Freshness (data recency): [result]
- Reconciliation (ties to source of truth): [result]

## Recommendations
1. [fix] - [expected outcome]
2. [fix] - [expected outcome]

## Limitations and Assumptions
- [limitation or assumption]

## Validation Receipt Inputs
- Pass/fail: [status]
- Blocking issues: [items]
- Accepted risks: [items and owner]
```

## Common Context Gaps and Solutions

If rules are missing, proceed with basic profiling and clearly label rule-based checks as open. If objectives are unclear, ask: "What decision will this data support, and which wrong number would be most costly?"

