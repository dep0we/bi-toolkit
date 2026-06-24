#!/usr/bin/env bash
# receipt.sh - write assay gate receipts in the exact format the gates read.

set -euo pipefail

KIND="${1:-}"
ID="${2:-}"
SOURCE="${3:-}"
RECEIPTS_DIR="${ASSAY_RECEIPTS_DIR:-.assay/receipts}"

usage() {
  echo "receipt.sh: usage: receipt.sh <spec|trivial|validation|adversarial-review|data-safety> <analysis-id> [json-file]" >&2
  echo "receipt.sh: pass JSON on stdin when no json-file is given. JSON is a structured data file." >&2
  exit 2
}

[ -n "$KIND" ] && [ -n "$ID" ] || usage

case "$ID" in
  *[!A-Za-z0-9._-]*|"")
    echo "receipt.sh: analysis-id may use only letters, numbers, dot, underscore, and dash" >&2
    exit 2
    ;;
esac

case "$KIND" in
  spec|trivial|validation|adversarial-review|data-safety) ;;
  *) usage ;;
esac

TMP_PAYLOAD=""
cleanup() {
  [ -n "$TMP_PAYLOAD" ] && rm -f "$TMP_PAYLOAD"
}
trap cleanup EXIT

if [ -z "$SOURCE" ] || [ "$SOURCE" = "-" ]; then
  TMP_PAYLOAD="$(mktemp "${TMPDIR:-/tmp}/assay-receipt.XXXXXX")"
  cat > "$TMP_PAYLOAD"
  SOURCE="$TMP_PAYLOAD"
fi

if command -v python3 >/dev/null 2>&1; then
  python3 - "$KIND" "$ID" "$RECEIPTS_DIR" "$SOURCE" <<'PY'
import json, os, sys, tempfile

kind, analysis_id, receipts_dir, source = sys.argv[1:5]

def fail(message):
    print(f"receipt.sh: {message}", file=sys.stderr)
    raise SystemExit(2)

try:
    raw = open(source, encoding="utf-8").read()
except Exception as exc:
    fail(f"could not read payload: {exc}")

if kind == "trivial" and not raw.lstrip().startswith("{"):
    data = {"reason": raw.strip()}
else:
    try:
        data = json.loads(raw)
    except Exception as exc:
        fail(f"payload is not readable JSON. JSON is a structured data file. {exc}")
    if not isinstance(data, dict):
        fail("payload must be a JSON object. A JSON object is key-value data.")

def require_text(obj, key):
    value = obj.get(key)
    if not isinstance(value, str) or not value.strip():
        fail(f"{kind} receipt needs '{key}'")

def clean_class(value):
    raw = str(value or "").strip()
    aliases = {
        "pii": "sensitive-PII",
        "sensitive-pii": "sensitive-PII",
        "phi": "sensitive-PHI",
        "sensitive-phi": "sensitive-PHI",
        "personal": "sensitive-PII",
        "health": "sensitive-PHI",
        "customer records": "customer",
        "customer-records": "customer",
        "non-sensitive": "none",
        "nonsensitive": "none",
    }
    return aliases.get(raw.lower(), raw)

def clean_detail(value):
    raw = str(value or "").strip().lower().replace("_", "-")
    aliases = {
        "row": "row-level",
        "row level": "row-level",
        "row-level": "row-level",
        "detail": "row-level",
        "detailed": "row-level",
        "aggregate": "aggregate",
        "aggregated": "aggregate",
        "summary": "aggregate",
    }
    return aliases.get(raw, raw)

def signed(value):
    if isinstance(value, str):
        return bool(value.strip())
    if isinstance(value, dict):
        return bool(str(value.get("signedBy") or value.get("operator") or "").strip())
    return False

if kind == "spec":
    out = dict(data)
    out["kind"] = "spec"
    for key in ("question", "metricDefinitions", "validAnswer"):
        if not out.get(key):
            fail("spec receipt needs question, metricDefinitions, and validAnswer")
    suffix = "spec-receipt"
