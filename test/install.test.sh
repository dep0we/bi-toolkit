#!/usr/bin/env bash
# install.test.sh — install.sh must ship ALL skills (the /assay router + the 31
# domain skills) and the engine, not just the router. Regression guard for the
# bug where only assay/SKILL.md was copied to a fresh project.
set -uo pipefail
KIT="$(cd "$(dirname "$0")/.." && pwd)"
pass=0; fail=0
check() { if eval "$2"; then echo "  PASS  $1"; pass=$((pass + 1)); else echo "  FAIL  $1"; fail=$((fail + 1)); fi; }

echo "install tests"
echo "============="
T="$(mktemp -d)"
bash "$KIT/install.sh" "$T" >/dev/null 2>&1
n=$(find "$T/.claude/skills" -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')
check "installs the /assay router + domain skills (>=31)" "[ \"$n\" -ge 31 ]"
check "installs the engine workflows" "[ -f \"$T/.claude/workflows/assay-execute.js\" ] && [ -f \"$T/.claude/workflows/assay-validate.js\" ]"
check "installs the gates + receipt writer" "[ -f \"$T/.claude/workflows/questioncheck.sh\" ] && [ -f \"$T/.claude/workflows/receipt.sh\" ]"
check "does not ship the dev-kit arc loop" "[ ! -e \"$T/.claude/skills/arc\" ]"
rm -rf "$T"
echo ""
echo "install: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
