#!/usr/bin/env bash
# metric-store.sh - read and update the assay living metric catalog.

set -euo pipefail

SUBCOMMAND="${1:-}"
CONFIG="${ASSAY_CONFIG:-assay.config.jsonc}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$SCRIPT_DIR/config.sh"
CATALOG_PATH="$(assay_config_path metricCatalogPath "${ASSAY_METRIC_CATALOG:-}" "metric-catalog.json" "$CONFIG")"

usage() {
  cat >&2 <<'USAGE'
metric-store.sh: usage:
  metric-store.sh add <name> <definition> <sourceOfTruth> <owner> <format> [notes]
  metric-store.sh get <name>
  metric-store.sh list
  metric-store.sh check <name> <definition>

Metric catalog means the shared metric definition file. Source-of-truth means
the official place to compare a metric.
USAGE
  exit 2
}

[ -n "$SUBCOMMAND" ] || usage

need_python() {
  if command -v python3 >/dev/null 2>&1; then
    echo python3
  else
    echo "metric-store: python3 is required to read JSON. JSON is structured data." >&2
    exit 2
  fi
}

RUNNER="$(need_python)"

case "$SUBCOMMAND" in
  add)
    shift
    [ "$#" -ge 5 ] || usage
    "$RUNNER" - "$CATALOG_PATH" "$CONFIG" "$@" <<'PY'
import json
import os
import re
import sys
import tempfile
from datetime import datetime, timezone

catalog_path, config_path = sys.argv[1:3]
name, definition, source_of_truth, owner, fmt = sys.argv[3:8]
notes = sys.argv[8] if len(sys.argv) > 8 else ""

def fail(message):
    print(f"metric-store: {message}", file=sys.stderr)
    raise SystemExit(2)

def strip_jsonc(text):
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return "\n".join(line for line in text.splitlines() if not line.lstrip().startswith("//"))

def load_json(path):
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
    except FileNotFoundError:
        data = {
            "schemaVersion": "metric-catalog/v1",
            "schema": {
                "description": "Living metric catalog. Living means the shared definition is updated as the team learns.",
                "metrics": {
                    "<metric_name>": {
                        "name": "Human-readable metric name.",
                        "definition": "Exact calculation rule, including numerator, denominator, filters, time window, and edge cases.",
                        "sourceOfTruth": "Official system, report, or table used to verify this metric.",
                        "owner": "Person or team accountable for approving definition changes.",
                        "format": "Unit or display format, such as USD, percent, count, days, or ratio.",
                        "notes": "Optional context, caveats, approval notes, or related dashboard links.",
                        "createdAt": "ISO-8601 timestamp written when the metric is first added.",
                        "updatedAt": "ISO-8601 timestamp written when the metric is last changed."
                    }
                }
            },
            "metrics": {},
        }
    except Exception as exc:
        fail(f"catalog is not readable JSON. JSON is structured data. {exc}")
    if not isinstance(data, dict):
        fail("catalog must be a JSON object. A JSON object is key-value data.")
    metrics = data.setdefault("metrics", {})
    if not isinstance(metrics, dict):
        fail("catalog metrics must be a JSON object. A JSON object is key-value data.")
    data.setdefault("schemaVersion", "metric-catalog/v1")
    return data

def load_config_source(path):
    try:
        raw = open(path, encoding="utf-8").read()
        data = json.loads(strip_jsonc(raw))
    except Exception:
        return None
    if not isinstance(data, dict):
        return None
    source_map = data.get("sourceOfTruth")
    return source_map if isinstance(source_map, dict) else None

def key_for(value):
    key = re.sub(r"[^A-Za-z0-9._-]+", "_", value.strip().lower()).strip("_")
    return key or "metric"

fields = {
    "name": name.strip(),
    "definition": definition.strip(),
    "sourceOfTruth": source_of_truth.strip(),
    "owner": owner.strip(),
    "format": fmt.strip(),
    "notes": notes.strip(),
}
for field, value in fields.items():
    if field != "notes" and not value:
        fail(f"add needs {field}")

catalog = load_json(catalog_path)
metrics = catalog["metrics"]
metric_key = key_for(fields["name"])
existing = metrics.get(metric_key)
now = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
created_at = existing.get("createdAt") if isinstance(existing, dict) and isinstance(existing.get("createdAt"), str) else now
metrics[metric_key] = {
    **fields,
    "createdAt": created_at,
    "updatedAt": now,
}

directory = os.path.dirname(catalog_path) or "."
os.makedirs(directory, exist_ok=True)
fd, tmp = tempfile.mkstemp(prefix=f".{os.path.basename(catalog_path)}.", suffix=".tmp", dir=directory)
try:
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        json.dump(catalog, f, indent=2)
        f.write("\n")
    os.replace(tmp, catalog_path)
