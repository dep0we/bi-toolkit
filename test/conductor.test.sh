#!/usr/bin/env bash
# conductor.test.sh - active analysis pointer, prompt hook, and onboarding help.

set -uo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACTIVE="$KIT/.claude/workflows/assay-active.sh"
HELP="$KIT/.claude/workflows/assay-help.sh"
HOOK="$KIT/.claude/hooks/governing-reminder.sh"

PASS=0
FAIL=0
pass() { printf '  PASS  %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  FAIL  %s\n' "$1"; FAIL=$((FAIL + 1)); }

run_capture() {
  local dir="$1"; shift
  local errf
  errf="$(mktemp "${TMPDIR:-/tmp}/assay-conductor.err.XXXXXX")"
  OUT="$(cd "$dir" && "$@" 2>"$errf")"
  RC=$?
  ERR="$(cat "$errf")"
  rm -f "$errf"
}

install_minimal_runtime() {
  local dir="$1"
  mkdir -p "$dir/.claude/hooks" "$dir/.claude/workflows"
  cp "$HOOK" "$dir/.claude/hooks/governing-reminder.sh"
  cp "$KIT/.claude/workflows/assay-state.sh" "$dir/.claude/workflows/assay-state.sh"
  cp "$KIT/.claude/workflows/assay-active.sh" "$dir/.claude/workflows/assay-active.sh"
  cp "$KIT/.claude/workflows/assay-help.sh" "$dir/.claude/workflows/assay-help.sh"
}

echo "conductor tests"
echo "==============="

T="$(mktemp -d "${TMPDIR:-/tmp}/assay-conductor.XXXXXX")"
install_minimal_runtime "$T"
run_capture "$T" bash .claude/hooks/governing-reminder.sh
if [ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | grep -q 'No active analysis - run /assay status or /assay help'; then
  pass "hook prints no-active guidance and exits zero"
else
  fail "expected no-active hook guidance (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/assay-conductor.XXXXXX")"
install_minimal_runtime "$T"
run_capture "$T" bash .claude/workflows/assay-active.sh set retention-q2 analysis
run_capture "$T" bash .claude/hooks/governing-reminder.sh
if [ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | grep -q 'Active analysis: retention-q2 (Stage 2, analysis)' && printf '%s\n' "$OUT" | grep -q 'Next required step: /assay spec retention-q2' && printf '%s\n' "$OUT" | grep -q 'Run /assay spec'; then
  pass "hook prints active analysis, stage, next step, and command"
else
  fail "expected active hook state (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/assay-conductor.XXXXXX")"
install_minimal_runtime "$T"
printf '{not json\n' > "$T/.assay.active-bad"
run_capture "$T" env ASSAY_ACTIVE_FILE=".assay.active-bad" bash .claude/hooks/governing-reminder.sh
if [ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | grep -q 'No active analysis - run /assay status or /assay help'; then
  pass "hook never exits non-zero on malformed active pointer"
else
  fail "expected malformed active pointer to be harmless (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/assay-conductor.XXXXXX")"
run_capture "$T" bash "$ACTIVE" set revenue-drop data-product
run_capture "$T" bash "$ACTIVE" show
if [ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | grep -q '"analysisId": "revenue-drop"' && printf '%s\n' "$OUT" | grep -q '"track": "data-product"'; then
  pass "active pointer records analysis id and track"
else
  fail "expected active pointer JSON (rc=$RC stdout=$OUT stderr=$ERR)"
fi
run_capture "$T" bash "$ACTIVE" clear revenue-drop
if [ "$RC" -eq 0 ] && [ ! -e "$T/.assay/active.json" ]; then
  pass "active pointer clears by analysis id"
else
  fail "expected active pointer to clear (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/assay-conductor.XXXXXX")"
install_minimal_runtime "$T"
run_capture "$T" bash .claude/workflows/assay-help.sh
if [ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | grep -q 'next required step: /assay intake'; then
  pass "help points new operators to intake"
else
  fail "expected help to point to intake (rc=$RC stdout=$OUT stderr=$ERR)"
fi
run_capture "$T" bash .claude/workflows/assay-active.sh set retention-q2 analysis
run_capture "$T" bash .claude/workflows/assay-help.sh
if [ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | grep -q 'next required step: /assay spec retention-q2'; then
  pass "help includes state-derived next step"
else
  fail "expected help to include state next step (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

echo ""
echo "conductor: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
