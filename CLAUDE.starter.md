# CLAUDE.md — Analysis Project

This file captures how this BI project works. Fill in the project-specific
sections during `/assay intake`. The "Governing rules" section below is fixed —
keep it verbatim; it is how the kit protects your numbers.

## Governing rules — how this project works (keep these verbatim)

These are not optional and apply to **every** analysis (answering with data or
numbers) in this folder, even a quick "just look at this" or "see what you can
do" request. Skipping any of them is a **named exception that needs your
explicit OK first** — never a silent default. "It was a small dataset and the
answer came fast" is exactly when the discipline slips.

1. **Route through the assay loop by default.** Any analysis runs the lifecycle
   (ordered path from question to delivery): frame → spec → discovery (recording
   no forks, meaning choices that change the number, if none exist) → execute →
   validate → deliver, writing a receipt (a saved proof file) at each gated
   stage. Answering inline in the chat, skipping the loop, is the exception — say
   so and get the operator's OK before doing it.

2. **An analysis is NOT done until an independent agent validates it.** Findings
   must NOT be shown to anyone until a **fresh agent that did not produce the
   numbers** (the `red-teamer` sub-agent, a worker agent given a narrow task)
   has adversarially reviewed them, meaning attacked weak spots in the answer,
   and a validation receipt (saved proof that checks happened) exists.
   **Self-review by the agent that ran the analysis does not count** — it cannot
   catch its own framing errors or hidden assumptions. Reconcile to
   source-of-truth (the official place to compare against) via the `reconciler`
   sub-agent before presenting.

3. **Delegate the mechanical work; keep the main model for judgment.** Data
   crunching — profiling, counting, running queries — goes to the worker
   sub-agents (worker agents given narrow tasks: `eda-profiler`, `query-runner`;
   they run on a cheaper model). The main model (the agent leading judgment)
   plans, interprets, and synthesizes. Do not run profiling scripts inline on the
   main model because it is faster to type — that wastes the expensive model on
   grunt work and skips the delegation the kit is built on.

4. **Plain language always.** Every term shown to the operator is defined inline
   in 4-8 words, e.g. cohort (a group tracked over time). Frame choices by
   consequence, not jargon.

5. **Proactively orient new or confused operators.** If the operator seems new,
   seems confused, or asks a data question without using `/assay`, briefly
   explain that the kit will guide them step by step, then start the loop with
   `/assay intake` or `/assay frame`. Do not lecture; take their hand.

## What This Project Does

Describe the recurring analysis, dashboard, or reporting work in plain language.

## BI Stack

- Warehouse:
- BI tool:
- Query language:
- Main datasets:

## Source Of Truth

Source-of-truth means the official place to compare against.

| Metric | Source-of-truth | Owner | Notes |
| --- | --- | --- | --- |
|  |  |  |  |

## Validation Habit

Reconciliation means numbers match the official source, or differences are
explained.

- How numbers are checked today:
- Accepted tolerance, if any:
- Who approves exceptions:

## Stakeholders

- Decision makers:
- Reviewers:
- Audience:

## High-Stakes Definition

High-stakes means the answer drives money, headcount, or strategy. List local
examples here:

- 

## Delivery Rules

- What "done" means:
- Required charts or tables:
- Required caveats:
- Recurring refresh cadence, if any:

## Plain-Language Rule

Every operator-facing term must be defined inline in 4-8 words. Example:
cohort (group tracked over time).
