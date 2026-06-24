#!/usr/bin/env bash
# distribution-manifest.test.sh - local handoff manifest behavior.

set -uo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$KIT/.claude/workflows/distribution-manifest.sh"

PASS=0
FAIL=0
pass() { printf '  PASS  %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  FAIL  %s\n' "$1"; FAIL=$((FAIL + 1)); }

write_config() {
  local dir="$1" classification="$2" sensitive="${3:-false}"
  mkdir -p "$dir/.assay/receipts" "$dir/reports/retention-q2"
  cat > "$dir/assay.config.jsonc" <<'JSON'
{
  "receiptsDir": ".assay/receipts",
  "deliverablesDir": "reports",
  "distribution": {
    "audience": "finance leaders",
    "channelDescription": "email to finance-leaders",
    "cadence": "monthly after finance close"
  },
  "dataSafety": {
    "defaultClassification": "internal"
  }
}
JSON
  cat > "$dir/.assay/receipts/retention-q2-spec-receipt.json" <<JSON
{
  "kind": "spec",
  "track": "data-product",
  "question": "What changed?",
  "metricDefinitions": {"Net retention": "retained revenue divided by prior revenue"},
  "validAnswer": "A refreshed dashboard.",
  "decisionImpact": "strategy",
  "dataClassification": "$classification",
  "containsSensitiveData": $sensitive
}
JSON
  cat > "$dir/snapshot.json" <<'JSON'
{
  "schemaVersion": "assay-metrics-snapshot/v1",
  "analysisId": "retention-q2",
  "timestamp": "20260625T000000Z",
  "audience": "finance leaders",
  "metrics": {
    "Net retention": 108
  }
}
JSON
}

run_manifest() {
  local dir="$1" errf
  errf="$(mktemp "${TMPDIR:-/tmp}/distribution.err.XXXXXX")"
  OUT="$(cd "$dir" && bash "$SCRIPT" retention-q2 reports/retention-q2/dashboard.html 20260625T000000Z snapshot.json 2>"$errf")"
  RC=$?
  ERR="$(cat "$errf")"
  rm -f "$errf"
}

echo "distribution-manifest tests"
echo "==========================="

T="$(mktemp -d "${TMPDIR:-/tmp}/distribution.XXXXXX")"
write_config "$T" "internal" false
run_manifest "$T"
MANIFEST="$(printf '%s\n' "$OUT" | sed -n 's/^assay-distribution-manifest://p')"
if [ "$RC" -eq 0 ] && [ -f "$T/$MANIFEST" ] && python3 - "$T/$MANIFEST" <<'PY'
import json
import sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
ok = (
    data.get("audience") == "finance leaders"
    and data.get("channelDescription") == "email to finance-leaders"
    and data.get("cadence") == "monthly after finance close"
    and data.get("dataClassification") == "internal"
    and "issue #8" in data.get("sendNote", "")
)
raise SystemExit(0 if ok else 1)
PY
then
  pass "emits manifest with audience, cadence, channel, and classification"
else
  fail "expected distribution manifest (rc=$RC stdout=$OUT stderr=$ERR manifest=$MANIFEST)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/distribution.XXXXXX")"
write_config "$T" "sensitive-PII" true
run_manifest "$T"
if [ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | grep -qx 'assay-distribution-withheld:sensitive-needs-signoff' && ! ls "$T/reports/retention-q2"/distribution-*.json >/dev/null 2>&1; then
  pass "withholds manifest when sensitive data lacks sign-off"
else
  fail "expected sensitive manifest withholding (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/distribution.XXXXXX")"
write_config "$T" "sensitive-PII" true
cat > "$T/.assay/receipts/retention-q2-data-safety-receipt.json" <<'JSON'
{
  "kind": "data-safety",
  "dataClassification": "sensitive-PII",
  "deliveryAudience": "finance leaders",
  "dataLeavesCompany": false,
  "exportDestination": "none",
  "detailLevel": "aggregate",
  "operatorSignoff": "operator approved this audience and handling"
}
JSON
run_manifest "$T"
MANIFEST="$(printf '%s\n' "$OUT" | sed -n 's/^assay-distribution-manifest://p')"
if [ "$RC" -eq 0 ] && [ -f "$T/$MANIFEST" ] && grep -q '"dataClassification": "sensitive-PII"' "$T/$MANIFEST"; then
  pass "emits sensitive manifest after data-safety sign-off"
else
  fail "expected signed sensitive manifest (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

echo ""
echo "distribution-manifest: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
