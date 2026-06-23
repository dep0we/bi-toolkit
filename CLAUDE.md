# CLAUDE.md — bi-toolkit

This file loads in every session for this repo. It captures the project's
design principles and working rules for **building the kit**. Project rules here
take precedence over global preferences.

---

## What this is

bi-toolkit is a Claude Code kit that standardizes a BI / data-analysis workflow,
the way the dev-process-kit standardizes building software. It gives a BI team a
repeatable operating spine — a staged lifecycle, fail-closed quality gates,
adversarial review rounds, and Sonnet sub-agents for the legwork — wrapped around
proven data-analysis skills. Its users are **BI operators who run analytics but
are not deeply technical**: the kit's whole job is to make rigorous analysis
repeatable for them, in plain language. It installs into a fresh project folder
with one public command that pulls from this GitHub repo.

**This kit is itself built *through* the dev-process-kit's arc loop.** The repo
you are working in is a software project; the thing it produces is a workflow
kit. Keep that straight (see principle 10).

---

## Design principles — the taste rules

These keep the kit coherent as it grows. When a proposed change would violate
one, **stop and write down why before proceeding.** Silently breaking them is not
allowed.

### 1. Single source of truth for state

The kit's authoritative state is **the files in this repo** — the lifecycle
definitions, skills, workflow scripts, and gate scripts. A target project's
installed `.claude/` is a *copy* pulled from here, never an independent original.
The intake interview's output (the operator's captured process) is the
authoritative state *for that installed project*, living in its config and
`CLAUDE.md`.

### 2. Abstractions earn their place

Don't add a stage, gate, skill, or config knob for a hypothetical future need.
Add it the second time a real workflow needs it. Every stage an operator has to
understand is rent they pay; the lifecycle stays as small as it can while still
being trustworthy.

### 3. Layers compose; they don't merge

Three layers stay distinct: the **spine** (lifecycle + gates + orchestration),
the **domain skills** (the 31 data-analysis skills, wrapped as stage content),
and the **operator's own config** (their captured process). Don't fold a domain
skill's logic into the spine, or hardcode an operator-specific choice into a
shared skill.

### 4. Cost and safety are first-class

The kit spends model tokens (Sonnet sub-agents) and produces analysis that drives
real decisions. The gates are the safety mechanism: no analysis executes without a
spec (`questioncheck`), and no deliverable ships without reconciliation to
source-of-truth plus — for high-stakes work — an adversarial review
(`validationcheck`). A gate that can be skipped silently is a bug.

### 5. Audit trail is structural

Every analysis leaves a record: the spec, the methodology decisions that were
ruled, the validation receipt, the score. A conclusion an operator can't trace
back to its decisions and its source-of-truth check is incomplete.

### 6. Errors fail loud, not silent

Gates fail closed and say why, in plain language. A validation mismatch, a missing
spec, or an unreconciled number stops the flow with a readable reason — never a
silent pass that ships a wrong number every week.

### 7. Backward compatibility by default

An operator who installed the kit keeps working when we ship a new version.
Re-running the installer overwrites tooling but never clobbers their captured
process (their config, their `CLAUDE.md`). Breaking changes to the install
contract or the lifecycle are deliberate, versioned, and called out in the
changelog with an upgrade note.

### 8. Documentation matches reality, not aspirations

The PLAYBOOK, README, and methodology describe the lifecycle the kit *actually*
runs today. A stage documented but not wired, or a gate described as enforced but
actually advisory, is the exact drift this kit exists to prevent.

### 9. The spec/contract is the product

This kit has two contracts that must never drift from behavior:
(a) the **install contract** — what the public one-liner pulls and what lands in a
target `.claude/`; and (b) the **lifecycle contract** — the stages, the two tracks,
and what each gate enforces. Code or skills that change either without updating its
documented contract are incomplete.

### 10. Plain language is the product, not a nicety

The kit's users run BI but are not deeply technical. **Every operator-facing string
the kit emits** — decision packets, intake questions, deliverable templates, error
messages, skill prompts — defines any technical or statistical term inline in 4-8
words ("p-value (chance the result is just noise)", "cohort (a group tracked over
time)") and frames choices by consequence, not jargon. This is enforced as a review
lens (`plain-language` in `arc.config.jsonc`) and is a Tier-A tripwire to weaken.
It is the kit's signature; treat a jargon leak as a defect, not a style nit.

### 11. Two tracks, one spine

