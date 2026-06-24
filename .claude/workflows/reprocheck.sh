#!/usr/bin/env bash
# reprocheck.sh - optional reproducibility gate for assay delivery.

set -euo pipefail

ID="${1:-}"
CONFIG="${2:-assay.config.jsonc}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$SCRIPT_DIR/config.sh"
RECEIPTS_DIR="$(assay_config_path receiptsDir "${ASSAY_RECEIPTS_DIR:-}" ".assay/receipts" "$CONFIG")"

if [ -z "$ID" ]; then
  echo "reprocheck: usage: reprocheck.sh <analysis-id> [assay.config.jsonc]" >&2
  echo "reprocheck: reproducibility means re-running work gets the same answer." >&2
  exit 2
fi

case "$ID" in
  *[!A-Za-z0-9._-]*|"")
    echo "reprocheck: analysis-id may use only letters, numbers, dot, underscore, and dash" >&2
    exit 2
    ;;
esac

if ! command -v python3 >/dev/null 2>&1; then
  echo "reprocheck: requires python3 to read assay.config.jsonc. JSONC means JSON with comments." >&2
  exit 2
fi

python3 - "$ID" "$CONFIG" "$RECEIPTS_DIR" <<'PY'
import json
import os
import subprocess
import sys

analysis_id, config_path, receipts_dir = sys.argv[1:4]

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
            return json.load(f)
    except FileNotFoundError:
        return None
    except Exception as exc:
        print(f"reprocheck: receipt is not readable JSON. JSON is a structured data file. {exc}", file=sys.stderr)
        raise SystemExit(2)

def load_jsonc(path):
    try:
        raw = open(path, encoding="utf-8").read()
    except FileNotFoundError:
        return {}
    try:
        data = json.loads(strip_jsonc(raw))
    except Exception as exc:
        print(f"reprocheck: could not read {path}. JSONC means JSON with comments. {exc}", file=sys.stderr)
        raise SystemExit(2)
    if not isinstance(data, dict):
        print("reprocheck: config must be a JSON object. A JSON object is key-value data.", file=sys.stderr)
        raise SystemExit(2)
    return data

config = load_jsonc(config_path)
command = config.get("reproCommand")
spec = load_json(os.path.join(receipts_dir, f"{analysis_id}-spec-receipt.json")) or {}
track = str(spec.get("track", "")).strip().lower()
is_data_product = track in {"data-product", "data_product", "dataproduct"}

if command is None or (isinstance(command, str) and not command.strip()):
    print("reprocheck: NOTE - reproducibility unverified because reproCommand is unset. Reproducibility means re-running work gets the same answer.", file=sys.stderr)
    if is_data_product:
        print("reprocheck: WARNING - this is a data product, meaning a recurring report or dashboard. Recurring reports should set reproCommand so changed outputs block delivery.", file=sys.stderr)
    print("assay-gate-ok:reprocheck", file=sys.stderr)
    raise SystemExit(0)

if not isinstance(command, str):
    print("reprocheck: reproCommand must be a string command. A command is text the shell runs.", file=sys.stderr)
    raise SystemExit(2)

env = os.environ.copy()
env["ASSAY_ANALYSIS_ID"] = analysis_id
print(f"reprocheck: running reproCommand for {analysis_id}. Reproducibility means re-running work gets the same answer.", file=sys.stderr)
result = subprocess.run(command, shell=True, env=env)
if result.returncode != 0:
    print("assay-gate-failed:repro-command-failed")
    print("reprocheck: Delivery is blocked because reproCommand exited non-zero. Non-zero means the rerun found changed outputs or another failure.", file=sys.stderr)
    raise SystemExit(1)

print("assay-gate-ok:reprocheck", file=sys.stderr)
PY
