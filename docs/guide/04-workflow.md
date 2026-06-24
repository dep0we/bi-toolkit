# Workflow

The assay loop is the lifecycle (ordered path from question to delivery). It has one shared spine and two tracks: ANALYSIS (one-time answer) and DATA PRODUCT (recurring report or dashboard).

Previous: [First Run](03-first-run.md) | [Index](README.md) | Next: [Gates And Receipts](05-gates-and-receipts.md)

## Diagram In Text

```text
Start
  |
  v
Stage 0 Intake
  |
  v
Stage 1 Frame
  |
  +--> ANALYSIS track -------------------+
  |                                      |
  | Stage 2 Spec                         |
  | Stage 3 Plan Review                  |
  | Stage 4 Profile Data                 |
  | Stage 5 Discovery                    |
  | Stage 6 Execute                      |
  | Stage 7 Validate                     |
  | Stage 8 Review + Score               |
  | Stage 9 Deliver                      |
  | Stage 11 Document                    |
  | Stage 12 Retro                       |
  |                                      |
  +--> DATA PRODUCT track ---------------+
                                         |
      Stage 2 Spec                       |
      Stage 3 Plan Review                |
      Stage 4d Design Product            |
      Stage 6 Build / Execute            |
      Stage 7 Validate                   |
      Stage 8 Review + Score             |
      Stage 9 Deliver                    |
      Stage 10 Monitor / Refresh         |
      Stage 11 Document                  |
      Stage 12 Retro                     |
```

## The Stages

Stage 0 Intake captures your BI stack (tools and systems), source-of-truth (official place to compare), validation habit (how numbers are checked), stakeholders, and done rules.

Stage 1 Frame decides whether the work is ANALYSIS or DATA PRODUCT and names the decision the answer supports.

Stage 2 Spec defines the question, metric definitions (exact calculation rules), scope, and valid answer. It writes the spec receipt (saved proof file).

Stage 3 Plan Review pressure-tests decision value, data availability, methodology (chosen analysis approach), and plain language.

Stage 4 Profile Data checks shape, freshness, missing values, duplicates, outliers (unusual values that can skew), and table relationships.

Stage 4d Design Product is for DATA PRODUCT work. It chooses layout, metrics, refresh cadence (how often it updates), access, and semantic layer (shared metric definitions).

Stage 5 Discovery finds methodology forks (choices that change numbers) before results are computed.

Stage 6 Execute runs the ruled analysis or builds the report/dashboard.

Stage 7 Validate reconciles results to source-of-truth (official place to compare).

Stage 8 Review + Score uses a fresh red-teamer (independent checking agent) to attack weak spots and score the work.

Stage 9 Deliver packages the answer, evidence, caveats (limits that affect trust), and next steps.

Stage 10 Monitor / Refresh is for DATA PRODUCT work. It checks recurring runs and metric drift (unexpected number movement).

Stage 11 Document records assumptions, queries, decisions, and validation notes.

Stage 12 Retro captures lessons for the next analysis.

## When To Use ANALYSIS

Use ANALYSIS when:

- the question is one-time;
- the audience needs an answer, not a maintained dashboard;
- the time window is specific;
- the output can be a report, table, or recommendation.

Examples:

```text
Why did Q2 renewal revenue drop?
Which locations drove labor overage last month?
Did the campaign change conversion?
```

## When To Use DATA PRODUCT

Use DATA PRODUCT when:

- the report will recur;
- people will act from the same numbers repeatedly;
- refresh timing matters;
- ownership, access, and layout matter;
- a wrong number could repeat.

Examples:

```text
Build a weekly renewal risk dashboard.
Create a monthly gross margin scorecard.
Replace a manual executive report.
```

## What To Type

If you know the work is one-time:

```text
/assay frame
```

Then say:

```text
This is ANALYSIS because it answers one question for one decision.
```

If you know the work is recurring:

```text
/assay frame
```

Then say:

```text
This is DATA PRODUCT because it will refresh every week and be used repeatedly.
```

If you are unsure:

```text
/assay help
```

You will see the current next step and plain guidance.

