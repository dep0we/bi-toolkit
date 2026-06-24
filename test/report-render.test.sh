#!/usr/bin/env bash
# report-render.test.sh - report artifacts for /assay deliver.

set -uo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$KIT/.claude/workflows/report-render.sh"

PASS=0
FAIL=0
pass() { printf '  PASS  %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  FAIL  %s\n' "$1"; FAIL=$((FAIL + 1)); }

write_sample() {
  local dir="$1"
  cat > "$dir/assay.config.jsonc" <<'JSON'
{
  "receiptsDir": "proof",
  "deliverablesDir": "reports",
  "report": {
    "orgName": "Example Finance",
    "accentColor": "#0f766e",
    "footer": "Internal finance use only.",
    "outputFormats": ["html", "pdf"]
  }
}
JSON
  cat > "$dir/deliverable.json" <<'JSON'
{
  "schemaVersion": "assay-report/v1",
  "analysisId": "retention-q2",
  "title": "Q2 Retention Report",
  "audience": "finance leadership",
  "conclusion": "Retention improved because expansion revenue offset fewer renewals.",
  "keyFindings": [
    {
      "title": "Expansion offset churn",
      "detail": "Expansion revenue grew faster than lost recurring revenue.",
      "evidence": "Validated against the finance source.",
      "consequence": "Leadership can prioritize expansion plays while monitoring renewal risk."
    }
  ],
  "evidence": [
    {
      "label": "Retention",
      "detail": "Compared Q2 actuals to the prior quarter.",
      "source": "Finance source"
    }
  ],
  "methodology": ["Compared active customers quarter over quarter using the approved metric definition."],
  "caveats": ["Late invoices may shift the final total."],
  "reconciliationNotes": ["Totals matched the finance source within the approved tolerance."],
  "score": {
    "confidence": 4,
    "dataCompleteness": 4,
    "methodologySoundness": 4,
    "reproducibility": 4
  },
  "nextSteps": ["Finance owner - review late invoices - next close cycle."],
  "figures": [
    {
      "title": "Retention movement",
      "description": "A planned chart slot for the retention trend."
    }
  ]
}
JSON
}

run_render() {
  local dir="$1" errf
  errf="$(mktemp "${TMPDIR:-/tmp}/report-render.err.XXXXXX")"
  OUT="$(cd "$dir" && ASSAY_REPORT_PDF_RENDERER=none bash "$SCRIPT" retention-q2 deliverable.json 2>"$errf")"
  RC=$?
  ERR="$(cat "$errf")"
  rm -f "$errf"
}

echo "report-render tests"
echo "==================="

T="$(mktemp -d "${TMPDIR:-/tmp}/report-render.XXXXXX")"
write_sample "$T"
run_render "$T"
HTML="$(printf '%s\n' "$OUT" | sed -n 's/^assay-report-html://p')"
if [ "$RC" -eq 0 ] && [ -f "$T/$HTML" ] && grep -qi '<!doctype html>' "$T/$HTML" && grep -q 'Q2 Retention Report' "$T/$HTML" && ! grep -Eqi '<link|https?://' "$T/$HTML"; then
  pass "renderer produces valid self-contained HTML from sample deliverable"
else
  fail "expected self-contained HTML (rc=$RC stdout=$OUT stderr=$ERR html=$HTML)"
fi

if [ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | grep -q '^assay-report-pdf-note:No PDF renderer' && ! ls "$T/reports/retention-q2/"*.pdf >/dev/null 2>&1; then
  pass "renderer succeeds with HTML only when no PDF renderer is present"
else
  fail "expected HTML-only PDF fallback (rc=$RC stdout=$OUT stderr=$ERR)"
fi

if [ "$RC" -eq 0 ] && grep -q 'Example Finance' "$T/$HTML" && grep -q -- '--accent: #0f766e' "$T/$HTML"; then
  pass "renderer applies orgName and accentColor branding"
else
  fail "expected branding in report HTML (rc=$RC stdout=$OUT stderr=$ERR)"
fi

RECEIPT="$T/proof/retention-q2-deliverable-receipt.json"
if [ "$RC" -eq 0 ] && [ -f "$RECEIPT" ] && python3 - "$RECEIPT" "$HTML" <<'PY'
import json
import sys
receipt_path, html_path = sys.argv[1:3]
data = json.load(open(receipt_path, encoding="utf-8"))
ok = (
    data.get("kind") == "deliverable"
    and data.get("analysisId") == "retention-q2"
    and data.get("paths", {}).get("html") == html_path
    and isinstance(data.get("timestamp"), str)
    and data["timestamp"]
)
raise SystemExit(0 if ok else 1)
PY
then
  pass "deliverable receipt is written and readable"
else
  fail "expected readable deliverable receipt (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

echo ""
echo "report-render: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
