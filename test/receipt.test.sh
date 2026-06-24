#!/usr/bin/env bash
# receipt.test.sh - receipt writer round trips against the gate readers.

set -uo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WRITER="$KIT/.claude/workflows/receipt.sh"
QUESTION="$KIT/.claude/workflows/questioncheck.sh"
VALIDATION="$KIT/.claude/workflows/validationcheck.sh"
DATACHECK="$KIT/.claude/workflows/datacheck.sh"
INSTALL="$KIT/install.sh"

PASS=0
FAIL=0
pass() { printf '  PASS  %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  FAIL  %s\n' "$1"; FAIL=$((FAIL + 1)); }

run_question_gate() {
  local dir="$1" id="$2" errf
  errf="$(mktemp "${TMPDIR:-/tmp}/receipt-question.err.XXXXXX")"
  OUT="$(cd "$dir" && bash "$QUESTION" "$id" 2>"$errf")"
  RC=$?
  ERR="$(cat "$errf")"
  rm -f "$errf"
}

run_validation_gate() {
  local dir="$1" id="$2" errf
  errf="$(mktemp "${TMPDIR:-/tmp}/receipt-validation.err.XXXXXX")"
  OUT="$(cd "$dir" && bash "$VALIDATION" "$id" 2>"$errf")"
  RC=$?
  ERR="$(cat "$errf")"
  rm -f "$errf"
}

run_data_gate() {
  local dir="$1" id="$2" errf
  errf="$(mktemp "${TMPDIR:-/tmp}/receipt-data.err.XXXXXX")"
  OUT="$(cd "$dir" && bash "$DATACHECK" "$id" 2>"$errf")"
  RC=$?
  ERR="$(cat "$errf")"
  rm -f "$errf"
}

echo "receipt writer tests"
echo "===================="

T="$(mktemp -d "${TMPDIR:-/tmp}/receipt.XXXXXX")"
(cd "$T" && bash "$WRITER" spec "retention-q2" <<'JSON') >/dev/null
{
  "question": "What changed retention in Q2?",
  "metricDefinitions": {
    "retention": "active customers this quarter divided by active customers last quarter"
  },
  "validAnswer": "A reconciled answer with caveats.",
  "decisionImpact": "strategy decision",
  "track": "analysis"
}
JSON
run_question_gate "$T" "retention-q2"
if [ "$RC" -eq 0 ]; then
  pass "writer spec receipt passes questioncheck"
else
  fail "expected written spec receipt to pass questioncheck (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/receipt.XXXXXX")"
cat > "$T/assay.config.jsonc" <<'JSON'
{
  "receiptsDir": "custom-receipts"
}
JSON
(cd "$T" && bash "$WRITER" spec "retention-q2" <<'JSON') >/dev/null
{
  "question": "What changed retention in Q2?",
  "metricDefinitions": {
    "retention": "active customers this quarter divided by active customers last quarter"
  },
  "validAnswer": "A reconciled answer with caveats.",
  "decisionImpact": "strategy decision",
  "track": "analysis"
}
JSON
run_question_gate "$T" "retention-q2"
if [ "$RC" -eq 0 ] && [ -f "$T/custom-receipts/retention-q2-spec-receipt.json" ]; then
  pass "writer and questioncheck honor receiptsDir from config"
else
  fail "expected custom receiptsDir round trip (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/receipt.XXXXXX")"
(cd "$T" && bash "$WRITER" data-safety "retention-q2" <<'JSON') >/dev/null
{
  "dataClassification": "customer",
  "deliveryAudience": "internal retention leaders",
  "dataLeavesCompany": false,
  "exportDestination": "none",
  "detailLevel": "aggregate",
  "operatorSignoff": "operator approved this audience and handling"
}
JSON
run_data_gate "$T" "retention-q2"
if [ "$RC" -eq 0 ]; then
  pass "writer data-safety receipt passes datacheck"
else
  fail "expected written data-safety receipt to pass datacheck (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/receipt.XXXXXX")"
(cd "$T" && bash "$WRITER" spec "retention-q2" <<'JSON') >/dev/null
{
  "question": "What changed retention in Q2?",
  "metricDefinitions": {
    "retention": "active customers this quarter divided by active customers last quarter"
  },
  "validAnswer": "A reconciled answer with caveats.",
  "decisionImpact": "strategy decision",
  "track": "analysis"
}
JSON
(cd "$T" && bash "$WRITER" validation "retention-q2" <<'JSON') >/dev/null
{
  "reconciled": true,
  "reconciliation": {
    "retention": "Compared to finance source-of-truth."
  }
}
JSON
(cd "$T" && bash "$WRITER" adversarial-review "retention-q2" <<'JSON') >/dev/null
{
  "scores": {
    "confidence": 4,
    "dataCompleteness": 4,
    "methodologySoundness": 4,
    "reproducibility": 4
  }
}
JSON
cat > "$T/assay.config.jsonc" <<'JSON'
{ "sourceOfTruth": { "retention": "Finance system of record" } }
JSON
run_validation_gate "$T" "retention-q2"
if [ "$RC" -eq 0 ]; then
  pass "writer validation and review receipts pass validationcheck"
else
  fail "expected written back-gate receipts to pass validationcheck (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/receipt.XXXXXX")"
(cd "$T" && bash "$WRITER" deliverable "retention-q2" <<'JSON') >/dev/null
{
  "analysisId": "retention-q2",
  "timestamp": "2026-06-24T00:00:00Z",
  "paths": {
    "html": ".assay/deliverables/retention-q2/report-20260624T000000Z.html"
  },
  "pdfNote": "No PDF renderer, meaning a tool that makes PDF files, was available."
}
JSON
if [ -f "$T/.assay/receipts/retention-q2-deliverable-receipt.json" ] && python3 - "$T/.assay/receipts/retention-q2-deliverable-receipt.json" <<'PY'
import json
import sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
ok = data.get("kind") == "deliverable" and data.get("paths", {}).get("html")
raise SystemExit(0 if ok else 1)
PY
then
  pass "writer deliverable receipt is readable"
else
  fail "expected written deliverable receipt"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/receipt-install.XXXXXX")"
bash "$INSTALL" "$T" >/dev/null
missing=()
for f in \
  ".claude/workflows/config.sh" \
  ".claude/workflows/assay-preflight.sh" \
  ".claude/workflows/govcheck.sh" \
  ".claude/workflows/datacheck.sh" \
  ".claude/workflows/receipt.sh" \
  ".claude/workflows/report-render.sh" \
  ".claude/workflows/dashboard-render.sh" \
  ".claude/workflows/assay-discovery.js" \
  ".claude/workflows/assay-execute.js" \
  ".claude/workflows/assay-validate.js"; do
  [ -f "$T/$f" ] || missing+=("$f")
done
if [ "${#missing[@]}" -eq 0 ] && bash "$INSTALL" --check "$T" >/dev/null; then
  pass "installer copies receipt writer and assay workflows"
else
    fail "installer missed required files: ${missing[*]}"
fi
rm -rf "$T"

echo ""
echo "receipt writer: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
