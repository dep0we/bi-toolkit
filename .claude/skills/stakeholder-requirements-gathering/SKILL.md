---
name: stakeholder-requirements-gathering
description: Structured requirements gathering for BI analysis requests. Use when scoping new analysis work, clarifying an unclear business question, choosing the analysis or data-product track, or documenting acceptance criteria with stakeholders.
---

# Stakeholder Requirements Gathering

Used in the assay lifecycle at: Stage 0 (shared) and Stage 1 (shared)

## Quick Start

Use this skill to turn an analysis request into a clear decision, scope, owner list, and done criteria. Keep questions plain: define any business or data term inline, then explain what decision changes based on the answer.

## Context Requirements

Before proceeding, collect:

1. **Analysis request**: the question, decision, deadline, and why it matters.
2. **Requirements template**: the required format for scope, metrics, assumptions, owners, and approval.
3. **Intake process**: how the team currently captures requests, source-of-truth systems, and validation habits.
4. **Prioritization framework**: how urgency, business value, effort, and risk are ranked.

## Context Gathering

If any required context is missing, ask for it directly.

### For Analysis Request

"What decision should this analysis support?

Please include:
- The business question in one sentence.
- The action someone may take after seeing the answer.
- The deadline or recurring cadence.
- The metric (number stakeholders act on) and source-of-truth (official system for that number)."

### For Requirements Template

"What format should the requirements follow?

Please share:
- Required sections or examples from prior work.
- Who must approve the scope.
- What counts as done for this deliverable."

### For Intake Process

"How does your team intake analysis work today?

Please include:
- Where requests arrive.
- Who clarifies questions.
- How metric definitions are confirmed.
- How results are validated before sharing."

### For Prioritization Framework

"How should this request be prioritized?

Please include:
- Decision impact: money, headcount, strategy, customer experience, or lower-stakes context.
- Urgency and deadline consequence.
- Expected effort or known blockers.
- Stakeholders who must agree."

### Handling Partial Context

If only some context is available:
- Proceed with what is known and label unknowns.
- Use plain defaults only when they do not change the decision.
- Ask follow-up questions before committing to scope, metrics, or track.

## Workflow

### Step 1: Validate Context

Confirm:
- [ ] The real decision is named.
- [ ] The intended track is clear: analysis (answer a question) or data product (recurring report/dashboard).
- [ ] Key stakeholders and approvers are identified.
- [ ] Source-of-truth systems are named for important metrics.
- [ ] Acceptance criteria explain what will be true when the work is done.

### Step 2: Execute Core Analysis

Follow a structured intake:

1. **Initial assessment**: restate the request in plain language and identify the decision consequence.
2. **Scope definition**: capture included populations, time windows, metrics, filters, and exclusions.
3. **Risk check**: flag high-stakes uses that affect money, headcount, strategy, or recurring unattended reporting.
4. **Quality checks**: confirm validation expectations and known source-of-truth comparisons.
5. **Checkpoint**: share the proposed scope before moving to spec.

### Step 3: Synthesize Findings

Produce a requirements summary with:
- Business question and decision.
- Track recommendation and why it matters.
- Stakeholders, approvers, and delivery format.
- Metrics, definitions, and source-of-truth systems.
- Assumptions, exclusions, and open questions.
- Acceptance criteria and validation plan.

### Step 4: Iterate Based on Feedback

After sharing the draft:
- Tighten vague wording into observable criteria.
- Resolve metric-definition conflicts before execution.
- Record open choices that need Stage 2 spec decisions.
- Escalate any fork that could change the answer stakeholders act on.

## Context Validation

Before completing the intake, verify:

- [ ] Context is sufficient for a meaningful spec.
- [ ] No contradictions remain in stakeholders, metrics, timing, or source-of-truth.
- [ ] Scope is achievable within the stated deadline.
- [ ] Output format matches the audience and decision.

## Output Template

```markdown
Stakeholder Requirements Gathering
Generated: [timestamp]

## Context Summary
- Business question:
- Decision this informs:
- Track: analysis / data product
- Stakeholders and approvers:
- Delivery deadline or cadence:

## Methodology
[Brief description of the intake approach and checks performed]

## Key Findings
1. **Decision**: [What action depends on this answer] - [Consequence]
2. **Scope**: [What is included/excluded] - [Consequence]
3. **Validation Need**: [What must tie out] - [Consequence]

## Detailed Analysis
[Requirements, metric definitions, source-of-truth systems, assumptions, and open questions]

## Recommendations
1. **Track Recommendation**: [Analysis or data product] - [Why this route fits]
2. **Next Stage**: [What Stage 2 must lock] - [Why it matters]

## Limitations & Assumptions
- [Known gap or assumption]
- [Known gap or assumption]

## Next Steps
1. [Approval or clarification needed]
2. [Spec receipt item to create]
```

## Common Context Gaps & Solutions

**Scenario: User requests requirements gathering without context**  
Response: "I can help scope this. What decision will the answer change, and which metric (number stakeholders act on) matters most?"

**Scenario: Partial context provided**  
Response: "I can proceed with the known details and mark the missing items. I need source-of-truth (official system for the number) before execution."

**Scenario: Unclear objectives**  
Response: "What action will someone take if the answer is high, low, or unchanged?"

**Scenario: Domain-specific terminology**  
Response: "When you say [term], do you mean [plain definition]? The definition matters because it changes which rows are counted."

## Advanced Options

After the basic intake, offer:
- Deeper stakeholder interview questions.
- Priority scoring by business impact and deadline risk.
- Alternative scope options with consequences.
- Acceptance-criteria rewrite for the Stage 2 spec receipt.

## Integration with Other Skills

Works well with:
- `schema-mapper` for source and table discovery.
- `analysis-qa-checklist` for validation expectations.
- `technical-to-business-translator` for stakeholder-ready wording.
