# Conductor And Help

The conductor is the part of the kit that keeps the current analysis and next step visible. It uses the active pointer, status helper, help helper, and reminder hook.

Previous: [Recurring And Monitoring](09-recurring-and-monitoring.md) | [Index](README.md) | Next: [Troubleshooting FAQ](11-troubleshooting-faq.md)

## Active Analysis

Active analysis means the saved work to resume first. The kit stores it here:

```text
.assay/active.json
```

When you frame work, Claude sets it:

```text
assay-active-set:renewal-revenue-q2:analysis
```

When delivery succeeds, Claude clears it:

```text
assay-active-clear:renewal-revenue-q2
```

If delivery fails, it does not clear the active pointer. That helps you resume later.

## Every-Turn Reminder

The installer adds a `UserPromptSubmit` hook. A hook is a small command that runs at a set time. This hook prints the active analysis and next step each turn.

It is a reminder, not the hard gate. The hard blocks are the gate scripts, such as `questioncheck` and `validationcheck`.

## /assay help

Type:

```text
/assay help
```

What you will see:

```text
assay help

What this kit does: it guides BI work from question to trusted answer.
...
Current next step:
next required step: /assay intake
No active analysis or receipts were found. Receipts are saved proof files.
```

If an active analysis exists, help uses it:

```text
Current next step:
next required step: /assay validate renewal-revenue-q2
```

## /assay status

Type:

```text
/assay status
```

If there are multiple in-flight analyses, you will see one line per analysis:

```text
renewal-revenue-q2    next: /assay validate renewal-revenue-q2    blocker: missing-validation
labor-scorecard       next: /assay deliver labor-scorecard         blocker: none
```

For one analysis:

```text
/assay status renewal-revenue-q2
```

You will see:

```text
assay-state: renewal-revenue-q2
completed stages:
  - Stage 2 spec receipt
  - governing-doc baseline
  - Stage 5 discovery record
  - methodology rulings
open findings:
  - missing-validation [validationcheck]: Missing Stage 7 validation receipt...
stage: Stage 7 Validate
blocking gate: validationcheck (missing-validation)
next required step: /assay validate renewal-revenue-q2
```

## /assay finish

Finish means continue a stalled analysis from saved proof.

Type:

```text
/assay finish renewal-revenue-q2
```

The helper reports the next required step. Claude must continue from that step only. It must not recompute completed stages or jump around a gate.

## /assay resume

Resume is an alias for finish. Alias means another command name for the same action.

If you remember the id:

```text
/assay resume renewal-revenue-q2
```

If you do not remember the id:

```text
/assay resume
```

If there is no active analysis, you will see:

```text
assay-state: no active analysis - run /assay status or /assay help
```

Then type:

```text
/assay status
```

## /assay ledger

The ledger is the saved list of methodology rulings. Methodology rulings are approved choices that can change numbers.

Type:

```text
/assay ledger
```

Claude runs:

```bash
bash .claude/workflows/decision-ledger.sh list
```

You can ask:

```text
Show the rulings for renewal-revenue-q2.
```

or:

```text
Show prior refresh-cadence rulings.
```

## New User Guidance

The installed `CLAUDE.md` tells Claude to proactively orient new or confused operators. If you ask a data question without `/assay`, Claude should briefly explain the loop and start with `/assay intake` or `/assay frame`.

You can always say:

```text
I am new. Please tell me the next command and why it matters.
```

