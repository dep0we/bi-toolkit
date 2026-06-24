#!/usr/bin/env bash
# assay-active.sh - durable pointer to the current assay analysis.

set -euo pipefail

CMD="${1:-show}"
ID="${2:-}"
TRACK="${3:-analysis}"
ACTIVE_FILE="${ASSAY_ACTIVE_FILE:-.assay/active.json}"

usage() {
  echo "assay-active: usage: assay-active.sh <set|show|clear> [analysis-id] [analysis|data-product]" >&2
  echo "assay-active: active analysis means the saved work to resume first." >&2
  exit 2
}

valid_id() {
  case "$1" in
    *[!A-Za-z0-9._-]*|"") return 1 ;;
    *) return 0 ;;
  esac
}

clean_track() {
  case "$1" in
    analysis|"") printf '%s\n' "analysis" ;;
    data-product|data_product|dataproduct) printf '%s\n' "data-product" ;;
    *) return 1 ;;
  esac
}

case "$CMD" in
  set)
    valid_id "$ID" || {
      echo "assay-active: analysis-id may use only letters, numbers, dot, underscore, and dash" >&2
      exit 2
    }
    TRACK="$(clean_track "$TRACK")" || {
      echo "assay-active: track must be analysis or data-product" >&2
      exit 2
    }
    mkdir -p "$(dirname "$ACTIVE_FILE")"
    tmp="${ACTIVE_FILE}.tmp.$$"
    if command -v python3 >/dev/null 2>&1; then
      python3 - "$ID" "$TRACK" "$tmp" <<'PY'
import datetime
import json
import os
import sys

analysis_id, track, tmp = sys.argv[1:4]
data = {
    "schemaVersion": 1,
    "analysisId": analysis_id,
    "track": track,
    "updatedAt": datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z"),
}
with open(tmp, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
    else
      timestamp="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
      {
        printf '{\n'
        printf '  "schemaVersion": 1,\n'
        printf '  "analysisId": "%s",\n' "$ID"
        printf '  "track": "%s",\n' "$TRACK"
        printf '  "updatedAt": "%s"\n' "$timestamp"
        printf '}\n'
      } > "$tmp"
    fi
    mv -f "$tmp" "$ACTIVE_FILE"
    echo "assay-active-set:$ID:$TRACK"
    ;;
  show)
    if [ ! -f "$ACTIVE_FILE" ]; then
      echo "assay-active: no active analysis - run /assay status or /assay help"
      exit 0
    fi
    cat "$ACTIVE_FILE"
    ;;
  clear)
    if [ -n "$ID" ]; then
      valid_id "$ID" || {
        echo "assay-active: analysis-id may use only letters, numbers, dot, underscore, and dash" >&2
        exit 2
      }
    fi
    if [ ! -f "$ACTIVE_FILE" ]; then
      echo "assay-active-clear:none"
      exit 0
    fi
    if [ -n "$ID" ] && command -v python3 >/dev/null 2>&1; then
      active_id="$(python3 - "$ACTIVE_FILE" <<'PY' 2>/dev/null || true
import json
import sys
try:
    data = json.load(open(sys.argv[1], encoding="utf-8"))
    print(data.get("analysisId", ""))
except Exception:
    print("")
PY
)"
      if [ "$active_id" != "$ID" ]; then
        echo "assay-active-left:${active_id:-unknown}"
        exit 0
      fi
    elif [ -n "$ID" ] && ! grep -q "\"analysisId\"[[:space:]]*:[[:space:]]*\"$ID\"" "$ACTIVE_FILE" 2>/dev/null; then
      echo "assay-active-left:unknown"
      exit 0
    fi
    rm -f "$ACTIVE_FILE"
    echo "assay-active-clear:${ID:-active}"
    ;;
  *)
    usage
    ;;
esac
