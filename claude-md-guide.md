# Guide: Writing The Project CLAUDE.md

The installed `CLAUDE.md` is the operator project's working memory. It should
describe how the team really runs analysis, not how the kit works internally.

## What To Capture

Write down:

- The BI stack: warehouse, BI tool, query language, and important datasets.
- The source-of-truth list, meaning the official source for each key metric.
- The validation habit, meaning how numbers are checked before delivery.
- The stakeholder map, meaning who decides, reviews, and receives results.
- The high-stakes definition, meaning what work drives money, headcount, or
  strategy.
- The delivery rules, meaning what must be included before work is done.

## Writing Rules

Use short, direct sentences. Avoid team-specific shorthand unless you define it.
Define technical or statistical terms inline in 4-8 words. Keep examples local:
name the actual dashboard, metric, owner, or source.

## Good Entry

```text
Gross margin comes from NetSuite. The dashboard may show detail by product, but
the total must reconcile to NetSuite before delivery.
```

## Weak Entry

```text
Use the finance source for margin.
```

The weak version does not name the source or the validation rule.
