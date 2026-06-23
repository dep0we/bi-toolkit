# Changelog

All notable changes are recorded here. Release notes are taken from this file verbatim.
Format: [Keep a Changelog](https://keepachangelog.com/). Versioning: [SemVer](https://semver.org/).

## [Unreleased]

### Added
- bi-toolkit kit: two-track BI lifecycle (analysis + data-product), the assay loop engine (discovery/execute/validate), 31 adapted data-analyst skills, two fail-closed gates (questioncheck, validationcheck) with a receipt writer, public one-liner installer, and CI.
- Phase 1 assay spine: operator docs, config template, public bootstrap,
  rerunnable installer, `/assay` router, gate scripts, test harness, and starter
  BI memory lessons.

### Changed
- Updated architecture docs and gitignore rules so this kit source tracks its
  own `.claude` engine files while installed projects ignore runtime receipts.

### Fixed
