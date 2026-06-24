#!/usr/bin/env bash
# distribution-manifest.sh - write a local ready-to-send handoff manifest.

set -euo pipefail

ID="${1:-}"
ARTIFACT="${2:-}"
TIMESTAMP="${3:-}"
SNAPSHOT="${4:-}"
CONFIG="${5:-${ASSAY_CONFIG:-assay.config.jsonc}}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$SCRIPT_DIR/config.sh"

usage() {
  echo "distribution-manifest: usage: distribution-manifest.sh <analysis-id> <artifact-path> <timestamp> <metrics-snapshot-json> [assay.config.jsonc]" >&2
  echo "distribution-manifest: manifest means a ready-to-send local handoff file." >&2
  exit 2
}

[ -n "$ID" ] && [ -n "$ARTIFACT" ] && [ -n "$TIMESTAMP" ] && [ -n "$SNAPSHOT" ] || usage

case "$ID" in
  *[!A-Za-z0-9._-]*|"")
    echo "distribution-manifest: analysis-id may use only letters, numbers, dot, underscore, and dash" >&2
    exit 2
    ;;
esac

if ! command -v python3 >/dev/null 2>&1; then
  echo "distribution-manifest: requires python3 to write JSON. JSON is a structured data file." >&2
  exit 2
fi

DELIVERABLES_DIR="$(assay_config_path deliverablesDir "${ASSAY_DELIVERABLES_DIR:-}" ".assay/deliverables" "$CONFIG")"
RECEIPTS_DIR="$(assay_config_path receiptsDir "${ASSAY_RECEIPTS_DIR:-}" ".assay/receipts" "$CONFIG")"
OUT_DIR="$DELIVERABLES_DIR/$ID"
mkdir -p "$OUT_DIR"

python3 - "$ID" "$ARTIFACT" "$TIMESTAMP" "$SNAPSHOT" "$CONFIG" "$RECEIPTS_DIR" "$OUT_DIR" <<'PY'
import json
import os
import sys

analysis_id, artifact_path, timestamp, snapshot_path, config_path, receipts_dir, out_dir = sys.argv[1:8]
SENSITIVE = {"sensitive-PII", "sensitive-PHI", "payroll", "customer"}

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
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}

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

def signed(value):
    if isinstance(value, str):
        return bool(value.strip())
    if isinstance(value, dict):
        return bool(str(value.get("signedBy") or value.get("operator") or "").strip())
    return False

def sensitive_flag(value):
    if value is True:
        return True
    if isinstance(value, str):
        return value.strip().lower() in {"true", "yes", "sensitive", "pii", "phi", "payroll", "customer"}
    if isinstance(value, list):
        return any(sensitive_flag(v) for v in value)
    if isinstance(value, dict):
        return any(sensitive_flag(v) for v in value.values())
    return False

config = load_jsonc(config_path)
snapshot = load_json(snapshot_path)
spec = load_json(os.path.join(receipts_dir, f"{analysis_id}-spec-receipt.json"))
data_safety = load_json(os.path.join(receipts_dir, f"{analysis_id}-data-safety-receipt.json"))
distribution = config.get("distribution") if isinstance(config.get("distribution"), dict) else {}
data_safety_config = config.get("dataSafety") if isinstance(config.get("dataSafety"), dict) else {}

classification = clean_class(
    data_safety.get("dataClassification")
    or spec.get("dataClassification")
    or spec.get("classification")
    or data_safety_config.get("defaultClassification")
    or "internal"
)
spec_sensitive = any(sensitive_flag(spec.get(key)) for key in (
    "containsSensitiveData",
    "sensitiveData",
    "sensitive",
    "sensitiveFlags",
    "sensitiveDataFlags",
    "hasPII",
    "hasPHI",
    "hasPayroll",
    "hasCustomerRecords",
))
is_sensitive = classification in SENSITIVE or spec_sensitive
has_signoff = data_safety.get("kind") == "data-safety" and signed(data_safety.get("operatorSignoff"))

if is_sensitive and not has_signoff:
    print("assay-distribution-withheld:sensitive-needs-signoff")
    print("distribution-manifest: withheld because sensitive data lacks data-safety sign-off. Sign-off means operator approval for audience and handling.", file=sys.stderr)
    raise SystemExit(0)

audience = (
    distribution.get("audience")
    or data_safety.get("deliveryAudience")
    or snapshot.get("audience")
    or spec.get("audience")
    or "audience not configured"
)
channel = distribution.get("channelDescription") or "channel not configured"
cadence = distribution.get("cadence") or spec.get("cadence") or snapshot.get("cadence") or "cadence not configured"

manifest = {
    "schemaVersion": "assay-distribution/v1",
    "analysisId": analysis_id,
    "createdAt": timestamp,
    "artifactPath": artifact_path,
    "audience": audience,
    "channelDescription": channel,
    "cadence": cadence,
    "dataClassification": classification,
    "detailLevel": data_safety.get("detailLevel") or "not recorded",
    "dataSafetyReceipt": os.path.join(receipts_dir, f"{analysis_id}-data-safety-receipt.json") if data_safety else None,
    "sendStatus": "not-sent-local-handoff",
    "sendNote": "Actual email, Slack, or BI-tool sending is deferred to issue #8.",
}
manifest_path = os.path.join(out_dir, f"distribution-{timestamp}.json")
with open(manifest_path, "w", encoding="utf-8") as f:
    json.dump(manifest, f, indent=2)
    f.write("\n")

print(f"assay-distribution-manifest:{manifest_path}")
PY
