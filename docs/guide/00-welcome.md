# Welcome

bi-toolkit is a Claude Code (an AI assistant you run in a folder) kit for BI (business reporting and metrics) work. It gives you a repeatable path for answering data questions and building recurring reports.

The workflow is called the assay loop. Assay means test quality and composition. In this kit, that means every important number is defined, checked, and explained before it is delivered.

[Index](README.md) | Next: [Setup](01-setup.md)

## Who This Is For

Use this guide if you:

- build reports, dashboards, scorecards, or analysis;
- know your data and business process;
- are new to AI (software that drafts and checks work);
- are new to Claude Code (an AI assistant you run in a folder);
- want a patient, step-by-step process.

You do not need to be a developer. You will type short commands and answer plain questions.

## What The Toolkit Does

The toolkit helps Claude do the legwork:

- collect context;
- define the question;
- find method choices before numbers run;
- run or guide the analysis;
- reconcile results to source-of-truth (official place to compare);
- write receipts (saved proof files);
- package a report or dashboard.

You make the judgment calls:

- what decision matters;
- which metric definition is right;
- what source-of-truth is official;
- whether a caveat changes the decision;
- whether an accepted risk is reasonable.

## Trustworthy Analysis

Trustworthy analysis means a person can answer five questions:

1. What question did we answer?
2. How did we define each metric?
3. What data did we use?
4. Did the result reconcile to source-of-truth (official place to compare)?
5. What limits or caveats affect the decision?

The kit blocks delivery when proof is missing. A block is a required stop, not a crash.

## Two Kinds Of Work

### ANALYSIS

ANALYSIS means a one-time answer. Use it when someone asks:

- "Why did renewal revenue drop?"
- "Which stores missed margin?"
- "Did the test improve conversion?"
- "What changed since last quarter?"

The output is a validated answer with evidence, caveats (limits that affect trust), and next steps.

### DATA PRODUCT

DATA PRODUCT means a recurring report or dashboard. Use it when you need:

- a weekly scorecard;
- a monthly finance dashboard;
- a recurring operations exception report;
- a report that refreshes on a schedule.

The output is a recurring report or dashboard with stricter validation. A wrong recurring number repeats until someone catches it, so the kit treats it more carefully.

## What It Feels Like

You type:

```text
/assay frame
```

Claude responds with questions such as:

```text
What decision will this answer support?
Is this a one-time analysis or a recurring data product?
What source-of-truth should the final number tie to?
```

You answer in normal words:

```text
This is a one-time analysis. Finance wants to know why Q2 renewal revenue dropped before the forecast meeting. Renewal revenue should tie to the finance close report.
```

Claude then guides the next step. You do not have to remember the whole workflow.

## Your Role

Think of Claude as a careful analyst assistant. It can draft, inspect, compare, and summarize. It cannot decide what your business should count as official.

Good operator input:

```text
Use invoice date, not close date, because Finance reports renewal revenue by invoice month.
```

Weak operator input:

```text
Just use the normal date.
```

The first answer gives the kit a ruling (operator-approved method choice). The second answer hides a method choice that could change the number.

