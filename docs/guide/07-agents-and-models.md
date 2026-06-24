# Agents And Models

An agent is a focused AI worker. A model is the AI system doing the thinking. The kit uses the main model for judgment and sub-agents (worker agents with narrow tasks) for legwork.

Previous: [Skills](06-skills.md) | [Index](README.md) | Next: [Reports And Dashboards](08-reports-and-dashboards.md)

## The Simple Rule

Main model equals judgment.

Sub-agents equal legwork.

Cross-family review equals second opinion.

Cross-family means a different model family reviews the work.

## Main Model

The main model stays in the conversation with you.

Use it for:

- framing the request;
- asking you for rulings;
- deciding what to delegate;
- interpreting results;
- accepting or rejecting sub-agent work;
- writing the final answer.

It should not silently decide a methodology fork (choice that changes numbers). It should ask you.

## The 4 Sub-Agents

| Agent | What it does | What it should not do |
| --- | --- | --- |
| `eda-profiler` | Profiles data shape, freshness, nulls, duplicates, outliers, and risks. | It should not decide material method choices. |
| `query-runner` | Runs ruled queries and calculations exactly to the spec. | It should not change the method or write stakeholder delivery copy. |
| `reconciler` | Ties results to source-of-truth and records validation evidence. | It should not wave through unreconciled results. |
| `red-teamer` | Attacks conclusion, method, reconciliation, score, and wording. | It should not soften blocking issues for convenience. |

Nulls are blank or unknown values. Outliers are unusual values that can skew.

## Why Use Sub-Agents

Sub-agents do bounded work:

```text
Profile this table for missing values and duplicates.
Run this ruled query.
Compare this total to Finance.
Attack this conclusion for weak assumptions.
```

The main model keeps responsibility for judgment:

```text
Does this caveat change the answer?
Should we ask the operator for a ruling?
Is this result ready to deliver?
```

## The Model Dial

The model dial is the cost-and-quality choice for AI work.

Use the strongest model for:

- methodology (chosen analysis approach);
- risk decisions;
- synthesis;
- final review.

Use cheaper sub-agents for:

- profiling;
- counting;
- running queries;
- drafting bounded notes;
- reconciliation checks.

Use cross-family review when:

- the work is high-stakes;
- the method is debatable;
- the result will drive money, headcount, or strategy;
- you want a second opinion that may catch confirmation bias.

Confirmation bias means seeing only supporting evidence.

## What You Will See

During execution, Claude may say:

```text
I am sending the data profile to eda-profiler and the ruled calculation to query-runner. I will use their outputs to synthesize the answer.
```

During validation, Claude may say:

```text
I am sending reconciliation to reconciler and independent review to red-teamer. Self-review does not count.
```

That split is intentional. It keeps the person-facing conversation focused on judgment while the workers handle repeatable tasks.

