# bi-toolkit — Architecture

bi-toolkit has three layers: the assay spine, the operator's project config, and
later domain skills. Phase 1 ships only the spine: docs, installer, `/assay`
router, deterministic gates, tests, and starter memory.

## Spine

The spine is the shared lifecycle and enforcement layer:

- `PLAYBOOK.md`, `methodology.md`, and `model-dial.md` explain the process.
- `.claude/skills/assay/SKILL.md` routes `/assay` subcommands.
- `.claude/workflows/questioncheck.sh` blocks Stage 6 without a spec receipt.
- `.claude/workflows/validationcheck.sh` blocks Stage 9 without reconciliation
  and required review scores.
- `.claude/workflows/decision-ledger.sh` is copied from the dev-process kit as a
  reusable ledger query tool.

## Operator Config

`assay.config.example.jsonc` becomes `assay.config.jsonc` in an installed
project. It captures stack, source-of-truth, tripwires, review lenses, thresholds,
and high-stakes rules. Source-of-truth means the official place to compare
against.

Runtime receipts live under `.assay/receipts/` and are gitignored. A receipt is a
saved proof file for a completed stage.

## Install Contract

`bootstrap.sh` is the public `curl | bash` entry point. It downloads the public
repo with `curl` and `tar`, then runs `install.sh` into the current folder.
`install.sh` is rerunnable: it overwrites kit tooling but does not overwrite
operator config or docs.

## Later Phases

The 31 domain skills, `assay-discovery.js`, `assay-execute.js`,
`assay-validate.js`, and Sonnet agent definitions are not present in Phase 1.
Docs and router copy must not claim those engines exist yet.
