# bi-toolkit

## 1. What this is

bi-toolkit is a Claude Code kit that standardizes a BI (business intelligence
reporting and metrics) / data-analysis workflow. It does for analysis what a
dev-process kit does for shipping code: it gives the operator a repeatable path,
named gates, proof files, and review steps.

The workflow is called the **assay loop**. Assay means test quality and
composition. The kit ships trustworthy **ANALYSIS** instead of code.

It is built for BI operators who run analytics but are not deeply technical.
The kit keeps the work in plain language, asks for business rulings before
numbers are run, reconciles results to source-of-truth (official system used to
verify), and blocks delivery when proof is missing.

## 2. Install

Run this in a fresh project folder:

```bash
curl -fsSL https://raw.githubusercontent.com/dep0we/bi-toolkit/main/bootstrap.sh | bash
```

Then open Claude Code in that folder and run:

```text
/assay intake
```

The install is self-contained to that folder. It copies the `/assay` router,
workflow scripts (files that run kit steps), gates, worker agents, skills,
config template (starter settings file for project), starter `CLAUDE.md`, and
receipt tools into the project. It does not require GitHub CLI (terminal tool
for GitHub tasks), authentication (proof that sign-in is valid), or a GitHub
account.

For a local checkout of this kit, you can also run:

```bash
./install.sh /path/to/analysis-project
```

The installer is rerunnable. It overwrites kit tooling, but it does not overwrite
an operator's existing `assay.config.jsonc`, `CLAUDE.md`, or docs.

## 3. How it works

The assay loop has one spine and two tracks. Stage 1 routes the request:

| Track | Use it when | Output |
| --- | --- | --- |
| ANALYSIS | The operator needs a one-time answer. | A reconciled answer with caveats, meaning limits that affect trust. |
| DATA PRODUCT | The operator needs a recurring report or dashboard. | A recurring report or dashboard with stricter validation. |

The shared spine:

1. **Intake** - capture the BI stack, data sources, source-of-truth list, validation habit, stakeholders, and done criteria.
2. **Frame** - decide whether this is ANALYSIS or DATA PRODUCT, and what decision the answer supports.
3. **Spec** - define the question, metric definitions (exact calculation rules), scope, and valid answer.
4. **Discovery** - find methodology forks (choices that change the method) before results are computed.
5. **Execute** - run the analysis or build the report using the ruled method.
6. **Validate** - reconcile results to source-of-truth, meaning numbers match or differences are explained.
7. **Review + Score** - use a fresh red-teamer to attack the conclusion and score the result.
8. **Deliver** - package the answer, evidence, caveats, methodology, and next steps.
9. **Document** - record assumptions, queries, decisions, and validation notes.
10. **Learn** - capture lessons for the next analysis.

DATA PRODUCT work also includes product design and refresh monitoring because a
bad recurring number keeps repeating until someone catches it.

The loop has three fail-closed gates. Fail-closed means the gate blocks until
proof exists.

| Gate | Blocks | What must exist |
| --- | --- | --- |
| `questioncheck` | Stage 6 execution | A Stage 2 spec receipt. |
| `validationcheck` | Stage 9 delivery | A validation receipt, plus a passing review score when required. |
| `datacheck` | Stage 9 delivery | A data-safety receipt when sensitive data is involved. |

`questioncheck` prevents execution without a spec receipt. The spec receipt
records the question, metric definitions, valid answer, decision impact, and
track.

`validationcheck` prevents delivery without reconciliation to source-of-truth.
For high-stakes work, meaning work that drives money, headcount, or strategy,
and for DATA PRODUCT work, it also requires a passing adversarial-review receipt.

`datacheck` prevents delivery when sensitive data is unclassified or lacks
recorded handling. Sensitive data means personal identifying info (PII), health
info (PHI), payroll, or customer records.

Receipts are saved proof files under `.assay/receipts/`. The usual receipt files
are:

- `<analysis-id>-spec-receipt.json`
- `<analysis-id>-validation-receipt.json`
- `<analysis-id>-adversarial-review-receipt.json`
- `<analysis-id>-data-safety-receipt.json`

The review score has four dimensions:

| Dimension | Plain meaning |
| --- | --- |
| Confidence | How sure the answer is right. |
| Data completeness | How much relevant data was included. |
| Methodology soundness | Whether the approach survives expert review. |
| Reproducibility | Whether someone else can rerun it. |

The default threshold is 3 out of 5 on every dimension. A lower score blocks
delivery unless the operator records an acceptance reason.

## 4. The governing rules

These rules are non-negotiable and are enforced through the installed project
`CLAUDE.md`.

| Rule | What it means |
| --- | --- |
| Route through the loop by default. | Inline analysis is a named exception and needs operator OK. |
| Fresh red-team validation is required. | An analysis is not done until a red-teamer sub-agent that did not produce the numbers validates it. Self-review never counts. |
| Delegate mechanical work. | Profiling and queries go to cheaper sub-agents; the main model stays focused on judgment. |
| Plain language always. | Define technical or statistical terms inline in 4-8 words. |

If a choice can change a number that stakeholders act on, the kit must surface
that choice before computing results.

## 5. The `/assay` commands

| Command | What it does |
| --- | --- |
| `/assay intake` | Captures the BI stack, source-of-truth list, validation habits, stakeholders, and delivery rules. |
| `/assay frame` | Chooses ANALYSIS or DATA PRODUCT and names the decision the work supports. |
| `/assay spec` | Writes the spec receipt with the question, metrics, scope, and valid answer. |
| `/assay discovery` | Finds methodology forks before results are computed. |
| `/assay execute` | Runs the ruled analysis or builds the ruled report after `questioncheck` passes. |
| `/assay validate` | Reconciles results to source-of-truth and writes validation evidence. |
| `/assay deliver` | Packages the final answer after `validationcheck` passes. |
| `/assay status` | Shows existing receipts, blocking gates, and the next recommended step. |

