#!/usr/bin/env bash
# questioncheck.sh - front gate for the assay loop.

set -euo pipefail

ID="${1:-}"
if [ -z "$ID" ]; then
  echo "questioncheck: usage: questioncheck.sh <analysis-id>" >&2
  exit 2
fi

RECEIPTS_DIR="${ASSAY_RECEIPTS_DIR:-.assay/receipts}"
RECEIPT="$RECEIPTS_DIR/${ID}-spec-receipt.json"

gate() {
  local token="$1" message="$2"
  printf 'assay-gate-failed:%s\n' "$token"
  printf 'questioncheck: %s\n' "$message" >&2
  exit 1
}

if [ ! -f "$RECEIPT" ]; then
  gate "missing-spec" "Stage 6 is blocked because no Stage 2 spec receipt exists. Create ${RECEIPT} with the question, metric definitions, and what a valid answer looks like. A receipt is a saved proof file."
fi

if command -v python3 >/dev/null 2>&1; then
  STATUS="$(python3 - "$RECEIPT" <<'PY' || true
import json, sys
path = sys.argv[1]
try:
    data = json.load(open(path, encoding="utf-8"))
except Exception:
    print("invalid-json")
    raise SystemExit

kind = data.get("kind")
if kind == "trivial":
    reason = data.get("reason")
    print("ok" if isinstance(reason, str) and reason.strip() else "missing-reason")
elif kind == "spec":
    required = ["question", "metricDefinitions", "validAnswer"]
    missing = [k for k in required if not data.get(k)]
    print("ok" if not missing else "incomplete-spec")
else:
    print("bad-kind")
PY
)"
elif command -v node >/dev/null 2>&1; then
  STATUS="$(node - "$RECEIPT" <<'NODE' || true
const fs = require("fs");
let data;
try { data = JSON.parse(fs.readFileSync(process.argv[2], "utf8")); }
catch { console.log("invalid-json"); process.exit(0); }
if (data.kind === "trivial") {
  console.log(typeof data.reason === "string" && data.reason.trim() ? "ok" : "missing-reason");
} else if (data.kind === "spec") {
  const required = ["question", "metricDefinitions", "validAnswer"];
  console.log(required.every((k) => data[k]) ? "ok" : "incomplete-spec");
} else {
  console.log("bad-kind");
}
NODE
)"
else
  echo "questioncheck: requires python3 or node to read the spec receipt" >&2
  exit 2
fi

case "$STATUS" in
  ok)
    printf 'assay-gate-ok:questioncheck\n' >&2
    exit 0
    ;;
  invalid-json)
    gate "invalid-spec" "The spec receipt is not readable JSON. JSON is a structured data file. Recreate ${RECEIPT}."
    ;;
  incomplete-spec)
    gate "incomplete-spec" "The spec receipt is missing the question, metric definitions, or valid-answer rule. Metric definitions are exact calculation rules."
    ;;
  missing-reason)
    gate "incomplete-spec" "The trivial spec receipt needs a one-line reason, so the skip is explicit and visible."
    ;;
  *)
    gate "invalid-spec" "The spec receipt must have kind 'spec' or 'trivial'."
    ;;
esac
