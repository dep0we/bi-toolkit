#!/usr/bin/env bash
# assay-state.test.sh - resume/status helper behavior.

set -uo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$KIT/.claude/workflows/assay-state.sh"

PASS=0
FAIL=0
pass() { printf '  PASS  %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  FAIL  %s\n' "$1"; FAIL=$((FAIL + 1)); }

run_state() {
  local dir="$1"; shift
  local errf
  errf="$(mktemp "${TMPDIR:-/tmp}/assay-state.err.XXXXXX")"
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
  "sourceOfTruth": { "retention": "Finance source" },
  "dataSafety": { "defaultClassification": "internal" },
  "scoreThresholds": { "defaultMinDimension": 3 }
}
JSON
}

write_spec() {
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
}

write_discovery() {
  local dir="$1"
  mkdir -p "$dir/.assay/rulings"
  cat > "$dir/.assay/rulings/retention-q2-latest-discovery.json" <<'JSON'
{
  "schemaVersion": 1,
  "analysisId": "retention-q2",
  "discoveryRunId": "disc-1",
  "forkIds": ["window"],
  "recordedAt": "2026-06-24T00:00:00Z"
}
JSON
}

write_rulings() {
  local dir="$1"
  mkdir -p "$dir/.assay/rulings"
  cat > "$dir/.assay/rulings/retention-q2-rulings.json" <<'JSON'
{
  "schemaVersion": 1,
  "analysisId": "retention-q2",
  "discoveryRunId": "disc-1",
  "forkIds": ["window"],
  "rulings": {
    "window": "use calendar quarter"
  }
}
JSON
}

write_validation_and_low_review() {
  local dir="$1"
  mkdir -p "$dir/.assay/receipts"
  cat > "$dir/.assay/receipts/retention-q2-validation-receipt.json" <<'JSON'
{
  "kind": "validation",
  "reconciled": true,
  "reconciliation": {
    "retention": "Compared to finance source."
  }
}
JSON
  cat > "$dir/.assay/receipts/retention-q2-adversarial-review-receipt.json" <<'JSON'
{
  "kind": "adversarial-review",
  "scores": {
    "confidence": 4,
    "dataCompleteness": 4,
    "methodologySoundness": 2,
    "reproducibility": 4
  }
}
JSON
}

snapshot_gov() {
  local dir="$1"
  (cd "$dir" && bash "$KIT/.claude/workflows/govcheck.sh" snapshot retention-q2 >/dev/null 2>&1)
}

echo "assay-state tests"
echo "================="

T="$(mktemp -d "${TMPDIR:-/tmp}/assay-state.XXXXXX")"
write_config_and_doc "$T"
write_spec "$T"
snapshot_gov "$T"
write_discovery "$T"
run_state "$T" status retention-q2
if [ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | grep -q 'next required step: record methodology rulings for retention-q2'; then
  pass "computes next step for partial analysis with missing rulings"
else
  fail "expected missing-rulings next step (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/assay-state.XXXXXX")"
write_config_and_doc "$T"
write_spec "$T"
snapshot_gov "$T"
write_discovery "$T"
write_rulings "$T"
write_validation_and_low_review "$T"
run_state "$T" finish retention-q2
if [ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | grep -q 'assay-finish-blocked:sub-threshold-score' && printf '%s\n' "$OUT" | grep -q 'next required step: /assay validate retention-q2' && ! printf '%s\n' "$OUT" | grep -q 'next required step: /assay deliver retention-q2'; then
  pass "finish does not bypass a failing validation gate"
else
  fail "expected finish to stop at low score (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/assay-state.XXXXXX")"
write_config_and_doc "$T"
write_spec "$T"
snapshot_gov "$T"
run_state "$T" status
if [ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | grep -q '^retention-q2[	]next:'; then
  pass "status without id lists in-flight analyses"
else
  fail "expected in-flight analysis listing (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

echo ""
echo "assay-state: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
