---
name: dashboard-specification
description: Create BI dashboard specifications that define users, decisions, metrics, layout, refresh, access, and validation needs. Use when planning, replacing, or improving a recurring dashboard or report.
---

# Dashboard Specification

Used in the assay lifecycle at: Stage 4d (data product)

## Quick Start

Create a dashboard specification before development starts. A dashboard, meaning a recurring view of business metrics, should state the decision it supports, who uses it, which metrics are trusted, how often data refreshes, and how the product will be validated.

## Context Requirements

1. **Purpose**: the decision or routine the dashboard supports.
2. **Users**: roles, frequency, and comfort with data tools.
3. **Metrics**: KPI (key performance indicator) and supporting metrics.
4. **Metric definitions**: how each number is calculated and which source is trusted.
5. **Data sources**: systems, tables, and refresh timing.
6. **Layout**: what belongs first, what can be filtered, and what needs detail.
7. **Access and cadence**: who can see it, when it refreshes, and who owns it.

## Context Gathering

"To spec this dashboard, I need:

- Primary decision: what should someone decide after opening it?
- Primary users: who uses it, how often, and under what time pressure?
- Must-have metrics versus nice-to-have metrics.
- Source of truth (trusted system for final numbers) for each key metric.
- Data availability and freshness.
- Existing dashboards to replace, improve, or reconcile.
- Access rules, refresh cadence, and owner."

If the request is "show everything," narrow by consequence: "If the dashboard gets crowded, users may miss the number that needs action. What is the first question it must answer?"

## Workflow

### Step 1: Define Dashboard Purpose

Document:

- Dashboard name.
- Purpose in one plain sentence.
- Decision supported.
- Track: operational, executive, finance, sales, product, or customer.
- Success criteria, such as fewer ad hoc requests or faster daily review.

### Step 2: Define Users and Use Cases

For each user persona:

- Role.
- Frequency.
- Main use case.
- Action they can take.
- Detail level they need.

Design by consequence. Executives usually need fewer, higher-level numbers; operators need faster filters and detail tables.

### Step 3: Define Metric Hierarchy

Separate:

- Primary metrics: first-screen numbers that decide whether attention is needed.
- Secondary metrics: context that explains movement.
- Detail fields: rows used for follow-up.

For every metric, include definition, calculation, source of truth, update timing, owner, and edge cases. Define metric terms inline, such as MRR (monthly recurring subscription revenue) or churn (customers or revenue lost).

### Step 4: Design Information Architecture

Create a layout that supports scanning:

- Top: primary KPI (key performance indicator) values and status.
- Middle: trends, comparisons, and drivers.
- Bottom: details for follow-up.
- Filters: only those needed for the decision.
- Drill-down (clicking summary into detail): only when users need root-cause follow-up.

Avoid adding interactions that make the dashboard harder to interpret or slower to load.

### Step 5: Specify Interactivity

Define:

- Global filters and defaults.
- Drill-down paths.
- Click actions, such as opening CRM records.
- Tooltips, meaning hover text explaining values.
- Export needs.
- Alert thresholds, with who receives alerts.

Frame every interaction by what it enables: "Filter by region to find which manager owns the miss," not "add region slicer."

### Step 6: Document Data Requirements

For each source:

- System and table names.
- Refresh cadence.
- Lag, meaning how late the data may be.
- Keys used to join data.
- Data-quality checks.
- Reconciliation method against source of truth.

If data freshness does not match the use case, call it out. A dashboard used every morning cannot rely on weekly refresh without misleading users.

### Step 7: Generate the Complete Specification

Produce a single specification that a builder can implement and a reviewer can validate. Include wireframe notes, metric definitions, data requirements, acceptance checks, and open questions.

## Context Validation

- [ ] User need and decision are clear.
- [ ] Metrics have definitions and source-of-truth owners.
- [ ] Data sources are available and fresh enough.
- [ ] Refresh cadence matches the decision.
- [ ] Layout prioritizes what users check first.
- [ ] Interactivity supports action, not curiosity alone.
- [ ] Validation plan exists before release.

## Output Template

```text
# Dashboard Specification: [name]

Purpose: [decision or routine supported]
Primary users: [roles and frequency]
Owner: [person/team]
Refresh: [cadence and expected lag]

## Target Users
- [role]: [frequency] - [decision/action]

## Metrics
### Primary
- [metric]: [plain definition], [calculation], [source of truth], [owner]

### Secondary
- [metric]: [plain definition], [calculation], [source of truth], [owner]

## Layout
- Top: [KPI cards or headline numbers]
- Middle: [trend and breakdown charts]
- Bottom: [detail tables or follow-up list]

## Interactivity
- Filters: [defaults and options]
- Drill-down (summary into detail): [paths]
- Actions: [click-throughs or exports]

## Data Requirements
- Source: [system/table]
- Grain (one row represents): [definition]
- Refresh: [timing]
- Checks: [quality and reconciliation checks]

## Validation Before Release
- [check] - [what happens if it fails]

## Success Metrics
- [how we know the dashboard is useful]

## Open Questions
- [question blocking implementation or validation]
```

## Common Scenarios

- Executive dashboard: fewer metrics, clearer thresholds, static summary export.
- Existing dashboard improvement: audit usage, remove clutter, reconcile duplicates.
- Self-service analytics: stronger filters, saved views, and documentation.
- Operational dashboard: faster refresh, alerts, and detail tables.

