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
- the dashboard engine renders static HTML dashboards.
- the decision ledger records `refresh-cadence` decisions.

Some recurring-report support named below is described as part of the toolkit direction but is not fully present as executable scripts in this repo. For exact flags and commands, see `CHANGELOG.md` and `PLAYBOOK.md` as the implementation lands.

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

`deliverable-diff` means a comparison between report versions. I could not verify a `deliverable-diff` script or command in this repo. Purpose: show what changed between the prior delivered file and the current delivered file before the operator sends it. See `CHANGELOG.md` and `PLAYBOOK.md` for exact flags when finalized.

How the operator uses it:

```text
Ask Claude: compare this run to the last delivered run and summarize what changed before I send it.
```

Claude should look at receipts, output files, and rulings, then produce a plain change note.

## Drift And Refresh Monitoring

Drift means numbers move unexpectedly. Refresh means new data arrives for the report.

The repo's playbook includes Stage 10 Monitor / Refresh for DATA PRODUCT work. The current `reprocheck` can run a configured `reproCommand` before delivery.

Example config:

```json
"reproCommand": "bash scripts/build-renewal-scorecard.sh"
```

What happens during delivery:

```text
reprocheck: running reproCommand for renewal-scorecard. Reproducibility means re-running work gets the same answer.
assay-gate-ok:reprocheck
```

`driftcheck` means a recurring metric movement check. I could not verify a `driftcheck` script or command in this repo. Purpose: compare the new run to expected ranges, prior runs, or thresholds and flag unexpected movement. See `CHANGELOG.md` and `PLAYBOOK.md` for exact flags when finalized.

How the operator uses it:

```text
Ask Claude: check the refreshed dashboard for metric drift and explain any unexpected movement before delivery.
```

## Distribution Handoff

Distribution means who receives the report and where it goes. For sensitive data, `datacheck` already requires:

- delivery audience;
- whether data leaves the company;
- export destination;
- row-level or aggregate detail;
- operator sign-off.

A distribution manifest means a delivery handoff record. I could not verify a distribution-manifest script or exact schema in this repo. Purpose: record who gets the recurring report, where it is published, who owns refresh issues, and what to do when validation fails. See `CHANGELOG.md` and `PLAYBOOK.md` for exact flags when finalized.

How the operator uses it:

```text
Ask Claude: prepare the distribution handoff for this recurring report: audience, destination, owner, refresh timing, and failure contact.
```

## Living Metric Store

A living metric store means maintained metric definitions. It prevents "renewal revenue" from changing meaning across runs.

The repo verifies supporting pieces:

- `sourceOfTruth` in `assay.config.jsonc`;
- `semantic-model-builder` skill;
- `data-catalog-entry` skill;
- decision ledger for methodology rulings;
- `analysis-documentation` skill.

I could not verify a single executable "living metric store" command or file contract in this repo. Purpose: keep current metric definitions, owners, source-of-truth, tolerances, and known caveats in one maintained place. See `CHANGELOG.md` and `PLAYBOOK.md` for exact flags when finalized.

How the operator uses it:

```text
Ask Claude: update the metric definition record for renewal revenue with the approved Finance definition and source-of-truth.
```

## Recurring Report Checklist

Before a data product is delivered, confirm:

- the track is `data-product`;
- source-of-truth is configured;
- refresh cadence is ruled and recorded;
- the dashboard or report has an owner;
- sensitive-data handling is recorded;
- `reproCommand` is set or the warning is accepted;
- validation and adversarial review receipts exist;
- distribution handoff is clear.

