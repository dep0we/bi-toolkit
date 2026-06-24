# bi-toolkit — Build Spec (the "assay loop")

This is the executable spec for the whole kit. A builder (human or AI) should be
able to construct bi-toolkit from this document plus the two source repos named
below. Read `CLAUDE.md` (the repo's governing rules) first; this spec must not
contradict it.

## Two source repos on disk (read, adapt, do NOT re-invent)

- **Spine source:** `/Users/dep0we/Projects/dev-process-kit/` — the operating
  machinery to adapt: `README.md`, `PLAYBOOK.md`, `methodology.md`,
  `model-dial.md`, `CLAUDE.starter.md`, `claude-md-guide.md`,
  `arc.config.example.jsonc`, `bootstrap.sh`, `install.sh`, `check-prereqs.sh`,
  `workflows/*.js`, `workflows/arc-preflight.sh`, `workflows/decision-ledger.sh`,
  `skill/arc/SKILL.md`, `test/run.sh` and `test/*.test.sh`. **Copy these as the
  starting point and retarget the language/logic from "shipping code" to
  "shipping trustworthy analysis."** Keep the structure, the fail-closed gate
  pattern, the rounds-based adversarial review, and the model dial.
- **Domain source:** `/Users/dep0we/Projects/data-analyst-plugin/` — 31 skills
  under `skills/<name>/SKILL.md` and 12 commands under `commands/`. These are the
  domain content. **Adapt and wrap them as stage content; do not rebuild them.**
  Preserve each skill's substance (Context Requirements, Context Gathering,
  Workflow, Output Template); add a short "Used in the assay lifecycle at: Stage
  N (<track>)" header and apply the plain-language rule (below) to any operator-
  facing copy.

## Naming

The dev-kit's engine is the "arc loop"; ours is the **assay loop** (assay = test
the quality/composition of something). The operator-facing command is `/assay`
with subcommands. Replace `arc` → `assay` in adapted files; rename `arc-*.js` →
`assay-*.js`, `/arc` skill → `/assay` skill, `arc.config` → `assay.config`.

## Who uses this and the one non-negotiable rule

Users are **BI operators who run analytics but are not deeply technical.**
**Plain-language rule (governing, enforced):** every operator-facing string —
decision packets, intake questions, deliverable templates, error messages, skill
prompts, gate output — must define any technical or statistical term inline in
4-8 words and frame choices by consequence, not jargon. Examples: "p-value
(chance the result is just noise)", "cohort (a group tracked over time)",
"median (middle value, ignores outliers)", "idempotent (safe to re-run without
doubling up)". This is a review lens (`plain-language` in `assay.config`) and a
Tier-A tripwire to weaken. Treat a jargon leak as a defect.

## The model dial (unchanged in shape from the dev-kit)

- The operator's main model judges, orchestrates, rules decisions, and runs
  adversarial review.
