#!/usr/bin/env bash
# report-render.sh - render a validated assay deliverable to report artifacts.

set -euo pipefail

ID="${1:-}"
SOURCE="${2:-}"
CONFIG="${3:-${ASSAY_CONFIG:-assay.config.jsonc}}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$SCRIPT_DIR/config.sh"

usage() {
  echo "report-render: usage: report-render.sh <analysis-id> <deliverable-json> [assay.config.jsonc]" >&2
  echo "report-render: deliverable-json is the report input contract. JSON is a structured data file." >&2
  exit 2
}

[ -n "$ID" ] && [ -n "$SOURCE" ] || usage

case "$ID" in
  *[!A-Za-z0-9._-]*|"")
    echo "report-render: analysis-id may use only letters, numbers, dot, underscore, and dash" >&2
    exit 2
    ;;
esac

[ -f "$SOURCE" ] || { echo "report-render: deliverable file not found: $SOURCE" >&2; exit 2; }

if ! command -v python3 >/dev/null 2>&1; then
  echo "report-render: python3 is required to render reports from JSON. JSON is a structured data file." >&2
  exit 2
fi

DELIVERABLES_DIR="$(assay_config_path deliverablesDir "${ASSAY_DELIVERABLES_DIR:-}" ".assay/deliverables" "$CONFIG")"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="$DELIVERABLES_DIR/$ID"
HTML="$OUT_DIR/report-$TIMESTAMP.html"
PDF="$OUT_DIR/report-$TIMESTAMP.pdf"
RECEIPT_PAYLOAD="$(mktemp "${TMPDIR:-/tmp}/assay-deliverable-receipt.XXXXXX")"

cleanup() {
  rm -f "$RECEIPT_PAYLOAD"
}
trap cleanup EXIT

mkdir -p "$OUT_DIR"

python3 - "$ID" "$SOURCE" "$CONFIG" "$HTML" "$TIMESTAMP" <<'PY'
import base64
import html
import json
import mimetypes
import os
import re
import sys

analysis_id, source_path, config_path, html_path, timestamp = sys.argv[1:6]

def fail(message):
    print(f"report-render: {message}", file=sys.stderr)
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
        fail(f"could not read deliverable JSON. JSON is a structured data file. {exc}")
    if not isinstance(data, dict):
        fail("deliverable must be a JSON object. A JSON object is key-value data.")
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

def text_value(value):
    if value is None:
        return ""
    if isinstance(value, str):
        return value.strip()
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, dict):
        parts = []
        for key in ("title", "label", "summary", "detail", "description", "value", "source", "note"):
            if value.get(key):
                parts.append(str(value[key]).strip())
        return " - ".join(part for part in parts if part)
    return str(value).strip()

def as_list(value):
    if value is None or value == "":
        return []
    if isinstance(value, list):
        return value
    return [value]

def paragraph_block(value):
    items = as_list(value)
    if not items:
        return '<p class="empty">Not provided.</p>'
    if len(items) == 1 and not isinstance(items[0], dict):
        return "".join(f"<p>{esc(part.strip())}</p>" for part in str(items[0]).split("\n\n") if part.strip())
    out = ["<ul>"]
    for item in items:
        text = text_value(item)
        if text:
            out.append(f"<li>{esc(text)}</li>")
    out.append("</ul>")
    return "\n".join(out)

def finding_block(items):
    rows = []
    for item in as_list(items):
        if isinstance(item, dict):
            title = item.get("title") or item.get("label") or "Finding"
            detail = item.get("detail") or item.get("summary") or item.get("description") or ""
            evidence = item.get("evidence") or ""
            consequence = item.get("consequence") or item.get("meaning") or ""
            rows.append("<article class=\"finding\">")
            rows.append(f"<h3>{esc(title)}</h3>")
            if detail:
                rows.append(f"<p>{esc(detail)}</p>")
            if evidence:
                rows.append(f"<p><strong>Evidence:</strong> {esc(text_value(evidence))}</p>")
            if consequence:
                rows.append(f"<p><strong>Why it matters:</strong> {esc(consequence)}</p>")
            rows.append("</article>")
        else:
            rows.append(f"<article class=\"finding\"><p>{esc(item)}</p></article>")
    return "\n".join(rows) if rows else '<p class="empty">Not provided.</p>'

