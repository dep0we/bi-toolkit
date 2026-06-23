#!/usr/bin/env bash
# validationcheck.test.sh - back-gate behavior for assay Stage 9.

set -uo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$KIT/.claude/workflows/validationcheck.sh"

PASS=0
FAIL=0
pass() { printf '  PASS  %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  FAIL  %s\n' "$1"; FAIL=$((FAIL + 1)); }

run_gate() {
  local dir="$1" id="$2" errf
  errf="$(mktemp "${TMPDIR:-/tmp}/validationcheck.err.XXXXXX")"
  OUT="$(cd "$dir" && bash "$SCRIPT" "$id" 2>"$errf")"
  RC=$?
  ERR="$(cat "$errf")"
  rm -f "$errf"
}

write_spec() {
  local dir="$1" track="${2:-analysis}" impact="${3:-strategy decision}"
  mkdir -p "$dir/.assay/receipts"
  cat > "$dir/.assay/receipts/retention-q2-spec-receipt.json" <<JSON
{
  "kind": "spec",
  "track": "$track",
  "question": "What changed retention in Q2?",
  "metricDefinitions": {"retention": "active divided by prior active"},
  "validAnswer": "A reconciled answer.",
  "decisionImpact": "$impact"
}
JSON
}

write_validation() {
  local dir="$1" reconciled="$2"
  mkdir -p "$dir/.assay/receipts"
  cat > "$dir/.assay/receipts/retention-q2-validation-receipt.json" <<JSON
{
  "kind": "validation",
  "reconciled": $reconciled,
  "reconciliation": {
    "retention": "Compared to finance source-of-truth."
  }
}
JSON
}

write_review() {
  local dir="$1" methodology="$2"
  mkdir -p "$dir/.assay/receipts"
  cat > "$dir/.assay/receipts/retention-q2-adversarial-review-receipt.json" <<JSON
{
  "kind": "adversarial-review",
  "scores": {
    "confidence": 4,
    "dataCompleteness": 4,
    "methodologySoundness": $methodology,
    "reproducibility": 4
  }
}
JSON
}

echo "validationcheck tests"
echo "====================="

T="$(mktemp -d "${TMPDIR:-/tmp}/validationcheck.XXXXXX")"
write_spec "$T"
write_validation "$T" false
run_gate "$T" "retention-q2"
if [ "$RC" -eq 1 ] && printf '%s\n' "$OUT" | grep -qx 'assay-gate-failed:unreconciled'; then
  pass "blocks unreconciled result"
else
  fail "expected unreconciled block (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/validationcheck.XXXXXX")"
write_spec "$T" "analysis" "strategy decision"
write_validation "$T" true
write_review "$T" 2
run_gate "$T" "retention-q2"
if [ "$RC" -eq 1 ] && printf '%s\n' "$OUT" | grep -qx 'assay-gate-failed:sub-threshold-score'; then
  pass "blocks sub-threshold Stage 8 score"
else
  fail "expected sub-threshold block (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/validationcheck.XXXXXX")"
write_spec "$T" "data-product" "weekly operations review"
write_validation "$T" true
write_review "$T" 3
run_gate "$T" "retention-q2"
if [ "$RC" -eq 0 ]; then
  pass "passes reconciled data product with passing score"
else
  fail "expected passing validation (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

echo ""
echo "validationcheck: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