- Sub-agents (Sonnet via the Workflow tool's `agent()`) do legwork: run queries,
  profile data, compute metrics, draft sections.
- A cross-family model (`codex exec`) gives a second opinion on methodology and on
  the final conclusion — the BI analog of catching code blind spots is catching
  confirmation bias and methodology error.

## The lifecycle — one spine, two tracks

Stage 1 asks: **are we answering a question (analysis) or building a recurring
report/dashboard (data product)?** and routes. Stages marked [shared] run on both
tracks; [A] analysis-only; [DP] data-product-only.

| Stage | Name | Track | What runs (domain skills) | Decides |
|------:|------|-------|---------------------------|---------|
| 0 | **Intake** (once per project) | [shared] | Guided interview → writes `assay.config` + project `CLAUDE.md` and captures key metrics into the living metric catalog. Captures: data sources + warehouse, BI/viz tool, query language, **source-of-truth for each key metric**, how they validate today, what "done" means for a deliverable, key stakeholders, recurring cadences. (stakeholder-requirements-gathering, schema-mapper, context-packager) | their real process |
| 1 | **Frame** | [shared] | Is the request worth doing, and which track? What decision does the answer drive? (stakeholder-requirements-gathering) | go/no-go + track |
| 2 | **Spec** | [shared] | Precise question, metric definitions, scope, what a valid answer looks like, success criteria. Reads metric definitions from the living metric catalog and flags drift, meaning definitions split across analyses, before writing the **spec receipt** the front gate checks. (analysis-planning, analysis-assumptions-log, business-metrics-calculator for definitions) | scope + definitions |
| 3 | **Plan review** | [shared] | Pressure-test the plan from 3 lenses: decision-value, methodology/stats-rigor, data-availability. (autoplan analog) | which concerns matter |
| 4 | **Profile data** | [A] | Connect, EDA, schema map. (programmatic-eda, schema-mapper, data-quality-audit) | — |
| 4d | **Design the product** | [DP] | Layout, which metrics, refresh cadence, access, semantic layer. (dashboard-specification, semantic-model-builder, visualization-builder) | design direction |
| 5 | **Discovery: lock methodology** | [A] | Find every methodology fork (how to define churn, which window, null/outlier handling, segment defs); tier A/B/C; bring Tier-A as plain-language packets. NO results computed yet. (adapt `arc-discovery.js`) | every methodology fork |
| 6 | **Execute** | [shared] | Sub-agents run queries/compute to the rulings, then adversarial review IN ROUNDS (validation, reconciliation, stats-rigor, plain-language, cross-family) until a clean round. [A] computes the analysis; [DP] builds the report/dashboard. (adapt `arc-execute.js`; domain skills per track) | unforeseen forks |
| 7 | **Validate** | [shared] | Do the numbers tie to source-of-truth? Writes the **validation receipt** the back gate checks. (data-quality-audit, metric-reconciliation, query-validation, analysis-qa-checklist) | accept anomalies |
| 8 | **Adversarial / peer review + score** | [shared, gated] | Red-team the conclusion; score it on the rubric (below). Mandatory on high-stakes analyses AND on every data-product at build time. (peer-review-template) | accept/revise findings |
| 9 | **Package + deliver** | [shared] | Synthesize, summarize, narrate, visualize for the audience. (insight-synthesis, executive-summary-generator, data-narrative-builder, technical-to-business-translator, methodology-explainer, visualization-builder) | approval to release |
| 10 | **Monitor / refresh** | [DP] | Scheduled refresh + drift checks each run (lighter validation). (metric-reconciliation, dashboard-specification) | — |
| 11 | **Document** | [shared] | Make it reproducible. (analysis-documentation, semantic-model-builder, data-catalog-entry, analysis-assumptions-log) | — |
| 12 | **Retro / learn** | [shared] | Capture lessons; metric-drift watch. (analysis-retrospective) | — |

Governing rule (copy from dev-kit PLAYBOOK): every stage runs by default; the AI
may *propose* skipping with a reason and must get explicit OK; never skip silently.

## The two enforced gates (fail-closed, no silent skip)

Adapt `workflows/arc-preflight.sh` (which implements `speccheck` + `seccheck`)
into two BI gates. Same mechanics: deterministic check, writes/reads a receipt
file tied to the analysis, blocks the next phase on failure with a plain-language
reason.

1. **`questioncheck`** (front gate, like speccheck): no Stage 6 execution until a
   **spec receipt** exists for the analysis — recording the question, the metric
   definitions, and what a valid answer looks like. Receipt `kind: "spec"` (ran
   Stage 2) or `kind: "trivial"` with a one-line reason. No silent skip.
2. **`validationcheck`** (back gate, like seccheck): no Stage 9 delivery until a
   **validation receipt** exists showing results reconciled to source-of-truth,
   AND — if the analysis is high-stakes (drives money, headcount, or strategy) OR
   is a data-product (runs unattended) — a Stage 8 **adversarial-review receipt**
   with a passing **score**. Fail-closed; "not high-stakes" is the gate's call
   from the spec's declared decision-impact, not an operator bypass.

Receipts live under `.assay/receipts/` (gitignored runtime, like
`.gstack/arc-rulings/`). Decision ledger (`decision-ledger.sh`) reused as-is.

## The scoring rubric (Dan named "scoring results")

Stage 8 scores each result 1-5 on four dimensions, in plain language:
- **Confidence** — how sure are we the answer is right (sample size, noise)?
- **Data completeness** — how much of the relevant data did we actually have?
- **Methodology soundness** — would the approach survive an expert's read?
- **Reproducibility** — could someone else re-run this and get the same number?

A result scoring below threshold (default: any dimension < 3) **blocks delivery**
at `validationcheck` until raised or explicitly accepted by the operator with a
recorded reason. Thresholds live in `assay.config`.

## Distribution — the public one-liner

Operator opens Claude Code in a fresh, empty folder and runs:
```
curl -fsSL https://raw.githubusercontent.com/dep0we/bi-toolkit/main/bootstrap.sh | bash
```
`bootstrap.sh` must, in this remote-pull context: clone/download this repo into a
temp dir (or the kit into `.assay-kit/`), run `install.sh` to copy
`.claude/skills/`, `.claude/workflows/`, `.claude/agents/` and scaffold
`assay.config` + the doc stubs into the current folder, seed memory, then tell the
operator to run `/assay intake`. It must NOT require `gh` or auth (public repo,
`curl` only). Keep the dev-kit's re-runnable, never-clobber-operator-config
behavior. `install.sh` keeps the dev-kit's copy + gitignore approach.

## `assay.config.example.jsonc`

Adapt `arc.config.example.jsonc`. Keep `tripwires`, `reviewLenses` (include a
`plain-language` lens and a `methodology` lens), `crossFamily`, `prepDimensions`.
Add BI-specific fields: `sourceOfTruth` (map of metric → authoritative source),
`metricCatalogPath` (path to the living metric catalog), `stack` (warehouse, BI tool, query language), `scoreThresholds`, and
`highStakesDefinition`. Replace code tripwires with methodology tripwires (metric
definitions, segment boundaries, statistical-method choice, data-source switch,
anything that changes a number stakeholders act on).

## Living metric store

The kit ships a tracked `metric-catalog.json` at the project root. Tracked means
committed to version control, because metric definitions are shared team
knowledge. The catalog schema is `metric-catalog/v1`:

- `metrics.<metric>.name`: human metric name.
- `metrics.<metric>.definition`: exact calculation rule.
- `metrics.<metric>.sourceOfTruth`: official system or report.
- `metrics.<metric>.owner`: person or team approving changes.
- `metrics.<metric>.format`: unit or display format.
- `metrics.<metric>.notes`: caveats, links, or approval notes.

`.claude/workflows/metric-store.sh` manages the catalog:

```bash
bash .claude/workflows/metric-store.sh add <name> <definition> <sourceOfTruth> <owner> <format> [notes]
bash .claude/workflows/metric-store.sh get <name>
bash .claude/workflows/metric-store.sh list
bash .claude/workflows/metric-store.sh check <name> <definition>
```

`metricCatalogPath` in config wins first, then `ASSAY_METRIC_CATALOG`, then the
default `metric-catalog.json`. The catalog is the richer living record.
`sourceOfTruth` in config remains a compatibility map for existing gates and can
be derived from the catalog during intake. If they disagree, escalate the
source-of-truth mismatch as a methodology fork, meaning a choice that changes
numbers.

## File manifest (build all of these)

Top-level (adapt from dev-kit, retarget to BI + plain language):
`README.md` (overwrite stub), `PLAYBOOK.md`, `methodology.md`, `model-dial.md`,
`CLAUDE.starter.md` (BI-flavored, plain-language-heavy — this is the template the
kit SHIPS to operators, distinct from the repo's own CLAUDE.md),
`claude-md-guide.md`, `assay.config.example.jsonc`, `bootstrap.sh`, `install.sh`,
`check-prereqs.sh`.

Engine under `.claude/` (note: dev-kit gitignores `.claude/workflows/` and the
skill in target repos, but THIS repo is the kit's source, so these are COMMITTED
here — adjust `.gitignore` so the kit's own engine files are tracked):
`.claude/skills/assay/SKILL.md` (router: `/assay intake|frame|spec|discovery|
execute|validate|deliver|status|finish`), `.claude/workflows/assay-discovery.js`,
`.claude/workflows/assay-execute.js`, `.claude/workflows/assay-validate.js`,
`.claude/workflows/questioncheck.sh`, `.claude/workflows/validationcheck.sh`,
`.claude/workflows/metric-store.sh`, `.claude/workflows/decision-ledger.sh`
(reuse).

Sub-agent defs under `.claude/agents/` (Sonnet workers): `query-runner`,
`eda-profiler`, `reconciler`, `red-teamer`. Match the Agent-tool agent-definition
format.

Domain skills under `.claude/skills/<name>/SKILL.md`: all 31 adapted from
data-analyst-plugin per the lifecycle mapping in the table above.

Tests under `test/`: `run.sh` (harness) + per-gate tests proving each gate
fails-closed (e.g. `questioncheck` blocks with no spec receipt; `validationcheck`
blocks an unreconciled result and a sub-threshold score). Mirror dev-kit's
`test/*.test.sh` style. `testCommand` is already `bash test/run.sh`.

`seed-memory/`: 4-6 BI lessons (e.g. "a recurring report that's wrong is wrong
every week — validate harder than a one-off", "reconcile to source-of-truth
before trusting any new metric", "define the metric before you query it").

## Build phasing (for the builder)

1. **Spine + gates + installers + test harness** — docs, `assay.config.example`,
   `bootstrap.sh`, `install.sh`, `check-prereqs.sh`, the two gate scripts, the
   `/assay` SKILL.md router, `test/run.sh` + gate tests. Get `bash test/run.sh`
   green.
2. **Adapt the 31 domain skills** — wrap each per the lifecycle mapping + plain
   language. Independent per skill; batch freely.
3. **Engine workflows** — `assay-discovery.js`, `assay-execute.js`,
   `assay-validate.js` adapted from the arc-*.js originals; the sub-agent defs.

Commit in logical chunks (one concept each). Do not merge; stop at PR-ready.
Update `CHANGELOG.md` `[Unreleased]` and keep `docs/ARCHITECTURE.md` honest.
