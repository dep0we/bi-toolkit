# Recurring And Monitoring

DATA PRODUCT work means a recurring report or dashboard. The kit treats data products more strictly because a wrong recurring number repeats until someone catches it.

Previous: [Reports And Dashboards](08-reports-and-dashboards.md) | [Index](README.md) | Next: [Conductor And Help](10-conductor-and-help.md)

## What Is Verified In This Repo

The current repo verifies these data-product behaviors:

- DATA PRODUCT is a first-class track.
- Stage 4d designs the product.
- Stage 10 monitors refreshes and drift.
- data products require stronger validation and review scoring.
- `reprocheck` warns strongly when a data product has no `reproCommand`.
- the report engine and dashboard engine write per-run metric snapshots.
- `deliverable-diff.sh` compares the current run with the prior run.
- `driftcheck.sh` checks refresh health and metric drift.
- `distribution-manifest.sh` writes a local delivery handoff, or withholds it when sensitive data needs sign-off.
- `metric-catalog.json` and `metric-store.sh` maintain shared metric definitions.

## Versioning

Versioning means keeping named versions of outputs. For recurring reports, versioning answers:

- Which report run did we send?
- Which inputs did it use?
- Which metric definitions were active?
- Which caveats applied?
- What changed since the last run?

Operator use:

```text
/assay status renewal-scorecard
```

Then check deliverable receipts (saved proof files) under:

```text
.assay/receipts/
```

and output files under:

```text
.assay/deliverables/<analysis-id>/
```

## What Changed Since Last Run

Recurring reports need a clear change summary:

- metric values changed;
- source data refreshed;
- methodology rulings changed;
- dashboard layout changed;
- caveats changed;
- validation status changed.

`deliverable-diff` means a comparison between report versions. The script writes:

- `diff-<timestamp>.txt`: plain-language change notes;
- `latest.json`: pointer to the newest snapshot.

The exact command is:

```bash
bash .claude/workflows/deliverable-diff.sh <analysis-id> <metrics-snapshot-json> <artifact-path> [assay.config.jsonc]
```

During report or dashboard delivery, the renderer runs this automatically after it writes the new metrics snapshot.

## Drift And Refresh Monitoring

Drift means numbers move unexpectedly. Refresh means new data arrives for the report.

The exact command is:

```bash
bash .claude/workflows/driftcheck.sh <analysis-id> <metrics-snapshot-json> [assay.config.jsonc]
```

`driftcheck.sh` writes:

- `drift-<timestamp>.txt`: the plain-language monitoring result;
- `latest-drift.json`: structured drift state for later tools.

The block-vs-warn rule is:

- broken or empty data-product refresh BLOCKS delivery;
- metric drift WARNS, because a changed number may still be real.

Broken refresh means `refreshOk` is false or `rendererStatus` is failed or error. Empty refresh means `rowCount` is zero or below. Those block only when the spec receipt says the track is `data-product`.

Metric drift compares the new snapshot to the previous `latest.json` snapshot. The config key is:

```json
"monitoring": {
  "defaultTolerance": 0.10,
  "metrics": {
    "net_retention": { "tolerance": 0.05, "mode": "relative" },
    "open_invoice_count": { "tolerance": 10, "mode": "absolute" }
  }
}
```

Relative tolerance means percent movement from the prior run. Absolute tolerance means raw number movement.

## Distribution Handoff

Distribution means who receives the report and where it goes. A distribution manifest means a delivery handoff record.

The exact command is:

```bash
bash .claude/workflows/distribution-manifest.sh <analysis-id> <artifact-path> <timestamp> <metrics-snapshot-json> [assay.config.jsonc]
```

The manifest records:

- audience;
- channel description;
- cadence;
- data classification;
- data-safety receipt path, when present;
- local send status.

The config key is:

```json
"distribution": {
  "audience": "finance leaders",
  "channelDescription": "email to finance-leaders",
  "cadence": "monthly after finance close"
}
```

Sensitive-data distribution is withheld when sensitive data lacks data-safety sign-off. Withheld means no distribution manifest is written. Sensitive data means personal identifying info, health info, payroll, or customer records.

For sensitive data, `datacheck` requires:

- delivery audience;
- whether data leaves the company;
- export destination;
- row-level or aggregate detail;
- operator sign-off.

## Living Metric Store

A living metric store means maintained metric definitions. It prevents "renewal revenue" from changing meaning across runs.

The shared file is:

```text
metric-catalog.json
```

The path comes from `metricCatalogPath` in `assay.config.jsonc`. If that is not set, the default is `metric-catalog.json`.

`metric-store.sh` manages the catalog:

```bash
bash .claude/workflows/metric-store.sh add <name> <definition> <sourceOfTruth> <owner> <format> [notes]
bash .claude/workflows/metric-store.sh get <name>
bash .claude/workflows/metric-store.sh list
bash .claude/workflows/metric-store.sh check <name> <definition>
```

What each command does:

- `add`: creates or updates one metric definition.
- `get`: prints one metric definition.
- `list`: prints the known metrics.
- `check`: compares a proposed definition to the catalog.

During `/assay spec`, Claude checks each proposed metric against the catalog:

- `metric-store:match`: use the catalog definition.
- `metric-store:not-found`: ask whether to add the metric before continuing.
- `metric-store:differs`: escalate as drift, meaning definitions split across analyses.

The catalog is a shared definition record. It does not replace validation against source systems.

## Recurring Report Checklist

Before a data product is delivered, confirm:

- the track is `data-product`;
- source-of-truth is configured;
- refresh cadence is ruled and recorded;
- the dashboard or report has an owner;
- sensitive-data handling is recorded;
- `reproCommand` is set or the warning is accepted;
- validation and adversarial review receipts exist;
- metric definitions are checked against `metric-catalog.json`;
- distribution handoff is clear, or sensitive-data withholding is expected.
