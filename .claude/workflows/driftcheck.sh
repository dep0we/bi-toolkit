#!/usr/bin/env bash
# driftcheck.sh - warning and blocking checks for recurring data-product runs.

set -euo pipefail

ID="${1:-}"
SNAPSHOT="${2:-}"
CONFIG="${3:-${ASSAY_CONFIG:-assay.config.jsonc}}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$SCRIPT_DIR/config.sh"

usage() {
  echo "driftcheck: usage: driftcheck.sh <analysis-id> <metrics-snapshot-json> [assay.config.jsonc]" >&2
  echo "driftcheck: drift means a metric moved beyond the allowed tolerance." >&2
  exit 2
}

[ -n "$ID" ] && [ -n "$SNAPSHOT" ] || usage

case "$ID" in
  *[!A-Za-z0-9._-]*|"")
    echo "driftcheck: analysis-id may use only letters, numbers, dot, underscore, and dash" >&2
    exit 2
    ;;
esac

[ -f "$SNAPSHOT" ] || { echo "driftcheck: snapshot file not found: $SNAPSHOT" >&2; exit 2; }

if ! command -v python3 >/dev/null 2>&1; then
  echo "driftcheck: requires python3 to compare metric values. Metric means a tracked business number." >&2
  exit 2
fi

DELIVERABLES_DIR="$(assay_config_path deliverablesDir "${ASSAY_DELIVERABLES_DIR:-}" ".assay/deliverables" "$CONFIG")"
RECEIPTS_DIR="$(assay_config_path receiptsDir "${ASSAY_RECEIPTS_DIR:-}" ".assay/receipts" "$CONFIG")"
OUT_DIR="$DELIVERABLES_DIR/$ID"
mkdir -p "$OUT_DIR"

python3 - "$ID" "$SNAPSHOT" "$CONFIG" "$RECEIPTS_DIR" "$OUT_DIR" <<'PY'
import json
import math
import os
import re
import sys
import tempfile

analysis_id, snapshot_path, config_path, receipts_dir, out_dir = sys.argv[1:6]
latest_path = os.path.join(out_dir, "latest.json")
state_path = os.path.join(out_dir, "latest-drift.json")

def fail(message):
    print(f"driftcheck: {message}", file=sys.stderr)
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
        fail(f"could not read JSON. JSON is a structured data file. {exc}")
    return data if isinstance(data, dict) else {}

def maybe_json(path):
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        return data if isinstance(data, dict) else None
    except Exception:
        return None

def load_jsonc(path):
    try:
        raw = open(path, encoding="utf-8").read()
    except FileNotFoundError:
        return {}
    try:
        data = json.loads(strip_jsonc(raw))
    except Exception:
        return {}
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
    if isinstance(value, dict):
        return number(value.get("value"))
    return None

def fmt(value):
    n = number(value)
    if n is None:
        return str(value)
    if abs(n) >= 100:
        return f"{n:,.0f}"
    if n.is_integer():
        return f"{n:.0f}"
    return f"{n:,.2f}".rstrip("0").rstrip(".")

def metrics(data):
    raw = data.get("metrics")
    if isinstance(raw, dict):
        return {str(k): v for k, v in raw.items()}
    return {}

def is_data_product(spec):
    track = str(spec.get("track") or "").strip().lower()
    return track in {"data-product", "data_product", "dataproduct"}

def tolerance_for(config, metric):
    monitoring = config.get("monitoring") if isinstance(config, dict) else {}
    if not isinstance(monitoring, dict):
        monitoring = {}
    default = monitoring.get("defaultTolerance", 0.1)
    per_metric = monitoring.get("metrics") or monitoring.get("perMetricTolerance") or {}
    value = per_metric.get(metric, default) if isinstance(per_metric, dict) else default
    mode = "relative"
    if isinstance(value, dict):
        mode = str(value.get("mode") or value.get("type") or mode).lower()
        value = value.get("tolerance", value.get("value", default))
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        value = 0.1
    if mode not in {"relative", "absolute"}:
        mode = "relative"
    return float(value), mode