BI work splits into **analysis** (answer a question, drive a decision) and
**data products** (build a recurring report/dashboard). Both share intake, the
metric-definition spec, the validation gate, adversarial review, and
documentation; they diverge in the middle (analysis = heavy methodology
discovery; data-product = heavy design + scheduled-refresh maintenance). Keep the
shared spine shared and the track-specific stages clearly track-specific.

### 12. Marry, don't rebuild

The 31 data-analyst skills already exist and are the domain layer. Adapt and wrap
them to fit the lifecycle; reach for rebuilding a skill from scratch only when
adaptation genuinely can't fit it. New skills are for spine gaps the existing set
doesn't cover.

### 13. The two CLAUDE.md's never cross

This repo has **two** distinct CLAUDE-style files with opposite audiences:
*this* `CLAUDE.md` (rules for developers/AI building the kit) and
`CLAUDE.starter.md` (the template the kit ships, that a BI operator fills in at
intake). Never edit one thinking of the other's audience. Product copy that should
be plain-for-operators goes in the starter and the skills, not here.

---

## Working methods — the process disciplines

These are the disciplines this kit is built under. Leave them in place; full
rationale is in the dev-process-kit's `methodology.md`.

- **Decision-first.** Surface every material decision before building; never
  decide a load-bearing fork silently. When in doubt, escalate. (The `/arc`
  discovery loop does this.)

- **Adversarial review in rounds, not one pass.** Two rounds minimum, more for
  riskier diffs. Each round re-reviews the previous round's fixes. Include the
  shortcut-hunter lens and — for this kit — the plain-language lens.

- **Verify before claim.** Reproduce a behavior before asserting it. Run the gate
  script, install into a scratch folder, check the actual output. Confirm your own
  claims the same way you'd verify an external one.

- **Converge on a clean round, not the round cap.** "Done" means a full review
  round found zero blocking issues — not "I ran three rounds."

- **Ship end-to-end via the pipeline.** Branch, test, changelog, version, commit,
  push, PR, doc-sync — every time. Never hand-roll commit/push/PR.

- **Bisectable commits, not save-points.** One concept per commit (core change /
  tests / docs).

- **The changelog is the single source of truth.** Every PR adds its own changelog
  bullets as part of the diff.

- **Reversible vs irreversible — different gates.** Local edits, branches, scratch
  installs proceed freely. Merging, tagging, publishing, force-pushing need
  explicit approval every time.

- **File scope-creep inline.** A side-issue surfaced mid-task gets filed as a
  GitHub issue immediately; it does not ride along in the current PR.

---

## Conventions

- **Issues / backlog:** GitHub Issues at `dep0we/bi-toolkit`. Use the bootstrapped
  label taxonomy (`enhancement`, `bug`, `documentation`, `infrastructure`,
  `polish`, `security`, `spec`, `question`). Don't track this kit's work elsewhere.

- **Branches + PRs:** feature branch → PR → self-review → merge. `main` is
  protected; never push to it directly. `/ship` runs the pipeline.

- **Tests:** `bash test/run.sh` runs the full suite (shell harness, like the
  dev-process-kit's). New gate logic, install behavior, and workflow scripts ship
  with tests; a gate without a test that fails when the gate is stripped is not
  done.

- **Releases + versioning:** SemVer, recorded in `CHANGELOG.md`; release notes are
  taken from it verbatim.

- **Knowledge routing:** none — this repo is self-contained. The kit *is* the
  product, so its design, methodology, and decisions live in the repo (`docs/`,
  PLAYBOOK, methodology). There is no separate knowledge home.

---

## Where things live

| Doc | Purpose |
|-----|---------|
| `docs/ARCHITECTURE.md` | How the kit fits together (spine / skills / operator config); read first |
| `docs/DECISIONS.md` | Architecture Decision Record (ADR) log |
| `CHANGELOG.md` | What shipped in each release; source of release notes |
| `PLAYBOOK.md` | The BI lifecycle, stage by stage — the operating manual the kit ships (to be authored) |
| `methodology.md` | Why the lifecycle and gates are shaped this way (to be authored) |
| `CLAUDE.starter.md` | The template the kit ships; a BI operator fills it in at intake (product content, NOT this file) |
| `.gstack/arc.config.jsonc` | The arc loop's per-project rules for building this kit |
| GitHub Issues `dep0we/bi-toolkit` | Executable backlog |
