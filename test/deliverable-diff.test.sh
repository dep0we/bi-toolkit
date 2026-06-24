#!/usr/bin/env bash
# deliverable-diff.test.sh - compare recurring deliverable snapshots.

set -uo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$KIT/.claude/workflows/deliverable-diff.sh"

PASS=0
FAIL=0
pass() { printf '  PASS  %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  FAIL  %s\n' "$1"; FAIL=$((FAIL + 1)); }

echo "deliverable-diff tests"
echo "======================"

T="$(mktemp -d "${TMPDIR:-/tmp}/deliverable-diff.XXXXXX")"
cat > "$T/assay.config.jsonc" <<'JSON'
{
  "deliverablesDir": "reports"
}
JSON
mkdir -p "$T/reports/retention-q2"
cat > "$T/snap1.json" <<'JSON'
{
  "schemaVersion": "assay-metrics-snapshot/v1",
  "analysisId": "retention-q2",
  "timestamp": "20260624T000000Z",
  "metrics": {
    "Net retention": 100,
    "Revenue": 120000
  },
  "findings": ["Retention held steady"]
}
JSON
OUT="$(cd "$T" && bash "$SCRIPT" retention-q2 snap1.json reports/retention-q2/report-1.html 2>&1)"
RC=$?
DIFF="$(printf '%s\n' "$OUT" | sed -n 's/^assay-deliverable-diff://p')"
if [ "$RC" -eq 0 ] && [ -f "$T/$DIFF" ] && grep -q 'First run' "$T/$DIFF" && [ -f "$T/reports/retention-q2/latest.json" ]; then
  pass "writes first-run summary and latest pointer"
else
  fail "expected first-run diff and latest pointer (rc=$RC stdout=$OUT)"
fi

cat > "$T/snap2.json" <<'JSON'
{
  "schemaVersion": "assay-metrics-snapshot/v1",
  "analysisId": "retention-q2",
  "timestamp": "20260625T000000Z",
  "metrics": {
    "Net retention": 108,
    "Revenue": 118000
  },
  "findings": ["Retention improved", "Revenue softened"]
}
JSON
OUT="$(cd "$T" && bash "$SCRIPT" retention-q2 snap2.json reports/retention-q2/report-2.html 2>&1)"
RC=$?
DIFF="$(printf '%s\n' "$OUT" | sed -n 's/^assay-deliverable-diff://p')"
if [ "$RC" -eq 0 ] && [ -f "$T/$DIFF" ] && grep -q 'What changed since last run' "$T/$DIFF" && grep -q 'Net retention: increased from 100 to 108' "$T/$DIFF" && grep -q 'New: Retention improved' "$T/$DIFF"; then
  pass "summarizes metric and finding changes across two runs"
else
  fail "expected changed metrics and findings in diff (rc=$RC stdout=$OUT diff=$DIFF)"
fi
rm -rf "$T"

echo ""
echo "deliverable-diff: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
