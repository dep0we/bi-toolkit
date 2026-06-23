---
name: assay
description: Router for the assay BI quality loop. Invoke when the operator types /assay with a subcommand: intake, frame, spec, discovery, execute, validate, deliver, or status.
---

# /assay - BI quality loop router

The assay loop helps BI operators ship trustworthy analysis. It routes work
through the staged lifecycle: intake, frame, spec, discovery, execute, validate,
review, deliver, document, and learn.

Project-specific rules live in `assay.config.jsonc`. Receipts live in
`.assay/receipts/`. A receipt is a saved proof file for a completed stage.

## Plain-Language Rule

Every operator-facing term must be defined inline in 4-8 words. Example:
cohort (group tracked over time). If a term might be unclear to a BI operator,
define it where it appears.

## Load Config First

Before every subcommand:

1. Read `assay.config.jsonc` if present.
2. If absent, continue with safe defaults and recommend `/assay intake`.
3. Do not overwrite the operator's config.

## Subcommands

### `/assay intake`

Interview the operator and fill in:

- BI stack: warehouse, BI tool, query language.
- Source-of-truth list, meaning the official source for each key metric.
- Validation habit, meaning how numbers are checked.
- Stakeholders and delivery rules.
- High-stakes examples, meaning work that drives money, headcount, or strategy.

Write or update `assay.config.jsonc` and `CLAUDE.md` only with operator approval.

### `/assay frame`

Decide whether the request is:

- analysis, meaning a one-time answer to a question; or
- data product, meaning a recurring report or dashboard.

Capture the decision the answer supports. If no decision exists, recommend
stopping or reframing.

### `/assay spec`

Write the Stage 2 spec receipt under `.assay/receipts/`.

Required fields:

- `kind`: `spec` or `trivial`.
- `question`: the precise question.
- `metricDefinitions`: the exact calculation rules.
- `validAnswer`: what would count as a complete answer.
- `decisionImpact`: what business choice this drives.
- `track`: `analysis` or `data-product`.

For a trivial receipt, include `reason` instead of the full spec fields.

### `/assay discovery`

Find methodology forks before results are computed. Methodology means the chosen
analysis approach. Escalate any fork that changes a number stakeholders act on.

Do not compute final results in this stage.

### `/assay execute`

Before running work, call:

```bash
bash .claude/workflows/questioncheck.sh <analysis-id>
```

If it fails, stop. Explain that Stage 6 is blocked until the Stage 2 spec receipt
exists. Do not bypass the gate.

Then run the analysis or build the data product according to the spec and ruled
methodology.

### `/assay validate`

Reconcile results to source-of-truth. Reconciliation means numbers match the
official source, or differences are explained.

Write the Stage 7 validation receipt under `.assay/receipts/`.

For high-stakes work or data products, also write the Stage 8 adversarial-review
receipt with scores for confidence, data completeness, methodology soundness,
and reproducibility.

### `/assay deliver`

Before packaging the answer, call:

```bash
bash .claude/workflows/validationcheck.sh <analysis-id>
```

If it fails, stop. Explain the missing proof in plain language. Do not deliver
until the gate passes.

Then package the answer with:

- the conclusion;
- the evidence;
- caveats, meaning limits that affect trust;
- methodology, meaning the chosen analysis approach;
- reconciliation notes;
- next steps.

### `/assay status`

Read `.assay/receipts/` and report:

- which stage receipts exist;
- which gate would block next;
- the next recommended subcommand.

## Receipt Names

Use a stable analysis id such as `revenue-retention-q2`.

Receipt files:

- `.assay/receipts/<analysis-id>-spec-receipt.json`
- `.assay/receipts/<analysis-id>-validation-receipt.json`
- `.assay/receipts/<analysis-id>-adversarial-review-receipt.json`

## Phase 1 Scope

This installed skill currently routes the spine and gates. Domain skills and
`assay-*.js` workflow engines are later phases, so do not claim they exist yet.
