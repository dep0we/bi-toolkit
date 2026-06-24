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

write_config() {
  local dir="$1"
  cat > "$dir/assay.config.jsonc" <<'JSON'
{
  "sourceOfTruth": { "retention": "Finance system of record" },
  "scoreThresholds": { "defaultMinDimension": 3 }
}
JSON
}

write_config_methodology_override() {
  local dir="$1"
  cat > "$dir/assay.config.jsonc" <<'JSON'
{
  "sourceOfTruth": { "retention": "Finance system of record" },
  "scoreThresholds": {
    "defaultMinDimension": 4,
    "methodologySoundness": 2
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
write_config "$T"
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
write_config "$T"
run_gate "$T" "retention-q2"
if [ "$RC" -eq 0 ]; then
  pass "passes reconciled data product with passing score (source-of-truth configured)"
else
  fail "expected passing validation (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/validationcheck.XXXXXX")"
write_spec "$T" "analysis" "strategy decision"
write_validation "$T" true
write_review "$T" 2
write_config_methodology_override "$T"
run_gate "$T" "retention-q2"
if [ "$RC" -eq 0 ]; then
  pass "uses per-dimension threshold override with default fallback"
else
  fail "expected methodologySoundness override to pass (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

# High-stakes/data-product work blocks when sourceOfTruth is unconfigured,
# even with otherwise-passing scores (intake required in practice).
T="$(mktemp -d "${TMPDIR:-/tmp}/validationcheck.XXXXXX")"
write_spec "$T" "data-product" "strategy decision"
write_validation "$T" true
write_review "$T" 4
run_gate "$T" "retention-q2"
if [ "$RC" -eq 1 ] && printf '%s\n' "$OUT" | grep -qx 'assay-gate-failed:source-of-truth-unconfigured'; then
  pass "blocks high-stakes delivery when sourceOfTruth is unconfigured"
else
  fail "expected source-of-truth-unconfigured block (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

# Routine one-off work still needs Stage 8 review; self-review does not count.
T="$(mktemp -d "${TMPDIR:-/tmp}/validationcheck.XXXXXX")"
write_spec "$T" "analysis" "curiosity exploration"
write_validation "$T" true
run_gate "$T" "retention-q2"
if [ "$RC" -eq 1 ] && printf '%s\n' "$OUT" | grep -qx 'assay-gate-failed:missing-review'; then
  pass "blocks routine work when Stage 8 review is missing"
else
  fail "expected missing-review block (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

# Routine one-off work is NOT blocked by an empty sourceOfTruth after review,
# but warns loudly.
T="$(mktemp -d "${TMPDIR:-/tmp}/validationcheck.XXXXXX")"
write_spec "$T" "analysis" "curiosity exploration"
write_validation "$T" true
write_review "$T" 4
run_gate "$T" "retention-q2"
if [ "$RC" -eq 0 ] && printf '%s\n' "$ERR" | grep -qi 'sourceOfTruth is not configured'; then
  pass "passes reviewed routine work but warns on unconfigured sourceOfTruth"
else
  fail "expected pass-with-warning (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

echo ""
echo "validationcheck: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
