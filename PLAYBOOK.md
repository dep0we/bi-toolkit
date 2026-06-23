# The Assay Playbook

This is the operating manual for shipping trustworthy analysis with AI. The
assay loop (staged checks for BI answers) has a simple rule: every stage runs by
default. Claude may propose skipping a stage only with a plain reason and your
explicit approval. Silent skips are defects. A request to "see what you can do"
or find numbers is analysis (answering with data or numbers) and enters the loop
by default.

## Non-Negotiable Disciplines

- Route through the loop by default; inline answers require a named exception
  and your explicit approval.
- Validate with a fresh `red-teamer` sub-agent, meaning a worker agent given a
  narrow task. Self-review, meaning review by the same agent, does not count.
- Delegate mechanical work, meaning repeatable profiling, counting, and queries,
  to `eda-profiler` and `query-runner` sub-agents.

## Lifecycle

| Stage | Name | Track | What Happens | Gate |
| ---: | --- | --- | --- | --- |
| 0 | Intake | Shared | Capture data sources, BI tool, query language, source-of-truth (official comparison source), validation habits, stakeholders, and done criteria. | - |
| 1 | Frame | Shared | Decide whether the request answers a question or creates a data product (a recurring report or dashboard). | - |
| 2 | Spec | Shared | Define the question, metrics, scope, and what a valid answer looks like. Writes the spec receipt (saved proof file). | Required before Stage 6 |
| 3 | Plan Review | Shared | Pressure-test decision value, methodology (the chosen analysis approach), and data availability. | - |
| 4 | Profile Data | Analysis | Inspect tables, missing values, joins, and suspicious data. | - |
| 4d | Design Product | Data Product | Choose layout, metrics, refresh rhythm, access, and semantic layer (shared metric definitions). | - |
| 5 | Discovery | Analysis | Lock methodology forks before results are computed. | - |
| 6 | Execute | Shared | Run the analysis or build the report using the locked decisions. Delegate profiling, counting, and queries to worker sub-agents. | `questioncheck` |
| 7 | Validate | Shared | Reconcile results to source-of-truth, meaning numbers match the official source or differences are explained. Use the `reconciler` sub-agent; do not self-check. | Required before Stage 9 |
| 8 | Review + Score | Shared | Red-team the conclusion with a fresh `red-teamer` sub-agent that did not produce the numbers. Score confidence, completeness, methodology, and reproducibility. | Required for every non-trivial analysis (not approved as too small to gate) |
| 9 | Deliver | Shared | Package the answer, charts, caveats, and next steps for the audience. | `validationcheck` |
| 10 | Monitor | Data Product | Check refreshes and metric drift, meaning numbers move unexpectedly. | - |
| 11 | Document | Shared | Record assumptions, queries, decisions, and validation notes. | - |
| 12 | Retro | Shared | Capture lessons for the next analysis. | - |

## Tracks

**Analysis** answers a question once, usually to support a decision.

**Data product** builds something recurring, such as a dashboard or weekly
scorecard. A data product gets stricter review because a wrong number repeats
until someone catches it.

## The Two Gates

`questioncheck` runs before Stage 6. It fails closed when no Stage 2 spec receipt
exists. Failing closed means the script stops the next step unless proof exists.
The receipt records the question, metric definitions, and what a valid answer
looks like. A trivial receipt is allowed only with a one-line reason.

`validationcheck` runs before Stage 9. It fails closed when there is no
validation receipt, when reconciliation failed, when the adversarial-review
receipt is missing, or when a required Stage 8 score is missing or below
threshold, meaning the minimum allowed score. Adversarial review means a review
that attacks the answer.
High-stakes work means work that drives money, headcount, or strategy. The gate
decides that from the spec receipt's decision-impact field, not from an operator
bypass.

## Score Rubric

Stage 8 scores each result from 1 to 5:

- **Confidence** - how sure we are the answer is right.
- **Data completeness** - how much relevant data was included.
- **Methodology soundness** - whether the approach would survive expert review.
- **Reproducibility** - whether someone else could rerun it and get the same
  number.

Default threshold, meaning the minimum allowed score: every dimension must be at
least 3. A lower score blocks delivery unless the operator records an acceptance
reason.

## Operator Rule

The operator owns judgment: scope, trade-offs, risk acceptance, and delivery
approval. Claude owns legwork: drafting, checking, summarizing, and finding weak
spots, while worker sub-agents run repeatable profiling, counting, and queries.
When a choice changes the number stakeholders act on, Claude must surface it
before computing results.