elif kind == "trivial":
    reason = data.get("reason", "")
    if not isinstance(reason, str) or not reason.strip():
        fail("trivial receipt needs a one-line reason")
    out = {"kind": "trivial", "reason": reason.strip()}
    suffix = "spec-receipt"
elif kind == "validation":
    out = dict(data)
    out["kind"] = "validation"
    if not isinstance(out.get("reconciled"), bool):
        fail("validation receipt needs reconciled true or false")
    if not out.get("reconciliation"):
        fail("validation receipt needs reconciliation details")
    suffix = "validation-receipt"
elif kind == "adversarial-review":
    out = dict(data)
    out["kind"] = "adversarial-review"
    scores = out.get("scores")
    if not isinstance(scores, dict):
        fail("adversarial-review receipt needs scores")
    required = ("confidence", "dataCompleteness", "methodologySoundness", "reproducibility")
    for key in required:
        if not isinstance(scores.get(key), (int, float)):
            fail(f"adversarial-review score '{key}' must be a number")
    suffix = "adversarial-review-receipt"
else:
    out = dict(data)
    out["kind"] = "data-safety"
    classification = clean_class(out.get("dataClassification") or out.get("classification"))
    allowed = {"none", "internal", "sensitive-PII", "sensitive-PHI", "payroll", "customer"}
    if classification not in allowed:
        fail("data-safety receipt needs dataClassification: none, internal, sensitive-PII, sensitive-PHI, payroll, or customer")
    out["dataClassification"] = classification
    require_text(out, "deliveryAudience")
    if not isinstance(out.get("dataLeavesCompany"), bool):
        fail("data-safety receipt needs dataLeavesCompany true or false")
    if out["dataLeavesCompany"] is True:
        require_text(out, "exportDestination")
    elif not isinstance(out.get("exportDestination"), str):
        out["exportDestination"] = "none"
    detail = clean_detail(out.get("detailLevel") or out.get("sharingLevel"))
    if detail not in {"row-level", "aggregate"}:
        fail("data-safety receipt needs detailLevel row-level or aggregate")
    out["detailLevel"] = detail
    if not signed(out.get("operatorSignoff")):
        fail("data-safety receipt needs operatorSignoff")
    suffix = "data-safety-receipt"

os.makedirs(receipts_dir, exist_ok=True)
dest = os.path.join(receipts_dir, f"{analysis_id}-{suffix}.json")
fd, tmp = tempfile.mkstemp(prefix=f".{analysis_id}-{suffix}.", suffix=".tmp", dir=receipts_dir)
try:
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        json.dump(out, f, indent=2)
        f.write("\n")
    os.replace(tmp, dest)
except Exception:
    try:
        os.unlink(tmp)
    except OSError:
        pass
    raise

print(f"assay-receipt-written:{kind}:{dest}")
PY
elif command -v node >/dev/null 2>&1; then
  node - "$KIND" "$ID" "$RECEIPTS_DIR" "$SOURCE" <<'NODE'
const fs = require("fs");
const os = require("os");
const path = require("path");
const [kind, analysisId, receiptsDir, source] = process.argv.slice(2);

function fail(message) {
  console.error(`receipt.sh: ${message}`);
  process.exit(2);
}

let raw;
try {
  raw = fs.readFileSync(source, "utf8");
} catch (e) {
  fail(`could not read payload: ${e.message}`);
}

let data;
if (kind === "trivial" && !raw.trimStart().startsWith("{")) {
  data = { reason: raw.trim() };
} else {
  try {
    data = JSON.parse(raw);
  } catch (e) {
    fail(`payload is not readable JSON. JSON is a structured data file. ${e.message}`);
  }
  if (!data || Array.isArray(data) || typeof data !== "object") {
    fail("payload must be a JSON object. A JSON object is key-value data.");
  }
}

