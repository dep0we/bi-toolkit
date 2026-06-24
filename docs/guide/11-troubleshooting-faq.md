# Troubleshooting FAQ

This page covers common beginner problems, especially if you are new to AI tools and terminal-driven work.

Previous: [Conductor And Help](10-conductor-and-help.md) | [Index](README.md) | Next: [Glossary](12-glossary.md)

## It stopped and asked for a spec. Did I do something wrong?

No. The kit is protecting the analysis.

You may see:

```text
assay-gate-failed:missing-spec
questioncheck: Stage 6 is blocked because no Stage 2 spec receipt exists...
```

Spec means written question, metrics, scope, and valid answer. The fix is:

```text
/assay spec <analysis-id>
```

Tell Claude:

```text
Here is the question, metric definition, scope, valid answer, and decision impact.
```

## What is a receipt?

A receipt is a saved proof file. It records that a step happened and what proof exists.

Receipts live under:

```text
.assay/receipts/
```

You usually do not edit them. Claude writes them through the kit.

## The PDF did not generate. Is the report lost?

No. HTML still works.

You may see:

```text
assay-report-pdf-note:No PDF renderer, meaning a tool that makes PDF files, was available. Open the HTML report and use print-to-PDF if a PDF is needed.
```

Open the HTML report path in your browser and choose print-to-PDF.

Optional PDF tools are:

- `pandoc`;
- `wkhtmltopdf`;
- Chrome;
- Chromium.

## I closed the window. How do I pick up?

Open the project folder again. Start Claude Code:

```bash
claude
```

Then type:

```text
/assay resume
```

If that does not find an active analysis:

```text
/assay status
```

Then resume the analysis id shown:

```text
/assay resume <analysis-id>
```

## It says source-of-truth is not configured.

Source-of-truth means official place to compare. High-stakes work and data products need it configured.

You may see:

```text
assay-gate-failed:source-of-truth-unconfigured
```

Fix:

```text
/assay intake
```

Tell Claude:

```text
For renewal revenue, source-of-truth is the Finance close report.
For gross margin, source-of-truth is NetSuite.
For active customers, source-of-truth is Salesforce account status.
```

## The numbers need a source of truth, but we have two.

Say that plainly. This is a methodology fork (choice that changes numbers).

Example:

```text
Finance has the close report, but Sales uses Salesforce. Finance is official for total renewal revenue. Salesforce is useful for owner and segment cuts.
```

Claude should ask you to rule which source wins for each metric.

## It found a new methodology fork during execution.

That is expected sometimes. It means a material choice appeared after data inspection.

Example:

```text
Customer segment differs between Finance and Sales. This can change the driver table.
```

Answer with a ruling:

```text
Use Finance segment for the official result. Add Sales segment as a supporting view only.
```

## It says data classification is unknown.

Classification means how sensitive the data is.

Fix by telling Claude:

```text
Data classification is internal.
```

or:

```text
Data classification is customer records. Delivery audience is internal finance leadership. Data leaves company: false. Detail level: aggregate. I approve this handling.
```

## It says a governing doc changed.

Governing docs are protected rule files. The kit snapshots them at discovery and blocks if they change before delivery.

If the change was accidental, undo it.

If a person approved the change:

```bash
ASSAY_GOVCHECK_APPROVED=1 bash .claude/workflows/govcheck.sh resnapshot <analysis-id>
```

Do not run that just to get around the gate.

## It says reproducibility is unverified.

Reproducibility means re-running work gets the same answer.

If `reproCommand` is unset, the gate warns but passes:

```text
reprocheck: NOTE - reproducibility unverified because reproCommand is unset.
assay-gate-ok:reprocheck
```

For recurring reports, add a command in `assay.config.jsonc`:

```json
"reproCommand": "bash scripts/build-report.sh"
```

## Claude is asking too many questions.

For BI work, questions are often the safeguard. Answer briefly:

```text
Use invoice date because Finance reports by invoice month.
```

If a question does not matter, say:

```text
This choice does not change the number or decision. Use the simpler option and record it as a low-risk assumption.
```

## Claude is making assumptions.

Stop it and ask for the assumption log:

```text
List every assumption you are making, what could change if it is wrong, and which ones need my ruling.
```

## Tips For Working With An AI Assistant

Be specific:

```text
Compare Q2 to Q1, using invoice date, excluding one-time services.
```

Let it ask:

```text
Ask me before choosing any method that changes the number.
```

Review its work:

```text
Show the reconciliation and caveats before delivery.
```

Name official sources:

```text
Finance close report is official for revenue. Tableau is not official for revenue totals.
```

Correct it directly:

```text
That definition is wrong. Renewal revenue excludes new-logo ARR.
```

