---
name: technical-to-business-translator
description: Translate technical BI analysis into clear business language. Use when explaining statistics, SQL logic, data quality, methodology, or technical findings to non-technical stakeholders.
---

# Technical To Business Translator

Used in the assay lifecycle at: Stage 9 (shared)

## Quick Start

Use this skill to turn technical findings into plain business language without changing the substance. Define technical terms inline in 4-8 words and frame choices by consequence.

## Context Requirements

Before proceeding, collect:

1. **Technical content**: the original analysis, SQL, method notes, metrics, or finding.
2. **Stakeholder technical levels**: who will read it and what they already understand.
3. **Approved terminology**: business names for metrics, products, teams, and systems.
4. **Forbidden jargon**: terms to avoid or replace.
5. **Decision context**: the action the reader may take.

## Context Gathering

### For Technical Content

"Please share the technical content to translate:
- Original wording.
- Metrics and definitions.
- Any charts, query notes, or methodology details.
- What must not change."

### For Stakeholder Technical Levels

"Who is the audience?
- Executive: needs decision and consequence.
- Operator: needs what to do next.
- Analyst-adjacent: can handle light detail.
- Mixed: plain summary first, audit detail after."

### For Approved Terminology

"Which terms should I use?
- Official metric names.
- Product or department names.
- Source-of-truth (official system for the number).
- Words stakeholders already use."

### For Forbidden Jargon

"Which words should I avoid or define?

Examples:
- p-value (chance result is just noise).
- confidence interval (likely range for true value).
- cohort (group tracked over time).
- schema (map of tables and columns)."

### Handling Partial Context

If only the technical content is available:
- Translate conservatively.
- Preserve facts and uncertainty.
- Mark audience or terminology assumptions.

## Workflow

### Step 1: Validate Context

Confirm:
- [ ] Original meaning is understood.
- [ ] Audience and decision are known.
- [ ] Required terms are named.
- [ ] Uncertainty and limitations are preserved.

### Step 2: Execute Core Translation

Translate in layers:

1. **Business answer**: what this means.
2. **Consequence**: why it matters.
3. **Evidence**: which numbers support it.
4. **Method**: how we know, only as much as needed.
5. **Caveat**: what could change the action.

Replace jargon with definitions, not vagueness.

### Step 3: Synthesize Findings

Produce:
- A plain-language version.
- A term map showing replacements.
- Any unresolved wording risks.
- A short explanation of what changed and what did not.

### Step 4: Iterate Based on Feedback

Refine tone, length, and detail level. If the reviewer asks to remove caveats that affect the decision, keep the caveat and make it clearer.

## Context Validation

Before finalizing:

- [ ] Meaning and numbers are unchanged.
- [ ] Every technical term is defined inline or replaced.
- [ ] Choices are framed by business consequence.
- [ ] The reader knows what action is safe.
- [ ] No validation or certainty is implied unless supported.

## Output Template

```markdown
Technical To Business Translation
Generated: [timestamp]

## Context Summary
- Audience:
- Original technical content:
- Decision context:
- Required terminology:

## Methodology
[How the content was translated and what was preserved]

## Key Findings
1. **Main Message**: [Plain-language message] - [Business consequence]
2. **Evidence**: [Number or support] - [Why it is trustworthy]
3. **Caveat**: [Limitation] - [How it affects action]

## Detailed Translation
### Business-Ready Version
[Translated text]

### Term Map
| Technical term | Plain-language wording | Reason |
| --- | --- | --- |

## Recommendations
1. [Use this wording] - [Expected outcome]
2. [Clarify this item] - [Expected outcome]

## Limitations & Assumptions
- [Audience or terminology assumption]
- [Unresolved technical caveat]

## Next Steps
1. [Stakeholder review]
2. [Final packaging]
```

## Common Context Gaps & Solutions

**Scenario: Technical content arrives without audience**  
Response: "I can translate this for a general business reader, but I need the decision context to tune detail level."

**Scenario: Partial context provided**  
Response: "I will preserve the facts and mark terminology assumptions."

**Scenario: Unclear objectives**  
Response: "What should the reader decide, approve, or do after reading this?"

**Scenario: Domain-specific terminology**  
Response: "Define it inline the first time or replace it with the business term stakeholders use."

## Advanced Options

- Executive rewrite.
- Plain-language glossary.
- Slide note translation.
- Methodology simplification.
- Risk and caveat rewrite.

## Integration with Other Skills

Works well with:
- `methodology-explainer` for method sections.
- `executive-summary-generator` for leadership packaging.
- `visualization-builder` for chart labels and annotations.
