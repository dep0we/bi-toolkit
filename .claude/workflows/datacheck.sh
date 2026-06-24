#!/usr/bin/env bash
# datacheck.sh - data-safety gate for assay delivery.

set -euo pipefail

ID="${1:-}"
if [ -z "$ID" ]; then
  echo "datacheck: usage: datacheck.sh <analysis-id> [assay.config.jsonc]" >&2
  exit 2
fi

CONFIG="${2:-assay.config.jsonc}"
RECEIPTS_DIR="${ASSAY_RECEIPTS_DIR:-.assay/receipts}"
SPEC="$RECEIPTS_DIR/${ID}-spec-receipt.json"
DATA_SAFETY="$RECEIPTS_DIR/${ID}-data-safety-receipt.json"

gate() {
  local token="$1" message="$2"
  printf 'assay-gate-failed:%s\n' "$token"
  printf 'datacheck: %s\n' "$message" >&2
  exit 1
}

if command -v python3 >/dev/null 2>&1; then
  STATUS="$(python3 - "$SPEC" "$DATA_SAFETY" "$CONFIG" <<'PY' || true
import json
import re
import sys

spec_path, receipt_path, config_path = sys.argv[1:4]

ALLOWED = {"none", "internal", "sensitive-PII", "sensitive-PHI", "payroll", "customer"}
SENSITIVE = {"sensitive-PII", "sensitive-PHI", "payroll", "customer"}
UNKNOWN = {"", "unset", "unknown", "tbd", "todo", "null", "none-set"}

