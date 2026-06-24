# Gates And Receipts

A gate is a required stop-check before continuing. A receipt is a saved proof file. Gates read receipts and other project state. If proof is missing, the gate blocks.

Previous: [Workflow](04-workflow.md) | [Index](README.md) | Next: [Skills](06-skills.md)

## Why Gates Exist

The gates protect you from common BI failures:

- running numbers before defining the metric;
- delivering results that do not tie to source-of-truth (official place to compare);
- sharing sensitive data without a recorded audience;
- changing governing rules during the work;
- shipping a recurring report that cannot be rerun.

A gate failure is not a scolding. It is a checklist item with a clear fix.

## Receipt Files

Receipts usually live here:

```text
.assay/receipts/
```

Common receipts:

```text
<analysis-id>-spec-receipt.json
<analysis-id>-validation-receipt.json
<analysis-id>-adversarial-review-receipt.json
<analysis-id>-data-safety-receipt.json
<analysis-id>-deliverable-receipt.json
<analysis-id>-govbaseline.json
```

JSON means structured key-value data. You normally do not hand-edit receipts. Claude writes them through `.claude/workflows/receipt.sh`.

## questioncheck

Protects: Stage 6 Execute.

What it checks:

- a Stage 2 spec receipt exists;
- the spec receipt has `kind: "spec"` or `kind: "trivial"`;
- a real spec has a question, metric definitions, and valid answer;
- a trivial spec has a one-line reason.

Common block:

```text
assay-gate-failed:missing-spec
questioncheck: Stage 6 is blocked because no Stage 2 spec receipt exists...
```

How to satisfy it:

```text
/assay spec <analysis-id>
```

Give Claude:

```text
Question:
Metric definitions:
Scope:
Valid answer:
Decision impact:
Track: analysis or data-product
```

## validationcheck

Protects: Stage 9 Deliver.

What it checks:

- validation receipt exists;
- validation receipt says `reconciled: true`;
- reconciliation details exist;
- non-trivial work has an adversarial-review receipt;
- the review has scores for confidence, data completeness, methodology soundness, and reproducibility;
- high-stakes work and data products have configured source-of-truth.

Common blocks:

```text
assay-gate-failed:missing-validation
validationcheck: Stage 9 is blocked because no Stage 7 validation receipt exists.
```

```text
assay-gate-failed:sub-threshold-score
validationcheck: A Stage 8 score is below threshold...
```

```text
assay-gate-failed:source-of-truth-unconfigured
validationcheck: This work is high-stakes... but sourceOfTruth is not configured.
```

How to satisfy it:

```text
/assay validate <analysis-id>
```

If source-of-truth is missing:

```text
/assay intake
```

Then add the official source for each key metric.

## govcheck

Protects: Stage 9 Deliver.

What it checks:

- discovery created a governing-doc baseline (saved starting copy);
- protected rule files did not change during the analysis.

Default protected files come from `assay.config.jsonc`:

```text
CLAUDE.md
methodology.md
docs/DECISIONS.md
docs/spec/assay-spec.md
```

Common block:

```text
assay-gate-failed:governing-doc-edit
govcheck: Delivery is blocked because a guarded governing doc changed during this analysis...
```

How to satisfy it:

- If the change was accidental, restore or undo the rule-file change.
- If a person approved the rule update, resnapshot with explicit approval:

```bash
ASSAY_GOVCHECK_APPROVED=1 bash .claude/workflows/govcheck.sh resnapshot <analysis-id>
```

Only do that when the rule change is intentional.

## datacheck

Protects: Stage 9 Deliver.

What it checks:

- data classification (how sensitive data is) is known;
- sensitive data has a data-safety receipt;
- the receipt has audience, export destination, detail level, and operator sign-off;
- data leaving the company goes only to an approved destination.

Sensitive data means personal, health, payroll, or customer records.

Common blocks:

```text
assay-gate-failed:unknown-classification
datacheck: Delivery is blocked because the data classification is unset...
```

```text
assay-gate-failed:missing-data-safety
datacheck: Delivery is blocked because this work touches sensitive data...
```

How to satisfy it:

Tell Claude:

```text
Data classification: customer records.
Delivery audience: internal finance leadership.
Data leaves company: false.
Export destination: none.
Detail level: aggregate.
Operator sign-off: I approve this audience and handling.
```

Claude writes the data-safety receipt.

## reprocheck

Protects: Stage 9 Deliver.

What it checks:

- if `reproCommand` is set in `assay.config.jsonc`, the command exits zero;
- zero means success;
- non-zero means the rerun failed or changed beyond tolerance.

If `reproCommand` is not set, it does not block, but it warns:

```text
reprocheck: NOTE - reproducibility unverified because reproCommand is unset.
assay-gate-ok:reprocheck
```

For DATA PRODUCT work, it also warns that recurring reports should set `reproCommand`.

How to satisfy it:

Add a command in `assay.config.jsonc` that reruns the analysis or report build:

```json
"reproCommand": "bash scripts/build-renewal-report.sh"
```

Then run:

```text
/assay deliver <analysis-id>
```

## See Status

Type:

```text
/assay status
```

You will see:

```text
completed stages:
  - Stage 2 spec receipt
open findings:
  - missing-validation [validationcheck]: Missing Stage 7 validation receipt...
blocking gate: validationcheck (missing-validation)
next required step: /assay validate renewal-revenue-q2
```

