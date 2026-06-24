#!/usr/bin/env bash
# dashboard-render.sh - render a validated assay dashboard to static HTML.

set -euo pipefail

ID="${1:-}"
SOURCE="${2:-}"
CONFIG="${3:-${ASSAY_CONFIG:-assay.config.jsonc}}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$SCRIPT_DIR/config.sh"

usage() {
  echo "dashboard-render: usage: dashboard-render.sh <analysis-id> <dashboard-json> [assay.config.jsonc]" >&2
  echo "dashboard-render: dashboard-json uses schemaVersion assay-dashboard/v1. JSON is a structured key-value data file." >&2
  exit 2
}

[ -n "$ID" ] && [ -n "$SOURCE" ] || usage

case "$ID" in
  *[!A-Za-z0-9._-]*|"")
    echo "dashboard-render: analysis-id may use only letters, numbers, dot, underscore, and dash" >&2
    exit 2
    ;;
esac

[ -f "$SOURCE" ] || { echo "dashboard-render: dashboard data contract not found: $SOURCE" >&2; exit 2; }

if ! command -v python3 >/dev/null 2>&1; then
  echo "dashboard-render: python3 is required to render dashboards from JSON. JSON is a structured key-value data file." >&2
  exit 2
fi

DELIVERABLES_DIR="$(assay_config_path deliverablesDir "${ASSAY_DELIVERABLES_DIR:-}" ".assay/deliverables" "$CONFIG")"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="$DELIVERABLES_DIR/$ID"
HTML="$OUT_DIR/dashboard-$TIMESTAMP.html"
SNAPSHOT="$OUT_DIR/metrics-$TIMESTAMP.json"
RECEIPT_PAYLOAD="$(mktemp "${TMPDIR:-/tmp}/assay-dashboard-deliverable-receipt.XXXXXX")"
DRIFT_STATUS=""
DRIFT_SUMMARY=""
DRIFT_STATE=""
DIFF_PATH=""
DISTRIBUTION_MANIFEST=""
DISTRIBUTION_WITHHELD=""

cleanup() {
  rm -f "$RECEIPT_PAYLOAD"
}
trap cleanup EXIT

mkdir -p "$OUT_DIR"

python3 - "$ID" "$SOURCE" "$CONFIG" "$HTML" "$TIMESTAMP" <<'PY'
import base64
import html
import json
import math
import mimetypes
import os
import re
import sys

analysis_id, source_path, config_path, html_path, timestamp = sys.argv[1:6]

def fail(message):
    print(f"dashboard-render: {message}", file=sys.stderr)
    raise SystemExit(2)

def strip_jsonc(text):
    out = []
    i = 0
    in_str = False
    quote = ""
    escape = False
    while i < len(text):
        ch = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ""
        if in_str:
            out.append(ch)
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == quote:
                in_str = False
            i += 1
            continue
        if ch in ("'", '"'):
            in_str = True
            quote = ch
            out.append(ch)
            i += 1
            continue
        if ch == "/" and nxt == "/":
            i += 2
            while i < len(text) and text[i] not in "\r\n":
                i += 1
            continue
        if ch == "/" and nxt == "*":
            i += 2
            while i + 1 < len(text) and not (text[i] == "*" and text[i + 1] == "/"):
                i += 1
            i += 2
            continue
        out.append(ch)
        i += 1
    return "".join(out)

def load_json(path):
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
    except Exception as exc:
        fail(f"could not read dashboard JSON. JSON is a structured key-value data file. {exc}")
    if not isinstance(data, dict):
        fail("dashboard contract must be a JSON object. A JSON object is key-value data.")
    return data

def load_config(path):
    try:
        raw = open(path, encoding="utf-8").read()
    except FileNotFoundError:
        return {}
    try:
        data = json.loads(strip_jsonc(raw))
    except Exception:
        return {}
    return data if isinstance(data, dict) else {}

def esc(value):
    return html.escape(str(value), quote=True)

def clean_accent(value):
    raw = str(value or "").strip()
    if re.fullmatch(r"#[0-9A-Fa-f]{6}", raw):
        return raw
    return "#2563eb"

def text(value):
    if value is None:
        return ""
    return str(value).strip()

def number(value):
    if isinstance(value, bool):
        return None
    if isinstance(value, (int, float)) and math.isfinite(value):
        return float(value)
    if isinstance(value, str):
        cleaned = value.strip().replace(",", "").replace("$", "").replace("%", "")
        try:
            parsed = float(cleaned)
        except ValueError:
            return None
        return parsed if math.isfinite(parsed) else None
    return None