def load_json(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return None
    except Exception:
        print("invalid-json")
        raise SystemExit

def strip_jsonc(text):
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return "\n".join(line for line in text.splitlines() if not line.lstrip().startswith("//"))

def load_jsonc(path):
    try:
        text = open(path, encoding="utf-8").read()
    except FileNotFoundError:
        return {}
    try:
        return json.loads(strip_jsonc(text))
    except Exception:
        return {}

def text(value):
    return value if isinstance(value, str) else ""

def clean_class(value):
    if value is None:
        return ""
    raw = str(value).strip()
    aliases = {
        "pii": "sensitive-PII",
        "sensitive-pii": "sensitive-PII",
        "phi": "sensitive-PHI",
        "sensitive-phi": "sensitive-PHI",
        "personal": "sensitive-PII",
        "health": "sensitive-PHI",
        "customer-records": "customer",
        "customer records": "customer",
        "non-sensitive": "none",
        "nonsensitive": "none",
    }
    return aliases.get(raw.lower(), raw)

def normalize_detail(value):
    raw = str(value or "").strip().lower().replace("_", "-")
    aliases = {
        "row": "row-level",
        "row-level": "row-level",
        "row level": "row-level",
        "detail": "row-level",
        "detailed": "row-level",
        "aggregate": "aggregate",
        "aggregated": "aggregate",
        "summary": "aggregate",
    }
    return aliases.get(raw, raw)

def boolish(value):
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        raw = value.strip().lower()
        if raw in {"true", "yes", "y"}:
            return True
        if raw in {"false", "no", "n"}:
            return False
    return None

def sensitive_flag(value):
    if value is True:
        return True
    if isinstance(value, str):
        return value.strip().lower() in {"true", "yes", "sensitive", "pii", "phi", "payroll", "customer"}
    if isinstance(value, list):
        return any(sensitive_flag(v) for v in value)
    if isinstance(value, dict):
        for v in value.values():
            if sensitive_flag(v):
                return True
    return False

def any_sensitive_flags(*objects):
    keys = (
        "containsSensitiveData",
        "sensitiveData",
        "sensitive",
        "sensitiveFlags",
        "sensitiveDataFlags",
        "hasPII",
        "hasPHI",
        "hasPayroll",
        "hasCustomerRecords",
    )
    for obj in objects:
        if not isinstance(obj, dict):
            continue
        for key in keys:
            if key in obj and sensitive_flag(obj.get(key)):
                return True
    return False

def operator_signed(value):
    if isinstance(value, str):
        return bool(value.strip())
    if isinstance(value, dict):
        return bool(text(value.get("signedBy")).strip() or text(value.get("operator")).strip())
    return False

def configured_default(config):
    data_safety = config.get("dataSafety") if isinstance(config, dict) else {}
    if not isinstance(data_safety, dict):
        return ""
    return clean_class(data_safety.get("defaultClassification", ""))

def approved_destinations(config):
    data_safety = config.get("dataSafety") if isinstance(config, dict) else {}
    if not isinstance(data_safety, dict):
        return []
    values = data_safety.get("approvedExportDestinations", [])
    if not isinstance(values, list):
        return []
    return [str(v).strip().lower() for v in values if str(v).strip()]

config = load_jsonc(config_path)
spec = load_json(spec_path) or {}
receipt = load_json(receipt_path)

spec_kind = str(spec.get("kind", "")).lower()
if spec_kind == "trivial" and receipt is None:
    print("ok")
    raise SystemExit

spec_class = clean_class(
    spec.get("dataClassification")
    or spec.get("classification")
    or spec.get("dataSafetyClassification")
    or configured_default(config)
)
spec_has_sensitive = any_sensitive_flags(spec)

if receipt is None:
    if spec_class in SENSITIVE or spec_has_sensitive:
        print("missing-data-safety")
    elif spec_class in {"none", "internal"}:
        print("ok")
    elif str(spec_class).strip().lower() in UNKNOWN:
        print("unknown-classification")
    else:
        print("invalid-classification")
    raise SystemExit

if not isinstance(receipt, dict):
    print("invalid-data-safety")
    raise SystemExit
if receipt.get("kind") != "data-safety":
    print("invalid-data-safety")
    raise SystemExit

classification = clean_class(receipt.get("dataClassification") or receipt.get("classification"))
if classification not in ALLOWED:
    print("invalid-classification")
    raise SystemExit

receipt_has_sensitive = any_sensitive_flags(receipt)
if classification in {"none", "internal"} and receipt_has_sensitive:
    print("sensitive-flag-without-classification")
    raise SystemExit
if classification in {"none", "internal"} and spec_has_sensitive:
    print("sensitive-flag-without-classification")
    raise SystemExit

audience = text(receipt.get("deliveryAudience")).strip()
leaves = boolish(receipt.get("dataLeavesCompany"))
destination = text(receipt.get("exportDestination")).strip()
detail = normalize_detail(receipt.get("detailLevel") or receipt.get("sharingLevel"))
signed = operator_signed(receipt.get("operatorSignoff"))

if not audience or leaves is None or detail not in {"row-level", "aggregate"} or not signed:
    print("incomplete-data-safety")
    raise SystemExit
if leaves and not destination:
    print("incomplete-data-safety")
    raise SystemExit
if leaves:
    approved = approved_destinations(config)
    if not approved or destination.lower() not in approved:
        print("unapproved-export-destination")
        raise SystemExit

if classification in SENSITIVE:
    print("ok")
elif classification in {"none", "internal"}:
    print("ok")
else:
    print("invalid-classification")
PY
)"
elif command -v node >/dev/null 2>&1; then
  STATUS="$(node - "$SPEC" "$DATA_SAFETY" "$CONFIG" <<'NODE' || true
const fs = require("fs");
const [specPath, receiptPath, configPath] = process.argv.slice(2);
const allowed = new Set(["none", "internal", "sensitive-PII", "sensitive-PHI", "payroll", "customer"]);
const sensitive = new Set(["sensitive-PII", "sensitive-PHI", "payroll", "customer"]);
const unknown = new Set(["", "unset", "unknown", "tbd", "todo", "null", "none-set"]);