def evidence_block(items):
    rows = []
    for item in as_list(items):
        if isinstance(item, dict):
            label = item.get("label") or item.get("title") or item.get("metric") or "Evidence"
            detail = item.get("detail") or item.get("summary") or item.get("value") or ""
            source = item.get("source") or ""
            rows.append("<tr>")
            rows.append(f"<th>{esc(label)}</th>")
            rows.append(f"<td>{esc(text_value(detail))}</td>")
            rows.append(f"<td>{esc(text_value(source))}</td>")
            rows.append("</tr>")
        else:
            rows.append(f"<tr><th>Evidence</th><td>{esc(item)}</td><td></td></tr>")
    if not rows:
        return '<p class="empty">Not provided.</p>'
    return '<table><thead><tr><th>Item</th><th>Detail</th><th>Source</th></tr></thead><tbody>' + "\n".join(rows) + "</tbody></table>"

def score_block(value):
    scores = value or {}
    if isinstance(scores, dict) and isinstance(scores.get("scores"), dict):
        scores = scores["scores"]
    if not isinstance(scores, dict) or not scores:
        return '<p class="empty">Not provided.</p>'
    labels = {
        "confidence": "Confidence (how sure the answer is right)",
        "dataCompleteness": "Data completeness (how much relevant data was present)",
        "methodologySoundness": "Methodology soundness (approach survives expert review)",
        "reproducibility": "Reproducibility (can re-run same work)",
    }
    rows = []
    for key in ("confidence", "dataCompleteness", "methodologySoundness", "reproducibility"):
        if key in scores:
            rows.append(f"<tr><th>{esc(labels[key])}</th><td>{esc(scores[key])}</td></tr>")
    for key, val in scores.items():
        if key not in labels and isinstance(val, (str, int, float)):
            rows.append(f"<tr><th>{esc(key)}</th><td>{esc(val)}</td></tr>")
    return "<table><tbody>" + "\n".join(rows) + "</tbody></table>" if rows else '<p class="empty">Not provided.</p>'

def embed_image(path):
    if not path:
        return ""
    candidate = path
    if not os.path.isabs(candidate):
        candidate = os.path.join(os.path.dirname(source_path), candidate)
    if not os.path.isfile(candidate):
        return ""
    mime = mimetypes.guess_type(candidate)[0] or "application/octet-stream"
    with open(candidate, "rb") as f:
        encoded = base64.b64encode(f.read()).decode("ascii")
    return f"data:{mime};base64,{encoded}"

def figures_block(items):
    rows = []
    for item in as_list(items):
        if isinstance(item, dict):
            title = item.get("title") or item.get("label") or "Figure"
            desc = item.get("description") or item.get("detail") or ""
            alt = item.get("alt") or desc or title
            uri = item.get("dataUri") or embed_image(item.get("imagePath") or item.get("path"))
            rows.append("<figure>")
            if uri:
                rows.append(f'<img src="{esc(uri)}" alt="{esc(alt)}" />')
            rows.append(f"<figcaption><strong>{esc(title)}</strong>{': ' + esc(desc) if desc else ''}</figcaption>")
            rows.append("</figure>")
        else:
            rows.append(f"<figure><figcaption>{esc(item)}</figcaption></figure>")
    return "\n".join(rows) if rows else '<p class="empty">No figures were included.</p>'

data = load_json(source_path)
config = load_config(config_path)
report_config = config.get("report") if isinstance(config.get("report"), dict) else {}

if data.get("analysisId") and data.get("analysisId") != analysis_id:
    fail("deliverable analysisId does not match the command analysis-id")

title = data.get("title") or data.get("headline") or f"Assay Report: {analysis_id}"
conclusion = data.get("conclusion") or data.get("bottomLine") or data.get("summary")
if not isinstance(conclusion, str) or not conclusion.strip():
    fail("deliverable needs conclusion. Conclusion means the answer in plain language.")

