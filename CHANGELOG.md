# Changelog

All notable changes are recorded here. Release notes are taken from this file verbatim.
Format: [Keep a Changelog](https://keepachangelog.com/). Versioning: [SemVer](https://semver.org/).

## [Unreleased]

### Added
- Bundle 3 data-safety gate: `datacheck` now blocks delivery when sensitive BI
  data lacks recorded audience, handling, export destination, detail level, and
  operator sign-off; `receipt.sh` can write `data-safety` receipts, installs now
  ship `datacheck.sh` and `data-safety.md`, and `/assay intake` captures data
  classification defaults plus approved export destinations.
- Bundle 2 durable methodology rulings: `/assay discovery` now records discovery
  run ids and surfaced fork ids, `/assay execute` now fails closed when rulings
  are missing, incomplete, or stale, and operators can explicitly reaffirm
  rulings after a deliberate discovery rerun.
- Active BI lessons: installed seed-memory files now get a generated
  `seed-memory/MEMORY.md` index when missing, and execute/validate workflows load
  relevant lessons into prep, run, reconcile, score, and review prompts.
- BI decision ledger: durable decision history now writes to
  `.assay/rulings/decisions.jsonl` and validates BI decision classes such as
  metric-definition, source-of-truth, cohort-or-window, null-or-outlier,
  statistical-method, segment-boundary, and refresh-cadence.
- Bundle 1 gate enforcement: `/assay` now has a structural preflight dispatcher
  for discovery, execute, and deliver; discovery snapshots protected governing
  docs, execute enforces the spec gate, and deliver enforces validation plus
  governing-doc protection.
- `govcheck` protects `governingDocs` during an analysis by comparing current
  rule files to the discovery baseline under `.assay/receipts/`; operator-
  approved rule updates can intentionally resnapshot with an approval flag.
- Installer now ships a `UserPromptSubmit` governing-reminder hook and merges it
  into `.claude/settings.json` without clobbering existing settings when python3
  or node is available.
- Governing rules now ENFORCED, not just described: the project CLAUDE.md and /assay router require routing through the loop by default, independent validation by a fresh red-teamer (self-review never counts), and delegation of mechanical work to sub-agents. validationcheck now requires the independent review for every non-trivial analysis (trivial work escapes).
- validationcheck: high-stakes and data-product work now blocks delivery when `sourceOfTruth` is unconfigured (makes `/assay intake` required in practice); routine work passes but warns. Source-of-truth is the anchor the back gate reconciles against.
- bi-toolkit kit: two-track BI lifecycle (analysis + data-product), the assay loop engine (discovery/execute/validate), 31 adapted data-analyst skills, two fail-closed gates (questioncheck, validationcheck) with a receipt writer, public one-liner installer, and CI.
- Phase 1 assay spine: operator docs, config template, public bootstrap,
  rerunnable installer, `/assay` router, gate scripts, test harness, and starter
  BI memory lessons.

### Changed
- Updated architecture docs and gitignore rules so this kit source tracks its
  own `.claude` engine files while installed projects ignore runtime receipts.

### Fixed
