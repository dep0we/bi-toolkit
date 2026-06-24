# Skills

A skill is a reusable instruction set Claude can use for a specific kind of BI work. The kit includes the `/assay` router plus 31 domain skills.

Previous: [Gates And Receipts](05-gates-and-receipts.md) | [Index](README.md) | Next: [Agents And Models](07-agents-and-models.md)

## Router

| Skill | Plain description | Use this when... |
| --- | --- | --- |
| `assay` | Runs the BI quality loop and commands. | You type `/assay help`, `/assay intake`, `/assay frame`, `/assay spec`, `/assay discovery`, `/assay execute`, `/assay validate`, `/assay deliver`, `/assay status`, `/assay finish`, `/assay resume`, or `/assay ledger`. |

## Intake And Framing

| Skill | Plain description | Use this when... |
| --- | --- | --- |
| `stakeholder-requirements-gathering` | Turns a loose request into clear needs. | You need to clarify the question, decision, audience, track, or acceptance criteria. |
| `context-packager` | Packages goals, systems, files, and constraints. | You need to organize the context Claude should use. |
| `analysis-planning` | Structures question, scope, metrics, risks, and deliverables. | You are preparing the Stage 2 spec. |
| `analysis-assumptions-log` | Tracks assumptions, trade-offs, risks, and validation plans. | You need an audit trail for choices that could change the answer. |
| `business-metrics-calculator` | Defines and calculates standard business metrics. | You need exact metric definitions or common SaaS, e-commerce, finance, marketplace, or product metrics. |
| `schema-mapper` | Maps tables, fields, and relationships. | You are exploring unfamiliar data or finding join paths. |

## Analysis Techniques

| Skill | Plain description | Use this when... |
| --- | --- | --- |
| `programmatic-eda` | Runs first-pass data inspection. | You need data shape, distributions, missing values, correlations, or obvious risks. |
| `data-quality-audit` | Audits data against rules and source expectations. | You need to check data quality or prepare validation evidence. |
| `ab-test-analysis` | Reviews A/B test setup and results. | You need conversion lift, sample split, confidence, guardrails, or rollout advice. |
| `cohort-analysis` | Tracks groups over time. | You need retention, revenue, adoption, or behavior by start date, channel, or plan. |
| `funnel-analysis` | Measures multi-step conversion and drop-off. | You need signup, checkout, onboarding, renewal, lead, or process funnel analysis. |
| `impact-quantification` | Sizes business impact and ROI. | You need opportunity size, cost, savings, or prioritization by value. |
| `root-cause-investigation` | Investigates unexpected metric movement. | A metric changed and stakeholders need drivers. |
| `segmentation-analysis` | Groups customers, users, products, or accounts. | You need meaningful behavior groups or outcome comparisons by segment. |
| `time-series-analysis` | Analyzes trends, seasonality, anomalies, and forecasts. | You need metric movement over time or cautious planning ranges. |
| `sql-to-business-logic` | Translates SQL into business rules. | You need to explain or check what a query really counts. |
| `semantic-model-builder` | Documents shared metric and entity definitions. | You need a semantic layer for recurring reports or reproducible analysis. |
| `dashboard-specification` | Designs dashboard requirements. | You need users, decisions, metrics, layout, refresh, access, and validation needs. |
| `visualization-builder` | Chooses and designs clear BI visuals. | You need charts, dashboard views, or presentation-ready visuals. |

## Validation And Review

| Skill | Plain description | Use this when... |
| --- | --- | --- |
| `metric-reconciliation` | Compares numbers across sources and explains differences. | Results must tie to finance, BI, warehouse, product, or migrated-system totals. |
| `query-validation` | Reviews SQL correctness and business logic. | You need joins, filters, aggregation, source ties, or performance checked. |
| `analysis-qa-checklist` | Runs BI quality checks before delivery. | You are preparing validation or checking calculations. |
| `peer-review-template` | Runs structured adversarial review and scoring. | You need a red-team review before delivery. |

## Communication

| Skill | Plain description | Use this when... |
| --- | --- | --- |
| `insight-synthesis` | Turns findings into decision-ready insights. | You need conclusions and recommendations from validated results. |
| `executive-summary-generator` | Writes concise leadership summaries. | You need a short report for executives. |
| `data-narrative-builder` | Builds plain-language reports and commentary. | You need a delivered story from validated analysis. |
| `technical-to-business-translator` | Converts technical BI language to business language. | You need SQL, statistics, or methodology explained plainly. |
| `methodology-explainer` | Explains methods, assumptions, and limits. | You need to tell stakeholders how the analysis was done. |

## Documentation

| Skill | Plain description | Use this when... |
| --- | --- | --- |
| `analysis-documentation` | Creates reproducible analysis documentation. | You need to archive question, method, data, results, and validation. |
| `data-catalog-entry` | Documents datasets, ownership, quality, and lineage. | You need a catalog entry or data dictionary. |
| `analysis-retrospective` | Captures lessons after analysis or release. | You need to record what worked, what failed, and what to watch next time. |

## Production And Output

These are domain skills used heavily when a result becomes a report or dashboard:

| Skill | Plain description | Use this when... |
| --- | --- | --- |
| `dashboard-specification` | Defines recurring dashboard behavior. | You are building a data product. |
| `semantic-model-builder` | Makes shared definitions reusable. | You need recurring metrics to stay consistent. |
| `visualization-builder` | Creates decision-readable charts. | You need a chart, report visual, or dashboard panel. |
| `analysis-documentation` | Saves the reproducible trail. | Someone needs to rerun or audit the work. |
| `data-catalog-entry` | Records data ownership and meaning. | The report depends on reusable datasets. |

## How To Ask For A Skill

You usually do not need to name skills. The `/assay` router chooses them from the stage.

You can still ask plainly:

```text
Use cohort analysis to compare renewal retention by signup quarter.
```

or:

```text
Use metric reconciliation to tie the dashboard total to Finance.
```

