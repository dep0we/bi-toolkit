#!/usr/bin/env bash
# datacheck.test.sh - data-safety gate behavior for assay delivery.

set -uo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$KIT/.claude/workflows/datacheck.sh"
WRITER="$KIT/.claude/workflows/receipt.sh"

PASS=0
FAIL=0
pass() { printf '  PASS  %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  FAIL  %s\n' "$1"; FAIL=$((FAIL + 1)); }

run_gate() {
  local dir="$1" id="$2" errf
  errf="$(mktemp "${TMPDIR:-/tmp}/datacheck.err.XXXXXX")"
  OUT="$(cd "$dir" && bash "$SCRIPT" "$id" 2>"$errf")"
  RC=$?
  ERR="$(cat "$errf")"
  rm -f "$errf"
}

write_spec() {
  local dir="$1" classification="$2" sensitive="${3:-false}"
  mkdir -p "$dir/.assay/receipts"
  cat > "$dir/.assay/receipts/retention-q2-spec-receipt.json" <<JSON
{
  "kind": "spec",
  "track": "analysis",
  "question": "What changed retention in Q2?",
  "metricDefinitions": {"retention": "active divided by prior active"},
  "validAnswer": "A reconciled answer.",
  "decisionImpact": "strategy decision",
  "dataClassification": "$classification",
  "containsSensitiveData": $sensitive
}
JSON
}

write_config() {
  local dir="$1"
  cat > "$dir/assay.config.jsonc" <<'JSON'
{
  "dataSafety": {
    "defaultClassification": "unset",
    "approvedExportDestinations": ["company email", "approved BI tool"]
  }
}
JSON
}

echo "datacheck tests"
echo "==============="

T="$(mktemp -d "${TMPDIR:-/tmp}/datacheck.XXXXXX")"
write_spec "$T" "sensitive-PII" true
write_config "$T"
run_gate "$T" "retention-q2"
if [ "$RC" -eq 1 ] && printf '%s\n' "$OUT" | grep -qx 'assay-gate-failed:missing-data-safety'; then
  pass "blocks sensitive analysis with no handling receipt"
else
  fail "expected missing-data-safety block (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/datacheck.XXXXXX")"
write_spec "$T" "customer" true
write_config "$T"
mkdir -p "$T/.assay/receipts"
cat > "$T/.assay/receipts/retention-q2-data-safety-receipt.json" <<'JSON'
{
  "kind": "data-safety",
  "dataClassification": "customer",
  "dataLeavesCompany": false,
  "exportDestination": "none",
  "detailLevel": "aggregate",
  "operatorSignoff": "operator approved this handling"
}
JSON
run_gate "$T" "retention-q2"
if [ "$RC" -eq 1 ] && printf '%s\n' "$OUT" | grep -qx 'assay-gate-failed:incomplete-data-safety'; then
  pass "blocks sensitive analysis with no audience"
else
  fail "expected incomplete-data-safety block (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/datacheck.XXXXXX")"
write_spec "$T" "internal" false
write_config "$T"
run_gate "$T" "retention-q2"
if [ "$RC" -eq 0 ]; then
  pass "passes internal non-sensitive analysis"
else
  fail "expected internal non-sensitive pass (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/datacheck.XXXXXX")"
write_spec "$T" "unset" false
write_config "$T"
run_gate "$T" "retention-q2"
if [ "$RC" -eq 1 ] && printf '%s\n' "$OUT" | grep -qx 'assay-gate-failed:unknown-classification'; then
  pass "blocks unknown classification on non-trivial analysis"
else
  fail "expected unknown-classification block (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/datacheck.XXXXXX")"
write_config "$T"
(cd "$T" && bash "$WRITER" data-safety "retention-q2" <<'JSON') >/dev/null
{
  "dataClassification": "sensitive-PHI",
  "deliveryAudience": "internal benefits leadership",
  "dataLeavesCompany": true,
  "exportDestination": "company email",
  "detailLevel": "aggregate",
  "operatorSignoff": {
    "signedBy": "operator",
    "reason": "approved benefits summary"
  }
}
JSON
run_gate "$T" "retention-q2"
if [ "$RC" -eq 0 ] && [ -f "$T/.assay/receipts/retention-q2-data-safety-receipt.json" ]; then
  pass "receipt.sh writes and validates a data-safety receipt"
else
  fail "expected writer data-safety receipt pass (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

echo ""
echo "datacheck: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
