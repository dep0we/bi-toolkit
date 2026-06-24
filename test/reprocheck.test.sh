#!/usr/bin/env bash
# reprocheck.test.sh - reproducibility gate behavior for assay delivery.

set -uo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$KIT/.claude/workflows/reprocheck.sh"

PASS=0
FAIL=0
pass() { printf '  PASS  %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  FAIL  %s\n' "$1"; FAIL=$((FAIL + 1)); }

run_gate() {
  local dir="$1" id="$2" errf
  errf="$(mktemp "${TMPDIR:-/tmp}/reprocheck.err.XXXXXX")"
  OUT="$(cd "$dir" && bash "$SCRIPT" "$id" 2>"$errf")"
  RC=$?
  ERR="$(cat "$errf")"
  rm -f "$errf"
}

write_spec() {
  local dir="$1" track="${2:-analysis}"
  mkdir -p "$dir/.assay/receipts"
  cat > "$dir/.assay/receipts/retention-q2-spec-receipt.json" <<JSON
{
  "kind": "spec",
  "track": "$track",
  "question": "What changed retention in Q2?",
  "metricDefinitions": {"retention": "active divided by prior active"},
  "validAnswer": "A reconciled answer.",
  "decisionImpact": "weekly operations review"
}
JSON
}

echo "reprocheck tests"
echo "================"

T="$(mktemp -d "${TMPDIR:-/tmp}/reprocheck.XXXXXX")"
write_spec "$T" "analysis"
cat > "$T/assay.config.jsonc" <<'JSON'
{
  "sourceOfTruth": {"retention": "Finance source"}
}
JSON
run_gate "$T" retention-q2
if [ "$RC" -eq 0 ] && printf '%s\n' "$ERR" | grep -q 'reproducibility unverified'; then
  pass "passes when reproCommand is unset and prints note"
else
  fail "expected unset reproCommand pass-with-note (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/reprocheck.XXXXXX")"
write_spec "$T" "data-product"
cat > "$T/assay.config.jsonc" <<'JSON'
{
  "sourceOfTruth": {"retention": "Finance source"}
}
JSON
run_gate "$T" retention-q2
if [ "$RC" -eq 0 ] && printf '%s\n' "$ERR" | grep -q 'WARNING - this is a data product'; then
  pass "warns strongly when a data product has no reproCommand"
else
  fail "expected data-product warning (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/reprocheck.XXXXXX")"
write_spec "$T" "analysis"
cat > "$T/assay.config.jsonc" <<'JSON'
{
  "reproCommand": "bash -c 'exit 7'"
}
JSON
run_gate "$T" retention-q2
if [ "$RC" -eq 1 ] && printf '%s\n' "$OUT" | grep -qx 'assay-gate-failed:repro-command-failed'; then
  pass "blocks on a failing reproCommand"
else
  fail "expected repro-command-failed block (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/reprocheck.XXXXXX")"
write_spec "$T" "analysis"
cat > "$T/assay.config.jsonc" <<'JSON'
{
  "reproCommand": "test \"$ASSAY_ANALYSIS_ID\" = retention-q2"
}
JSON
run_gate "$T" retention-q2
if [ "$RC" -eq 0 ] && printf '%s\n' "$ERR" | grep -qx 'assay-gate-ok:reprocheck'; then
  pass "passes on a succeeding reproCommand"
else
  fail "expected reproCommand success (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

echo ""
echo "reprocheck: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
