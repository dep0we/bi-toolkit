#!/usr/bin/env bash
# validationcheck.sh - back gate for the assay loop.

set -euo pipefail

ID="${1:-}"
if [ -z "$ID" ]; then
  echo "validationcheck: usage: validationcheck.sh <analysis-id> [assay.config.jsonc]" >&2
  exit 2
fi

CONFIG="${2:-assay.config.jsonc}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$SCRIPT_DIR/config.sh"
RECEIPTS_DIR="$(assay_config_path receiptsDir "${ASSAY_RECEIPTS_DIR:-}" ".assay/receipts" "$CONFIG")"
SPEC="$RECEIPTS_DIR/${ID}-spec-receipt.json"
VALIDATION="$RECEIPTS_DIR/${ID}-validation-receipt.json"
REVIEW="$RECEIPTS_DIR/${ID}-adversarial-review-receipt.json"

gate() {
  local token="$1" message="$2"
  printf 'assay-gate-failed:%s\n' "$token"
  printf 'validationcheck: %s\n' "$message" >&2
  exit 1
}

[ -f "$VALIDATION" ] || gate "missing-validation" "Stage 9 is blocked because no Stage 7 validation receipt exists. A receipt is a saved proof file."

if command -v python3 >/dev/null 2>&1; then
  STATUS="$(python3 - "$SPEC" "$VALIDATION" "$REVIEW" "$CONFIG" <<'PY' || true
import json, re, sys
spec_path, validation_path, review_path, config_path = sys.argv[1:5]

def load_json(path, required=False):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        if required:
            raise
        return None
    except Exception:
        print("invalid-json")
        raise SystemExit

def load_jsonc(path):
    try:
        text = open(path, encoding="utf-8").read()
    except FileNotFoundError:
        return {}
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    lines = []
    for line in text.splitlines():
        if line.lstrip().startswith("//"):
            continue
        lines.append(line)
    try:
        return json.loads("\n".join(lines))
    except Exception:
        return {}

try:
    validation = load_json(validation_path, required=True)
except FileNotFoundError:
    print("missing-validation")
    raise SystemExit

if validation.get("kind") != "validation":
    print("invalid-validation")
    raise SystemExit
if validation.get("reconciled") is not True:
    print("unreconciled")
    raise SystemExit
if not validation.get("reconciliation"):
    print("missing-reconciliation")
    raise SystemExit

spec = load_json(spec_path) or {}
config = load_jsonc(config_path)
def threshold_for(thresholds, key):
    if not isinstance(thresholds, dict):
        return 3
    default = thresholds.get("defaultMinDimension", 3)
    if isinstance(default, bool) or not isinstance(default, (int, float)):
        default = 3
    value = thresholds.get(key, default)
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        value = default
    return value

kind = str(spec.get("kind", "")).lower()
impact = " ".join(str(spec.get(k, "")) for k in ("decisionImpact", "highStakesReason")).lower()
track = str(spec.get("track", "")).lower()
high = spec.get("highStakes") is True or any(w in impact for w in ("money", "headcount", "strategy"))
data_product = track in ("data-product", "data_product", "dataproduct")
needs_review = kind != "trivial"

sot = config.get("sourceOfTruth") if isinstance(config, dict) else None
sot_configured = isinstance(sot, dict) and len(sot) > 0

if (high or data_product) and not sot_configured:
    # High-stakes or data-product work cannot claim a source-of-truth tie when
    # no source-of-truth is configured. Make intake required in practice here.
    print("source-of-truth-unconfigured")
    raise SystemExit

if needs_review:
    review = load_json(review_path)
    if not review:
        print("missing-review")
        raise SystemExit
    if review.get("kind") != "adversarial-review":
        print("invalid-review")
        raise SystemExit

    thresholds = config.get("scoreThresholds", {}) if isinstance(config, dict) else {}
    scores = review.get("scores") or {}
    required = ["confidence", "dataCompleteness", "methodologySoundness", "reproducibility"]
    missing = [k for k in required if k not in scores]
    if missing:
        print("missing-score")
        raise SystemExit
    low = [k for k in required if not isinstance(scores.get(k), (int, float)) or scores.get(k) < threshold_for(thresholds, k)]
    if low:
        if review.get("acceptedBelowThreshold") is True and isinstance(review.get("acceptanceReason"), str) and review["acceptanceReason"].strip():
            print("ok" if sot_configured else "ok-warn-sot")
        else:
            print("sub-threshold-score")
        raise SystemExit
print("ok" if sot_configured else "ok-warn-sot")
PY
)"
elif command -v node >/dev/null 2>&1; then
  STATUS="$(node - "$SPEC" "$VALIDATION" "$REVIEW" "$CONFIG" <<'NODE' || true
