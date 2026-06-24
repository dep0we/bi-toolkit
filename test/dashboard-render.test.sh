#!/usr/bin/env bash
# dashboard-render.test.sh - static dashboard artifacts for /assay deliver.

set -uo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$KIT/.claude/workflows/dashboard-render.sh"

PASS=0
FAIL=0
pass() { printf '  PASS  %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  FAIL  %s\n' "$1"; FAIL=$((FAIL + 1)); }

write_sample() {
  local dir="$1"
  cat > "$dir/assay.config.jsonc" <<'JSON'
{
  "receiptsDir": "proof",
  "deliverablesDir": "dashboards",
  "report": {
    "orgName": "Example Finance",
    "accentColor": "#0f766e",
    "footer": "Internal finance use only."
  }
}
JSON
  cat > "$dir/dashboard.json" <<'JSON'
{
  "schemaVersion": "assay-dashboard/v1",
  "analysisId": "retention-q2",
  "title": "Q2 Retention Dashboard",
  "audience": "finance leadership",
  "refreshNote": "Monthly after finance close.",
  "panels": [
    {
      "type": "kpi",
      "title": "Net retention",
      "data": {
        "label": "Net retention",
        "value": "108%",
        "delta": "+4 points versus prior quarter",
        "note": "Tied to the finance source."
      }
    },
    {
      "type": "bar",
      "title": "Revenue by segment",
      "data": {
        "labels": ["Enterprise", "Mid-market", "SMB"],
        "values": [92000, 47000, 18000],
        "source": "Finance source"
      }
    },
    {
      "type": "line",
      "title": "Retention trend",
      "data": {
        "points": [
          { "x": "2026-04", "y": 102 },
          { "x": "2026-05", "y": 105 },
          { "x": "2026-06", "y": 108 }
        ],
        "source": "Finance source"
      }
    },
    {
      "type": "table",
      "title": "Accounts to review",
      "data": {
        "columns": ["Owner", "Account", "Status"],
        "rows": [
          ["Finance", "Acme", "Reviewed"],
          ["Sales", "Northwind", "Needs follow-up"]
        ]
      }
    }
  ]
}
JSON
}

run_render() {
  local dir="$1" errf
  errf="$(mktemp "${TMPDIR:-/tmp}/dashboard-render.err.XXXXXX")"
  OUT="$(cd "$dir" && bash "$SCRIPT" retention-q2 dashboard.json 2>"$errf")"
  RC=$?
  ERR="$(cat "$errf")"
  rm -f "$errf"
}

write_logo_base_sample() {
  local dir="$1"
  mkdir -p "$dir/assets" "$dir/config" "$dir/input"
  python3 - "$dir/assets/logo.png" <<'PY'
import base64
import sys
png = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII="
open(sys.argv[1], "wb").write(base64.b64decode(png))
PY
  cat > "$dir/config/assay.config.jsonc" <<'JSON'
{
  "receiptsDir": "proof",
  "deliverablesDir": "dashboards",
  "report": {
    "orgName": "Example Finance",
    "logoPath": "assets/logo.png",
    "accentColor": "#0f766e",
    "footer": "Internal finance use only."
  }
}
JSON
  cat > "$dir/input/dashboard.json" <<'JSON'
{
  "schemaVersion": "assay-dashboard/v1",
  "analysisId": "retention-q2",
  "title": "Q2 Retention Dashboard",
  "audience": "finance leadership",
  "refreshNote": "Monthly after finance close.",
  "panels": [
    {
      "type": "kpi",
      "title": "Net retention",
      "data": {
        "label": "Net retention",
        "value": "108%"
      }
    }
  ]
}
JSON
}

run_render_with_paths() {
  local dir="$1" errf
  errf="$(mktemp "${TMPDIR:-/tmp}/dashboard-render.err.XXXXXX")"
  OUT="$(cd "$dir" && bash "$SCRIPT" retention-q2 input/dashboard.json config/assay.config.jsonc 2>"$errf")"
  RC=$?
  ERR="$(cat "$errf")"
  rm -f "$errf"
}

echo "dashboard-render tests"
echo "======================"

T="$(mktemp -d "${TMPDIR:-/tmp}/dashboard-render.XXXXXX")"
write_sample "$T"
run_render "$T"
HTML="$(printf '%s\n' "$OUT" | sed -n 's/^assay-dashboard-html://p')"
if [ "$RC" -eq 0 ] && [ -f "$T/$HTML" ] && grep -qi '<!doctype html>' "$T/$HTML" && grep -q '<svg class="chart-svg"' "$T/$HTML" && grep -q 'Q2 Retention Dashboard' "$T/$HTML"; then
  pass "renderer produces valid HTML with inline SVG charts from every panel type"
else
  fail "expected dashboard HTML with SVG charts (rc=$RC stdout=$OUT stderr=$ERR html=$HTML)"
fi

if [ "$RC" -eq 0 ] && ! grep -Eqi '<script|<link|https?://|src="//|href="//' "$T/$HTML"; then
  pass "dashboard output has no external URLs or script/link dependencies"
else
  fail "expected offline-safe dashboard HTML (rc=$RC stdout=$OUT stderr=$ERR)"
fi

if [ "$RC" -eq 0 ] && grep -q 'Example Finance' "$T/$HTML" && grep -q -- '--accent: #0f766e' "$T/$HTML"; then
  pass "renderer applies report branding to dashboard"
else
  fail "expected branding in dashboard HTML (rc=$RC stdout=$OUT stderr=$ERR)"
fi

T2="$(mktemp -d "${TMPDIR:-/tmp}/dashboard-render-logo.XXXXXX")"
write_logo_base_sample "$T2"
run_render_with_paths "$T2"
HTML2="$(printf '%s\n' "$OUT" | sed -n 's/^assay-dashboard-html://p')"
if [ "$RC" -eq 0 ] && [ -f "$T2/$HTML2" ] && grep -q 'data:image/png;base64' "$T2/$HTML2"; then
  pass "dashboard logoPath resolves relative to project working directory"
else
  fail "expected dashboard logo from project working directory (rc=$RC stdout=$OUT stderr=$ERR html=$HTML2)"
fi
rm -rf "$T2"

if [ "$RC" -eq 0 ] && grep -q 'universal static HTML view' "$T/$HTML" && grep -q 'Power BI / Tableau / Looker / Metabase' "$T/$HTML"; then
  pass "dashboard states universal static HTML scope and future tool exports"
else
  fail "expected dashboard scope note (rc=$RC stdout=$OUT stderr=$ERR)"
fi

RECEIPT="$T/proof/retention-q2-deliverable-receipt.json"
if [ "$RC" -eq 0 ] && [ -f "$RECEIPT" ] && python3 - "$RECEIPT" "$HTML" <<'PY'
import json
import sys
receipt_path, html_path = sys.argv[1:3]
data = json.load(open(receipt_path, encoding="utf-8"))
ok = (
    data.get("kind") == "deliverable"
    and data.get("artifactType") == "dashboard"
    and data.get("analysisId") == "retention-q2"
    and data.get("paths", {}).get("html") == html_path
    and isinstance(data.get("timestamp"), str)
    and data["timestamp"]
)
raise SystemExit(0 if ok else 1)
PY
then
  pass "deliverable receipt is written with dashboard artifact type"
else
  fail "expected readable dashboard deliverable receipt (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

echo ""
echo "dashboard-render: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