function load(path) {
  try { return JSON.parse(fs.readFileSync(path, "utf8")); }
  catch (e) {
    if (e.code === "ENOENT") return null;
    console.log("invalid-json"); process.exit(0);
  }
}
function stripJsonc(text) {
  text = text.replace(/\/\*[\s\S]*?\*\//g, "");
  return text.split("\n").filter((line) => !line.trimStart().startsWith("//")).join("\n");
}
function loadJsonc(path) {
  try { return JSON.parse(stripJsonc(fs.readFileSync(path, "utf8"))); }
  catch { return {}; }
}
function cleanClass(value) {
  if (value === undefined || value === null) return "";
  const raw = String(value).trim();
  const aliases = {
    pii: "sensitive-PII",
    "sensitive-pii": "sensitive-PII",
    phi: "sensitive-PHI",
    "sensitive-phi": "sensitive-PHI",
    personal: "sensitive-PII",
    health: "sensitive-PHI",
    "customer-records": "customer",
    "customer records": "customer",
    "non-sensitive": "none",
    nonsensitive: "none",
  };
  return aliases[raw.toLowerCase()] || raw;
}
function normalizeDetail(value) {
  const raw = String(value || "").trim().toLowerCase().replace(/_/g, "-");
  const aliases = {
    row: "row-level",
    "row-level": "row-level",
    "row level": "row-level",
    detail: "row-level",
    detailed: "row-level",
    aggregate: "aggregate",
    aggregated: "aggregate",
    summary: "aggregate",
  };
  return aliases[raw] || raw;
}
function boolish(value) {
  if (typeof value === "boolean") return value;
  if (typeof value === "string") {
    const raw = value.trim().toLowerCase();
    if (["true", "yes", "y"].includes(raw)) return true;
    if (["false", "no", "n"].includes(raw)) return false;
  }
  return null;
}
function sensitiveFlag(value) {
  if (value === true) return true;
  if (typeof value === "string") return ["true", "yes", "sensitive", "pii", "phi", "payroll", "customer"].includes(value.trim().toLowerCase());
  if (Array.isArray(value)) return value.some(sensitiveFlag);
  if (value && typeof value === "object") return Object.values(value).some(sensitiveFlag);
  return false;
}
function anySensitiveFlags(...objects) {
  const keys = ["containsSensitiveData", "sensitiveData", "sensitive", "sensitiveFlags", "sensitiveDataFlags", "hasPII", "hasPHI", "hasPayroll", "hasCustomerRecords"];
  for (const obj of objects) {
    if (!obj || typeof obj !== "object" || Array.isArray(obj)) continue;
    for (const key of keys) if (Object.prototype.hasOwnProperty.call(obj, key) && sensitiveFlag(obj[key])) return true;
  }
  return false;
}
function operatorSigned(value) {
  if (typeof value === "string") return Boolean(value.trim());
  if (value && typeof value === "object" && !Array.isArray(value)) return Boolean(String(value.signedBy || value.operator || "").trim());
  return false;
}
function configuredDefault(config) {
  const dataSafety = config && typeof config === "object" ? config.dataSafety : {};
  return cleanClass(dataSafety && typeof dataSafety === "object" ? dataSafety.defaultClassification : "");
}
function approvedDestinations(config) {
  const dataSafety = config && typeof config === "object" ? config.dataSafety : {};
  const values = dataSafety && typeof dataSafety === "object" ? dataSafety.approvedExportDestinations : [];
  return Array.isArray(values) ? values.map((v) => String(v).trim().toLowerCase()).filter(Boolean) : [];
}

const config = loadJsonc(configPath);
const spec = load(specPath) || {};
const receipt = load(receiptPath);
const specKind = String(spec.kind || "").toLowerCase();
if (specKind === "trivial" && !receipt) { console.log("ok"); process.exit(0); }

const specClass = cleanClass(spec.dataClassification || spec.classification || spec.dataSafetyClassification || configuredDefault(config));
const specHasSensitive = anySensitiveFlags(spec);
if (!receipt) {
  if (sensitive.has(specClass) || specHasSensitive) console.log("missing-data-safety");
  else if (["none", "internal"].includes(specClass)) console.log("ok");
  else if (unknown.has(String(specClass).trim().toLowerCase())) console.log("unknown-classification");
  else console.log("invalid-classification");
  process.exit(0);
}

if (!receipt || Array.isArray(receipt) || typeof receipt !== "object" || receipt.kind !== "data-safety") { console.log("invalid-data-safety"); process.exit(0); }
const classification = cleanClass(receipt.dataClassification || receipt.classification);
if (!allowed.has(classification)) { console.log("invalid-classification"); process.exit(0); }
if ((["none", "internal"].includes(classification) && anySensitiveFlags(receipt)) || anySensitiveFlags(spec)) {
  if (["none", "internal"].includes(classification)) { console.log("sensitive-flag-without-classification"); process.exit(0); }
}
const audience = String(receipt.deliveryAudience || "").trim();
const leaves = boolish(receipt.dataLeavesCompany);
const destination = String(receipt.exportDestination || "").trim();
const detail = normalizeDetail(receipt.detailLevel || receipt.sharingLevel);
const signed = operatorSigned(receipt.operatorSignoff);
if (!audience || leaves === null || !["row-level", "aggregate"].includes(detail) || !signed) { console.log("incomplete-data-safety"); process.exit(0); }
if (leaves && !destination) { console.log("incomplete-data-safety"); process.exit(0); }
if (leaves) {
  const approved = approvedDestinations(config);
  if (!approved.length || !approved.includes(destination.toLowerCase())) { console.log("unapproved-export-destination"); process.exit(0); }
}
console.log("ok");
NODE
)"
else
  echo "datacheck: requires python3 or node to read receipt files" >&2
  exit 2