let out;
let suffix;
function cleanClass(value) {
  const raw = String(value || "").trim();
  const aliases = {
    pii: "sensitive-PII",
    "sensitive-pii": "sensitive-PII",
    phi: "sensitive-PHI",
    "sensitive-phi": "sensitive-PHI",
    personal: "sensitive-PII",
    health: "sensitive-PHI",
    "customer records": "customer",
    "customer-records": "customer",
    "non-sensitive": "none",
    nonsensitive: "none",
  };
  return aliases[raw.toLowerCase()] || raw;
}
function cleanDetail(value) {
  const raw = String(value || "").trim().toLowerCase().replace(/_/g, "-");
  const aliases = {
    row: "row-level",
    "row level": "row-level",
    "row-level": "row-level",
    detail: "row-level",
    detailed: "row-level",
    aggregate: "aggregate",
    aggregated: "aggregate",
    summary: "aggregate",
  };
  return aliases[raw] || raw;
}
function signed(value) {
  if (typeof value === "string") return Boolean(value.trim());
  if (value && typeof value === "object" && !Array.isArray(value)) return Boolean(String(value.signedBy || value.operator || "").trim());
  return false;
}

if (kind === "spec") {
  out = { ...data, kind: "spec" };
  if (!out.question || !out.metricDefinitions || !out.validAnswer) {
    fail("spec receipt needs question, metricDefinitions, and validAnswer");
  }
  suffix = "spec-receipt";
} else if (kind === "trivial") {
  if (typeof data.reason !== "string" || !data.reason.trim()) {
    fail("trivial receipt needs a one-line reason");
  }
  out = { kind: "trivial", reason: data.reason.trim() };
  suffix = "spec-receipt";
} else if (kind === "validation") {
  out = { ...data, kind: "validation" };
  if (typeof out.reconciled !== "boolean") fail("validation receipt needs reconciled true or false");
  if (!out.reconciliation) fail("validation receipt needs reconciliation details");
  suffix = "validation-receipt";
} else if (kind === "adversarial-review") {
  out = { ...data, kind: "adversarial-review" };
  const scores = out.scores;
  if (!scores || typeof scores !== "object" || Array.isArray(scores)) fail("adversarial-review receipt needs scores");
  for (const key of ["confidence", "dataCompleteness", "methodologySoundness", "reproducibility"]) {
    if (typeof scores[key] !== "number") fail(`adversarial-review score '${key}' must be a number`);
  }
  suffix = "adversarial-review-receipt";
} else {
  out = { ...data, kind: "data-safety" };
  const classification = cleanClass(out.dataClassification || out.classification);
  if (!["none", "internal", "sensitive-PII", "sensitive-PHI", "payroll", "customer"].includes(classification)) {
    fail("data-safety receipt needs dataClassification: none, internal, sensitive-PII, sensitive-PHI, payroll, or customer");
  }
  out.dataClassification = classification;
  if (typeof out.deliveryAudience !== "string" || !out.deliveryAudience.trim()) fail("data-safety receipt needs deliveryAudience");
  if (typeof out.dataLeavesCompany !== "boolean") fail("data-safety receipt needs dataLeavesCompany true or false");
  if (out.dataLeavesCompany === true && (typeof out.exportDestination !== "string" || !out.exportDestination.trim())) fail("data-safety receipt needs exportDestination");
  if (out.dataLeavesCompany === false && typeof out.exportDestination !== "string") out.exportDestination = "none";
  const detail = cleanDetail(out.detailLevel || out.sharingLevel);
  if (!["row-level", "aggregate"].includes(detail)) fail("data-safety receipt needs detailLevel row-level or aggregate");
  out.detailLevel = detail;
  if (!signed(out.operatorSignoff)) fail("data-safety receipt needs operatorSignoff");
  suffix = "data-safety-receipt";
}

fs.mkdirSync(receiptsDir, { recursive: true });
const dest = path.join(receiptsDir, `${analysisId}-${suffix}.json`);
const tmp = path.join(receiptsDir, `.${analysisId}-${suffix}.${process.pid}.${Date.now()}.tmp`);
fs.writeFileSync(tmp, `${JSON.stringify(out, null, 2)}\n`);
fs.renameSync(tmp, dest);
console.log(`assay-receipt-written:${kind}:${dest}`);
NODE
else
  echo "receipt.sh: requires python3 or node to write receipt files" >&2
  exit 2
fi
