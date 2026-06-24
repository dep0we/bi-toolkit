#!/usr/bin/env bash
# assay-state.sh - read-only state and resume summary for assay analyses.

set -euo pipefail

MODE="${1:-status}"
ID="${2:-}"

case "$MODE" in
  status|json|finish|list) ;;
  *)
    ID="$MODE"
    MODE="status"
    ;;
esac

if [ "$MODE" = "json" ] || [ "$MODE" = "finish" ]; then
  if [ -z "$ID" ]; then
    echo "assay-state: usage: assay-state.sh $MODE <analysis-id>" >&2
    exit 2
  fi
fi

case "$ID" in
  *[!A-Za-z0-9._-]*)
    echo "assay-state: analysis-id may use only letters, numbers, dot, underscore, and dash" >&2
    exit 2
    ;;
esac

if ! command -v python3 >/dev/null 2>&1; then
  echo "assay-state: requires python3 to read receipts. A receipt is a saved proof file." >&2
  exit 2
fi

python3 - "$MODE" "$ID" "${ASSAY_RECEIPTS_DIR:-.assay/receipts}" "${ASSAY_RULINGS_DIR:-.assay/rulings}" "assay.config.jsonc" <<'PY'
import datetime
import hashlib
import json
import os
import re
import sys

mode, requested_id, receipts_dir, rulings_dir, config_path = sys.argv[1:6]

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
            return json.load(f), None
    except FileNotFoundError:
        return None, "missing"
    except Exception as exc:
        return None, f"invalid-json: {exc}"

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

def receipt_path(analysis_id, suffix):
    return os.path.join(receipts_dir, f"{analysis_id}-{suffix}.json")

def ruling_path(analysis_id, suffix):
    return os.path.join(rulings_dir, f"{analysis_id}-{suffix}.json")

def finding(token, message, gate=None, severity="blocker"):
    return {"token": token, "message": message, "gate": gate, "severity": severity}

def score_label(key):
    return {
        "confidence": "confidence (how sure the answer is right)",
        "dataCompleteness": "data completeness (how much relevant data was present)",
        "methodologySoundness": "methodology soundness (whether approach survives review)",
        "reproducibility": "reproducibility (can someone re-run same work)",
    }.get(key, key)

def high_or_data_product(spec):
    impact = " ".join(str(spec.get(k, "")) for k in ("decisionImpact", "highStakesReason")).lower()
    track = str(spec.get("track", "")).lower()
    high = spec.get("highStakes") is True or any(w in impact for w in ("money", "headcount", "strategy"))
    data_product = track in ("data-product", "data_product", "dataproduct")
    return high, data_product

def current_fingerprint(path):
    if not os.path.exists(path):
        return {"path": path, "exists": False, "sha256": None}
    if not os.path.isfile(path):
        return {"path": path, "exists": False, "sha256": "not-a-file"}
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return {"path": path, "exists": True, "sha256": h.hexdigest()}

def data_safety_status(analysis_id, spec, config):
    receipt, err = load_json(receipt_path(analysis_id, "data-safety-receipt"))
    if str(spec.get("kind", "")).lower() == "trivial" and receipt is None:
        return True, None

    def clean(value):
        raw = str(value or "").strip()
        aliases = {
            "pii": "sensitive-PII",
            "sensitive-pii": "sensitive-PII",
            "phi": "sensitive-PHI",
            "sensitive-phi": "sensitive-PHI",
            "customer records": "customer",
            "customer-records": "customer",
            "non-sensitive": "none",
            "nonsensitive": "none",
        }
        return aliases.get(raw.lower(), raw)

    def has_sensitive(obj):
        if not isinstance(obj, dict):
            return False
        keys = ("containsSensitiveData", "sensitiveData", "sensitive", "sensitiveFlags", "sensitiveDataFlags", "hasPII", "hasPHI", "hasPayroll", "hasCustomerRecords")
        for key in keys:
            value = obj.get(key)
            if value is True:
                return True
            if isinstance(value, str) and value.strip().lower() in {"true", "yes", "sensitive", "pii", "phi", "payroll", "customer"}:
                return True
        return False

    data_safety = config.get("dataSafety") if isinstance(config.get("dataSafety"), dict) else {}
    default_class = clean(data_safety.get("defaultClassification", ""))
    spec_class = clean(spec.get("dataClassification") or spec.get("classification") or spec.get("dataSafetyClassification") or default_class)
    sensitive = {"sensitive-PII", "sensitive-PHI", "payroll", "customer"}
    unknown = {"", "unset", "unknown", "tbd", "todo", "null", "none-set"}

    if receipt is None:
        if spec_class in sensitive or has_sensitive(spec):
            return False, finding("missing-data-safety", "Missing data-safety receipt. Data-safety means audience and handling proof.", "datacheck")
        if spec_class in {"none", "internal"}:
            return True, None
        if spec_class.lower() in unknown:
            return False, finding("unknown-classification", "Data classification is unset. Classification means how sensitive the data is.", "datacheck")
        return False, finding("invalid-classification", "Data classification is not recognized.", "datacheck")
    if err and err != "missing":
        return False, finding("invalid-data-safety", "Data-safety receipt is not readable JSON. JSON is a structured data file.", "datacheck")
    if not isinstance(receipt, dict) or receipt.get("kind") != "data-safety":
        return False, finding("invalid-data-safety", "Data-safety receipt has the wrong kind.", "datacheck")
    return True, None