fi

case "$STATUS" in
  ok)
    printf 'assay-gate-ok:datacheck\n' >&2
    exit 0
    ;;
  missing-data-safety)
    gate "missing-data-safety" "Delivery is blocked because this work touches sensitive data, meaning personal, health, payroll, or customer records, but no data-safety receipt exists. Record the audience, handling, export destination, detail level, and operator sign-off before delivering."
    ;;
  unknown-classification)
    gate "unknown-classification" "Delivery is blocked because the data classification is unset. Classification means how sensitive the data is. Choose none, internal, sensitive-PII (personal identifying info), sensitive-PHI (health info), payroll, or customer before delivering."
    ;;
  invalid-classification)
    gate "invalid-classification" "Delivery is blocked because the data classification is not recognized. Use none, internal, sensitive-PII (personal identifying info), sensitive-PHI (health info), payroll, or customer."
    ;;
  sensitive-flag-without-classification)
    gate "sensitive-flag-without-classification" "Delivery is blocked because sensitive-data flags are present, but the classification says none or internal. Sensitive data means personal, health, payroll, or customer records. Reclassify the work and record handling."
    ;;
  incomplete-data-safety)
    gate "incomplete-data-safety" "Delivery is blocked because the data-safety receipt is missing audience, handling, export destination, detail level, or operator sign-off. Audience means who will receive the answer. Detail level means row-level records or aggregate summary."
    ;;
  unapproved-export-destination)
    gate "unapproved-export-destination" "Delivery is blocked because data leaves the company, but the export destination is not approved in dataSafety.approvedExportDestinations. Export destination means where the data is sent."
    ;;
  invalid-json|invalid-data-safety)
    gate "invalid-data-safety" "Delivery is blocked because the data-safety receipt is not readable. A receipt is a saved proof file, and JSON is a structured data file."
    ;;
  *)
    gate "invalid-data-safety" "Delivery is blocked because the data-safety gate could not understand the receipt files."
    ;;
esac