def fmt(value):
    if isinstance(value, (int, float)) and math.isfinite(value):
        if abs(value) >= 100:
            return f"{value:,.0f}"
        if float(value).is_integer():
            return f"{value:.0f}"
        return f"{value:,.2f}".rstrip("0").rstrip(".")
    return text(value)

def embed_image(path):
    if not path:
        return ""
    candidate = path
    if not os.path.isabs(candidate):
        candidate = os.path.abspath(candidate)
    if not os.path.isfile(candidate):
        return ""
    mime = mimetypes.guess_type(candidate)[0] or "application/octet-stream"
    with open(candidate, "rb") as f:
        encoded = base64.b64encode(f.read()).decode("ascii")
    return f"data:{mime};base64,{encoded}"

def normalize_pairs(data, chart_type):
    if not isinstance(data, dict):
        fail(f"{chart_type} panel needs data object. Data object means named chart values.")
    pairs = []
    items = data.get("items") or data.get("points")
    if isinstance(items, list):
        for item in items:
            if isinstance(item, dict):
                label = text(item.get("label") or item.get("x") or item.get("name") or item.get("date"))
                val = number(item.get("value") if "value" in item else item.get("y"))
                if label and val is not None:
                    pairs.append((label, val))
            elif isinstance(item, list) and len(item) >= 2:
                label = text(item[0])
                val = number(item[1])
                if label and val is not None:
                    pairs.append((label, val))
    if not pairs:
        labels = data.get("labels")
        values = data.get("values")
        if isinstance(labels, list) and isinstance(values, list):
            for label, raw in zip(labels, values):
                val = number(raw)
                if text(label) and val is not None:
                    pairs.append((text(label), val))
    if not pairs:
        fail(f"{chart_type} panel needs labels and values. Labels are names; values are numbers.")
    return pairs

def axis_range(values):
    lo = min(values + [0])
    hi = max(values + [0])
    if lo == hi:
        hi = lo + 1
    pad = (hi - lo) * 0.08
    return lo - pad, hi + pad

def svg_frame(title, inner):
    return (
        '<svg class="chart-svg" viewBox="0 0 680 320" role="img" '
        f'aria-label="{esc(title)}">'
        f"{inner}</svg>"
    )

def bar_svg(title, pairs, accent):
    width, height = 680, 320
    left, right, top, bottom = 54, 24, 28, 58
    plot_w = width - left - right
    plot_h = height - top - bottom
    values = [v for _, v in pairs]
    lo, hi = axis_range(values)
    zero = max(min(0, hi), lo)
    def y(v):
        return top + (hi - v) / (hi - lo) * plot_h
    bar_gap = 10
    slot = plot_w / max(len(pairs), 1)
    bar_w = max(12, slot - bar_gap)
    parts = [
        f'<line x1="{left}" y1="{top}" x2="{left}" y2="{top + plot_h}" class="axis" />',
        f'<line x1="{left}" y1="{y(zero):.2f}" x2="{left + plot_w}" y2="{y(zero):.2f}" class="axis" />',
        f'<text x="{left - 8}" y="{top + 4}" class="axis-label" text-anchor="end">{esc(fmt(hi))}</text>',
        f'<text x="{left - 8}" y="{top + plot_h}" class="axis-label" text-anchor="end">{esc(fmt(lo))}</text>',
    ]
    for i, (label, value) in enumerate(pairs):
        x = left + i * slot + (slot - bar_w) / 2
        y0 = y(zero)
        yv = y(value)
        rect_y = min(y0, yv)
        rect_h = max(1, abs(y0 - yv))
        label_short = label if len(label) <= 14 else label[:13] + "..."
        parts.append(f'<rect x="{x:.2f}" y="{rect_y:.2f}" width="{bar_w:.2f}" height="{rect_h:.2f}" rx="3" fill="{accent}" />')
        parts.append(f'<text x="{x + bar_w / 2:.2f}" y="{rect_y - 7:.2f}" class="value-label" text-anchor="middle">{esc(fmt(value))}</text>')
        parts.append(f'<text x="{x + bar_w / 2:.2f}" y="{height - 22}" class="axis-label" text-anchor="middle">{esc(label_short)}</text>')
    return svg_frame(title, "\n".join(parts))

