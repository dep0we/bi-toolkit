#!/usr/bin/env bash
# deliverable-diff.sh - compare this deliverable run to the prior run.

set -euo pipefail

ID="${1:-}"
SNAPSHOT="${2:-}"
ARTIFACT="${3:-}"
CONFIG="${4:-${ASSAY_CONFIG:-assay.config.jsonc}}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$SCRIPT_DIR/config.sh"

usage() {
  echo "deliverable-diff: usage: deliverable-diff.sh <analysis-id> <metrics-snapshot-json> <artifact-path> [assay.config.jsonc]" >&2
  echo "deliverable-diff: metrics snapshot means saved key numbers from one run." >&2
  exit 2
}

[ -n "$ID" ] && [ -n "$SNAPSHOT" ] && [ -n "$ARTIFACT" ] || usage

case "$ID" in
  *[!A-Za-z0-9._-]*|"")
    echo "deliverable-diff: analysis-id may use only letters, numbers, dot, underscore, and dash" >&2
    exit 2
    ;;
esac

[ -f "$SNAPSHOT" ] || { echo "deliverable-diff: snapshot file not found: $SNAPSHOT" >&2; exit 2; }

if ! command -v python3 >/dev/null 2>&1; then
  echo "deliverable-diff: requires python3 to compare snapshots. Snapshot means saved key numbers from one run." >&2
  exit 2
fi

DELIVERABLES_DIR="$(assay_config_path deliverablesDir "${ASSAY_DELIVERABLES_DIR:-}" ".assay/deliverables" "$CONFIG")"
OUT_DIR="$DELIVERABLES_DIR/$ID"
mkdir -p "$OUT_DIR"

python3 - "$ID" "$SNAPSHOT" "$ARTIFACT" "$OUT_DIR" <<'PY'
import json
import math
import os
import sys
import tempfile

analysis_id, snapshot_path, artifact_path, out_dir = sys.argv[1:5]
latest_path = os.path.join(out_dir, "latest.json")

def fail(message):
    print(f"deliverable-diff: {message}", file=sys.stderr)
    raise SystemExit(2)

def load_json(path):
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
    except Exception as exc:
        fail(f"could not read JSON. JSON is a structured data file. {exc}")
    if not isinstance(data, dict):
        fail("snapshot must be a JSON object. A JSON object is key-value data.")
    return data

def maybe_load(path):
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        return data if isinstance(data, dict) else None
    except Exception:
        return None

def metrics(data):
    raw = data.get("metrics")
    if isinstance(raw, dict):
        return {str(k): v for k, v in raw.items()}
    return {}

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

def finding_texts(data):
    values = data.get("findings")
    if not isinstance(values, list):
        return []
    out = []
    for item in values:
        text = str(item).strip()
        if text:
            out.append(text)
    return out

current = load_json(snapshot_path)
timestamp = str(current.get("timestamp") or "").strip()
if not timestamp:
    fail("snapshot needs timestamp")

previous = None
latest = maybe_load(latest_path)
if latest:
    previous_snapshot = latest.get("snapshotPath")
    if isinstance(previous_snapshot, str) and previous_snapshot.strip():
        previous = maybe_load(previous_snapshot)

diff_path = os.path.join(out_dir, f"diff-{timestamp}.txt")
lines = [
    f"What changed since last run for {analysis_id}",
    "",
]

if not previous:
    lines.extend([
        "First run: no prior deliverable was found, so there is nothing to compare yet.",
        "The latest pointer now records this run for the next comparison.",
    ])
else:
    prev_metrics = metrics(previous)
    curr_metrics = metrics(current)
    all_names = sorted(set(prev_metrics) | set(curr_metrics))
    metric_lines = []
    for name in all_names:
        old = prev_metrics.get(name)
        new = curr_metrics.get(name)
        if name not in prev_metrics:
            metric_lines.append(f"- {name}: new metric at {fmt(new)}.")
            continue
        if name not in curr_metrics:
            metric_lines.append(f"- {name}: metric was removed; prior value was {fmt(old)}.")
            continue
        old_n = number(old)
        new_n = number(new)
        if old_n is not None and new_n is not None:
            delta = new_n - old_n
            if delta == 0:
                metric_lines.append(f"- {name}: unchanged at {fmt(new_n)}.")
            else:
                direction = "increased" if delta > 0 else "decreased"
                pct = ""
                if old_n != 0:
                    pct = f" ({abs(delta) / abs(old_n) * 100:.1f}% change)"
                metric_lines.append(f"- {name}: {direction} from {fmt(old_n)} to {fmt(new_n)}; change {fmt(abs(delta))}{pct}.")
        elif old != new:
            metric_lines.append(f"- {name}: changed from {fmt(old)} to {fmt(new)}.")
        else:
            metric_lines.append(f"- {name}: unchanged at {fmt(new)}.")

    if metric_lines:
        lines.append("Key metrics (main numbers watched for decisions):")
        lines.extend(metric_lines)
    else:
        lines.append("Key metrics (main numbers watched for decisions): no key metrics were recorded in either run.")

    prev_findings = set(finding_texts(previous))
    curr_findings = set(finding_texts(current))
    added = sorted(curr_findings - prev_findings)
    removed = sorted(prev_findings - curr_findings)
    lines.append("")
    lines.append("Findings (plain-language takeaways):")
    if not added and not removed:
        lines.append("- No finding title changes were detected.")
    for item in added:
        lines.append(f"- New: {item}")
    for item in removed:
        lines.append(f"- Removed: {item}")

with open(diff_path, "w", encoding="utf-8") as f:
    f.write("\n".join(lines).rstrip() + "\n")

pointer = {
    "schemaVersion": "assay-deliverable-latest/v1",
    "analysisId": analysis_id,
    "timestamp": timestamp,
    "artifactPath": artifact_path,
    "snapshotPath": snapshot_path,
    "diffPath": diff_path,
}
fd, tmp = tempfile.mkstemp(prefix=".latest.", suffix=".tmp", dir=out_dir)
try:
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        json.dump(pointer, f, indent=2)
        f.write("\n")
    os.replace(tmp, latest_path)
except Exception:
    try:
        os.unlink(tmp)
    except OSError:
        pass
    raise

print(f"assay-deliverable-diff:{diff_path}")
print(f"assay-deliverable-latest:{latest_path}")
PY
