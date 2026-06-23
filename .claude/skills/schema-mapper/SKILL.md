---
name: schema-mapper
description: Map database schemas and table relationships for BI work. Use when exploring unfamiliar data, documenting table relationships, identifying join paths, or creating data dictionaries for analysis and dashboard projects.
---

# Schema Mapper

Used in the assay lifecycle at: Stage 0 (shared) and Stage 4 (analysis)

## Quick Start

Use this skill to understand where data lives, how tables connect, and which fields can support the analysis. Define schema (map of tables and columns), grain (what one row represents), and join (how two tables connect) before writing queries.

## Context Requirements

Before mapping the schema, collect:

1. **Database access**: connection details, schema export, dbt (tool that builds warehouse tables) project, or existing documentation.
2. **Scope**: all tables, specific schema, specific tables, or naming patterns.
3. **Documentation goal**: ERD (picture of table relationships), join paths, data dictionary, lineage (where the data came from), or quick reference.
4. **Known relationships**: foreign keys (columns linking to another table) and informal relationships.

## Context Gathering

### For Database Access

"I can map the schema from one of these:

- Direct read-only database connection.
- Schema export from information_schema (database catalog of tables and columns).
- dbt (tool that builds warehouse tables) project files.
- Existing ERD, data dictionary, or warehouse documentation.

Which source can you provide?"

### For Scope

"Should I map:
- All tables in the database?
- One schema (group of related tables)?
- Specific tables?
- Tables matching patterns like `fct_*` and `dim_*`?

This matters because a broad map finds surprises, while a narrow map moves faster."

### For Documentation Goal

"What should the map help you do?

1. **Visual ERD**: see table relationships.
2. **Join path finder**: know how Table A connects to Table B.
3. **Data dictionary**: define tables and columns.
4. **Lineage map**: see where data came from.
5. **Quick reference**: common joins and trusted fields."

### For Relationships

"Do you know any relationships not enforced in the database?

Example: `orders.customer_email` matches `customers.email`, but there is no foreign key (column linking to another table). These matter because missing relationship rules can double-count or drop rows."

## Workflow

### Step 1: Connect and Discover Schema

List schemas, tables, and row counts where available. Confirm the result before continuing:

"Found [N] tables in [schema]. Does this match what you expected, and are any important tables missing?"

### Step 2: Extract Table Metadata

For each table in scope, collect:
- Table name and business purpose.
- Columns, data types (kind of value stored), nullability (can be blank), and defaults.
- Primary key (row's unique identifier).
- Foreign keys and indexes (lookup helpers).
- Grain and refresh cadence when known.

### Step 3: Infer Relationships

Identify:
- Explicit foreign keys from database constraints.
- Inferred relationships from naming patterns like `customer_id`.
- Common actor fields like `created_by` or `owner_id`.
- Relationship confidence: high, medium, or low.

State the consequence: "This join may multiply rows, so totals could be overstated."

### Step 4: Generate Data Dictionary

Create a table-level and column-level catalog:
- Table purpose.
- Grain.
- Key columns.
- Metric fields.
- Filters or deleted-record flags.
- Known caveats.
- Source-of-truth metrics tied to each table.

### Step 5: Find Join Paths

For each requested join:
- Show the path from source table to target table.
- Name join keys.
- State join type: inner join (keeps rows matching both tables), left join (keeps all rows from left table), or full join (keeps rows from both tables).
- Warn where the path can duplicate rows or lose records.

### Step 6: Generate ERD

If a visual is needed, create an ERD (picture of table relationships) with:
- Tables grouped by business area.
- Primary keys and foreign keys.
- Relationship confidence markers.
- Notes for informal relationships.

### Step 7: Generate Quick Reference Guide

Summarize:
- Trusted fact tables (event or transaction rows).
- Trusted dimension tables (descriptive lookup tables).
- Common joins.
- Fields to avoid.
- Validation checks to run after joining.

## Context Validation

Before completing:

- [ ] Scope and source are clear.
- [ ] Table grain is documented for important tables.
- [ ] Join paths identify duplication and row-loss risks.
- [ ] Source-of-truth metrics are tied to tables when known.
- [ ] Unverified relationships are labeled.

## Output Template

```markdown
Schema Mapping Report
Generated: [timestamp]

## Context Summary
- Data source:
- Scope:
- Documentation goal:
- Known source-of-truth metrics:

## Methodology
[How schema metadata and relationships were gathered]

## Key Findings
1. **Core Tables**: [Tables] - [Why they matter]
2. **Join Path**: [Path] - [Duplication or row-loss consequence]
3. **Data Risk**: [Risk] - [How it could change the answer]

## Detailed Analysis
### Tables
| Table | Purpose | Grain | Key columns | Caveats |
| --- | --- | --- | --- | --- |

### Relationships
| From | To | Key | Confidence | Consequence |
| --- | --- | --- | --- | --- |

### Join Paths
[Requested joins and safest path]

## Recommendations
1. [Trusted table or join approach] - [Expected outcome]
2. [Validation check] - [Expected outcome]

## Limitations & Assumptions
- [Missing metadata or unverified relationship]
- [Access or scope limitation]

## Next Steps
1. [Confirm relationship]
2. [Use map in spec or query build]
```

## Common Scenarios

### Scenario 1: "New to the database, need overview"
Start broad, then narrow to tables tied to the decision metric.

### Scenario 2: "How do I join Table A to Table B?"
Find all paths, then choose the one with the lowest duplication and row-loss risk.

### Scenario 3: "Document schema for new team members"
Produce a data dictionary and quick reference.

### Scenario 4: "Find all tables related to users"
Search names, foreign keys, and common identifiers.

### Scenario 5: "Validate schema against expectations"
Compare expected tables, keys, and grain to actual metadata.

## Handling Missing Context

If there is no live access, work from exports or docs and label confidence. If relationship rules are missing, require validation before using joins in Stage 6 execution.

## Advanced Options

- ERD generation.
- Join-risk review.
- Source-of-truth mapping.
- Data dictionary cleanup.
- Lineage summary for recurring dashboards.
