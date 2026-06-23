---
name: data-catalog-entry
description: Create standardized metadata for data assets. Use when documenting datasets, tables, dashboards, reports, API outputs, data dictionaries, ownership, quality, lineage, or access guidance.
---

# Data Catalog Entry

Used in the assay lifecycle at: Stage 11 (shared)

## Quick Start

Create a catalog entry that helps a BI operator find, understand, trust, and correctly use a data asset.

## Context Requirements

Collect:

1. **Data asset details**: What exists and where it lives.
2. **Business context**: What it represents and why it matters.
3. **Technical specifications**: Schema (list of fields and meanings), format, size, and refresh.
4. **Access and governance**: Who can use it and restrictions.
5. **Quality metrics**: Completeness, freshness, duplicates, and known issues.

## Context Gathering

### For Data Asset

"What data asset are we cataloging: table, view, CSV, dashboard, report, or API endpoint? Please provide name, location, owner, and created date if known."

### For Business Context

"What business process does this data represent, who uses it, what decisions does it support, and how critical is it?"

### For Schema

"Please provide column names, data types, meanings, sample values, relationships, and business rules. I will define schema as list of fields and meanings in the entry."

### For Quality

"How reliable is this data? Include completeness, freshness, known issues, duplicate risk, and whether it matches the source-of-truth (official system for this metric)."

### For Access

"Who can use this asset? Does it include PII (personally identifying information), financial data, confidential data, or compliance restrictions?"

## Workflow

### Step 1: Extract Technical Metadata

Capture:
- Asset name.
- Type.
- Location.
- Row count or size.
- Columns and data types.
- Primary key, if any.
- Foreign keys, if any.
- Sample rows, when safe.
- Last updated timestamp.

Define primary key as "field that uniquely identifies records" and foreign key as "field linking to another table" when used.

### Step 2: Add Business Context

Add:
- Display name.
- Plain-language description.
- Business owner.
- Technical owner.
- Domain.
- Criticality.
- Common use cases.
- Stakeholders.

### Step 3: Document Column Definitions

For each important field:
- Business name.
- Description.
- Example values.
- Business rules.
- Allowed values.
- Whether it is required.

Explain consequences. Example: "If order_status excludes refunded orders, revenue will not match finance refund reporting."

### Step 4: Add Data Quality Metrics

Include:
- Completeness (how much data is filled in).
- Freshness (how recently data updated).
- Duplicates (same record repeated).
- Accuracy checks.
- Known defects.
- Quality score only if the scoring method is documented.

### Step 5: Document Lineage

Lineage means where data comes from and goes. Record:
- Upstream sources.
- Transformations.
- Downstream dashboards, reports, and models.
- Refresh frequency.

### Step 6: Add Access and Governance

Document:
- Access level.
- Sensitivity.
- Compliance tags.
- Retention policy.
- How to request access.
- Approved and restricted uses.

### Step 7: Generate Catalog Entry

Produce a human-readable Markdown entry and, when useful, structured JSON metadata.

## Context Validation

Before publishing:
- [ ] Technical metadata is accurate.
- [ ] Business owner reviewed meaning.
- [ ] Column definitions are clear to non-technical users.
- [ ] Quality metrics are current.
- [ ] Access policies are documented.
- [ ] Lineage is complete enough to explain trust.

## Output Template

```markdown
# [Display Name]

## Overview
- Name: [schema.asset]
- Type: [table/view/file/dashboard]
- Domain: [business area]
- Criticality: [critical/high/medium/low]
- Description: [plain-language purpose]

## Ownership
- Business owner: [owner]
- Technical owner: [owner]

## Data Quality
- Completeness (how much data is filled in): [value]
- Freshness (how recently data updated): [value]
- Duplicates (same record repeated): [value]
- Known issues: [issues]

## Schema (list of fields and meanings)
| Column | Type | Business meaning | Required | Keys |
|---|---|---|---|---|
| [column] | [type] | [meaning] | [yes/no] | [PK/FK/-] |

## Use Cases
- [use case and decision supported]
- [use case and decision supported]

## Lineage (where data comes from and goes)
### Upstream Sources
- [source] - [refresh or transformation]

### Downstream Consumers
- [dashboard/report/model] - [use]

## Access and Governance
- Access level: [level]
- Sensitivity: [none/PII/financial/confidential]
- Compliance: [tags]
- Access instructions: [how to request]
- Approved uses: [uses]
- Restricted uses: [uses]

## Sample Queries or Examples
[optional]

---
Last updated: [timestamp]
```

## Common Scenarios

**New table needs catalog entry**: Extract metadata, interview owner, document definitions, assess quality, then publish.

**Catalog completeness audit**: Find missing entries, prioritize by usage and criticality, and fill gaps.

**Users cannot find data**: Improve descriptions, business names, tags, and use cases.

**Compliance audit**: Document sensitive fields, access controls, retention, and approved use.

**Analyst onboarding**: Add key datasets, common joins, and sample queries.

## Advanced Options

- **Automated metadata extraction**: Refresh technical metadata on a schedule.
- **Data profiling**: Add distributions and outlier summaries.
- **Schema change tracking**: Alert when fields change.
- **Usage analytics**: Track how often the asset is queried.
