---
name: assay
description: Router for the assay BI quality loop. Invoke when the operator types /assay with a subcommand: help, intake, frame, spec, discovery, execute, validate, deliver, status, finish, resume, or ledger.
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
4. **Orient new or confused operators.** If the operator seems new, seems
   confused, or asks a data question without using `/assay`, briefly explain
   that the kit will guide them step by step, then start the loop with
   `/assay intake` or `/assay frame`. Do not lecture; take their hand.

Project-specific rules live in `assay.config.jsonc`. Receipts live in
the configured receipts directory, defaulting to `.assay/receipts/`. A receipt
is a saved proof file for a completed stage. Always write receipts with
`.claude/workflows/receipt.sh`; do not hand-write the files directly.
Metric definitions live in the configured metric catalog, defaulting to
`metric-catalog.json`. A metric catalog is the shared metric definition file.

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
3. Read the metric catalog from `metricCatalogPath` if present; otherwise use
   `metric-catalog.json`.
4. Do not overwrite the operator's config.

## Subcommands

### `/assay help`

Show the plain-language guide and exact next step:

```bash
bash .claude/workflows/assay-help.sh
```

If the operator provides an analysis id, pass it through:

```bash
bash .claude/workflows/assay-help.sh <analysis-id>
```

Report the helper output directly. Help explains what the kit is, the lifecycle
one stage at a time, and the next required step from `assay-state.sh`. If no
active analysis or receipts exist, point the operator to `/assay intake`.
Help output must include:

```text
Help & updates:
Full written guide: docs/guide/ in this project (start at docs/guide/README.md).
Latest features + canonical docs: https://github.com/dep0we/bi-toolkit
To update your toolkit, re-run the install command:
curl -fsSL https://raw.githubusercontent.com/dep0we/bi-toolkit/main/bootstrap.sh | bash
```

### `/assay intake`

