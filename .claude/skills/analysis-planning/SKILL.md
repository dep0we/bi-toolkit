---
name: analysis-planning
description: Structure an analysis request into question, scope, metrics, data, method, risks, and deliverables before execution. Use when receiving new analysis requests or preparing the assay Stage 2 spec.
---

# Analysis Planning

Used in the assay lifecycle at: Stage 2 (shared spec)

## Quick Start

Turn a loose analysis request into a clear plan before computing results. The plan should say what decision the work supports, which metrics will be used, what data is needed, what method will be followed, and what would make the answer valid.

## Context Requirements

Before planning, collect:

1. **Analysis request**: the question being asked.
2. **Decision**: what action the answer will inform.
3. **Metrics**: numbers used to answer the question.
4. **Scope**: included and excluded time periods, segments, and data sources.
5. **Workflow**: steps from data pull through delivery.
6. **Time estimates**: due date and review checkpoints.
7. **Dependencies**: data, stakeholder, and validation needs.

## Context Gathering

### For the Analysis Request

"What question are we answering, and what decision depends on it?

Please provide:
- The exact question.
- Who will use the answer.
- What action they may take.
- Deadline or meeting date.
- What a useful answer looks like."

### For Metrics and Scope

"Which metrics should answer this question?

For each metric, I need:
- Plain definition.
- Source of truth.
- Time period.
- Segments.
- Inclusion and exclusion rules."

### For Workflow and Dependencies

"What needs to happen before delivery?

- Data sources and access.
- Query or tool language.
- Data-quality checks.
- Validation against source of truth.
- Reviewers.
- Final format."

### Handling Partial Context

Proceed with what is available only after marking unknowns as open questions. Do not silently choose a metric definition, time window, or source of truth when that choice could change the answer.

## Workflow

### Step 1: Validate Context

Confirm that the question, decision, stakeholders, and requested output are clear. If the work does not support a decision, recommend reframing or stopping.

### Step 2: Define the Spec

Write:

- Question.
- Decision supported.
- Metrics and definitions.
- Scope.
- Data sources.
- Valid-answer criteria.
- Deliverable format.

This becomes the spec receipt for the front gate.

### Step 3: Identify Methodology Forks

List choices that could change the result:

- Metric definition.
- Time window.
- Segment boundaries.
- Missing-value handling.
- Outlier handling, meaning how unusual values are treated.
- Comparison baseline.
- Statistical method, meaning the calculation approach.

Tier choices by consequence:

- Tier A: changes a decision-driving number.
- Tier B: affects interpretation.
- Tier C: small presentation or convenience choice.

### Step 4: Plan the Work

Break work into steps:

1. Pull or receive data.
2. Profile data.
3. Validate metric definitions.
4. Run analysis.
5. Reconcile to source of truth.
6. Review conclusion.
7. Package deliverable.

Add owners, dates, and dependencies where known.

### Step 5: Define Risks and Assumptions

Record assumptions in the assumptions log. Call out blockers early, especially missing source of truth, unclear metric definitions, inaccessible data, or high-stakes decisions without review time.

### Step 6: Confirm the Plan

Before execution, ask for confirmation of scope, metrics, and validation criteria. Do not compute final results until the Stage 2 spec is accepted or explicitly marked trivial.

## Context Validation

- [ ] Question is precise.
- [ ] Decision supported is stated.
- [ ] Metrics and definitions are documented.
- [ ] Source of truth is named.
- [ ] Scope and exclusions are clear.
- [ ] Validation criteria are defined.
- [ ] Open questions and risks are visible.

## Output Template

```text
Analysis Plan
Generated: [timestamp]

## Question
[exact question]

## Decision Supported
[what action this answer informs]

## Metrics and Definitions
- [metric]: [plain definition], [calculation], [source of truth]

## Scope
- Time period: [period]
- Segments: [segments]
- Included: [items]
- Excluded: [items]

## Data Sources
- [source/table/report] - [owner/access/freshness]

## Methodology Forks
- [choice] - [consequence if chosen differently] - [tier]

## Workflow Steps
1. [step]
2. [step]

## Validation Criteria
- [check that must pass]

## Risks and Assumptions
- [risk/assumption]

## Open Questions
- [question]
```

## Common Context Gaps and Solutions

If the request is too broad, ask which decision comes first. If the metric definition is unclear, stop and define it before analysis. If the source of truth is missing, mark validation as blocked.