org = report_config.get("orgName") or config.get("projectName") or "Assay BI Toolkit"
accent = clean_accent(report_config.get("accentColor"))
footer = report_config.get("footer") or report_config.get("confidentialityLine") or "Confidential - share only with the approved audience."
logo_uri = embed_image(report_config.get("logoPath"))
audience = data.get("audience") or ""
generated = data.get("generatedAt") or timestamp

sections = [
    ("Conclusion", paragraph_block(conclusion)),
    ("Key Findings", finding_block(data.get("keyFindings") or data.get("findings"))),
    ("Evidence", evidence_block(data.get("evidence"))),
    ("Methodology (chosen approach for answering the question)", paragraph_block(data.get("methodology"))),
    ("Caveats (limits that affect trust)", paragraph_block(data.get("caveats") or data.get("limitations"))),
    ("Reconciliation Notes (numbers checked against official source)", paragraph_block(data.get("reconciliationNotes") or data.get("reconciliation"))),
    ("Score (1 low to 5 high)", score_block(data.get("score") or data.get("scores"))),
    ("Charts and Figures", figures_block(data.get("figures") or data.get("charts"))),
    ("Next Steps", paragraph_block(data.get("nextSteps"))),
]

style = f"""
:root {{
  --accent: {accent};
  --ink: #172033;
  --muted: #5b6475;
  --line: #d8dde8;
  --panel: #f7f9fc;
}}
* {{ box-sizing: border-box; }}
body {{
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Arial, sans-serif;
  color: var(--ink);
  background: #ffffff;
  line-height: 1.55;
}}
.page {{ max-width: 980px; margin: 0 auto; padding: 40px 32px 28px; }}
header {{ border-bottom: 4px solid var(--accent); padding-bottom: 22px; margin-bottom: 28px; }}
.brand {{ display: flex; align-items: center; gap: 14px; color: var(--muted); font-size: 14px; }}
.brand img {{ max-height: 42px; max-width: 160px; object-fit: contain; }}
h1 {{ margin: 16px 0 8px; font-size: 32px; line-height: 1.15; letter-spacing: 0; }}
.meta {{ color: var(--muted); font-size: 14px; }}
section {{ padding: 22px 0; border-bottom: 1px solid var(--line); }}
h2 {{ margin: 0 0 12px; font-size: 19px; letter-spacing: 0; }}
h3 {{ margin: 0 0 8px; font-size: 16px; letter-spacing: 0; }}
p {{ margin: 0 0 10px; }}
ul {{ margin: 0; padding-left: 22px; }}
li {{ margin: 0 0 8px; }}
table {{ width: 100%; border-collapse: collapse; margin-top: 8px; font-size: 14px; }}
th, td {{ border: 1px solid var(--line); padding: 10px; vertical-align: top; text-align: left; }}
th {{ width: 28%; background: var(--panel); }}
.finding {{ background: var(--panel); border-left: 4px solid var(--accent); padding: 14px 16px; margin: 0 0 12px; }}
.empty {{ color: var(--muted); font-style: italic; }}
figure {{ margin: 0 0 16px; padding: 12px; border: 1px solid var(--line); background: #fff; }}
figure img {{ max-width: 100%; height: auto; display: block; margin-bottom: 10px; }}
figcaption {{ color: var(--muted); font-size: 14px; }}
footer {{ padding-top: 20px; color: var(--muted); font-size: 12px; }}
@media print {{
  body {{ color: #000; }}
  .page {{ max-width: none; padding: 24px; }}
  section {{ break-inside: avoid; }}
}}
"""

logo_html = f'<img src="{esc(logo_uri)}" alt="{esc(org)} logo" />' if logo_uri else ""
audience_html = f" | Audience: {esc(audience)}" if audience else ""
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
    f'<div class="meta">Analysis ID: {esc(analysis_id)} | Generated: {esc(generated)}{audience_html}</div>',
    "</header>",
]
for label, content in sections:
    body.append(f"<section><h2>{esc(label)}</h2>{content}</section>")
