---
name: context-packager
description: Package the right context for AI-assisted BI analysis. Use during intake or handoff to organize task goals, source systems, metric definitions, stakeholders, files, refresh needs, and known constraints.
---

# Context Packager

Used in the assay lifecycle at: Stage 0 (shared)

## Quick Start

Package the context an AI assistant needs to run a trustworthy analysis without guessing: question, decision, data sources, metric definitions, validation rules, stakeholders, and open risks.

## Context Requirements

Collect:

1. **Analysis task**: The question, decision, deliverable, and deadline.
2. **Essential context sources**: Files, dashboards, warehouses, queries, docs, and people.
3. **Context storage locations**: Where the project keeps config, notes, receipts, and outputs.
4. **Context refresh frequency**: How often sources change and what must be rechecked.

## Context Gathering

### For Analysis Task

"What are we trying to answer or build, what decision will it support, who will use it, and what does done mean?"

### For Essential Context Sources

"Which sources matter: warehouse tables, dashboards, spreadsheets, prior analyses, metric definitions, stakeholder notes, or source-of-truth systems?"

### For Context Storage Locations

"Where should the project store working notes, receipts, outputs, and final documentation? If this is an assay project, I will use the configured assay locations."

### For Context Refresh Frequency

"How often do the sources change: real time, daily, weekly, monthly, or only when manually updated? The consequence is whether we must refresh context before each run."

### Handling Partial Context

If context is incomplete:
- Package what is known.
- Mark unknowns visibly.
- Do not invent metric definitions or source-of-truth.
- Ask follow-up questions only for gaps that could change the analysis.

## Workflow

### Step 1: Validate Context

Confirm:
- [ ] The task and decision are clear.
- [ ] Stakeholders are named.
- [ ] Source systems are listed.
- [ ] Key metrics have definitions or are marked missing.
- [ ] Validation expectations are known.

### Step 2: Organize Source Context

Group context into:
- **Business question**: What decision this supports.
- **Data sources**: Warehouse, BI tool, spreadsheets, APIs, and dashboards.
- **Metric definitions**: Formula, filters, source-of-truth (official system for this metric), and owner.
- **Stakeholders**: Requestor, decision maker, reviewers, and data owners.
- **Constraints**: Deadline, access, privacy, refresh, and scope.
- **Receipts needed**: Spec, validation, and peer review if high-stakes.

### Step 3: Create the Context Pack

Write a compact, reusable packet that another analyst or AI assistant can load. Include exact file paths, query names, dashboard links, and owners when available.

### Step 4: Identify Gaps

List gaps by consequence:
- Blocks execution.
- Could change the result.
- Could change presentation.
- Nice to have.

### Step 5: Refresh Rules

Define what must be rechecked:
- Before executing queries.
- Before delivery.
- On each scheduled data-product refresh.

## Context Validation

Before finishing:
- [ ] No source is described vaguely if a path or owner is known.
- [ ] Metric definitions are not guessed.
- [ ] Open questions are tied to consequences.
- [ ] Context can be handed to another person.
- [ ] Plain-language definitions are used for technical terms.

## Output Template

```markdown
# Analysis Context Pack

Generated: [timestamp]

## Task
- Question or deliverable: [task]
- Decision supported: [decision]
- Track: [analysis / data product]
- Deadline or cadence: [date or refresh schedule]

## Stakeholders
| Role | Name | What they decide or own |
|---|---|---|
| Requestor | [name] | [role] |
| Decision maker | [name] | [role] |
| Data owner | [name] | [role] |

## Data Sources
| Source | Location | Owner | Refresh | Notes |
|---|---|---|---|---|
| [source] | [path/link/system] | [owner] | [cadence] | [notes] |

## Metric Definitions
| Metric | Definition | Source-of-truth (official system for this metric) | Open questions |
|---|---|---|---|
| [metric] | [formula and filters] | [source] | [questions] |

## Validation Expectations
- Reconcile to: [source]
- Accepted variance (gap between compared numbers): [threshold]
- Peer review needed? [yes/no and why]

## Scope
- In scope: [items]
- Out of scope: [items]
- Constraints: [access, privacy, timing]

## Context Gaps
| Gap | Consequence | Owner |
|---|---|---|
| [gap] | [blocks or changes result] | [owner] |

## Refresh Rules
- Before execution: [checks]
- Before delivery: [checks]
- Recurring refresh: [checks]
```

## Common Context Gaps & Solutions

**Task is vague**: Ask what decision the answer will drive and what would change if the answer is high or low.

**Metric definition missing**: Mark as blocking for Stage 2 spec until the definition is confirmed.

**Source-of-truth unclear**: List candidate systems and ask the owner to choose.

**Context changes often**: Add refresh checks so stale context does not produce stale results.

## Advanced Options

- **Handoff packet**: Package context for another analyst.
- **Assay intake seed**: Convert the packet into `assay.config` fields.
- **Recurring refresh pack**: Define what changes each run and what remains fixed.