## 6. The skills

The kit includes 31 domain skills plus the `/assay` router. The router controls
the lifecycle. The domain skills supply the analysis, validation, communication,
and documentation work inside that lifecycle.

| Role | Skills |
| --- | --- |
| Router | `assay` |
| Intake and framing | `stakeholder-requirements-gathering`, `context-packager`, `analysis-planning`, `analysis-assumptions-log`, `business-metrics-calculator`, `schema-mapper` |
| Analysis techniques | `programmatic-eda`, `data-quality-audit`, `ab-test-analysis`, `cohort-analysis`, `funnel-analysis`, `impact-quantification`, `root-cause-investigation`, `segmentation-analysis`, `time-series-analysis`, `sql-to-business-logic`, `semantic-model-builder`, `dashboard-specification`, `visualization-builder` |
| Validation and review | `metric-reconciliation`, `query-validation`, `analysis-qa-checklist`, `peer-review-template` |
| Communication | `insight-synthesis`, `executive-summary-generator`, `data-narrative-builder`, `technical-to-business-translator`, `methodology-explainer` |
| Documentation | `analysis-documentation`, `data-catalog-entry`, `analysis-retrospective` |

## 7. The sub-agents

The four worker agents run on a cheaper model. The main model assigns scoped
work and keeps responsibility for judgment.

| Agent | Role |
| --- | --- |
| `eda-profiler` | Profiles data shape, freshness, gaps, nulls (blank or unknown values), duplicates, and outliers (unusual values that can skew). |
| `query-runner` | Runs ruled queries and calculations exactly to the spec; it cannot change the method. |
| `reconciler` | Checks results against source-of-truth and records matched, accepted, or unresolved differences. |
| `red-teamer` | Independently re-derives the key numbers from the raw data without seeing the analysis code, then attacks the conclusion, method, reconciliation, score, and plain language. |

The design split matters: `query-runner` produces the official numbers to the
ruled method (it cannot change the method), while `red-teamer` independently
re-derives those numbers from the raw data as a separate check and attacks the
method. Same numbers reached two independent ways — execution and validation
never share a context, so neither can rubber-stamp the other.

## 8. The model dial

Use the main model for judgment, synthesis, and review:

- framing the request;
- asking the operator for rulings;
- deciding what to delegate;
- accepting or rejecting sub-agent work;
- writing the final answer.

Use sub-agents for legwork:

- profiling data;
- running ruled queries;
- calculating metrics;
- reconciling to source-of-truth;
- drafting bounded notes.

Use cross-family review for second opinions. Cross-family means a different
model family reviews the work. In this kit, Codex can be used to review
methodology and final conclusions, especially when the cost of being wrong is
higher than the cost of review.

## 9. Everyday usage

Example: answer "Why did Q2 renewal revenue drop?"

```text
/assay intake
```

Capture the warehouse (central store for analysis data), BI tool, renewal
revenue source-of-truth, usual reconciliation process, and who approves
exceptions.

```text
/assay frame
```

Route it as ANALYSIS because this is a one-time question. Name the decision it
supports, such as whether Sales should focus on a segment.

```text
/assay spec
```

Define renewal revenue, the Q2 date window, customer segments (groups with
shared traits), exclusions, and what would count as a valid answer. This writes
the spec receipt.

```text
/assay discovery
```

Surface method choices before numbers run: booking date versus close date,
gross versus net renewals, treatment of cancellations, and missing customer
segments.

```text
/assay execute
```

`questioncheck` verifies the spec receipt exists. Then `query-runner` runs the
ruled calculations and keeps a reproducible trail, meaning rerunnable with the
same result.

```text
/assay validate
```

`reconciler` ties the numbers to the source-of-truth. For high-stakes work, a
fresh `red-teamer` attacks the conclusion and score.

```text
/assay deliver
```

`validationcheck` verifies the proof exists. Then the final answer ships with
the conclusion, evidence, caveats, reconciliation notes, and next steps.

```text
/assay status
```

Use this anytime to see which receipts exist and what is blocked.

## 10. What's in the repo

| Path | What it is |
| --- | --- |
| `README.md` | This plain-language guide. |
| `PLAYBOOK.md` | The operator manual for the assay lifecycle. |
| `methodology.md` | Why the gates, receipts, review rounds, and plain-language rule exist. |
| `model-dial.md` | How to split judgment, legwork, and second opinions across models. |
| `CLAUDE.md` | Governing rules for building this kit. |
| `CLAUDE.starter.md` | Starter project memory installed into operator projects. |
| `claude-md-guide.md` | Guidance for filling in project `CLAUDE.md`. |
| `assay.config.example.jsonc` | Example project config. |
| `bootstrap.sh` | Public installer entry point. |
| `install.sh` | Local installer that copies the kit into a project. |
| `check-prereqs.sh` | Checks local prerequisites. |
| `.claude/skills/` | The `/assay` router and 31 domain skills. |
| `.claude/agents/` | The four worker agents. |
| `.claude/workflows/` | Workflow engines, gates, receipt writer, and decision ledger. |
| `docs/spec/assay-spec.md` | Build spec for the kit. |
| `docs/ARCHITECTURE.md` | Architecture notes for the spine, skills, and project config. |
| `docs/DECISIONS.md` | Architecture decision record. |
| `seed-memory/` | BI lessons installed with the kit. |
| `test/` | Install, receipt, and gate tests. |
| `.github/workflows/ci.yml` | CI (automatic tests on changes) test runner. |
