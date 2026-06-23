---
name: methodology-explainer
description: Explain analysis methodology in plain business language. Use when documenting how an analysis was performed, why a method was chosen, what assumptions matter, and how limitations affect decisions.
---

# Methodology Explainer

Used in the assay lifecycle at: Stage 9 (shared)

## Quick Start

Use this skill to explain the method behind an analysis so stakeholders can trust the answer without needing technical depth. Define each technical term inline and connect every method choice to its consequence.

## Context Requirements

Before proceeding, collect:

1. **Analysis methodology**: data sources, metric definitions, filters, time windows, statistical methods, and validation checks.
2. **Methodology template**: required format, length, and review standards.
3. **Detail level by audience**: executive, operational, analyst, or mixed.
4. **Known limitations**: missing data, assumptions, sample size (number of records), outliers (unusual values that distort results), or source changes.

## Context Gathering

### For Analysis Methodology

"Please share how the analysis was done:
- Data sources and source-of-truth (official system for the number).
- Metric definitions.
- Date range and filters.
- Method choices, such as cohort (group tracked over time), segment (group that behaves similarly), or statistical test (method to compare results).
- Validation checks already performed."

### For Methodology Template

"What format should the explanation follow?
- Short executive note.
- Appendix section.
- Audit-ready documentation.
- Slide speaker notes.
- Existing template."

### For Detail Level by Audience

"Who needs to understand this?
- Executives need consequence and trust.
- Operators need how to repeat it.
- Analysts need enough detail to audit it."

### Handling Partial Context

If only partial methodology is available:
- Explain what is known.
- Mark unknowns that could change the answer.
- Do not imply validation happened unless evidence is provided.

## Workflow

### Step 1: Validate Context

Confirm:
- [ ] The question and decision are clear.
- [ ] Data sources and metric definitions are named.
- [ ] Each method choice has a reason.
- [ ] Limitations are known or explicitly marked.
- [ ] Audience detail level is clear.

### Step 2: Execute Core Analysis

Translate the methodology:

1. **Plain summary**: explain what was measured and why.
2. **Data path**: name where the data came from and how it was filtered.
3. **Method choice**: explain each choice by consequence, not jargon.
4. **Validation**: describe tie-outs to source-of-truth and checks performed.
5. **Limitations**: state what could change the answer.

### Step 3: Synthesize Findings

Present:
- What was done.
- Why it was the right level of rigor.
- What the method can and cannot prove.
- What stakeholders should keep in mind before acting.

### Step 4: Iterate Based on Feedback

Adjust detail level, definitions, and examples. If reviewers challenge a method choice, explain the consequence of changing it and route unresolved choices back to the assay decision ledger.

## Context Validation

Before finalizing:

- [ ] No technical term is left undefined.
- [ ] Method choices explain business consequences.
- [ ] Validation is described accurately.
- [ ] Limitations are specific and decision-relevant.
- [ ] The explanation does not overclaim causation (one thing caused another) when the analysis only shows correlation (two measures moving together).

## Output Template

```markdown
Methodology Explanation
Generated: [timestamp]

## Context Summary
- Business question:
- Data sources:
- Audience:
- Decision supported:

## Methodology
[Plain-language explanation of the approach]

## Key Findings
1. **Method Choice**: [Choice] - [Consequence]
2. **Validation**: [Check] - [Why it supports trust]
3. **Limitation**: [Limitation] - [How it could affect action]

## Detailed Analysis
[Data sources, metric definitions, filters, method decisions, and validation steps]

## Recommendations
1. **Use this result for**: [Decision type] - [Why]
2. **Do not use this result for**: [Decision type] - [Why]

## Limitations & Assumptions
- [Limitation or assumption]
- [Limitation or assumption]

## Next Steps
1. [Reviewer or stakeholder confirmation]
2. [Documentation or validation follow-up]
```

## Common Context Gaps & Solutions

**Scenario: Method details are missing**  
Response: "I can draft the explanation, but I need the data source, metric definition, and validation checks before calling it complete."

**Scenario: Audience is mixed**  
Response: "I will put the plain-language method first and the audit detail afterward."

**Scenario: Technical term appears**  
Response: "Define it inline, for example: p-value (chance result is just noise)."

## Advanced Options

- Executive-ready methodology note.
- Audit appendix.
- Method choice comparison by consequence.
- Reviewer response draft.

## Integration with Other Skills

Works well with:
- `analysis-qa-checklist` for review evidence.
- `technical-to-business-translator` for final wording.
- `executive-summary-generator` for packaging.
