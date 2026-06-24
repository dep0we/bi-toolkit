#!/usr/bin/env bash
# decision-ledger.test.sh - BI decision ledger append and query tests.

set -uo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LEDGER="$KIT/.claude/workflows/decision-ledger.sh"

PASS=0
FAIL=0
pass() { printf '  PASS  %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  FAIL  %s\n' "$1"; FAIL=$((FAIL + 1)); }

echo "decision-ledger BI tests"
echo "========================"

T="$(mktemp -d "${TMPDIR:-/tmp}/decision-ledger.XXXXXX")"
cat > "$T/record.json" <<'JSON'
{
  "schemaVersion": 1,
  "issueId": "retention-q2",
  "issueTitle": "Retention Q2 analysis",
  "forkId": "window-choice",
  "domain": "analysis",
  "decisionType": "tier-a",
  "decisionClass": "cohort-or-window",
  "options": ["calendar quarter", "fiscal quarter"],
  "recommendation": "Use fiscal quarter.",
  "timestamp": "2026-06-24T12:00:00Z",
  "actualRuling": "Use fiscal quarter.",
  "rationale": "Finance reports retention by fiscal quarter.",
  "matchScore": "exact"
}
JSON
(cd "$T" && bash "$LEDGER" append "$T/record.json") >/dev/null 2>&1
if [ -f "$T/.assay/rulings/decisions.jsonl" ]; then
  pass "append writes to .assay/rulings/decisions.jsonl"
else
  fail "expected BI ledger path to be written"
fi
QUERY_OUT="$(cd "$T" && bash "$LEDGER" query --fork window-choice 2>/dev/null)"
if printf '%s\n' "$QUERY_OUT" | grep -q '"decisionClass": "cohort-or-window"'; then
  pass "query returns appended BI decision class"
else
  fail "expected query to return cohort-or-window record (output=$QUERY_OUT)"
fi
cat > "$T/bad-record.json" <<'JSON'
{
  "schemaVersion": 1,
  "issueId": "retention-q2",
  "forkId": "bad-choice",
  "domain": "analysis",
  "decisionType": "tier-a",
  "decisionClass": "tech-choice",
  "timestamp": "2026-06-24T12:00:00Z"
}
JSON
if (cd "$T" && bash "$LEDGER" append "$T/bad-record.json") >/dev/null 2>&1; then
  fail "expected non-BI decision class to be rejected"
else
  pass "append rejects non-BI decision class"
fi
rm -rf "$T"

echo ""
echo "decision-ledger: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
