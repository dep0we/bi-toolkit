#!/usr/bin/env bash
# intake.test.sh - the intake interview script ships, is wired into the router,
# and carries the baseline/2-minute/skip framing.
set -uo pipefail
KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUIDE="$KIT/.claude/skills/assay/assay-intake.md"
SKILL="$KIT/.claude/skills/assay/SKILL.md"
pass=0; fail=0
check() { if eval "$2"; then echo "  PASS  $1"; pass=$((pass + 1)); else echo "  FAIL  $1"; fail=$((fail + 1)); fi; }

echo "intake interview"
echo "================"
check "intake script exists in the kit" "[ -f \"$GUIDE\" ]"
check "router points to the intake script" "grep -q 'assay-intake.md' \"$SKILL\""
check "opening states 2 minutes, baseline, and skip" "grep -qi '2 minutes' \"$GUIDE\" && grep -qi 'baseline' \"$GUIDE\" && grep -qi 'skip' \"$GUIDE\""
check "defers heavy items (no exact-rule demand up front)" "grep -qi 'Defer the heavy' \"$GUIDE\""
T="$(mktemp -d)"
bash "$KIT/install.sh" "$T" >/dev/null 2>&1
check "install ships the intake script" "[ -f \"$T/.claude/skills/assay/assay-intake.md\" ]"
rm -rf "$T"

echo ""
echo "intake interview: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
