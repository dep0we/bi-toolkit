# bi-toolkit — Architecture

bi-toolkit has three layers: the assay spine, the operator's project config, and
domain skills. The kit ships docs, installer, `/assay` router, workflow engines,
deterministic gates, tests, starter memory, agents, and adapted BI skills.

## Spine

The spine is the shared lifecycle and enforcement layer:

- `PLAYBOOK.md`, `methodology.md`, and `model-dial.md` explain the process.
- `.claude/skills/assay/SKILL.md` routes `/assay` subcommands.
- `.claude/workflows/assay-discovery.js` surfaces methodology choices before
  results are computed. Methodology means the chosen analysis approach.
- `.claude/workflows/assay-execute.js` runs the ruled work and review rounds.
- `.claude/workflows/assay-validate.js` reconciles results and returns receipt
  payloads for the back gate.
- `.claude/workflows/receipt.sh` writes receipt files in the exact format the
  gates read.
- `.claude/workflows/metric-store.sh` reads and updates the living metric
  catalog. Living means the shared definition is updated as the team learns.
- `.claude/workflows/assay-state.sh` reads receipts and rulings to summarize
  status, meaning saved progress and next required step.
- `.claude/workflows/questioncheck.sh` blocks Stage 6 without a spec receipt.
- `.claude/workflows/validationcheck.sh` blocks Stage 9 without reconciliation
  and required review scores.
- `.claude/workflows/govcheck.sh` blocks delivery when protected governing docs
  changed after discovery.
- `.claude/workflows/datacheck.sh` blocks delivery without required sensitive-
  data handling proof.
- `.claude/workflows/reprocheck.sh` optionally runs `reproCommand` before
  delivery. Reproducibility means re-running work gets the same answer.
- `.claude/workflows/decision-ledger.sh` queries ledger rows appended by ruled
  methodology forks.

## Operator Config

`assay.config.example.jsonc` becomes `assay.config.jsonc` in an installed
project. It captures stack, source-of-truth, `receiptsDir`, `rulingsDir`,
`metricCatalogPath`, `reproCommand`, tripwires, review lenses, thresholds,
meaning minimum passing scores, and high-stakes rules. Source-of-truth means the
official place to compare against.

`metric-catalog.json` is tracked project knowledge, not runtime state. It is the
richer living record for metric name, definition, source-of-truth, owner, format,
and notes. The older `sourceOfTruth` config map remains for gate compatibility
and should be derived from or kept aligned with the catalog.

Runtime receipts default to `.assay/receipts/` and are gitignored. A receipt is
a saved proof file for a completed stage.

## Install Contract

`bootstrap.sh` is the public `curl | bash` entry point. It downloads the public
repo with `curl` and `tar`, then runs `install.sh` into the current folder.
`install.sh` is rerunnable: it overwrites kit tooling but does not overwrite
operator config, metric catalog, or docs.

## Domain Skills

The adapted domain skills live under `.claude/skills/`. They stay separate from
the spine so analysis content can improve without changing the gate contract.
