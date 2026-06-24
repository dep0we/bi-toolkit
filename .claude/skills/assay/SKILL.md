---
name: assay
description: Router for the assay BI quality loop. Invoke when the operator types /assay with a subcommand: intake, frame, spec, discovery, execute, validate, deliver, or status.
---

# /assay - BI quality loop router

The assay loop helps BI operators ship trustworthy analysis. It routes work
through the staged lifecycle: intake, frame, spec, discovery, execute, validate,
review, deliver, document, and learn.

## Governing rules (always apply, even for small or "just look at this" requests)

These mirror the Governing rules in the project `CLAUDE.md` and are not optional.
Skipping any is a named exception that needs the operator's explicit OK first.
A request to "see what you can do," find trends, compare numbers, profile data,
or summarize data is analysis (answering with data or numbers) unless the
operator explicitly approves a named exception.

1. **Route through the loop by default.** Any analysis runs frame → spec →
   discovery (recording no forks, meaning choices that change the number, if
   none exist) → execute → validate → deliver. Answering inline without the loop
   is the exception — name it and get approval.
2. **Independent validation is mandatory.** Do NOT present findings until a
   **fresh `red-teamer` sub-agent that did not produce the numbers** has
   reviewed them and a validation receipt (saved proof that checks happened)
   exists. A sub-agent is a worker agent given a narrow task. Self-review never
   counts.
3. **Delegate mechanical work.** Profiling, counting, and queries go to the
   `eda-profiler` and `query-runner` sub-agents (worker agents given narrow
   tasks; cheaper model). The main model (the agent leading judgment) plans,
   interprets, synthesizes — it does not run crunching scripts inline.

Project-specific rules live in `assay.config.jsonc`. Receipts live in
`.assay/receipts/`. A receipt is a saved proof file for a completed stage.
Always write receipts with `.claude/workflows/receipt.sh`; do not hand-write
the files directly.

The model must not bypass `.claude/workflows/assay-preflight.sh`. A preflight is
a required gate check before a chokepoint, meaning a named stopping point in
workflow. If preflight exits non-zero, STOP and explain the gate result in plain
language; do not continue by calling a lower-level workflow directly.

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
When drafting `CLAUDE.md`, copy the **Governing rules** section from
`CLAUDE.starter.md` verbatim, so every future session in this folder routes
through the loop, validates independently, and delegates mechanical work.

### `/assay frame`

Decide whether the request is:

- analysis, meaning a one-time answer to a question; or
- data product, meaning a recurring report or dashboard.

Capture the decision the answer supports. If no decision exists, recommend
stopping or reframing.

### `/assay spec`

Write the Stage 2 spec receipt under `.assay/receipts/` by calling:

```bash
bash .claude/workflows/receipt.sh spec <analysis-id> <<'JSON'
{
  "question": "...",
  "metricDefinitions": {
    "metric_name": "exact calculation rule"
  },
  "validAnswer": "...",
  "decisionImpact": "...",
  "track": "analysis"
}
JSON
```

Required fields:

- `kind`: `spec` or `trivial`.
- `question`: the precise question.
- `metricDefinitions`: the exact calculation rules.
- `validAnswer`: what would count as a complete answer.
- `decisionImpact`: what business choice this drives.
- `track`: `analysis` or `data-product`.

For a trivial receipt, include `reason` instead of the full spec fields.
Call:

```bash
bash .claude/workflows/receipt.sh trivial <analysis-id> <<'JSON'
{
  "reason": "..."
}
JSON
```

### `/assay discovery`

Find methodology forks before results are computed. Methodology means the chosen
analysis approach. Escalate any fork that changes a number stakeholders act on.

Before discovery, call:

```bash
bash .claude/workflows/assay-preflight.sh discovery <analysis-id>
```

If it fails, stop. Explain that the governing-doc baseline, meaning the saved
starting copy for comparison, could not be created or confirmed. Do not bypass
the preflight.

Invoke `.claude/workflows/assay-discovery.js` with the analysis request, the
Stage 2 spec receipt, and the config.

Do not compute final results in this stage.

After discovery returns, record the latest discovery run before execute:

