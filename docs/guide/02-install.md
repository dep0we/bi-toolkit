# Install

Install bi-toolkit from a fresh project folder (folder for one work area). The installer copies the kit into that folder and leaves your other folders alone.

Previous: [Setup](01-setup.md) | [Index](README.md) | Next: [First Run](03-first-run.md)

## The One-Liner

In the empty folder you made, type this in the terminal (the text command window):

```bash
curl -fsSL https://raw.githubusercontent.com/dep0we/bi-toolkit/main/bootstrap.sh | bash
```

What this means:

- `curl` downloads a file from the internet.
- `bash` runs a shell script (small command program).
- `|` pipes output, meaning passes it along.

What you will see:

```text
Downloading bi-toolkit...
Installing into /path/to/your/project...
Installing bi-toolkit assay spine into: /path/to/your/project
  installed: .claude/skills/ (... skills, incl. the /assay router)
  installed: .claude/hooks/
  installed: .claude/workflows/...
  created: assay.config.jsonc
  created: CLAUDE.md
  created: PLAYBOOK.md
  created: methodology.md
  created: model-dial.md
  created: claude-md-guide.md
  created: data-safety.md
  seeded: seed-memory/

Done. Next step: run /assay help, then /assay intake.
Receipts (saved proof files) will live under .assay/receipts/.

bi-toolkit is installed.
Open Claude Code in this folder and run: /assay help
When you are ready to set up the project, run: /assay intake
```

The exact list may be longer, but those are the important parts.

## What Lands In The Folder

Plain map:

```text
.claude/
  skills/       skills Claude can use
  agents/       worker agents for legwork
  workflows/    scripts that run gates and render outputs
  hooks/        reminder shown each turn

assay.config.jsonc   project settings
CLAUDE.md            project memory and rules
PLAYBOOK.md          lifecycle manual
methodology.md       why the method works
model-dial.md        when to use each model
data-safety.md       sensitive-data rules
seed-memory/         reusable BI lessons
.gitignore           ignores runtime proof folders
```

JSONC means JSON with comments. JSON means structured key-value data.

The installer is rerunnable. It overwrites kit tooling, but it does not overwrite your existing `assay.config.jsonc`, `CLAUDE.md`, or docs.

## Check The Install

Type:

```bash
bash .claude/workflows/assay-help.sh
```

You should see:

```text
assay help

What this kit does: it guides BI work from question to trusted answer.
...
Current next step:
next required step: /assay intake
No active analysis or receipts were found. Receipts are saved proof files.
```

## First Claude Command

Open Claude Code in the folder if it is not already open:

```bash
claude
```

Then type this inside Claude Code:

```text
/assay intake
```

Claude will start asking about:

- warehouse (central store for analysis data);
- BI tool (reporting or dashboard system);
- query language (how data is requested);
- source-of-truth (official place to compare);
- validation habit (how numbers are checked);
- stakeholders (people who use or approve);
- delivery rules (what done means);
- sensitive data (data needing special handling).

You do not need perfect answers. If you are unsure, say so. The kit is designed to ask follow-up questions.

