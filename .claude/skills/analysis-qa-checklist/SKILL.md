---
name: analysis-qa-checklist
description: Quality-assurance checklist for BI analyses before delivery. Use when reviewing analysis results, checking calculations, validating source-of-truth ties, or preparing a validation receipt.
---

# Analysis QA Checklist

Used in the assay lifecycle at: Stage 7 (shared)

## Quick Start

Use this skill to check whether an analysis is ready to share. Focus on correctness, validation, assumptions, and plain-language delivery. QA means quality assurance (checks before release).

## Context Requirements

Before proceeding, collect:

1. **Analysis to review**: query, notebook, spreadsheet, dashboard, output, or summary.
2. **QA checklist**: required team checks, assay gate requirements, and risk level.
3. **Peer review process**: reviewer names, approval expectations, and evidence format.
4. **Source-of-truth**: official system for each key metric.

## Context Gathering

### For Analysis to Review

"Please provide the analysis artifact:
- Query, workbook, notebook, dashboard link, or exported result.
- The business question.
- Date range and filters.
- Key metric definitions."

### For QA Checklist

"Which checks are required?
- Source-of-truth tie-out.
- Row-count checks.
- Metric-definition review.
- Query logic review.
- Outlier (unusual value that can distort results) handling.
- Plain-language review."

### For Peer Review Process

"Who needs to review this, and what evidence should be recorded?
- Analyst peer.
- Business owner.
- Data owner.
- Approver for high-stakes results."

### Handling Partial Context

If some artifacts are missing:
- Review the available pieces.
- Mark checks as pass, fail, or blocked.
- Do not mark ready-to-deliver until blocked checks are resolved or explicitly accepted.

## Workflow

### Step 1: Validate Context

Confirm:
- [ ] Question and decision are known.
- [ ] Key metrics and definitions are listed.
- [ ] Source-of-truth systems are named.
- [ ] The analysis artifact can be inspected.
- [ ] Delivery risk level is known.

### Step 2: Execute Core QA

Run the checklist:

1. **Question fit**: output answers the stated question.
2. **Metric definition**: numerator, denominator, time window, and filters match the spec.
3. **Data source**: source tables and extracts are correct.
4. **Query logic**: joins, filters, grouping, and date handling are sound.
5. **Reconciliation**: totals tie to source-of-truth or differences are explained.
6. **Sensitivity check**: test assumptions that could change the decision.
7. **Plain language**: every technical term is defined inline.

### Step 3: Synthesize Findings

Return:
- Pass/fail/blocker status.
- Evidence for each check.
- Issues ranked by decision risk.
- Required fixes before Stage 9 delivery.
- Items safe to defer, if any, with consequence.

### Step 4: Iterate Based on Feedback

After fixes:
- Re-run failed checks.
- Confirm no new issue was introduced.
- Update the validation receipt evidence.
- Escalate unresolved high-impact differences.

## Context Validation

Before completion, verify:

- [ ] Context is sufficient for meaningful QA.
- [ ] No contradictions remain in metrics, source, or date range.
- [ ] Scope is well-defined and achievable.
- [ ] Expected outputs are clear.
- [ ] Validation evidence is ready for the assay gate.

## Output Template

```markdown
Analysis QA Checklist
Generated: [timestamp]

## Context Summary
- Business question:
- Artifact reviewed:
- Key metrics:
- Source-of-truth:
- Risk level:

## Methodology
[Checks performed and evidence inspected]

## Key Findings
1. **Status**: [Pass / fail / blocked] - [Delivery consequence]
2. **Largest Risk**: [Issue] - [How it could change the answer]
3. **Validation Evidence**: [Tie-out or gap] - [Gate consequence]

## Detailed Analysis
| Check | Status | Evidence | Consequence |
| --- | --- | --- | --- |
| Question fit |  |  |  |
| Metric definition |  |  |  |
| Data source |  |  |  |
| Query logic |  |  |  |
| Reconciliation |  |  |  |
| Plain language |  |  |  |

## Recommendations
1. **Required Fix**: [Action] - [Expected outcome]
2. **Optional Improvement**: [Action] - [Expected outcome]

## Limitations & Assumptions
- [Check not performed and why]
- [Known caveat]

## Next Steps
1. [Owner] - [Fix or approval needed]
2. [Owner] - [Validation receipt update]
```

## Common Context Gaps & Solutions

**Scenario: Analysis provided without source-of-truth**  
Response: "I can review logic, but I cannot clear validation until we know the official system for this number."

**Scenario: Partial context provided**  
Response: "I will mark unavailable checks as blocked and explain what evidence would clear them."

**Scenario: Unclear objectives**  
Response: "What decision will this result support? That determines which issues block delivery."

## Advanced Options

- High-stakes review checklist.
- Dashboard QA checklist.
- Query-specific validation checklist.
- Validation receipt draft.

## Integration with Other Skills

Works well with:
- `query-validation` for SQL logic review.
- `methodology-explainer` for documented method notes.
- `technical-to-business-translator` for stakeholder-ready issue summaries.