const fs = require("fs");
const [specPath, validationPath, reviewPath, configPath] = process.argv.slice(2);
function load(path, required=false) {
  try { return JSON.parse(fs.readFileSync(path, "utf8")); }
  catch (e) {
    if (e.code === "ENOENT" && !required) return null;
    if (e.code === "ENOENT") { console.log("missing-validation"); process.exit(0); }
    console.log("invalid-json"); process.exit(0);
  }
}
function loadJsonc(path) {
  try {
    let text = fs.readFileSync(path, "utf8").replace(/\/\*[\s\S]*?\*\//g, "");
    text = text.split("\n").filter((l) => !l.trimStart().startsWith("//")).join("\n");
    return JSON.parse(text);
  } catch { return {}; }
}
const validation = load(validationPath, true);
if (validation.kind !== "validation") { console.log("invalid-validation"); process.exit(0); }
if (validation.reconciled !== true) { console.log("unreconciled"); process.exit(0); }
if (!validation.reconciliation) { console.log("missing-reconciliation"); process.exit(0); }
const spec = load(specPath) || {};
const config = loadJsonc(configPath);
function thresholdFor(thresholds, key) {
  thresholds = thresholds && typeof thresholds === "object" && !Array.isArray(thresholds) ? thresholds : {};
  let fallback = typeof thresholds.defaultMinDimension === "number" ? thresholds.defaultMinDimension : 3;
  let value = typeof thresholds[key] === "number" ? thresholds[key] : fallback;
  return value;
}
const kind = String(spec.kind || "").toLowerCase();
const impact = `${spec.decisionImpact || ""} ${spec.highStakesReason || ""}`.toLowerCase();
const track = String(spec.track || "").toLowerCase();
const high = spec.highStakes === true || ["money", "headcount", "strategy"].some((w) => impact.includes(w));
const dataProduct = ["data-product", "data_product", "dataproduct"].includes(track);
const needsReview = kind !== "trivial";
const sot = config.sourceOfTruth;
const sotConfigured = sot && typeof sot === "object" && !Array.isArray(sot) && Object.keys(sot).length > 0;
if ((high || dataProduct) && !sotConfigured) { console.log("source-of-truth-unconfigured"); process.exit(0); }
if (needsReview) {
  const review = load(reviewPath);
  if (!review) { console.log("missing-review"); process.exit(0); }
  if (review.kind !== "adversarial-review") { console.log("invalid-review"); process.exit(0); }
  const thresholds = config.scoreThresholds || {};
  const scores = review.scores || {};
  const required = ["confidence", "dataCompleteness", "methodologySoundness", "reproducibility"];
  if (!required.every((k) => Object.prototype.hasOwnProperty.call(scores, k))) { console.log("missing-score"); process.exit(0); }
  const low = required.filter((k) => typeof scores[k] !== "number" || scores[k] < thresholdFor(thresholds, k));
  if (low.length) {
    if (review.acceptedBelowThreshold === true && typeof review.acceptanceReason === "string" && review.acceptanceReason.trim()) console.log(sotConfigured ? "ok" : "ok-warn-sot");
    else console.log("sub-threshold-score");
    process.exit(0);
  }
}
console.log(sotConfigured ? "ok" : "ok-warn-sot");
NODE
)"
else
  echo "validationcheck: requires python3 or node to read receipt files" >&2
  exit 2
fi

case "$STATUS" in
  ok)
    printf 'assay-gate-ok:validationcheck\n' >&2
    exit 0
    ;;
  ok-warn-sot)
    printf 'validationcheck: WARNING - sourceOfTruth is not configured. Source-of-truth means the official place to compare each metric against (for example gross_margin -> NetSuite finance report). Reconciliation cannot be checked against a declared source, so this validation is weaker than it should be. Run /assay intake, or add your key metrics to sourceOfTruth in assay.config.jsonc.\n' >&2
    printf 'assay-gate-ok:validationcheck\n' >&2
    exit 0
    ;;
  source-of-truth-unconfigured)
    gate "source-of-truth-unconfigured" "This work is high-stakes, meaning it drives major business choices, or a data product, meaning a recurring report or dashboard - but sourceOfTruth is not configured. Source-of-truth means the official place to compare each metric against (for example gross_margin -> NetSuite finance report). Run /assay intake, or add your key metrics to sourceOfTruth in assay.config.jsonc, before delivering."
    ;;
  invalid-json)
    gate "invalid-receipt" "A receipt file is not readable JSON. JSON is a structured data file."
    ;;
  invalid-validation|missing-reconciliation)
    gate "invalid-validation" "The validation receipt must show reconciliation, meaning numbers match the official source or differences are explained."
    ;;
  unreconciled)
    gate "unreconciled" "The result has not reconciled to source-of-truth. Source-of-truth means the official place to compare against."
    ;;
  missing-review)
    gate "missing-review" "This non-trivial analysis, meaning not approved as too small to gate, is missing Stage 8 review and scoring. A fresh red-teamer sub-agent, meaning a worker agent given a narrow task, must review it before delivery. Self-review does not count."
    ;;
  invalid-review|missing-score)
    gate "invalid-review" "The Stage 8 review receipt must include scores for confidence (how sure the answer is right), data completeness (how much relevant data was present), methodology soundness (whether the approach survives expert review), and reproducibility (can someone re-run the same work)."
    ;;
  sub-threshold-score)
    gate "sub-threshold-score" "A Stage 8 score is below threshold, meaning the minimum allowed score. Raise the score or record an explicit acceptance reason before delivery."
    ;;
  missing-validation)
    gate "missing-validation" "Stage 9 is blocked because no Stage 7 validation receipt exists."
    ;;
  *)
    gate "invalid-receipt" "The validation gate could not understand the receipt files."
    ;;
esac