body.extend([
    f"<footer>{esc(footer)}</footer>",
    "</main>",
    "</body>",
    "</html>",
])

with open(html_path, "w", encoding="utf-8") as f:
    f.write("\n".join(body))
    f.write("\n")
PY

pdf_note=""
pdf_path=""
SNAPSHOT="$OUT_DIR/metrics-$TIMESTAMP.json"
DRIFT_STATUS=""
DRIFT_SUMMARY=""
DRIFT_STATE=""
DIFF_PATH=""
DISTRIBUTION_MANIFEST=""
DISTRIBUTION_WITHHELD=""

want_pdf() {
  python3 - "$CONFIG" <<'PY'
import json
import re
import sys

def strip_jsonc(text):
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return "\n".join(line for line in text.splitlines() if not line.lstrip().startswith("//"))

try:
    data = json.loads(strip_jsonc(open(sys.argv[1], encoding="utf-8").read()))
except Exception:
    data = {}
report = data.get("report") if isinstance(data, dict) else {}
formats = report.get("outputFormats") if isinstance(report, dict) else None
if not isinstance(formats, list):
    raise SystemExit(0)
lower = {str(item).lower() for item in formats}
raise SystemExit(0 if "pdf" in lower else 1)
PY
}

render_pdf() {
  if [ "${ASSAY_REPORT_PDF_RENDERER:-}" = "none" ]; then
    return 1
  fi

  if command -v pandoc >/dev/null 2>&1; then
    if pandoc "$HTML" -o "$PDF" >/dev/null 2>&1 && [ -s "$PDF" ]; then
      pdf_path="$PDF"
      return 0
    fi
    rm -f "$PDF"
  fi

  if command -v wkhtmltopdf >/dev/null 2>&1; then
    if wkhtmltopdf "$HTML" "$PDF" >/dev/null 2>&1 && [ -s "$PDF" ]; then
      pdf_path="$PDF"
      return 0
    fi
    rm -f "$PDF"
  fi

  local chrome=""
  for candidate in \
    google-chrome \
    google-chrome-stable \
    chromium \
    chromium-browser \
    chrome \
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    "/Applications/Chromium.app/Contents/MacOS/Chromium"; do
    if command -v "$candidate" >/dev/null 2>&1; then
      chrome="$(command -v "$candidate")"
      break
    elif [ -x "$candidate" ]; then
      chrome="$candidate"
      break
    fi
  done

  if [ -n "$chrome" ]; then
    local abs_html
    abs_html="$(cd "$(dirname "$HTML")" && pwd)/$(basename "$HTML")"
    if "$chrome" --headless --disable-gpu --no-sandbox --print-to-pdf="$PDF" "file://$abs_html" >/dev/null 2>&1 && [ -s "$PDF" ]; then
      pdf_path="$PDF"
      return 0
    fi
    rm -f "$PDF"
  fi

  return 1
}

if want_pdf; then
  if render_pdf; then
    pdf_note="PDF renderer, meaning a tool that makes PDF files, found; PDF created."
  else
    pdf_note="No PDF renderer, meaning a tool that makes PDF files, was available. Open the HTML report and use print-to-PDF if a PDF is needed."
  fi
else
  pdf_note="PDF skipped because report.outputFormats does not include pdf. PDF means print-ready file for sharing."
fi

python3 - "$ID" "$TIMESTAMP" "$SOURCE" "$HTML" "$SNAPSHOT" <<'PY'
import json
import math
import re
import sys

analysis_id, timestamp, source_path, artifact_path, snapshot_path = sys.argv[1:6]

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

def metric_name(item, fallback):
    if isinstance(item, dict):
        for key in ("metric", "name", "label", "title"):
            value = item.get(key)
            if isinstance(value, str) and value.strip():
                return value.strip()
    return fallback