This is the operator's first experience, so run it as a short, friendly
conversation. **Follow the interview script in `assay-intake.md`** (in this
skill's folder) exactly — do not improvise a different flow. The full question
wording, examples, and capture mapping live there.

Key rules:

- **Open** by saying it takes about **2 minutes**, everything is a **starting
  baseline that is not locked in and evolves with the project**, and **"skip" is
  always fine**.
- **Ask one or two questions at a time**, in plain language, leading with the
  concrete example on each. Never paste all the questions at once.
- **Defer the heavy stuff.** Capture only the essentials now — do NOT demand
  exact metric calculation rules, a full metric catalog, per-analysis data
  classification, or export destinations. The gates prompt for those lazily,
  when they actually matter.
- **At the end:** recap, then (with the operator's OK) write/update
  `assay.config.jsonc`, seed the metric catalog with each named metric's
  name + source-of-truth (definition pending first use) via
  `bash .claude/workflows/metric-store.sh add ...`, and draft `CLAUDE.md` —
  copying the **Governing rules** section from `CLAUDE.starter.md` verbatim.
  Then point to `/assay frame`.

Keep the config `sourceOfTruth` map and the metric catalog aligned; if they
disagree, surface it and ask which source is official.

### `/assay frame`

Decide whether the request is:

- analysis, meaning a one-time answer to a question; or
- data product, meaning a recurring report or dashboard.

Capture the decision the answer supports. If no decision exists, recommend
stopping or reframing.

Set the active analysis pointer after the analysis id and track are known:

```bash
bash .claude/workflows/assay-active.sh set <analysis-id> <analysis|data-product>
```

The active pointer is `.assay/active.json`. It lets a fresh session know which
analysis to resume first.

### `/assay spec`

Before writing the Stage 2 spec receipt, read each metric from the catalog:

```bash
bash .claude/workflows/metric-store.sh get <metric-name>
```

For every metric definition proposed in the spec, reconcile it against the
catalog:

```bash
bash .claude/workflows/metric-store.sh check <metric-name> <proposed-definition>
```

If the result is `metric-store:match`, use the catalog definition in the spec
receipt. If the result is `metric-store:not-found`, ask the operator whether to
add the metric with `metric-store.sh add` before continuing. If the result is
`metric-store:differs`, flag a methodology fork. A methodology fork is a choice
that changes numbers. Treat a different definition for a key metric as drift,
meaning definitions have split across analyses, and escalate loudly for an
operator ruling. The catalog is advisory and does not block every mismatch, but
do not hide drift on a decision-driving metric.

Write the Stage 2 spec receipt with the receipt writer by calling:

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

After writing either receipt, set the active analysis pointer. Use the receipt's
track when present; otherwise use `analysis`:

```bash
bash .claude/workflows/assay-active.sh set <analysis-id> <analysis|data-product>
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

This creates `<rulingsDir>/<analysis-id>-rulings.json`, defaulting to
`.assay/rulings/<analysis-id>-rulings.json`. A ruling is the operator's
approved method choice.
The rulings writer also appends one decision-ledger row for each ruled Tier-A
fork. The ledger is an audit trail of method choices.

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

Write the Stage 7 validation receipt with the receipt writer by passing the
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

Delivery includes the reproducibility gate. Reproducibility means re-running
work gets the same answer. If `assay.config.jsonc` has `reproCommand`, preflight
runs that command and blocks delivery when it exits non-zero. Non-zero means the
rerun found changed outputs or another failure. If `reproCommand` is unset,
preflight passes with a note that reproducibility is unverified; for a data
product, meaning a recurring report or dashboard, treat that note as a strong
warning and recommend adding `reproCommand`.

Delivery also requires data-safety proof when sensitive data is involved.
Sensitive data means personal identifying info (PII), health info (PHI),
payroll, or customer records. If the work is not clearly none or internal, call:

```bash
bash .claude/workflows/receipt.sh data-safety <analysis-id> <<'JSON'
{
  "dataClassification": "sensitive-PII",
  "deliveryAudience": "internal finance leadership",
  "dataLeavesCompany": false,
  "exportDestination": "none",
  "detailLevel": "aggregate",
  "operatorSignoff": "operator approved this audience and handling"
}
JSON
```

The data-safety receipt records the audience, whether data leaves the company,
the export destination, whether row-level records or aggregate summary is
shared, and operator sign-off. If data leaves the company, the destination must
be approved in `assay.config.jsonc`.

Then package the answer with:

- the conclusion;
- the evidence;
- caveats, meaning limits that affect trust;
- methodology, meaning the chosen analysis approach;
- reconciliation notes;
- next steps.

Write that package as a deterministic report input JSON file. The renderer
contract is `schemaVersion: "assay-report/v1"` plus:

```json
{
  "schemaVersion": "assay-report/v1",
  "analysisId": "<analysis-id>",
  "title": "Plain report title",
  "audience": "approved audience",
  "conclusion": "The answer in plain language.",
  "keyFindings": [
    {
      "title": "Finding label",
      "detail": "What happened.",
      "evidence": "Validated number and source.",
      "consequence": "Why the finding matters."
    }
  ],
  "evidence": [
    {
      "label": "Metric or check",
      "detail": "Value, date range, or comparison.",
      "source": "System, query, or receipt used."
    }
  ],
  "methodology": ["Chosen approach for answering the question."],
  "caveats": ["Limit that affects trust."],
  "reconciliationNotes": ["How numbers tied to the official source."],
  "score": {
    "confidence": 4,
    "dataCompleteness": 4,
    "methodologySoundness": 4,
    "reproducibility": 4
  },
  "nextSteps": ["Owner - action - timing."],
  "figures": [
    {
      "title": "Optional chart title",
      "description": "What the figure shows.",
      "imagePath": "optional local image path to embed"
    }
  ]
}
```

Store the input beside the report when possible, then render:

```bash
bash .claude/workflows/report-render.sh <analysis-id> <deliverable-json>
```

The renderer always writes a self-contained HTML report under the configured
deliverables directory, defaulting to `.assay/deliverables/<analysis-id>/`.
If `pandoc`, `wkhtmltopdf`, Chrome, or Chromium is available, it also writes a
PDF (print-ready file for sharing) next to the HTML. If no PDF renderer, meaning
a tool that makes PDF files, is available, delivery still succeeds and the output
tells the operator to open the HTML and print-to-PDF. Print-to-PDF means using
the browser print dialog to save a PDF file.

Report the `assay-report-html`, optional `assay-report-pdf`, and
`assay-report-receipt` paths from the renderer output. The renderer writes the
deliverable receipt, meaning saved proof of the delivered report artifact, with
`receipt.sh` kind `deliverable`; do not hand-write this receipt.
The renderer also writes a metrics snapshot (saved key numbers from one run),
runs driftcheck (metric movement beyond tolerance), writes a deliverable diff
(what changed since the prior run), and emits a local distribution manifest
(ready-to-send handoff file) when data-safety rules allow it.

For a data-product track, meaning a recurring report or dashboard, and when the
approved spec asks for a universal dashboard, write a deterministic dashboard
input JSON file after the deliver preflight passes. The dashboard contract is
`schemaVersion: "assay-dashboard/v1"` plus:

```json
{
  "schemaVersion": "assay-dashboard/v1",
  "analysisId": "<analysis-id>",
  "title": "Plain dashboard title",
  "audience": "approved audience",
  "refreshNote": "Refresh cadence and latest data timing.",
  "panels": [
    {
      "type": "kpi",
      "title": "Headline metric",
      "data": {
        "label": "Revenue",
        "value": 125000,
        "delta": "+8% versus last period",
        "note": "Tied to the finance source."
      }
    },
    {
      "type": "bar",
      "title": "Revenue by segment",
      "data": {
        "labels": ["Enterprise", "Mid-market"],
        "values": [90000, 35000],
        "source": "Finance source"
      }
    },
    {
      "type": "line",
      "title": "Revenue trend",
      "data": {
        "points": [
          { "x": "2026-04", "y": 112000 },
          { "x": "2026-05", "y": 119000 }
        ],
        "source": "Finance source"
      }
    },
    {
      "type": "table",
      "title": "Follow-up rows",
      "data": {
        "columns": ["Owner", "Metric", "Status"],
        "rows": [["Finance", "Revenue", "Reviewed"]]
      }
    }
  ]
}
```

Panel types are `kpi` for KPI (main number watched for decisions), `bar` for
group comparison, `line` for time series (values tracked over time), and `table`
for detail rows. Then render:

```bash
bash .claude/workflows/dashboard-render.sh <analysis-id> <dashboard-json>
```

The renderer writes a self-contained HTML dashboard, meaning a browser page
saved as a file, under the configured deliverables directory, defaulting to
`.assay/deliverables/<analysis-id>/`.
Self-contained means no external network or CDN (hosted shared script source).
Charts are inline SVG (browser-drawn chart image format), so they render
offline without JavaScript (browser code that adds behavior) chart libraries.
The renderer writes the deliverable receipt with `artifactType: "dashboard"`
using `receipt.sh` kind `deliverable`; do not hand-write this receipt. Report
the `assay-dashboard-html` and `assay-dashboard-receipt` paths from the renderer
output.

For a data-product track, meaning a recurring report or dashboard, delivery runs:

```bash
bash .claude/workflows/driftcheck.sh <analysis-id> <metrics-snapshot-json>
bash .claude/workflows/deliverable-diff.sh <analysis-id> <metrics-snapshot-json> <artifact-path>
bash .claude/workflows/distribution-manifest.sh <analysis-id> <artifact-path> <timestamp> <metrics-snapshot-json>
```

Driftcheck is a warning surface when metrics move beyond tolerance (allowed
movement before review). It blocks only when the refresh is broken or empty for
a data product. Broken refresh means the recurring data did not update; empty
refresh means it returned no rows. Distribution manifests are local handoffs
only; actual email, Slack, or BI-tool sends are deferred to issue #8. Do not
emit a distribution manifest for sensitive data unless the data-safety receipt
has operator sign-off.

Tool-specific exports for Power BI / Tableau / Looker / Metabase are future
work driven by intake. This engine produces the universal static-HTML view.

After the answer is successfully delivered, clear the active analysis pointer:

```bash
bash .claude/workflows/assay-active.sh clear <analysis-id>
```

Do not clear it when a preflight, validation, data-safety, reproducibility, or
governing-doc check fails.

### `/assay status`

For one analysis, call:

```bash
bash .claude/workflows/assay-state.sh status <analysis-id>
```

For all analyses, call:

```bash
bash .claude/workflows/assay-state.sh status
```

Report the helper output directly in plain language. Status means current saved
progress and the next required step. The helper reads the configured receipts
and rulings directories and reports:

- which stage receipts exist;
- which gate would block next;
- open findings, meaning missing proof or failed scores;
- last run, meaning the latest delivered artifact path;
- drift flags, meaning metric movement beyond tolerance;
- the single next required step.

When no analysis id is provided, list all in-flight analyses found under
`.assay/` and their next step. In-flight means saved work exists and delivery is
not yet proven complete in this session.

### `/assay finish <analysis-id>`

First report current state:

```bash
bash .claude/workflows/assay-state.sh finish <analysis-id>
```

Then resume only from the helper's `next required step`. Finish means continue a
stalled analysis from saved proof. It must not recompute completed stages, and it
must not bypass any gate. If the next step is:

- `/assay spec <analysis-id>`: write or repair only the Stage 2 spec receipt.
- `/assay discovery <analysis-id>`: run discovery preflight and discovery; do not
  compute final results.
- `record methodology rulings`: ask the operator to rule the surfaced forks and
  write rulings with `rulings.sh`; do not execute.
- `/assay validate <analysis-id>`: validate existing results when present,
  repair failed validation, or raise low review scores; do not deliver.
- `write data-safety receipt`: collect the audience, handling, destination,
  detail level, and operator sign-off; do not deliver.
- `/assay deliver <analysis-id>`: call deliver preflight exactly as `/assay
  deliver` does, including validationcheck, govcheck, datacheck, and reprocheck.

If `assay-state.sh finish` reports a blocking gate, explain it and drive the
corrective next step only. A gate is a required stop-check before continuing.
Never jump to a later stage because a previous output looks plausible.

### `/assay resume [analysis-id]`

Resume is an alias for finish. If an analysis id is supplied, treat it exactly
like `/assay finish <analysis-id>`. If no id is supplied, use the active pointer:

```bash
bash .claude/workflows/assay-state.sh resume
```

Then continue only from the helper's next required step. If no active analysis
exists, run `/assay status` or `/assay help`.

### `/assay ledger`

Query the methodology decision ledger, meaning the saved list of ruled forks:

```bash
bash .claude/workflows/decision-ledger.sh list
```

If the operator provides a filter, pass it through to the ledger helper:

```bash
bash .claude/workflows/decision-ledger.sh query --issue <analysis-id>
bash .claude/workflows/decision-ledger.sh query --fork <fork-id>
bash .claude/workflows/decision-ledger.sh match-rate
```

Report the helper output directly in plain language.

## Receipt Names

Use a stable analysis id such as `revenue-retention-q2`.

Receipt files:

- `<receiptsDir>/<analysis-id>-spec-receipt.json`
- `<receiptsDir>/<analysis-id>-validation-receipt.json`
- `<receiptsDir>/<analysis-id>-adversarial-review-receipt.json`

## Installed Components

This installed skill routes the spine and gates. The installed workflow engines
are `.claude/workflows/assay-discovery.js`,
`.claude/workflows/assay-execute.js`, and
`.claude/workflows/assay-validate.js`.
The installed `UserPromptSubmit` hook prints a governing-rule reminder and the
current active-analysis state each turn. It keeps the rules and next step
visible, but it is not a hard block; the hard block is the non-zero exit from
`.claude/workflows/assay-preflight.sh`.
