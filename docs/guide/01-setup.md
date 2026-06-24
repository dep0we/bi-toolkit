# Setup

This page gets your computer ready at a beginner level. You only need a project folder (folder for one work area), Claude Code (an AI assistant you run in a folder), and a terminal (the text command window).

Previous: [Welcome](00-welcome.md) | [Index](README.md) | Next: [Install](02-install.md)

## What Claude Code Is

Claude Code is an AI assistant you run inside a folder. It can read files, write files, run commands, and ask you questions.

For this toolkit, Claude Code is the place where you type:

```text
/assay help
```

and Claude walks you through the BI workflow.

## Install Or Open Claude Code

Claude Code installation can differ by company account and computer setup. Use your company instructions or Anthropic's current Claude Code instructions if Claude Code is not installed yet.

After it is installed, you should be able to open a terminal (the text command window) and type:

```bash
claude
```

You will usually see a Claude Code screen or prompt. It may ask you to sign in. Sign in with the account your company expects you to use.

If `claude` is not found, you may see:

```text
command not found: claude
```

That means Claude Code is not installed or not on your PATH (the command lookup list). Ask your IT or AI tools owner for the correct install steps.

## What A Project Folder Is

A project folder is one folder that holds one body of work. For this kit, make a fresh folder for each BI project or reporting area.

Examples:

```text
renewal-analysis/
finance-scorecard/
store-ops-dashboard/
```

Do not install the kit into your Downloads folder or your whole Documents folder. Use a small, empty folder.

## Create An Empty Folder

Open your terminal (the text command window). Type:

```bash
mkdir renewal-analysis
cd renewal-analysis
```

What you will see:

```text
```

No output usually means it worked. `mkdir` means make directory, which is another word for folder. `cd` means change directory, which moves the terminal into that folder.

Check where you are:

```bash
pwd
```

You will see something like:

```text
/Users/you/renewal-analysis
```

Check that the folder is empty:

```bash
ls
```

You should see no files, or only files you intentionally put there.

## Open Claude Code In That Folder

From the same folder, type:

```bash
claude
```

You are now using Claude Code inside this project folder. When you install bi-toolkit, it will place its files in this folder only.

## What To Tell Claude First

If you are new, say:

```text
I am new to Claude Code. I am setting up bi-toolkit for a BI project. Please go step by step.
```

Then continue to [Install](02-install.md).

