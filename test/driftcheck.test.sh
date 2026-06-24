#!/usr/bin/env bash
# driftcheck.test.sh - recurring data-product monitoring behavior.

set -uo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$KIT/.claude/workflows/driftcheck.sh"

PASS=0
FAIL=0
pass() { printf '  PASS  %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  FAIL  %s\n' "$1"; FAIL=$((FAIL + 1)); }

write_base() {
  local dir="$1"
  mkdir -p "$dir/.assay/receipts" "$dir/reports/retention-q2"
  cat > "$dir/assay.config.jsonc" <<'JSON'
{
  "receiptsDir": ".assay/receipts",
  "deliverablesDir": "reports",
  "monitoring": {
    "defaultTolerance": 0.05,
    "metrics": {
      "Invoice count": { "tolerance": 10, "mode": "absolute" }
    }
  }
}
JSON
  cat > "$dir/.assay/receipts/retention-q2-spec-receipt.json" <<'JSON'
{
  "kind": "spec",
  "track": "data-product",
  "question": "What changed?",
  "metricDefinitions": {"Net retention": "retained revenue divided by prior revenue"},
  "validAnswer": "A refreshed dashboard.",
  "decisionImpact": "strategy"
}
JSON
  cat > "$dir/reports/retention-q2/prev.json" <<'JSON'
{
  "schemaVersion": "assay-metrics-snapshot/v1",
  "analysisId": "retention-q2",
  "timestamp": "20260624T000000Z",
  "rowCount": 50,
  "refreshOk": true,
  "metrics": {
    "Net retention": 100,
    "Invoice count": 200
  }
}
JSON
  cat > "$dir/reports/retention-q2/latest.json" <<'JSON'
{
  "schemaVersion": "assay-deliverable-latest/v1",
  "analysisId": "retention-q2",
  "timestamp": "20260624T000000Z",
  "snapshotPath": "reports/retention-q2/prev.json",
  "artifactPath": "reports/retention-q2/report-1.html"
}
JSON
}

run_drift() {
  local dir="$1" snapshot="$2" errf
  errf="$(mktemp "${TMPDIR:-/tmp}/driftcheck.err.XXXXXX")"
  OUT="$(cd "$dir" && bash "$SCRIPT" retention-q2 "$snapshot" 2>"$errf")"
  RC=$?
  ERR="$(cat "$errf")"
  rm -f "$errf"
}

echo "driftcheck tests"
echo "================"

T="$(mktemp -d "${TMPDIR:-/tmp}/driftcheck.XXXXXX")"
write_base "$T"
cat > "$T/current.json" <<'JSON'
{
  "schemaVersion": "assay-metrics-snapshot/v1",
  "analysisId": "retention-q2",
  "timestamp": "20260625T000000Z",
  "rowCount": 50,
  "refreshOk": true,
  "metrics": {
    "Net retention": 110,
    "Invoice count": 205
  }
}
JSON
run_drift "$T" current.json
if [ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | grep -qx 'assay-drift-status:warning' && grep -q 'Net retention' "$T/reports/retention-q2/drift-20260625T000000Z.txt"; then
  pass "flags out-of-tolerance metric movement as warning"
else
  fail "expected warning drift flag (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/driftcheck.XXXXXX")"
write_base "$T"
cat > "$T/current.json" <<'JSON'
{
  "schemaVersion": "assay-metrics-snapshot/v1",
  "analysisId": "retention-q2",
  "timestamp": "20260625T000000Z",
  "rowCount": 50,
  "refreshOk": true,
  "metrics": {
    "Net retention": 103,
    "Invoice count": 207
  }
}
JSON
run_drift "$T" current.json
if [ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | grep -qx 'assay-drift-status:ok'; then
  pass "passes metric movement within tolerance"
else
  fail "expected ok drift status (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/driftcheck.XXXXXX")"
write_base "$T"
cat > "$T/current.json" <<'JSON'
{
  "schemaVersion": "assay-metrics-snapshot/v1",
  "analysisId": "retention-q2",
  "timestamp": "20260625T000000Z",
  "rowCount": 0,
  "refreshOk": true,
  "metrics": {
    "Net retention": 100
  }
}
JSON
run_drift "$T" current.json
if [ "$RC" -eq 1 ] && printf '%s\n' "$OUT" | grep -qx 'assay-gate-failed:broken-refresh' && grep -q 'no rows' "$T/reports/retention-q2/drift-20260625T000000Z.txt"; then
  pass "blocks data-product delivery on empty refresh"
else
  fail "expected broken-refresh block (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

echo ""
echo "driftcheck: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