except Exception:
    try:
        os.unlink(tmp)
    except OSError:
        pass
    raise

source_map = load_config_source(config_path)
if source_map:
    config_source = source_map.get(metric_key) or source_map.get(fields["name"])
    if isinstance(config_source, str) and config_source.strip() and config_source.strip() != fields["sourceOfTruth"]:
        print(f"metric-store: warning: config sourceOfTruth differs for {metric_key}", file=sys.stderr)
        print(f"metric-store: config sourceOfTruth is '{config_source.strip()}'", file=sys.stderr)
        print(f"metric-store: catalog sourceOfTruth is '{fields['sourceOfTruth']}'", file=sys.stderr)

action = "updated" if isinstance(existing, dict) else "added"
print(f"metric-store:{action}:{metric_key}:{catalog_path}")
PY
    ;;
  get)
    shift
    [ "$#" -eq 1 ] || usage
    "$RUNNER" - "$CATALOG_PATH" "$1" <<'PY'
import json
import re
import sys

catalog_path, name = sys.argv[1:3]

def key_for(value):
    return re.sub(r"[^A-Za-z0-9._-]+", "_", value.strip().lower()).strip("_") or "metric"

try:
    data = json.load(open(catalog_path, encoding="utf-8"))
except FileNotFoundError:
    print(f"metric-store:not-found:{key_for(name)}")
    raise SystemExit(1)
except Exception as exc:
    print(f"metric-store: catalog is not readable JSON. JSON is structured data. {exc}", file=sys.stderr)
    raise SystemExit(2)
metrics = data.get("metrics") if isinstance(data, dict) else None
metric = metrics.get(key_for(name)) if isinstance(metrics, dict) else None
if not isinstance(metric, dict):
    print(f"metric-store:not-found:{key_for(name)}")
    raise SystemExit(1)
print(json.dumps(metric, indent=2))
PY
    ;;
  list)
    shift
    [ "$#" -eq 0 ] || usage
    "$RUNNER" - "$CATALOG_PATH" <<'PY'
import json
import sys

catalog_path = sys.argv[1]
try:
    data = json.load(open(catalog_path, encoding="utf-8"))
except FileNotFoundError:
    print("metric-store: no metrics found")
    raise SystemExit(0)
except Exception as exc:
    print(f"metric-store: catalog is not readable JSON. JSON is structured data. {exc}", file=sys.stderr)
    raise SystemExit(2)
metrics = data.get("metrics") if isinstance(data, dict) else None
if not isinstance(metrics, dict) or not metrics:
    print("metric-store: no metrics found")
    raise SystemExit(0)
for key in sorted(metrics):
    metric = metrics[key]
    if isinstance(metric, dict):
        source = metric.get("sourceOfTruth") or "unknown source"
        owner = metric.get("owner") or "unknown owner"
        print(f"{key}\t{metric.get('name', key)}\t{source}\t{owner}")
PY
    ;;
  check)
    shift
    [ "$#" -eq 2 ] || usage
    "$RUNNER" - "$CATALOG_PATH" "$1" "$2" <<'PY'
import json
import re
import sys

catalog_path, name, proposed = sys.argv[1:4]

def key_for(value):
    return re.sub(r"[^A-Za-z0-9._-]+", "_", value.strip().lower()).strip("_") or "metric"

def normalize(value):
    return re.sub(r"\s+", " ", str(value or "").strip()).casefold()

metric_key = key_for(name)
try:
    data = json.load(open(catalog_path, encoding="utf-8"))
except FileNotFoundError:
    print(f"metric-store:not-found:{metric_key}")
    raise SystemExit(2)
except Exception as exc:
    print(f"metric-store: catalog is not readable JSON. JSON is structured data. {exc}", file=sys.stderr)
    raise SystemExit(2)
metrics = data.get("metrics") if isinstance(data, dict) else None
metric = metrics.get(metric_key) if isinstance(metrics, dict) else None
if not isinstance(metric, dict):
    print(f"metric-store:not-found:{metric_key}")
    raise SystemExit(2)
catalog_definition = metric.get("definition", "")
if normalize(catalog_definition) == normalize(proposed):
    print(f"metric-store:match:{metric_key}")
    raise SystemExit(0)
print(f"metric-store:differs:{metric_key}")
print(f"catalog-definition: {catalog_definition}")
print(f"proposed-definition: {proposed}")
raise SystemExit(1)
PY
    ;;
  *)
    usage
    ;;
esac
