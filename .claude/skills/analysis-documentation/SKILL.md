---
name: analysis-documentation
description: Create structured, reproducible documentation for analytical work. Use when documenting findings, methodology, assumptions, code, data sources, validation, or archived analysis evidence.
---

# Analysis Documentation

Used in the assay lifecycle at: Stage 11 (shared)

## Quick Start

Document analytical work so another person can understand what question was answered, how it was answered, what evidence supports it, and how to reproduce it.

## Context Requirements

Collect:

1. **Analysis artifacts**: Code, queries, results, visualizations, and receipts.
2. **Business context**: Problem statement, stakeholders, and decision.
3. **Methodology**: Approach, assumptions, and alternatives considered.
4. **Key findings**: Results, insights, recommendations, and validation.
5. **Audience**: Business, technical, audit, or mixed readers.

## Context Gathering

### For Analysis Artifacts

"Please provide the analysis materials: SQL, notebook, scripts, charts, tables, validation receipt, and any source files. I will document what each artifact proves."

### For Business Context

"What question did this answer, who requested it, what decision does it support, and what was in or out of scope?"

### For Methodology

"How was the analysis done? Include data sources, filters, assumptions, business rules, and any methods that could change the answer."

### For Findings

"What are the main findings, recommendations, confidence (how sure evidence supports answer), and limitations?"

### For Audience

"Who will read this: executives, stakeholders, data team, auditors, or a mixed group? I will structure detail accordingly."

## Workflow

### Step 1: Create Documentation Structure

Use these sections:
1. Executive summary.
2. Business context.
3. Data sources.
4. Methodology.
5. Results.
6. Validation.
7. Insights and recommendations.
8. Reproducibility.
9. Appendix.
10. Change log.

### Step 2: Document Data Sources

For each source, record:
- Name and location.
- Owner.
- Row count.
- Date range.
- Refresh timing.
- Grain (what one row represents).
- Key fields.
- Known issues.
- Source-of-truth (official system for this metric) status.

### Step 3: Document Methodology

For each analysis step, include:
- Purpose.
- Method.
- Rationale.
- Assumption.
- Consequence if the assumption is wrong.

Define cohort (group tracked over time), p-value (chance result is just noise), and statistical significance (unlikely to be random noise) inline when used.

### Step 4: Document Results with Context

For every key result:
- State the metric and value.
- Include the comparison or baseline.
- Explain the consequence.
- Include validation status.
- Link to supporting table or chart.

### Step 5: Document Insights and Recommendations

For each insight:
- Evidence.
- Business impact.
- Confidence.
- Recommended action.
- Expected outcome.
- Risk or limitation.

### Step 6: Add Code and Reproducibility

Include:
- Exact query or script path.
- Environment requirements.
- Inputs and outputs.
- Run order.
- Any manual steps.
- How to re-run without changing results.

### Step 7: Generate Complete Documentation

Assemble the final document, mark status, and ensure open questions are visible. Do not call a document final if validation is incomplete.

## Context Validation

Before finishing:
- [ ] All artifacts are linked or summarized.
- [ ] Business question and decision are explicit.
- [ ] Methodology is reproducible.
- [ ] Assumptions are visible.
- [ ] Results were validated or clearly marked draft.
- [ ] Technical terms are defined inline.

## Output Template

```markdown
# Analysis Documentation: [title]

**Date:** [date]
**Analyst:** [name]
**Status:** [Draft / Validated / Final]

## Executive Summary
[Question, approach, key result, and decision consequence.]

## Key Findings
1. [finding] - [consequence] - confidence (how sure evidence supports answer): [level]
2. [finding] - [consequence] - confidence: [level]
3. [finding] - [consequence] - confidence: [level]

## Business Context
- Question: [question]
- Decision supported: [decision]
- Stakeholders: [names or roles]
- Scope: [included and excluded]

## Data Sources
| Source | Owner | Grain (one row represents) | Date range | Quality notes |
|---|---|---|---|---|
| [source] | [owner] | [grain] | [range] | [notes] |

## Methodology
| Step | Method | Assumption | If wrong, consequence |
|---|---|---|---|
| [step] | [method] | [assumption] | [effect] |

## Results
[Tables, charts, and narrative with source links.]

## Validation
- Source-of-truth (official system for this metric): [source]
- Reconciliation status: [result]
- Open issues: [issues]

## Insights and Recommendations
1. [recommendation] - [expected outcome]
2. [recommendation] - [expected outcome]

## Reproducibility
- Code or query: [path]
- Inputs: [paths or systems]
- Run order: [steps]
- Environment: [tools and versions]

## Appendix
- [supporting details]

## Change Log
| Date | Author | Change |
|---|---|---|
| [date] | [name] | Initial version |
```

## Common Scenarios

**Ad-hoc analysis for stakeholders**: Keep the document lightweight, but include the question, result, recommendation, and validation status.

**Archive for future reference**: Include full methodology, code, assumptions, and reproducibility steps.

**Recurring analysis template**: Parameterize the date range, sources, and output sections.

**Audit or regulated review**: Include complete lineage (where data comes from and goes), approvals, and validation evidence.

**External sharing**: Remove confidential details and define all business-specific terms.

## Advanced Options

- **Executable notebook**: Combine code and narrative.
- **Automated documentation**: Generate recurring sections from a run.
- **Review checklist**: Add peer review findings and sign-off.