current = load_json(snapshot_path)
config = load_jsonc(config_path)
spec = maybe_json(os.path.join(receipts_dir, f"{analysis_id}-spec-receipt.json")) or {}
timestamp = str(current.get("timestamp") or "").strip()
if not timestamp:
    fail("snapshot needs timestamp")

row_count = current.get("rowCount")
row_count_n = number(row_count)
refresh_ok = current.get("refreshOk")
renderer_status = str(current.get("rendererStatus") or "ok").lower()
data_product = is_data_product(spec)

status = "ok"
flags = []
blocks = []

if data_product:
    if refresh_ok is False or renderer_status in {"failed", "error"}:
        blocks.append("Refresh failed, meaning the recurring data did not update.")
    if row_count_n is not None and row_count_n <= 0:
        blocks.append("Refresh returned no rows, meaning the recurring data is empty.")

latest = maybe_json(latest_path)
previous = None
if latest and isinstance(latest.get("snapshotPath"), str):
    previous = maybe_json(latest["snapshotPath"])

if previous:
    prev_metrics = metrics(previous)
    curr_metrics = metrics(current)
    for name in sorted(set(prev_metrics) & set(curr_metrics)):
        old = number(prev_metrics[name])
        new = number(curr_metrics[name])
        if old is None or new is None:
            continue
        tolerance, mode = tolerance_for(config, name)
        delta = new - old
        moved = abs(delta)
        basis = abs(old)
        if mode == "absolute":
            over = moved > tolerance
            limit_text = fmt(tolerance)
            movement_text = fmt(moved)
        else:
            ratio = 0.0 if basis == 0 and moved == 0 else (math.inf if basis == 0 else moved / basis)
            over = ratio > tolerance
            limit_text = f"{tolerance * 100:.1f}%"
            movement_text = "infinite" if math.isinf(ratio) else f"{ratio * 100:.1f}%"
        if over:
            direction = "increased" if delta > 0 else "decreased"
            flags.append({
                "metric": name,
                "previous": old,
                "current": new,
                "direction": direction,
                "movement": movement_text,
                "tolerance": limit_text,
                "message": f"{name} {direction} from {fmt(old)} to {fmt(new)}, moving {movement_text} beyond tolerance (allowed movement before review) of {limit_text}.",
            })

if blocks:
    status = "blocked"
elif flags:
    status = "warning"
elif not previous:
    status = "first-run"

drift_path = os.path.join(out_dir, f"drift-{timestamp}.txt")
lines = [f"Drift check for {analysis_id}", ""]
if blocks:
    lines.append("BLOCK: delivery should stop for this data product.")
    for item in blocks:
        lines.append(f"- {item}")
elif flags:
    lines.append("WARNING: metric drift found. Drift means a metric moved beyond the allowed tolerance.")
    for item in flags:
        lines.append(f"- {item['message']}")
elif not previous:
    lines.append("First run: no prior run exists, so drift cannot be measured yet.")
else:
    lines.append("No drift flags found. Each tracked metric stayed within tolerance (allowed movement before review).")

with open(drift_path, "w", encoding="utf-8") as f:
    f.write("\n".join(lines).rstrip() + "\n")

state = {
    "schemaVersion": "assay-drift/v1",
    "analysisId": analysis_id,
    "timestamp": timestamp,
    "status": status,
    "driftPath": drift_path,
    "snapshotPath": snapshot_path,
    "flags": flags,
    "blocks": blocks,
    "rowCount": row_count,
}
fd, tmp = tempfile.mkstemp(prefix=".latest-drift.", suffix=".tmp", dir=out_dir)
try:
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        json.dump(state, f, indent=2)
        f.write("\n")
    os.replace(tmp, state_path)
except Exception:
    try:
        os.unlink(tmp)
    except OSError:
        pass
    raise

print(f"assay-drift-status:{status}")
print(f"assay-drift-summary:{drift_path}")
print(f"assay-drift-state:{state_path}")
if blocks:
    print("assay-gate-failed:broken-refresh")
    for item in blocks:
        print(f"driftcheck: {item}", file=sys.stderr)
    raise SystemExit(1)
PY
