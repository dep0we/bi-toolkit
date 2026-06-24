#!/usr/bin/env bash
# assay-preflight.test.sh - dispatcher routes checkpoints to hard gates.

set -uo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$KIT/.claude/workflows/assay-preflight.sh"

PASS=0
FAIL=0
pass() { printf '  PASS  %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  FAIL  %s\n' "$1"; FAIL=$((FAIL + 1)); }

run_preflight() {
  local dir="$1"; shift
  local errf
  errf="$(mktemp "${TMPDIR:-/tmp}/assay-preflight.err.XXXXXX")"
  OUT="$(cd "$dir" && bash "$SCRIPT" "$@" 2>"$errf")"
  RC=$?
  ERR="$(cat "$errf")"
  rm -f "$errf"
}

write_config_and_doc() {
  local dir="$1"
  printf 'rule: protect this\n' > "$dir/GOV.md"
  cat > "$dir/assay.config.jsonc" <<'JSON'
{
  "governingDocs": ["GOV.md"],
  "sourceOfTruth": { "retention": "Finance system of record" },
  "dataSafety": { "defaultClassification": "internal" },
  "scoreThresholds": { "defaultMinDimension": 3 }
}
JSON
}

write_receipts() {
  local dir="$1"
  mkdir -p "$dir/.assay/receipts"
  cat > "$dir/.assay/receipts/retention-q2-spec-receipt.json" <<'JSON'
{
  "kind": "spec",
  "track": "analysis",
  "question": "What changed retention in Q2?",
  "metricDefinitions": {"retention": "active divided by prior active"},
  "validAnswer": "A reconciled answer.",
  "decisionImpact": "strategy decision"
}
JSON
  cat > "$dir/.assay/receipts/retention-q2-validation-receipt.json" <<'JSON'
{
  "kind": "validation",
  "reconciled": true,
  "reconciliation": {
    "retention": "Compared to finance source-of-truth."
  }
}
JSON
  cat > "$dir/.assay/receipts/retention-q2-adversarial-review-receipt.json" <<'JSON'
{
  "kind": "adversarial-review",
  "scores": {
    "confidence": 4,
    "dataCompleteness": 4,
    "methodologySoundness": 4,
    "reproducibility": 4
  }
}
JSON
}

echo "assay-preflight tests"
echo "====================="

T="$(mktemp -d "${TMPDIR:-/tmp}/assay-preflight.XXXXXX")"
write_config_and_doc "$T"
run_preflight "$T" discovery retention-q2
if [ "$RC" -eq 0 ] && [ -f "$T/.assay/receipts/retention-q2-govbaseline.json" ]; then
  pass "discovery snapshots governing docs"
else
  fail "expected discovery snapshot (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/assay-preflight.XXXXXX")"
run_preflight "$T" execute retention-q2
if [ "$RC" -eq 1 ] && printf '%s\n' "$OUT" | grep -qx 'assay-gate-failed:missing-spec'; then
  pass "execute routes to questioncheck and propagates failure"
else
  fail "expected execute missing-spec block (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/assay-preflight.XXXXXX")"
write_config_and_doc "$T"
run_preflight "$T" discovery retention-q2
run_preflight "$T" deliver retention-q2
if [ "$RC" -eq 1 ] && printf '%s\n' "$OUT" | grep -qx 'assay-gate-failed:missing-validation'; then
  pass "deliver routes to validationcheck first and propagates failure"
else
  fail "expected deliver missing-validation block (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/assay-preflight.XXXXXX")"
write_config_and_doc "$T"
run_preflight "$T" discovery retention-q2
write_receipts "$T"
printf 'rule: changed during analysis\n' > "$T/GOV.md"
run_preflight "$T" deliver retention-q2
if [ "$RC" -eq 1 ] && printf '%s\n' "$OUT" | grep -qx 'assay-gate-failed:governing-doc-edit'; then
  pass "deliver routes to govcheck after validation passes"
else
  fail "expected deliver governing-doc-edit block (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

echo ""
echo "assay-preflight: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
