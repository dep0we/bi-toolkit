# bi-toolkit

bi-toolkit is a Claude Code kit for shipping trustworthy analysis. It gives BI
operators a repeatable path for one-off analysis and recurring reports: define
the question, lock the metric meanings, run the work, reconcile the numbers to a
source-of-truth (the official place to compare against), review the conclusion,
then deliver.

Start with [PLAYBOOK.md](PLAYBOOK.md). It is the operator manual. The other
core files are:

- [methodology.md](methodology.md) - why the gates and review rounds exist.
- [model-dial.md](model-dial.md) - which model does judgment, legwork, and second
  opinions.
- [claude-md-guide.md](claude-md-guide.md) - how to fill in a project
  `CLAUDE.md`.
- [CLAUDE.starter.md](CLAUDE.starter.md) - the starter template installed into
  operator projects.
- [assay.config.example.jsonc](assay.config.example.jsonc) - the config file
  template.

## Install

From a fresh project folder:

```bash
curl -fsSL https://raw.githubusercontent.com/dep0we/bi-toolkit/main/bootstrap.sh | bash
```

The bootstrap script downloads this public kit with `curl`, runs `install.sh`
into the current folder, copies the `/assay` skill and gate scripts, seeds BI
lessons, and points you to `/assay intake`. It does not require GitHub CLI,
authentication, or a GitHub account.

For a local checkout of this kit:

```bash
./install.sh /path/to/analysis-project
```

The installer is rerunnable. It overwrites kit tooling, but it never overwrites
an operator's `assay.config.jsonc`, `CLAUDE.md`, or existing docs.

## Everyday Flow

Use `/assay` inside the analysis project:

```text
/assay intake     capture your BI stack and source-of-truth list
/assay frame      decide whether this is analysis or a data product
/assay spec       define the question, metrics, and valid answer
/assay discovery  lock methodology choices before results are computed
/assay execute    run the analysis or build the report
/assay validate   reconcile results to source-of-truth
/assay deliver    package the final answer
/assay status     show receipts and next action
```

Two gates are enforced in Phase 1:

- `questioncheck` blocks Stage 6 execution until a spec receipt exists.
- `validationcheck` blocks Stage 9 delivery until results are reconciled and,
  when required, reviewed with a passing score.

Receipts are saved under `.assay/receipts/` in the operator project. A receipt is
a saved proof file for a completed stage.

## What Phase 1 Includes

This branch ships the spine: docs, installer, config template, `/assay` router,
gate scripts, tests, and starter memory. It does not yet ship the 31 domain
skills or the `assay-*.js` workflow engines; those are later phases.
