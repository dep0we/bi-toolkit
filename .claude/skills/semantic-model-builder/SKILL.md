---
name: semantic-model-builder
description: Build semantic model documentation for BI metrics, entities, relationships, and data definitions. Use when defining business metrics, documenting tables, preparing data products, or making analysis reproducible.
---

# Semantic Model Builder

Used in the assay lifecycle at: Stage 4d (data product) and Stage 11 (shared documentation)

## Quick Start

Build semantic documentation, meaning business-friendly data definitions, so analysts and BI operators use the same metric, table, and relationship meanings. This prevents two dashboards from showing different numbers for the same business question.

## Context Requirements

1. **Metric, entity, or concept**: what needs documentation.
2. **Calculation logic**: SQL (query language for data), formula, or plain-English steps.
3. **Business context**: why it matters and what decision it supports.
4. **Data sources**: where the data comes from.
5. **Grain**: what one row represents.
6. **Relationships**: how tables connect.
7. **Source of truth**: trusted source for final numbers.

## Context Gathering

### Initial Prompt

"Let's build semantic documentation. What should we document?

- A specific metric, such as MRR (monthly recurring subscription revenue).
- A data model or table, such as `users` or `transactions`.
- A business concept, such as active customer.
- Multiple related items used by a dashboard or analysis."

### For Metrics

"For [metric name], I need:

1. Definition: what it means in plain English.
2. Calculation: SQL, formula, or steps.
3. Business context: who uses it, what decision it informs, and what good looks like.
4. Edge cases: what to include, exclude, or treat carefully.
5. Source of truth: trusted system or report."

### For Data Models

"For [table/model name], I need:

1. Purpose: what the table represents.
2. Grain (one row represents): one user, one order, one user per day, etc.
3. Key columns: IDs, dates, measures, and attributes.
4. Relationships: how it connects to other tables.
5. Known quality issues: duplicates, missing values, late-arriving rows."

### For Business Concepts

"For [concept], I need:

1. Definition.
2. How to identify it in data.
3. Where it is captured.
4. Why it matters.
5. What decisions change if the definition changes."

## Workflow

### Step 1: Gather Information

Start with what is available. If the user provides SQL, extract the metric, filters, joins, time windows, and edge cases. If the user provides a table name, identify grain, keys, relationships, and owner. If the user provides only a business term, translate it into data requirements and open questions.

### Step 2: Write Business Definitions

Write definitions in operator language first, then technical calculation second. Define technical terms inline:

- Grain (one row represents).
- Dimension (category used for slicing).
- Measure (number being calculated).
- Join (combining tables by matching keys).

### Step 3: Document Calculation Logic

For each metric, document:

- Formula or SQL.
- Filters.
- Time window.
- Included and excluded records.
- Null handling, meaning what happens with missing values.
- Rounding.
- Source of truth.

Frame choices by consequence: changing a time window changes comparability; excluding refunds changes revenue; counting test users inflates adoption.

### Step 4: Document Relationships

Map entities and relationships:

- Primary key, meaning unique row identifier.
- Foreign key, meaning link to another table.
- One-to-one, one-to-many, or many-to-many relationship, with the business meaning.

Call out relationship risks such as duplicate joins, which can multiply rows and overstate metrics.

### Step 5: Capture Ownership and Change Control

Record metric owner, source owner, review cadence, last updated date, and how proposed changes are approved. Metric-definition changes can alter dashboards and prior analyses, so they should be treated as lifecycle decisions.

## Context Validation

- [ ] Every metric has a plain-English definition.
- [ ] Every calculation has source, filters, time window, and edge cases.
- [ ] Grain is stated for every table.
- [ ] Relationships include keys and risk notes.
- [ ] Source of truth is named for decision-driving metrics.
- [ ] Open questions are separated from confirmed definitions.

## Output Template

```text
# Semantic Model: [metric/table/concept]

## Business Definition
[Plain-English definition and why it matters]

## Calculation
- Formula or SQL: [logic]
- Time window: [window]
- Filters: [included/excluded records]
- Null handling (missing value rule): [rule]
- Source of truth: [system/report]

## Grain
One row represents: [definition]

## Key Fields
- [field]: [meaning and type]

## Relationships
- [table.field] joins to [table.field] - [business meaning and risk]

## Edge Cases
- [case] - [decision consequence]

## Owner and Review
- Business owner: [name/team]
- Data owner: [name/team]
- Review cadence: [cadence]

## Open Questions
- [question]
```

