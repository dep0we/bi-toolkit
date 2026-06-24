#!/usr/bin/env bash
# metric-store.test.sh - living metric catalog command tests.

set -uo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STORE="$KIT/.claude/workflows/metric-store.sh"

PASS=0
FAIL=0
pass() { printf '  PASS  %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  FAIL  %s\n' "$1"; FAIL=$((FAIL + 1)); }

echo "metric store tests"
echo "=================="

T="$(mktemp -d "${TMPDIR:-/tmp}/metric-store.XXXXXX")"
cat > "$T/assay.config.jsonc" <<'JSON'
{
  "metricCatalogPath": "team-metrics.json",
  "sourceOfTruth": {
    "revenue": "Finance workbook"
  }
}
JSON

OUT="$(cd "$T" && bash "$STORE" add Revenue "sum closed-won invoice amount less credits" "Finance workbook" "Finance" "USD" "board metric")"
RC=$?
if [ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | grep -qx 'metric-store:added:revenue:team-metrics.json' && [ -f "$T/team-metrics.json" ]; then
  pass "add writes configured catalog path"
else
  fail "expected add to write configured catalog (rc=$RC output=$OUT)"
fi

OUT="$(cd "$T" && bash "$STORE" get revenue)"
RC=$?
if [ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | grep -q '"definition": "sum closed-won invoice amount less credits"' && printf '%s\n' "$OUT" | grep -q '"sourceOfTruth": "Finance workbook"'; then
  pass "get returns the stored metric"
else
  fail "expected get to return metric JSON (rc=$RC output=$OUT)"
fi

OUT="$(cd "$T" && bash "$STORE" list)"
RC=$?
if [ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | grep -q $'^revenue\tRevenue\tFinance workbook\tFinance$'; then
  pass "list includes stored metric"
else
  fail "expected list to include revenue (rc=$RC output=$OUT)"
fi

OUT="$(cd "$T" && bash "$STORE" add Revenue "sum closed-won invoice amount less credits" "Finance workbook" "RevOps" "USD" "owner update")"
RC=$?
GET="$(cd "$T" && bash "$STORE" get revenue)"
if [ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | grep -qx 'metric-store:updated:revenue:team-metrics.json' && printf '%s\n' "$GET" | grep -q '"owner": "RevOps"'; then
  pass "add updates an existing metric"
else
  fail "expected add to update metric (rc=$RC output=$OUT get=$GET)"
fi

OUT="$(cd "$T" && bash "$STORE" check revenue "sum closed-won invoice amount less credits")"
RC=$?
if [ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | grep -qx 'metric-store:match:revenue'; then
  pass "check reports match"
else
  fail "expected check match (rc=$RC output=$OUT)"
fi

OUT="$(cd "$T" && bash "$STORE" check revenue "sum invoices before credits")"
RC=$?
if [ "$RC" -eq 1 ] && printf '%s\n' "$OUT" | grep -qx 'metric-store:differs:revenue' && printf '%s\n' "$OUT" | grep -q '^catalog-definition:'; then
  pass "check reports differs"
else
  fail "expected check differs (rc=$RC output=$OUT)"
fi

OUT="$(cd "$T" && bash "$STORE" check churn "lost customers divided by starting customers")"
RC=$?
if [ "$RC" -eq 2 ] && printf '%s\n' "$OUT" | grep -qx 'metric-store:not-found:churn'; then
  pass "check reports not-found"
else
  fail "expected check not-found (rc=$RC output=$OUT)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/metric-store.XXXXXX")"
OUT="$(cd "$T" && ASSAY_METRIC_CATALOG=env-metrics.json bash "$STORE" add churn "lost customers divided by starting customers" "CRM" "Customer Success" "percent")"
RC=$?
if [ "$RC" -eq 0 ] && [ -f "$T/env-metrics.json" ]; then
  pass "env var controls catalog path when config is absent"
else
  fail "expected env catalog path (rc=$RC output=$OUT)"
fi
rm -rf "$T"

echo ""
echo "metric store: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