def analyze(analysis_id):
    config = load_jsonc(config_path)
    completed = []
    findings = []
    notes = []
    next_step = None
    blocking_gate = None

    spec, spec_err = load_json(receipt_path(analysis_id, "spec-receipt"))
    spec_ok = False
    if spec is None:
        findings.append(finding("missing-spec", "Missing Stage 2 spec receipt. A receipt is a saved proof file.", "questioncheck"))
        blocking_gate = findings[-1]
        next_step = f"/assay spec {analysis_id}"
    elif spec_err and spec_err != "missing":
        findings.append(finding("invalid-spec", "Spec receipt is not readable JSON. JSON is a structured data file.", "questioncheck"))
        blocking_gate = findings[-1]
        next_step = f"/assay spec {analysis_id}"
    else:
        kind = str(spec.get("kind", "")).lower()
        if kind == "trivial":
            spec_ok = bool(str(spec.get("reason", "")).strip())
        elif kind == "spec":
            spec_ok = bool(spec.get("question") and spec.get("metricDefinitions") and spec.get("validAnswer"))
        if spec_ok:
            completed.append("Stage 2 spec receipt")
        else:
            findings.append(finding("incomplete-spec", "Spec receipt is missing the question, metric definitions, or valid-answer rule. Metric definitions are exact calculation rules.", "questioncheck"))
            blocking_gate = findings[-1]
            next_step = f"/assay spec {analysis_id}"

    latest, latest_err = load_json(ruling_path(analysis_id, "latest-discovery"))
    gov, gov_err = load_json(receipt_path(analysis_id, "govbaseline"))
    if spec_ok and next_step is None:
        if gov is None:
            findings.append(finding("missing-govbaseline", "Missing governing-doc baseline. Baseline means saved starting copy for comparison.", "govcheck"))
            next_step = f"/assay discovery {analysis_id}"
        elif gov_err and gov_err != "missing":
            findings.append(finding("invalid-govbaseline", "Governing-doc baseline is not readable JSON. JSON is a structured data file.", "govcheck"))
            blocking_gate = findings[-1]
            next_step = f"/assay discovery {analysis_id}"
        else:
            completed.append("governing-doc baseline")
        if latest is None:
            findings.append(finding("missing-discovery", "Missing latest discovery record. Discovery means finding method choices before results.", "rulingscheck"))
            next_step = next_step or f"/assay discovery {analysis_id}"
        elif latest_err and latest_err != "missing":
            findings.append(finding("invalid-discovery", "Latest discovery record is not readable JSON. JSON is a structured data file.", "rulingscheck"))
            blocking_gate = blocking_gate or findings[-1]
            next_step = next_step or f"/assay discovery {analysis_id}"
        else:
            completed.append("Stage 5 discovery record")

    if spec_ok and latest is not None and next_step is None:
        rulings, rulings_err = load_json(ruling_path(analysis_id, "rulings"))
        if rulings is None:
            findings.append(finding("missing-rulings", "Missing methodology rulings. A ruling is the operator's approved method choice.", "rulingscheck"))
            blocking_gate = findings[-1]
            next_step = f"record methodology rulings for {analysis_id}"
        elif rulings_err and rulings_err != "missing":
            findings.append(finding("invalid-rulings", "Rulings file is not readable JSON. JSON is a structured data file.", "rulingscheck"))
            blocking_gate = findings[-1]
            next_step = f"record methodology rulings for {analysis_id}"
        elif rulings.get("discoveryRunId") != latest.get("discoveryRunId"):
            findings.append(finding("stale-rulings", "Methodology rulings are stale, meaning not from the newest review.", "rulingscheck"))
            blocking_gate = findings[-1]
            next_step = f"reaffirm or rewrite methodology rulings for {analysis_id}"
        else:
            fork_ids = latest.get("forkIds")
            ruling_map = rulings.get("rulings")
            missing = []
            if isinstance(fork_ids, list) and isinstance(ruling_map, dict):
                for fork_id in fork_ids:
                    value = ruling_map.get(fork_id)
                    ok = bool(value.strip()) if isinstance(value, str) else isinstance(value, dict) and bool(str(value.get("ruling", "")).strip())
                    if not ok:
                        missing.append(fork_id)
            else:
                missing = ["(invalid fork list)"]
            if missing:
                findings.append(finding("incomplete-rulings", "Missing rulings for surfaced forks: " + ", ".join(missing) + ". Surfaced means discovery found it.", "rulingscheck"))
                blocking_gate = findings[-1]
                next_step = f"record methodology rulings for {analysis_id}"
            else:
                completed.append("methodology rulings")

    validation, validation_err = load_json(receipt_path(analysis_id, "validation-receipt"))
    review, review_err = load_json(receipt_path(analysis_id, "adversarial-review-receipt"))
    if spec_ok and latest is not None and next_step is None:
        if validation is None:
            findings.append(finding("missing-validation", "Missing Stage 7 validation receipt. Validation means proof the numbers were checked.", "validationcheck"))
            next_step = f"/assay validate {analysis_id}"
        elif validation_err and validation_err != "missing":
            findings.append(finding("invalid-validation", "Validation receipt is not readable JSON. JSON is a structured data file.", "validationcheck"))
            blocking_gate = findings[-1]
            next_step = f"/assay validate {analysis_id}"
        elif validation.get("kind") != "validation" or not validation.get("reconciliation"):
            findings.append(finding("invalid-validation", "Validation receipt must include reconciliation. Reconciliation means numbers match official source or differences are explained.", "validationcheck"))
            blocking_gate = findings[-1]
            next_step = f"/assay validate {analysis_id}"
        elif validation.get("reconciled") is not True:
            findings.append(finding("unreconciled", "Validation says the result is unreconciled. Reconciled means checked against official source.", "validationcheck"))
            blocking_gate = findings[-1]
            next_step = f"/assay validate {analysis_id}"
        else:
            completed.append("Stage 7 validation receipt")

        if next_step is None:
            high, data_product = high_or_data_product(spec or {})
            sot = config.get("sourceOfTruth") if isinstance(config.get("sourceOfTruth"), dict) else {}
            if (high or data_product) and not sot:
                findings.append(finding("source-of-truth-unconfigured", "High-stakes or data-product work needs sourceOfTruth. Source-of-truth means official place to compare against.", "validationcheck"))
                blocking_gate = findings[-1]
                next_step = "/assay intake"
            elif str((spec or {}).get("kind", "")).lower() != "trivial":
                if review is None:
                    findings.append(finding("missing-review", "Missing Stage 8 adversarial-review receipt. Adversarial review means independent attack on the answer.", "validationcheck"))
                    next_step = f"/assay validate {analysis_id}"
                elif review_err and review_err != "missing":
                    findings.append(finding("invalid-review", "Adversarial-review receipt is not readable JSON. JSON is a structured data file.", "validationcheck"))
                    blocking_gate = findings[-1]
                    next_step = f"/assay validate {analysis_id}"
                elif review.get("kind") != "adversarial-review":
                    findings.append(finding("invalid-review", "Adversarial-review receipt has the wrong kind.", "validationcheck"))
                    blocking_gate = findings[-1]
                    next_step = f"/assay validate {analysis_id}"
                else:
                    scores = review.get("scores") if isinstance(review.get("scores"), dict) else {}
                    required = ["confidence", "dataCompleteness", "methodologySoundness", "reproducibility"]
                    missing_scores = [k for k in required if k not in scores]
                    threshold = int((config.get("scoreThresholds") or {}).get("defaultMinDimension", 3)) if isinstance(config.get("scoreThresholds"), dict) else 3
                    low = [k for k in required if not isinstance(scores.get(k), (int, float)) or scores.get(k) < threshold]
                    if missing_scores:
                        findings.append(finding("missing-score", "Review is missing scores for " + ", ".join(score_label(k) for k in missing_scores) + ".", "validationcheck"))
                        blocking_gate = findings[-1]
                        next_step = f"/assay validate {analysis_id}"
                    elif low and not (review.get("acceptedBelowThreshold") is True and str(review.get("acceptanceReason", "")).strip()):
                        findings.append(finding("sub-threshold-score", "Low review score: " + ", ".join(score_label(k) for k in low) + ". Threshold means minimum allowed score.", "validationcheck"))
                        blocking_gate = findings[-1]
                        next_step = f"/assay validate {analysis_id}"
                    else:
                        completed.append("Stage 8 adversarial review")

    if spec_ok and next_step is None:
        ok, data_finding = data_safety_status(analysis_id, spec or {}, config)
        if ok:
            completed.append("data-safety gate")
        else:
            findings.append(data_finding)
            blocking_gate = data_finding
            next_step = "write data-safety receipt for " + analysis_id

    if spec_ok and next_step is None:
        command = config.get("reproCommand")
        high, data_product = high_or_data_product(spec or {})
        if isinstance(command, str) and command.strip():
            notes.append("reproCommand is configured; /assay deliver will run reprocheck before packaging.")
        else:
            notes.append("reproCommand is unset, so reproducibility is unverified but not blocking.")
            if data_product:
                notes.append("WARNING: data product should set reproCommand. Data product means recurring report or dashboard.")
        completed.append("reprocheck policy evaluated")

    if spec_ok and next_step is None and gov is not None and not gov_err:
        changed = []
        for old in (gov.get("docs", []) if isinstance(gov, dict) else []):
            path = old.get("path") if isinstance(old, dict) else None
            if path and current_fingerprint(path) != old:
                changed.append(path)
        if changed:
            findings.append(finding("governing-doc-edit", "Guarded governing docs changed during analysis: " + ", ".join(changed) + ". Guarded docs are protected rule files.", "govcheck"))
            blocking_gate = findings[-1]
            next_step = f"resnapshot governing docs only with operator approval for {analysis_id}"
        else:
            completed.append("governing-doc check")

    if spec_ok and next_step is None:
        next_step = f"/assay deliver {analysis_id}"

    if blocking_gate is None:
        blockers = [f for f in findings if f.get("severity") == "blocker"]
        blocking_gate = blockers[0] if blockers else None

    return {
        "analysisId": analysis_id,
        "track": (spec or {}).get("track"),
        "completedStages": completed,
        "openFindings": findings,
        "notes": notes,
        "blockingGate": blocking_gate,
        "nextStep": next_step,
        "computedAt": datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z"),
    }