def line_svg(title, pairs, accent):
    width, height = 680, 320
    left, right, top, bottom = 54, 24, 28, 58
    plot_w = width - left - right
    plot_h = height - top - bottom
    values = [v for _, v in pairs]
    lo, hi = axis_range(values)
    def x(i):
        if len(pairs) == 1:
            return left + plot_w / 2
        return left + i / (len(pairs) - 1) * plot_w
    def y(v):
        return top + (hi - v) / (hi - lo) * plot_h
    path = " ".join(("M" if i == 0 else "L") + f"{x(i):.2f},{y(value):.2f}" for i, (_, value) in enumerate(pairs))
    parts = [
        f'<line x1="{left}" y1="{top}" x2="{left}" y2="{top + plot_h}" class="axis" />',
        f'<line x1="{left}" y1="{top + plot_h}" x2="{left + plot_w}" y2="{top + plot_h}" class="axis" />',
        f'<text x="{left - 8}" y="{top + 4}" class="axis-label" text-anchor="end">{esc(fmt(hi))}</text>',
        f'<text x="{left - 8}" y="{top + plot_h}" class="axis-label" text-anchor="end">{esc(fmt(lo))}</text>',
        f'<path d="{path}" fill="none" stroke="{accent}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round" />',
    ]
    label_indexes = {0, len(pairs) - 1}
    if len(pairs) > 2:
        label_indexes.add(len(pairs) // 2)
    for i, (label, value) in enumerate(pairs):
        cx = x(i)
        cy = y(value)
        parts.append(f'<circle cx="{cx:.2f}" cy="{cy:.2f}" r="5" fill="#ffffff" stroke="{accent}" stroke-width="3" />')
        if i in label_indexes:
            label_short = label if len(label) <= 16 else label[:15] + "..."
            parts.append(f'<text x="{cx:.2f}" y="{height - 22}" class="axis-label" text-anchor="middle">{esc(label_short)}</text>')
            parts.append(f'<text x="{cx:.2f}" y="{cy - 10:.2f}" class="value-label" text-anchor="middle">{esc(fmt(value))}</text>')
    return svg_frame(title, "\n".join(parts))

def kpi_panel(panel):
    data = panel.get("data") if isinstance(panel.get("data"), dict) else {}
    value = data.get("value", panel.get("value", ""))
    label = data.get("label") or panel.get("title") or "Metric"
    delta = data.get("delta") or data.get("change") or ""
    note = data.get("note") or data.get("source") or ""
    parts = [
        '<article class="panel kpi-panel">',
        f'<h2>{esc(panel.get("title") or label)}</h2>',
        f'<div class="kpi-value">{esc(fmt(value))}</div>',
        f'<div class="kpi-label">{esc(label)}</div>',
    ]
    if delta:
        parts.append(f'<div class="delta">{esc(delta)}</div>')
    if note:
        parts.append(f'<p class="panel-note">{esc(note)}</p>')
    parts.append("</article>")
    return "\n".join(parts)

def chart_panel(panel, chart_type, accent):
    data = panel.get("data")
    title = text(panel.get("title")) or chart_type.title()
    pairs = normalize_pairs(data, chart_type)
    chart = bar_svg(title, pairs, accent) if chart_type == "bar" else line_svg(title, pairs, accent)
    note = text(data.get("note") or data.get("source") or "") if isinstance(data, dict) else ""
    parts = [f'<article class="panel chart-panel"><h2>{esc(title)}</h2>', chart]
    if note:
        parts.append(f'<p class="panel-note">{esc(note)}</p>')
    parts.append("</article>")
    return "\n".join(parts)

def table_panel(panel):
    data = panel.get("data")
    if not isinstance(data, dict):
        fail("table panel needs data object. Data object means named table values.")
    columns = data.get("columns")
    rows = data.get("rows")
    if not isinstance(columns, list) or not columns:
        fail("table panel needs columns. Columns are table field names.")
    if not isinstance(rows, list):
        fail("table panel needs rows. Rows are table records.")
    body = []
    for row in rows:
        if isinstance(row, dict):
            body.append("<tr>" + "".join(f"<td>{esc(row.get(col, ''))}</td>" for col in columns) + "</tr>")
        elif isinstance(row, list):
            body.append("<tr>" + "".join(f"<td>{esc(row[i] if i < len(row) else '')}</td>" for i, _ in enumerate(columns)) + "</tr>")
        else:
            body.append(f"<tr><td colspan=\"{len(columns)}\">{esc(row)}</td></tr>")
    header = "".join(f"<th>{esc(col)}</th>" for col in columns)
    note = text(data.get("note") or data.get("source") or "")
    parts = [
        '<article class="panel table-panel">',
        f'<h2>{esc(panel.get("title") or "Detail Table")}</h2>',
        '<div class="table-wrap">',
        f'<table><thead><tr>{header}</tr></thead><tbody>{"".join(body)}</tbody></table>',
        "</div>",
    ]
    if note:
        parts.append(f'<p class="panel-note">{esc(note)}</p>')
    parts.append("</article>")
    return "\n".join(parts)

data = load_json(source_path)
config = load_config(config_path)
report_config = config.get("report") if isinstance(config.get("report"), dict) else {}

if data.get("schemaVersion") != "assay-dashboard/v1":
    fail("dashboard contract needs schemaVersion assay-dashboard/v1")
if data.get("analysisId") and data.get("analysisId") != analysis_id:
    fail("dashboard analysisId does not match the command analysis-id")
for key in ("title", "audience", "refreshNote"):
    if not isinstance(data.get(key), str) or not data.get(key).strip():
        fail(f"dashboard contract needs {key}")
panels = data.get("panels")
if not isinstance(panels, list) or not panels:
    fail("dashboard contract needs panels. Panels are dashboard sections.")

org = report_config.get("orgName") or config.get("projectName") or "Assay BI Toolkit"
accent = clean_accent(report_config.get("accentColor"))
footer = report_config.get("footer") or "Confidential - share only with the approved audience."
logo_uri = embed_image(report_config.get("logoPath"))
title = data["title"].strip()
audience = data["audience"].strip()
refresh = data["refreshNote"].strip()
generated = data.get("generatedAt") or timestamp

rendered_panels = []
for index, panel in enumerate(panels, start=1):
    if not isinstance(panel, dict):
        fail(f"panel {index} must be a JSON object. A JSON object is key-value data.")
    panel_type = panel.get("type")
    if panel_type not in {"kpi", "bar", "line", "table"}:
        fail(f"panel {index} has unsupported type. Use kpi, bar, line, or table.")
    if not isinstance(panel.get("title"), str) or not panel.get("title").strip():
        fail(f"panel {index} needs title")
    if panel_type == "kpi":
        rendered_panels.append(kpi_panel(panel))
    elif panel_type in {"bar", "line"}:
        rendered_panels.append(chart_panel(panel, panel_type, accent))
    else:
        rendered_panels.append(table_panel(panel))

style = f"""
:root {{
  --accent: {accent};
  --ink: #172033;
  --muted: #5b6475;
  --line: #d8dde8;
  --panel: #f7f9fc;
  --soft-accent: #eef6ff;
}}
* {{ box-sizing: border-box; }}
body {{
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Arial, sans-serif;
  color: var(--ink);
  background: #ffffff;
  line-height: 1.45;
}}
.page {{ max-width: 1180px; margin: 0 auto; padding: 34px 24px 28px; }}
header {{ border-bottom: 4px solid var(--accent); padding-bottom: 20px; margin-bottom: 24px; }}
.brand {{ display: flex; align-items: center; gap: 14px; color: var(--muted); font-size: 14px; }}
.brand img {{ max-height: 42px; max-width: 160px; object-fit: contain; }}
h1 {{ margin: 14px 0 8px; font-size: 32px; line-height: 1.15; letter-spacing: 0; }}
h2 {{ margin: 0 0 14px; font-size: 16px; line-height: 1.25; letter-spacing: 0; }}
.meta {{ color: var(--muted); font-size: 14px; }}
.notice {{ margin: 0 0 18px; padding: 12px 14px; background: var(--soft-accent); border-left: 4px solid var(--accent); color: var(--ink); }}
.grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); gap: 16px; align-items: stretch; }}
.panel {{ border: 1px solid var(--line); border-radius: 8px; background: #fff; padding: 16px; min-width: 0; }}
.kpi-panel {{ border-top: 4px solid var(--accent); }}
.kpi-value {{ font-size: 38px; line-height: 1; font-weight: 700; margin: 6px 0; overflow-wrap: anywhere; }}
.kpi-label, .delta, .panel-note {{ color: var(--muted); font-size: 14px; }}
.delta {{ color: var(--accent); font-weight: 700; margin-top: 8px; }}
.chart-panel {{ grid-column: span 2; }}
.table-panel {{ grid-column: 1 / -1; }}
.chart-svg {{ display: block; width: 100%; height: auto; min-height: 220px; }}
.axis {{ stroke: var(--line); stroke-width: 1; }}
.axis-label {{ fill: var(--muted); font-size: 12px; }}
.value-label {{ fill: var(--ink); font-size: 12px; font-weight: 700; }}
.table-wrap {{ overflow-x: auto; }}
table {{ width: 100%; border-collapse: collapse; font-size: 14px; }}
th, td {{ border: 1px solid var(--line); padding: 10px; text-align: left; vertical-align: top; }}
th {{ background: var(--panel); }}
footer {{ padding-top: 20px; color: var(--muted); font-size: 12px; }}
@media (max-width: 720px) {{
  .page {{ padding: 24px 16px; }}
  h1 {{ font-size: 27px; }}
  .chart-panel {{ grid-column: span 1; }}
}}
@media print {{
  body {{ color: #000; }}
  .page {{ max-width: none; padding: 24px; }}
  .panel {{ break-inside: avoid; }}
}}
"""

logo_html = f'<img src="{esc(logo_uri)}" alt="{esc(org)} logo" />' if logo_uri else ""
body = [
    "<!doctype html>",
    '<html lang="en">',
    "<head>",
    '<meta charset="utf-8" />',
    '<meta name="viewport" content="width=device-width, initial-scale=1" />',
    f"<title>{esc(title)}</title>",
    f"<style>{style}</style>",
    "</head>",
    "<body>",
    '<main class="page">',
    "<header>",
    f'<div class="brand">{logo_html}<span>{esc(org)}</span></div>',
    f"<h1>{esc(title)}</h1>",
    f'<div class="meta">Analysis ID: {esc(analysis_id)} | Audience: {esc(audience)} | Generated: {esc(generated)}</div>',
    f'<div class="meta">Refresh note: {esc(refresh)}</div>',
    "</header>",
    '<section class="notice">This dashboard (recurring view of business metrics) is a universal static HTML view (browser page saved as a file). Tool-specific exports for Power BI / Tableau / Looker / Metabase are future work driven by intake.</section>',
    '<section class="grid">',
    "\n".join(rendered_panels),
    "</section>",
    f"<footer>{esc(footer)}</footer>",
    "</main>",
    "</body>",
    "</html>",
]

with open(html_path, "w", encoding="utf-8") as f:
    f.write("\n".join(body))
    f.write("\n")
PY

python3 - "$ID" "$TIMESTAMP" "$SOURCE" "$HTML" "$SNAPSHOT" <<'PY'
import json
import math
import sys

analysis_id, timestamp, source, html_path, snapshot_path = sys.argv[1:6]

def load(path):
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    return data if isinstance(data, dict) else {}

def number(value):
    if isinstance(value, bool):
        return None
    if isinstance(value, (int, float)) and math.isfinite(value):
        return float(value)
    if isinstance(value, str):
        cleaned = value.strip().replace(",", "").replace("$", "").replace("%", "")
        try:
            parsed = float(cleaned)
        except ValueError:
            return None
        return parsed if math.isfinite(parsed) else None
    return None

def add_metric(metrics, name, value):
    if not name:
        return
    parsed = number(value)
    if parsed is not None:
        metrics[name] = parsed
    elif isinstance(value, str) and value.strip():
        metrics[name] = value.strip()

def row_count_from_table(panel):
    data = panel.get("data") if isinstance(panel.get("data"), dict) else {}
    rows = data.get("rows")
    return len(rows) if isinstance(rows, list) else 0

data = load(source)
metrics = {}
table_rows = 0
for panel in data.get("panels", []):
    if not isinstance(panel, dict):
        continue
    panel_data = panel.get("data") if isinstance(panel.get("data"), dict) else {}
    title = str(panel.get("title") or "").strip()
    if panel.get("type") == "kpi":
        add_metric(metrics, str(panel_data.get("label") or title).strip(), panel_data.get("value", panel.get("value")))
    elif panel.get("type") in {"bar", "line"} and isinstance(panel_data, dict):
        values = panel_data.get("values")
        points = panel_data.get("points")
        if isinstance(values, list) and values:
            add_metric(metrics, f"{title} latest", values[-1])
        elif isinstance(points, list) and points:
            last = points[-1]
            if isinstance(last, dict):
                add_metric(metrics, f"{title} latest", last.get("value", last.get("y")))
            elif isinstance(last, list) and len(last) >= 2:
                add_metric(metrics, f"{title} latest", last[1])
    if panel.get("type") == "table":
        table_rows += row_count_from_table(panel)

refresh = data.get("refresh") if isinstance(data.get("refresh"), dict) else {}
row_count = data.get("rowCount", refresh.get("rowCount"))
if row_count is None and table_rows:
    row_count = table_rows

snapshot = {
    "schemaVersion": "assay-metrics-snapshot/v1",
    "analysisId": analysis_id,
    "timestamp": timestamp,
    "artifactType": "dashboard",
    "artifactPath": html_path,
    "sourcePath": source,
    "audience": data.get("audience"),
    "cadence": data.get("cadence") or data.get("refreshCadence") or data.get("refreshNote"),
    "rowCount": row_count,
    "refreshOk": data.get("refreshOk", refresh.get("ok", True)),
    "rendererStatus": "ok",
    "metrics": metrics,
    "findings": [str(data.get("title") or "Dashboard").strip()],
}
with open(snapshot_path, "w", encoding="utf-8") as f:
    json.dump(snapshot, f, indent=2)
    f.write("\n")
PY

DRIFT_OUTPUT="$(ASSAY_CONFIG="$CONFIG" bash "$SCRIPT_DIR/driftcheck.sh" "$ID" "$SNAPSHOT" "$CONFIG")"
DRIFT_STATUS="$(printf '%s\n' "$DRIFT_OUTPUT" | sed -n 's/^assay-drift-status://p')"
DRIFT_SUMMARY="$(printf '%s\n' "$DRIFT_OUTPUT" | sed -n 's/^assay-drift-summary://p')"
DRIFT_STATE="$(printf '%s\n' "$DRIFT_OUTPUT" | sed -n 's/^assay-drift-state://p')"
printf '%s\n' "$DRIFT_OUTPUT"

DIFF_OUTPUT="$(ASSAY_CONFIG="$CONFIG" bash "$SCRIPT_DIR/deliverable-diff.sh" "$ID" "$SNAPSHOT" "$HTML" "$CONFIG")"
DIFF_PATH="$(printf '%s\n' "$DIFF_OUTPUT" | sed -n 's/^assay-deliverable-diff://p')"
printf '%s\n' "$DIFF_OUTPUT"

DISTRIBUTION_OUTPUT="$(ASSAY_CONFIG="$CONFIG" bash "$SCRIPT_DIR/distribution-manifest.sh" "$ID" "$HTML" "$TIMESTAMP" "$SNAPSHOT" "$CONFIG" 2>&1)"
DISTRIBUTION_MANIFEST="$(printf '%s\n' "$DISTRIBUTION_OUTPUT" | sed -n 's/^assay-distribution-manifest://p')"
DISTRIBUTION_WITHHELD="$(printf '%s\n' "$DISTRIBUTION_OUTPUT" | sed -n 's/^assay-distribution-withheld://p')"
printf '%s\n' "$DISTRIBUTION_OUTPUT"

python3 - "$ID" "$TIMESTAMP" "$SOURCE" "$HTML" "$SNAPSHOT" "$DIFF_PATH" "$DRIFT_STATUS" "$DRIFT_SUMMARY" "$DRIFT_STATE" "$DISTRIBUTION_MANIFEST" "$DISTRIBUTION_WITHHELD" > "$RECEIPT_PAYLOAD" <<'PY'
import json
import sys

analysis_id, timestamp, source, html_path, snapshot_path, diff_path, drift_status, drift_summary, drift_state, distribution_manifest, distribution_withheld = sys.argv[1:12]
payload = {
    "analysisId": analysis_id,
    "timestamp": timestamp,
    "artifactType": "dashboard",
    "paths": {"html": html_path},
    "dashboardInput": source,
    "metricsSnapshot": snapshot_path,
    "diffPath": diff_path,
    "driftStatus": drift_status,
    "driftSummary": drift_summary,
    "driftState": drift_state,
}
if distribution_manifest:
    payload["distributionManifest"] = distribution_manifest
if distribution_withheld:
    payload["distributionWithheld"] = distribution_withheld
print(json.dumps(payload, indent=2))
PY

ASSAY_CONFIG="$CONFIG" bash "$SCRIPT_DIR/receipt.sh" deliverable "$ID" "$RECEIPT_PAYLOAD" >/dev/null

printf 'assay-dashboard-html:%s\n' "$HTML"
printf 'assay-dashboard-receipt:%s/%s-deliverable-receipt.json\n' "$(assay_config_path receiptsDir "${ASSAY_RECEIPTS_DIR:-}" ".assay/receipts" "$CONFIG")" "$ID"
