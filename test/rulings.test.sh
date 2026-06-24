#!/usr/bin/env bash
# rulings.test.sh - durable methodology rulings gate tests.

set -uo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PREFLIGHT="$KIT/.claude/workflows/assay-preflight.sh"
RULINGS="$KIT/.claude/workflows/rulings.sh"

PASS=0
FAIL=0
pass() { printf '  PASS  %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  FAIL  %s\n' "$1"; FAIL=$((FAIL + 1)); }

write_spec() {
  local dir="$1"
  mkdir -p "$dir/.assay/receipts"
  cat > "$dir/.assay/receipts/retention-q2-spec-receipt.json" <<'JSON'
{
  "kind": "spec",
  "question": "What changed retention in Q2?",
  "metricDefinitions": {
    "retention": "active customers divided by prior active customers"
  },
  "validAnswer": "A reconciled answer.",
  "decisionImpact": "strategy decision",
  "track": "analysis"
}
JSON
}

run_execute() {
  local dir="$1" errf
  errf="$(mktemp "${TMPDIR:-/tmp}/rulings-preflight.err.XXXXXX")"
  OUT="$(cd "$dir" && bash "$PREFLIGHT" execute retention-q2 2>"$errf")"
  RC=$?
  ERR="$(cat "$errf")"
  rm -f "$errf"
}

write_complete_rulings() {
  local dir="$1" run_id="$2"
  (cd "$dir" && bash "$RULINGS" write retention-q2 "$run_id" <<'JSON') >/dev/null
{
  "forkIds": ["window-choice", "null-handling"],
  "rulings": {
    "window-choice": {
      "ruling": "Use fiscal quarter.",
      "rationale": "Matches finance reporting."
    },
    "null-handling": "Exclude unknown customer ids."
  }
}
JSON
}

echo "rulings gate tests"
echo "=================="

T="$(mktemp -d "${TMPDIR:-/tmp}/rulings.XXXXXX")"
write_spec "$T"
write_complete_rulings "$T" "run-1"
run_execute "$T"
if [ "$RC" -eq 0 ] && [ -f "$T/.assay/rulings/retention-q2-rulings.json" ]; then
  pass "complete rulings file lets execute checkpoint pass"
else
  fail "expected execute pass with complete rulings (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/rulings.XXXXXX")"
write_spec "$T"
run_execute "$T"
if [ "$RC" -eq 1 ] && printf '%s\n' "$OUT" | grep -qx 'assay-gate-failed:missing-rulings'; then
  pass "missing rulings file blocks execute"
else
  fail "expected missing-rulings block (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/rulings.XXXXXX")"
write_spec "$T"
mkdir -p "$T/.assay/rulings"
cat > "$T/.assay/rulings/retention-q2-latest-discovery.json" <<'JSON'
{
  "schemaVersion": 1,
  "analysisId": "retention-q2",
  "discoveryRunId": "run-1",
  "forkIds": ["window-choice", "null-handling"]
}
JSON
cat > "$T/.assay/rulings/retention-q2-rulings.json" <<'JSON'
{
  "schemaVersion": 1,
  "analysisId": "retention-q2",
  "discoveryRunId": "run-1",
  "forkIds": ["window-choice", "null-handling"],
  "rulings": {
    "window-choice": "Use fiscal quarter."
  }
}
JSON
run_execute "$T"
if [ "$RC" -eq 1 ] && printf '%s\n' "$OUT" | grep -qx 'assay-gate-failed:incomplete-rulings'; then
  pass "surfaced fork without ruling blocks execute"
else
  fail "expected incomplete-rulings block (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/rulings.XXXXXX")"
write_spec "$T"
write_complete_rulings "$T" "run-1"
(cd "$T" && bash "$RULINGS" discovery retention-q2 "run-2" <<'JSON') >/dev/null
["window-choice", "null-handling"]
JSON
run_execute "$T"
if [ "$RC" -eq 1 ] && printf '%s\n' "$OUT" | grep -qx 'assay-gate-failed:stale-rulings'; then
  pass "older discoveryRunId blocks as stale"
else
  fail "expected stale-rulings block (rc=$RC stdout=$OUT stderr=$ERR)"
fi
(cd "$T" && bash "$RULINGS" reaffirm retention-q2 <<'JSON') >/dev/null
{
  "reason": "operator confirmed the same choices still apply"
}
JSON
run_execute "$T"
if [ "$RC" -eq 0 ]; then
  pass "operator-approved reaffirm refreshes stale rulings"
else
  fail "expected reaffirmed rulings to pass (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

echo ""
echo "rulings gate: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