def add_metric(metrics, name, value):
    if not name:
        return
    if isinstance(value, dict):
        raw = value.get("value")
    else:
        raw = value
    parsed = number(raw)
    if parsed is not None:
        metrics[name] = parsed
    elif isinstance(raw, str) and raw.strip():
        metrics[name] = raw.strip()

def extract_metrics(data):
    metrics = {}
    raw = data.get("keyMetrics") or data.get("metrics")
    if isinstance(raw, dict):
        for key, value in raw.items():
            add_metric(metrics, str(key), value)
    elif isinstance(raw, list):
        for index, item in enumerate(raw, start=1):
            if isinstance(item, dict):
                add_metric(metrics, metric_name(item, f"metric-{index}"), item.get("value", item.get("result")))
            else:
                add_metric(metrics, f"metric-{index}", item)
    evidence = data.get("evidence")
    if isinstance(evidence, list):
        for item in evidence:
            if isinstance(item, dict) and any(k in item for k in ("metric", "value", "result")):
                add_metric(metrics, metric_name(item, ""), item.get("value", item.get("result", item.get("detail"))))
    return metrics

def extract_findings(data):
    raw = data.get("keyFindings") or data.get("findings") or []
    out = []
    if isinstance(raw, list):
        for item in raw:
            if isinstance(item, dict):
                title = str(item.get("title") or item.get("label") or "Finding").strip()
                detail = str(item.get("detail") or item.get("summary") or item.get("description") or "").strip()
                out.append(f"{title}: {detail}" if detail else title)
            elif str(item).strip():
                out.append(str(item).strip())
    return out

def extract_row_count(data):
    for key in ("rowCount", "rows", "recordCount"):
        value = data.get(key)
        parsed = number(value)
        if parsed is not None:
            return int(parsed)
    refresh = data.get("refresh") if isinstance(data.get("refresh"), dict) else {}
    parsed = number(refresh.get("rowCount"))
    if parsed is not None:
        return int(parsed)
    return None

data = load(source_path)
refresh = data.get("refresh") if isinstance(data.get("refresh"), dict) else {}
snapshot = {
    "schemaVersion": "assay-metrics-snapshot/v1",
    "analysisId": analysis_id,
    "timestamp": timestamp,
    "artifactType": "report",
    "artifactPath": artifact_path,
    "sourcePath": source_path,
    "audience": data.get("audience"),
    "cadence": data.get("cadence") or data.get("refreshCadence"),
    "rowCount": extract_row_count(data),
    "refreshOk": data.get("refreshOk", refresh.get("ok", True)),
    "rendererStatus": "ok",
    "metrics": extract_metrics(data),
    "findings": extract_findings(data),
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

python3 - "$ID" "$TIMESTAMP" "$SOURCE" "$HTML" "$pdf_path" "$pdf_note" "$SNAPSHOT" "$DIFF_PATH" "$DRIFT_STATUS" "$DRIFT_SUMMARY" "$DRIFT_STATE" "$DISTRIBUTION_MANIFEST" "$DISTRIBUTION_WITHHELD" > "$RECEIPT_PAYLOAD" <<'PY'
import json
import sys

analysis_id, timestamp, source, html_path, pdf_path, pdf_note, snapshot_path, diff_path, drift_status, drift_summary, drift_state, distribution_manifest, distribution_withheld = sys.argv[1:14]
paths = {"html": html_path}
if pdf_path:
    paths["pdf"] = pdf_path
payload = {
    "analysisId": analysis_id,
    "timestamp": timestamp,
    "paths": paths,
    "reportInput": source,
    "pdfNote": pdf_note,
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

printf 'assay-report-html:%s\n' "$HTML"
if [ -n "$pdf_path" ]; then
  printf 'assay-report-pdf:%s\n' "$pdf_path"
else
  printf 'assay-report-pdf-note:%s\n' "$pdf_note"
fi
printf 'assay-report-receipt:%s/%s-deliverable-receipt.json\n' "$(assay_config_path receiptsDir "${ASSAY_RECEIPTS_DIR:-}" ".assay/receipts" "$CONFIG")" "$ID"
