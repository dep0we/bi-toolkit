# /assay intake — the setup interview

This is the script the agent follows for `/assay intake`. It is the operator's
**first experience** with the toolkit, so it must feel like a short, friendly
conversation, not a form. Follow this flow; do not improvise a different one.

## How to run this interview

- **Ask in small batches** — one or two questions at a time, then wait for the
  answer. Never paste all the questions at once.
- **Plain language.** Define any technical or statistical term inline in 4-8
  words. Lead with the concrete example on every question.
- **Honor "skip."** If the operator says "skip", "not sure", or "later", accept
  it, record a sensible default (or leave it blank), and move on. Never push.
- **Defer the heavy stuff.** Capture the essentials now. Do NOT demand exact
  metric calculation rules, a full metric catalog, per-analysis data
  classification, or export destinations during intake — capture those lazily,
  the first time they actually matter.
- **Confirm at the end.** Recap what you captured, save it (with approval), and
  point to the next step.

## Opening (say this first, before any question)

> "I'll ask a handful of quick questions to set this up for how you work — about
> **2 minutes**. Everything here is just a **starting baseline**: nothing's
> locked in, you can change any answer later, and it'll **evolve as the project
> grows**. And if you don't have an answer right now, just say **'skip'** and
> we'll move on."

## The questions

**1. What this project is for**
> "In a sentence or two, what will you use this project for?"

Example to offer: *"weekly sales and margin reports for leadership, plus ad-hoc
questions when a number looks off."*
→ The project's purpose (fills `CLAUDE.md` "What This Project Does"). Note: this
is what the *project* is for, not a personal job description.

**2. Where your data lives + your tools**
> "Where does your data live, and what do you use to work with it?"

Example: *"Snowflake, I write SQL and build dashboards in Power BI"* — or
*"mostly Excel and CSV exports."* ("Describe it if you don't know exact names.")
→ `stack` (warehouse, BI tool, query language). Skip → leave blank; ask again
the first time a query needs to run.

**3. Your key numbers + their official source**
> "What are the 2-3 numbers you report most, and where's the *official* source
> for each — the place you'd trust to settle an argument?"

Example: *"Revenue → the finance system; Active customers → the product
database."* ("Just the big ones; we'll add more over time.")
→ `sourceOfTruth` map + seed the metric catalog with **name + source-of-truth
only**. Do NOT ask for the exact calculation rule now; offer to pin it down the
first time the metric is used.

**4. How you check numbers today**
> "Before you send a number, how do you make sure it's right?"

Example: *"cross-check the dashboard against the finance export."* ("'I eyeball
it' is a fine, honest answer.")
→ validation habit (recorded in `CLAUDE.md`).

**5. Audience + what "done" means**
> "Who's the main audience for your reports, and what does a finished
> deliverable usually include?"

Example: *"leadership; an exec summary and a couple of charts."*
→ stakeholders + delivery rules.

**6. Sensitive data**
> "Does your work usually touch sensitive data — customer records, employee or
> payroll info, or health data? A yes / no / 'sometimes' is fine."

("This just turns on an extra check before anything sensitive is shared. PII =
personal identifying info; PHI = health info.")
→ `dataSafety` default classification (none/internal vs sensitive). Defer export
destinations and per-analysis classification to when sensitive work happens.

**7. One high-stakes example**
> "Give me one analysis where being wrong would really matter — something that
> drives money, headcount, or a big decision."

→ `highStakesDefinition` (tells the toolkit when to be extra rigorous).

## Closing (say this last)

1. **Recap:** "Here's what I captured: [short recap of the answers]."
2. **Save (only with the operator's OK):**
   - write/update `assay.config.jsonc` (stack, sourceOfTruth, highStakesDefinition,
     dataSafety default, stakeholder/delivery notes);
   - seed the metric catalog for each named key metric (name + source-of-truth;
     definition captured later) with:
     `bash .claude/workflows/metric-store.sh add <name> "TBD" <source-of-truth> "TBD" "TBD" "definition pending first use"`
   - draft `CLAUDE.md`: copy the **Governing rules** section from
     `CLAUDE.starter.md` **verbatim**, and fill the project-specific sections
     from the answers.
3. **Remind:** "Saved to your project. Change any of it anytime — just tell me
   or edit `assay.config.jsonc`."
4. **Next step:** "Ready to start? Run `/assay frame`, or just tell me the
   question you're chasing."

## Notes for the agent

- Keep `assay.config.jsonc`'s `sourceOfTruth` map and the metric catalog aligned.
  If they ever disagree, surface it and ask which source is official.
- Anything skipped is a sound default, not a blocker. The gates will prompt for
  what they actually need, when they need it (e.g. a metric's exact definition,
  a data-safety sign-off) — so intake never has to be exhaustive.
