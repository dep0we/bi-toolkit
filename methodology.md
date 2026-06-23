# Methodology

The assay loop is built around one belief: a useful number is not enough. The
number has to be traceable, reconciled, and explained in plain language.
Exploratory requests like "see what you can do" are still analysis (answering
with data or numbers), so they enter the loop by default.

## Define Before Query

A metric definition must exist before the query runs. Metric definition means the
exact rule for calculating a number. Without it, two people can both calculate
"churn" and produce different answers while both think they are right.

The spec receipt records the question, metric definitions, scope, and valid
answer. That receipt is what `questioncheck` enforces.

## Surface Methodology Forks

Methodology means the chosen analysis approach. In BI work, the risky decisions
are often quiet: which date field counts, how to treat nulls, which customer
group is included, which source wins when two systems disagree.

Discovery finds those forks before results are computed. If a fork changes a
number that stakeholders act on, it is escalated.

## Delegate Mechanical Work

Mechanical work means repeatable profiling, counting, and queries. That work
goes to sub-agents, meaning worker agents given narrow tasks, so the main model
(the agent leading judgment) can frame, interpret, and synthesize. Running data
crunching inline on the main model skips the kit's cost and review discipline.

## Reconcile Before Trusting

Reconciliation means numbers match the official source, or differences are
explained. A result that does not tie to source-of-truth should not ship as a
business answer.

The validation receipt records what was compared, where it matched, where it did
not, and whether the difference is accepted. `validationcheck` enforces that
receipt before delivery.

## Independent Review in Rounds

A single review pass misses problems introduced by its own fixes. Rounds force a
fresh read after changes. The goal is a clean round: one complete review that
finds no blocking issue. The reviewer must be a fresh `red-teamer` sub-agent
that did not produce the numbers. Self-review, meaning review by the same agent,
does not count.

Every non-trivial analysis, meaning not approved as too small to gate, gets that
independent review before delivery. For high-stakes work and data products,
Stage 8 also enforces the score threshold (the minimum allowed score).
High-stakes means the answer drives money, headcount, or strategy. Data
products get the same score strictness because a recurring wrong number repeats
every refresh.

## Plain Language Is a Quality Gate

Operator-facing text must define technical or statistical terms inline in 4-8
words. Examples: cohort (group tracked over time), median (middle value, ignores
outliers), p-value (chance result is noise). If a stakeholder cannot tell what a
number means, the work is not ready.
