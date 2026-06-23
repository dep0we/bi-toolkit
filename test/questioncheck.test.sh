#!/usr/bin/env bash
# questioncheck.test.sh - front-gate behavior for assay Stage 6.

set -uo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$KIT/.claude/workflows/questioncheck.sh"

PASS=0
FAIL=0
pass() { printf '  PASS  %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  FAIL  %s\n' "$1"; FAIL=$((FAIL + 1)); }

run_gate() {
  local dir="$1" id="$2" errf
  errf="$(mktemp "${TMPDIR:-/tmp}/questioncheck.err.XXXXXX")"
  OUT="$(cd "$dir" && bash "$SCRIPT" "$id" 2>"$errf")"
  RC=$?
  ERR="$(cat "$errf")"
  rm -f "$errf"
}

echo "questioncheck tests"
echo "==================="

T="$(mktemp -d "${TMPDIR:-/tmp}/questioncheck.XXXXXX")"
run_gate "$T" "retention-q2"
if [ "$RC" -eq 1 ] && printf '%s\n' "$OUT" | grep -qx 'assay-gate-failed:missing-spec'; then
  pass "blocks Stage 6 with no spec receipt"
else
  fail "expected missing-spec block (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/questioncheck.XXXXXX")"
mkdir -p "$T/.assay/receipts"
cat > "$T/.assay/receipts/retention-q2-spec-receipt.json" <<'JSON'
{
  "kind": "spec",
  "question": "What changed retention in Q2?",
  "metricDefinitions": {
    "retention": "active customers this quarter divided by active customers last quarter"
  },
  "validAnswer": "A reconciled answer with caveats."
}
JSON
run_gate "$T" "retention-q2"
if [ "$RC" -eq 0 ]; then
  pass "passes with a complete spec receipt"
else
  fail "expected spec receipt to pass (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

echo ""
echo "questioncheck: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
