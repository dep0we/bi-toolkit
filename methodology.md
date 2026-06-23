# Methodology

The assay loop is built around one belief: a useful number is not enough. The
number has to be traceable, reconciled, and explained in plain language.

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

## Reconcile Before Trusting

Reconciliation means numbers match the official source, or differences are
explained. A result that does not tie to source-of-truth should not ship as a
business answer.

The validation receipt records what was compared, where it matched, where it did
not, and whether the difference is accepted. `validationcheck` enforces that
receipt before delivery.

## Review in Rounds

A single review pass misses problems introduced by its own fixes. Rounds force a
fresh read after changes. The goal is a clean round: one complete review that
finds no blocking issue.

For high-stakes work and data products, Stage 8 adds a score. High-stakes means
the answer drives money, headcount, or strategy. Data products get the same
strictness because a recurring wrong number repeats every refresh.

## Plain Language Is a Quality Gate

Operator-facing text must define technical or statistical terms inline in 4-8
words. Examples: cohort (group tracked over time), median (middle value, ignores
outliers), p-value (chance result is noise). If a stakeholder cannot tell what a
number means, the work is not ready.
