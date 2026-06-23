---
name: peer-review-template
description: Run structured peer review for analytical work. Use when red-teaming conclusions, reviewing methods, checking evidence, scoring an assay result, or providing actionable feedback before delivery.
---

# Peer Review Template

Used in the assay lifecycle at: Stage 8 (shared)

## Quick Start

Review analytical work for decision risk: wrong question, weak method, bad data, unsupported conclusion, unclear language, or missing validation.

## Context Requirements

Collect:

1. **Work to review**: Analysis document, query, workbook, notebook, dashboard, or result packet.
2. **Review template**: Required review areas or assay score dimensions.
3. **Review process**: Who reviews, how findings are handled, and whether the result is gated.
4. **Feedback standards**: Severity levels and what blocks delivery.

## Context Gathering

### For Work to Review

"Please provide the analysis, dashboard, query, or result packet. Include the spec receipt and validation receipt if this is part of an assay run."

### For Review Template

"Should I use the assay score dimensions: confidence (how sure answer is right), data completeness, methodology soundness, and reproducibility?"

### For Review Process

"Is this a blocking review before delivery, an advisory review, or a draft feedback pass? The consequence changes how strict the review should be."

### For Feedback Standards

"What severity should block delivery? If no rule is provided, I will treat incorrect numbers, missing validation, unclear source-of-truth, and unsupported recommendations as blockers."

### Handling Partial Context

If only part of the work is available:
- Review what is available.
- Mark missing evidence clearly.
- Do not approve delivery without enough evidence.

## Workflow

### Step 1: Validate Context

Confirm:
- [ ] The work product is available.
- [ ] The decision and audience are known.
- [ ] Data sources and method are visible.
- [ ] Validation evidence is present or marked missing.

### Step 2: Review by Lens

Use these lenses:
1. **Question fit**: Does the work answer the question asked?
2. **Data completeness**: Did the analysis use enough relevant data?
3. **Metric definition**: Are metrics defined and tied to source-of-truth?
4. **Methodology soundness**: Would the approach survive expert review?
5. **Reproducibility**: Could someone re-run it and get the same answer?
6. **Conclusion support**: Do recommendations follow from evidence?
7. **Plain language**: Are technical terms defined inline?

### Step 3: Score the Result

Score 1-5:
- **Confidence**: How sure the answer is right.
- **Data completeness**: How much relevant data was included.
- **Methodology soundness**: Whether the approach is appropriate.
- **Reproducibility**: Whether someone else can re-run it.

Any score below the assay threshold blocks delivery unless accepted with a recorded reason.

### Step 4: Write Findings

For each finding:
- Severity.
- Evidence.
- Consequence.
- Required fix.
- Owner if known.

Lead with blockers, then important non-blockers, then polish.

### Step 5: Iterate Based on Fixes

After fixes:
- Re-review the changed area.
- Check whether the fix created a new issue.
- Update score only when evidence changes.

## Context Validation

Before completing:
- [ ] Review findings cite evidence.
- [ ] Scores match the written findings.
- [ ] Blockers are clear.
- [ ] Recommendations are actionable.
- [ ] Plain-language issues are treated as defects.

## Output Template

```markdown
# Peer Review

Reviewed item: [name]
Reviewer: [name]
Date: [date]
Review type: [blocking / advisory / draft]

## Verdict
[Pass / revise before delivery / blocked]

## Assay Score
| Dimension | Score 1-5 | Reason |
|---|---:|---|
| Confidence (how sure answer is right) | [score] | [reason] |
| Data completeness (relevant data included) | [score] | [reason] |
| Methodology soundness (approach fits question) | [score] | [reason] |
| Reproducibility (can be re-run) | [score] | [reason] |

## Blocking Findings
1. **[title]**
   - Evidence: [specific evidence]
   - Consequence: [why this matters]
   - Required fix: [action]

## Non-Blocking Findings
1. [finding] - [suggested fix]

## Plain-Language Review
- [terms needing inline definition]
- [choices that need consequence framing]

## Open Questions
- [question]

## Re-Review Notes
- [what changed after fixes]
```

## Common Context Gaps & Solutions

**No validation receipt**: Mark as blocked for delivery and review only the draft logic.

**Method is unclear**: Ask for the query, notebook, or methodology notes before scoring.

**Audience is unclear**: Review for both business clarity and technical reproducibility.

**Domain term appears undefined**: Request an inline definition of 4-8 words.

## Advanced Options

- **Deep methodology review**: Focus on assumptions, statistical tests, and causality claims.
- **Plain-language-only pass**: Review wording for BI operators.
- **Score calibration**: Compare scores across multiple analyses.
