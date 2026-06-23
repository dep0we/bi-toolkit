---
name: sql-to-business-logic
description: Translate SQL queries into plain-language business logic. Use when documenting queries, validating whether SQL matches requirements, explaining analysis to non-technical stakeholders, or creating query catalog descriptions.
---

# SQL to Business Logic Translator

Used in the assay lifecycle at: Stage 11 (shared)

## Quick Start

Convert SQL into business-readable steps so stakeholders can confirm what the query counts, filters, excludes, groups, and returns.

## Context Requirements

Before translating SQL, collect:

1. **SQL query**: The full query or the query file.
2. **Business question**: What the query is supposed to answer.
3. **Audience**: Who needs to understand or approve the logic.
4. **Schema info**: Schema (list of fields and meanings), table descriptions, and business names for fields.
5. **Output format**: Narrative, bullets, validation checklist, or catalog entry.

## Context Gathering

### For SQL Query

"Share the SQL query or file path. I will explain what it does in business language and flag logic that may change the number."

### For Business Question

"What question should this query answer? Examples: monthly revenue trend, churn count, active customer list, or renewal pipeline."

### For Audience

"Who needs this explanation: data team, business stakeholders, leadership, or a mixed group? I will decide how much technical detail to include."

### For Schema

"Please provide table and column meanings if available. For example, status = completed means paid and fulfilled. Without this, I can translate structure but not business meaning."

### For Output Format

"Should the output be a narrative, step-by-step bullets, a validation checklist, or a catalog description?"

## Workflow

### Step 1: Parse SQL Structure

Identify:
- Query type: select, insert, update, or delete.
- Source tables and joins.
- Selected output fields.
- Filters.
- Grouping.
- Aggregations (summaries like count or sum).
- Sorting.
- Nested queries.

Define join (matching rows across tables) and aggregation (summary calculation across rows) inline when used.

### Step 2: Translate Selected Fields

For each output field:
- Use the business name when known.
- Explain calculations in plain words.
- Define distinct (count each item once) when used.
- Explain aliases as the names shown in the result.

### Step 3: Translate Filters

For each WHERE or HAVING condition:
- State what is included or excluded.
- Explain the business consequence.
- Flag date windows, status filters, null checks, and exclusions because they often change stakeholder-facing numbers.

### Step 4: Translate Grouping and Aggregations

Explain:
- Group by means "calculate separately for each group."
- Count, sum, average, min, and max in business terms.
- Date truncation as "roll up dates into [day/week/month]."
- Any grouping by number, such as GROUP BY 1, as a reference to an output column.

### Step 5: Generate Business Logic Narrative

Use this order:
1. Purpose.
2. Data sources.
3. Included records.
4. Excluded records.
5. Calculations.
6. Output.
7. Sorting.
8. Validation questions.

### Step 6: Add Validation Questions

Ask questions that reveal mismatches:
- Should these statuses be included?
- Is the date field the right one?
- Should revenue include tax, shipping, discounts, or refunds?
- Are repeat customers counted once or every time?
- Is the timezone correct?

## Context Validation

Before sharing:
- [ ] SQL query is complete.
- [ ] Business question is stated.
- [ ] Table and field meanings are documented or marked missing.
- [ ] Technical terms are defined inline.
- [ ] Validation questions focus on choices that change the number.

## Output Template

```markdown
# SQL Query Translation

## Business Purpose
[What business question this query answers.]

## What This Query Does
[Plain-language summary of the metric or list produced.]

## Step-by-Step Logic

1. **Start with:** [table or source and business meaning]
2. **Join (match rows across tables):** [tables and matching fields, if any]
3. **Filter to:** [included records]
4. **Exclude:** [excluded records]
5. **Group by (calculate separately for each group):** [fields]
6. **Calculate:** [metrics and formulas]
7. **Sort:** [order]

## Output Columns
| Column | Business meaning |
|---|---|
| [column] | [meaning] |

## Business Rules Applied
- [rule and consequence]
- [rule and consequence]

## Validation Questions
1. [question about a choice that changes the result]
2. [question about missing context]
3. [question about source-of-truth, the official system for this metric]

## Technical Notes
- [performance or edge case, defined plainly]
- [refresh timing or timezone]
```

## Common Scenarios

**Explain a query to a manager**: Focus on purpose, included records, excluded records, and validation questions.

**Document a query for analysts**: Include business logic, assumptions, edge cases, and query-change notes.

**Validate query logic before running**: Translate the query, compare it to requirements, and flag mismatches.

**Create query catalog entry**: Standardize purpose, inputs, outputs, business rules, owner, and refresh timing.

## Advanced Options

- **Optimization review**: Check whether the query could run faster and explain the consequence.
- **Data quality checks**: Add checks for nulls (empty values), duplicates (same record repeated), and expected ranges.
- **Query comparison**: Explain what changed between old and new versions.
- **Test cases**: Create sample inputs and expected outputs.
