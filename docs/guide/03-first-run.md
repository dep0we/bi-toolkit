# First Run

This page walks through one complete ANALYSIS (one-time answer) from intake to delivered report. The example question is: "Why did Q2 renewal revenue drop?"

Previous: [Install](02-install.md) | [Index](README.md) | Next: [Workflow](04-workflow.md)

## Before You Start

You are in Claude Code (an AI assistant you run in a folder). You have installed bi-toolkit in a project folder (folder for one work area).

Use a stable analysis id (short saved-work name):

```text
renewal-revenue-q2
```

## Step 0: Intake

Type:

```text
/assay intake
```

Claude asks:

```text
What warehouse, BI tool, and query language does this project use?
What are the source-of-truth systems for key metrics?
How do you validate numbers today?
Who are the decision makers, reviewers, and audience?
What counts as high-stakes work here?
What delivery rules should every answer follow?
```

You answer:

```text
Warehouse: Snowflake. BI tool: Tableau. Query language: SQL.
Renewal revenue source-of-truth: Finance close report.
Validation habit: totals must tie to Finance within $100 or the variance must be explained.
Decision maker: VP Sales. Reviewer: Finance analyst. Audience: Sales leadership.
High-stakes: revenue, forecast, headcount, and board metrics.
Done means a plain report with caveats and source notes.
```

What happens:

- Claude drafts updates to `assay.config.jsonc`.
- Claude drafts updates to `CLAUDE.md`.
- Claude should ask before writing those project settings.

## Step 1: Frame

Type:

```text
/assay frame
```

Claude asks:

```text
Is this ANALYSIS or DATA PRODUCT?
What decision will this answer support?
```

You answer:

```text
This is ANALYSIS. It is a one-time answer for why Q2 renewal revenue dropped. The decision is whether Sales should focus recovery work on a segment before the forecast meeting.
Use analysis id renewal-revenue-q2.
```

What happens:

```text
assay-active-set:renewal-revenue-q2:analysis
```

Active means saved work to resume first.

## Step 2: Spec

Type:

```text
/assay spec renewal-revenue-q2
```

Claude asks:

```text
What exact question are we answering?
Which metrics need definitions?
What is in scope and out of scope?
What would count as a valid answer?
What decision impact should be recorded?
```

You answer:

```text
Question: Why did Q2 renewal revenue drop compared with Q1?
Metric: renewal revenue means invoiced renewal ARR in the quarter, excluding new-logo revenue and one-time services.
Scope: Q1 and Q2 of this fiscal year, all active customer accounts, grouped by segment and sales owner.
Valid answer: quantify the drop, identify the largest drivers, reconcile total renewal revenue to Finance, and state caveats.
Decision impact: affects forecast and Sales recovery focus, so it drives money and strategy.
Data classification: internal aggregate unless customer-level tables are exported.
```

Claude writes a spec receipt (saved proof file):

```text
assay-receipt-written:spec:.assay/receipts/renewal-revenue-q2-spec-receipt.json
```

Why this matters: `questioncheck` will not let execution start without this receipt.

## Step 5: Discovery

Type:

```text
/assay discovery renewal-revenue-q2
```

Discovery means finding method choices before results. Claude does not compute final numbers here.

First, the kit snapshots governing docs (protected rule files):

```text
assay-gate-ok:govcheck-snapshot
```

Then Claude lists methodology forks (choices that change numbers), such as:

```text
Fork: Which date counts?
Option A: invoice date. Consequence: matches Finance close reporting.
Option B: contract close date. Consequence: may shift revenue into a different quarter.
Recommendation: invoice date, because the source-of-truth is Finance close.

Fork: Gross or net renewal revenue?
Option A: gross renewals only. Consequence: shows booked renewal volume.
Option B: net of credits and cancellations. Consequence: ties better to actual revenue impact.
Recommendation: use the Finance definition named in the close report.
```

You make rulings:

```text
Use invoice date. Use the Finance close definition. Exclude one-time services. Group by Finance segment, not Sales segment, because Finance owns the source-of-truth.
```

Claude records the rulings (operator-approved method choices):

```text
assay-discovery-recorded:.assay/rulings/renewal-revenue-q2-latest-discovery.json
assay-rulings-written:.assay/rulings/renewal-revenue-q2-rulings.json
```

## Step 6: Execute

Type:

```text
/assay execute renewal-revenue-q2
```

The front gate runs:

```text
assay-gate-ok:questioncheck
assay-gate-ok:rulingscheck
```

Claude delegates legwork:

- `eda-profiler` checks tables, freshness, nulls (blank or unknown values), duplicates, and outliers (unusual values that can skew).
- `query-runner` runs the ruled queries exactly to the spec.

Claude may say:

```text
I found a new Tier-A fork: customer segment differs between Finance and Sales. This can change the driver table. Please rule which segment source to use before I continue.
```

That is a block. It is the system protecting you from a silent choice. Answer with a ruling:

```text
Use Finance segment for the main answer. Add Sales segment only as a supporting cut if needed.
```

## Step 7: Validate

Type:

```text
/assay validate renewal-revenue-q2
```

Claude sends the `reconciler` sub-agent (worker agent with narrow task) to tie results to source-of-truth (official place to compare). It sends a fresh `red-teamer` sub-agent to attack the conclusion.

You may see:

```text
Finance close total: $4,820,000
Analysis total: $4,819,944
Variance: $56
Status: matched within tolerance
```

Claude writes:

```text
assay-receipt-written:validation:.assay/receipts/renewal-revenue-q2-validation-receipt.json
assay-receipt-written:adversarial-review:.assay/receipts/renewal-revenue-q2-adversarial-review-receipt.json
```

The review receipt includes scores:

```text
confidence: 4
dataCompleteness: 4
methodologySoundness: 4
reproducibility: 3
```

## Step 9: Deliver

Type:

```text
/assay deliver renewal-revenue-q2
```

Delivery preflight runs:

```text
assay-gate-ok:validationcheck
assay-gate-ok:govcheck
assay-gate-ok:datacheck
assay-gate-ok:reprocheck
```

If PDF tools are installed, the report renderer writes HTML and PDF. If not, it still writes HTML.

What you may see:

```text
assay-report-html:.assay/deliverables/renewal-revenue-q2/report-20260624T153000Z.html
assay-report-pdf-note:No PDF renderer, meaning a tool that makes PDF files, was available. Open the HTML report and use print-to-PDF if a PDF is needed.
assay-report-receipt:.assay/receipts/renewal-revenue-q2-deliverable-receipt.json
```

The report includes:

- conclusion;
- key findings;
- evidence;
- methodology (chosen analysis approach);
- caveats (limits that affect trust);
- reconciliation notes;
- score;
- next steps.

## What A Block Looks Like

Example:

```text
assay-gate-failed:missing-spec
questioncheck: Stage 6 is blocked because no Stage 2 spec receipt exists. Create .assay/receipts/renewal-revenue-q2-spec-receipt.json with the question, metric definitions, and what a valid answer looks like. A receipt is a saved proof file.
```

This is not an error in your work. It means the kit will not let numbers run before the question and metric definitions are written down.

What to type:

```text
/assay spec renewal-revenue-q2
```

