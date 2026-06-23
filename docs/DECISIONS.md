# Decisions — Architecture Decision Record (ADR) log

This file is the project's running log of **architecture decisions**: the
load-bearing choices about how the project is built and why. An ADR (Architecture
Decision Record) captures a single decision — the situation that forced it, what
was decided, why, and what it commits the project to.

**The rules:**

- **One entry per decision.** Numbered and dated, newest at the bottom.
- **Never edit an old entry to change the decision.** History is the point — a
  past decision and its reasoning stay readable even after they're overturned.
  To change a decision, write a NEW entry and set its `Supersedes:` to the old
  one's number; optionally mark the old one `Status: Superseded by ADR-NNNN`.
- **Append-only.** Fixing a typo is fine; rewriting what was decided is not.

Each entry uses these fields:

- **Status** — Proposed / Accepted / Superseded / Deprecated.
- **Supersedes** — the ADR number this one replaces, or "none".
- **Reversible** — yes / no / costly. Can this be undone cleanly later?
- **Context** — the situation and forces that made a decision necessary.
- **Decision** — what was decided, stated plainly.
- **Rationale** — why this option over the alternatives.
- **Consequences** — what this commits the project to, good and bad.

---

## ADR-0001 — 2026-06-17 — Adopt the arc decision-first quality loop

- **Status:** Accepted
- **Supersedes:** none
- **Reversible:** yes

**Context.** Building software with AI agents risks silent corner-cutting: an
agent makes a load-bearing decision on its own, or ships work that "looks done"
but skipped a review. We needed a repeatable process that surfaces material
decisions to the maintainer first and reviews its own work before claiming done.

**Decision.** Adopt the dev-process-kit's arc loop: `discovery` surfaces every
decision fork and escalates the material ones to the maintainer; `build`
implements to those rulings and reviews the diff in adversarial rounds until a
clean round; the loop never merges, tags, or publishes.

**Rationale.** A decision-first loop puts judgment where it belongs (the
maintainer) and legwork where it belongs (the agent), with adversarial
review-in-rounds catching what a single pass misses. It is the kit's core play,
proven on a production project before it was packaged.

**Consequences.** Every non-trivial change runs through discovery + build, which
is slower than going straight to code but eliminates silent decisions and
ships-with-holes work. The maintainer owns every merge. This decision is
reversible — drop the loop — but doing so forfeits those guarantees.

<!-- Growing docs/? When this folder holds more than these two stubs, add a
docs/README.md table of contents (a one-screen list of what is in docs/). Add a
docs/spec/ folder only when you have a real external contract, and a
docs/glossary.md only when the vocabulary has grown enough to need one. Add each
by hand, when you feel the absence, never preemptively: a doc written to be
thorough and never updated is a doc that lies. -->