def ids_found():
    ids = set()
    patterns = [
        (receipts_dir, re.compile(r"^(.+)-(?:spec-receipt|validation-receipt|adversarial-review-receipt|data-safety-receipt|govbaseline)\.json$")),
        (rulings_dir, re.compile(r"^(.+)-(?:latest-discovery|rulings)\.json$")),
    ]
    for directory, pattern in patterns:
        try:
            names = os.listdir(directory)
        except FileNotFoundError:
            continue
        for name in names:
            m = pattern.match(name)
            if m:
                ids.add(m.group(1))
    return sorted(ids)

def print_text(state, finish=False):
    print(("assay-finish" if finish else "assay-state") + f": {state['analysisId']}")
    print("completed stages:")
    if state["completedStages"]:
        for item in state["completedStages"]:
            print(f"  - {item}")
    else:
        print("  - none yet")
    print("open findings:")
    if state["openFindings"]:
        for item in state["openFindings"]:
            gate = f" [{item['gate']}]" if item.get("gate") else ""
            print(f"  - {item['token']}{gate}: {item['message']}")
    else:
        print("  - none")
    for note in state["notes"]:
        print(f"note: {note}")
    gate = state.get("blockingGate")
    if gate:
        print(f"blocking gate: {gate.get('gate') or 'unknown'} ({gate['token']})")
    else:
        print("blocking gate: none known")
    print(f"next required step: {state['nextStep']}")
    if finish and gate:
        print(f"assay-finish-blocked:{gate['token']}")

if mode == "list" or (mode == "status" and not requested_id):
    ids = ids_found()
    if not ids:
        print("assay-state: no in-flight analyses found under .assay/.")
        raise SystemExit(0)
    for analysis_id in ids:
        state = analyze(analysis_id)
        gate = state.get("blockingGate")
        token = gate["token"] if gate else "none"
        print(f"{analysis_id}\tnext: {state['nextStep']}\tblocker: {token}")
    raise SystemExit(0)

state = analyze(requested_id)
if mode == "json":
    print(json.dumps(state, indent=2))
    raise SystemExit(0)

print_text(state, finish=(mode == "finish"))
PY