```bash
bash .claude/workflows/rulings.sh discovery <analysis-id> <discoveryRunId> <<'JSON'
["fork-id-one", "fork-id-two"]
JSON
```

Ask the operator to rule every Tier-A fork. Then write the durable rulings file:

```bash
bash .claude/workflows/rulings.sh write <analysis-id> <discoveryRunId> <<'JSON'
{
  "forkIds": ["fork-id-one", "fork-id-two"],
  "rulings": {
    "fork-id-one": {
      "ruling": "approved option",
      "rationale": "why the operator chose it"
    },
    "fork-id-two": "approved option"
  }
}
JSON
```

This creates `.assay/rulings/<analysis-id>-rulings.json`. A ruling is the
operator's approved method choice.

### `/assay execute`

Before running work, call:

```bash
bash .claude/workflows/assay-preflight.sh execute <analysis-id>
```

If it fails, stop. Explain that Stage 6 is blocked until the Stage 2 spec receipt
exists and every surfaced Tier-A methodology fork has a current ruling. A
methodology fork is a choice that changes numbers. Do not bypass the gate.

If discovery was deliberately rerun and the old rulings still apply, get the
operator's explicit approval and re-affirm the current rulings:

```bash
bash .claude/workflows/rulings.sh reaffirm <analysis-id> <<'JSON'
{
  "reason": "operator confirmed these rulings still apply after rerun"
}
JSON
```

Then run the analysis or build the data product according to the spec and ruled
methodology. **Delegate the mechanical work to sub-agents** (they run on a
cheaper model): dispatch the `eda-profiler` to profile the data and the
`query-runner` to run the ruled queries and calculations. The main model
interprets and synthesizes their output — it does not run the crunching scripts
inline. Invoke `.claude/workflows/assay-execute.js` with the analysis request,
Stage 2 spec receipt, and operator rulings.

### `/assay validate`

Reconcile results to source-of-truth. Reconciliation means numbers match the
official source, or differences are explained. **Dispatch the `reconciler`
sub-agent** to tie results to source-of-truth and gather the validation evidence
— do not reconcile inline against your own numbers.

**The adversarial review MUST be done by a fresh `red-teamer` sub-agent that did
not produce the results.** Dispatch the `red-teamer` to re-derive the key numbers
from the raw data without seeing the analysis code, and to attack the soft spots
(assumptions, edge cases, framing). Self-review by the agent that ran the
analysis does NOT satisfy this stage — it cannot catch its own blind spots.

Invoke `.claude/workflows/assay-validate.js` with the analysis request, Stage 2
spec receipt, results, and config.

Write the Stage 7 validation receipt under `.assay/receipts/` by passing the
workflow's `validationReceipt` to:

```bash
bash .claude/workflows/receipt.sh validation <analysis-id> validation-receipt.json
```

For every non-trivial analysis, meaning not approved as too small to gate, also
write the Stage 8 adversarial-review receipt, meaning saved proof of independent
attack, by passing the workflow's `adversarialReviewReceipt` to:

```bash
bash .claude/workflows/receipt.sh adversarial-review <analysis-id> adversarial-review-receipt.json
```

The receipt must include scores for confidence (how sure the answer is right),
data completeness (how much relevant data was present), methodology soundness
(whether the approach survives expert review), and reproducibility (can someone
re-run the same work). High-stakes work, meaning work that drives money,
headcount, or strategy, and data products, meaning recurring reports or
dashboards, must meet the configured score threshold (the minimum allowed score)
before delivery.

### `/assay deliver`

Before packaging the answer, call:

```bash
bash .claude/workflows/assay-preflight.sh deliver <analysis-id>
```

If it fails, stop. Explain the missing proof or guarded-doc change in plain
language. A guarded doc is a rule file protected from unattended edits. Do not
deliver until the preflight passes.

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

## Installed Components

This installed skill routes the spine and gates. The installed workflow engines
are `.claude/workflows/assay-discovery.js`,
`.claude/workflows/assay-execute.js`, and
`.claude/workflows/assay-validate.js`.
The installed `UserPromptSubmit` hook prints a governing-rule reminder each
turn. It keeps the rules visible, but it is not a hard block; the hard block is
the non-zero exit from `.claude/workflows/assay-preflight.sh`.
