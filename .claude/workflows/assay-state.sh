#!/usr/bin/env bash
# assay-state.sh - read-only state and resume summary for assay analyses.

set -euo pipefail

MODE="${1:-status}"
ID="${2:-}"

case "$MODE" in
  status|json|finish|resume|list) ;;
  *)
    ID="$MODE"
    MODE="status"
    ;;
esac

if ! command -v python3 >/dev/null 2>&1; then
  echo "assay-state: requires python3 to read receipts. A receipt is a saved proof file." >&2
  exit 2
fi

if { [ "$MODE" = "finish" ] || [ "$MODE" = "resume" ]; } && [ -z "$ID" ]; then
  ID="$(python3 - "${ASSAY_ACTIVE_FILE:-.assay/active.json}" <<'PY' 2>/dev/null || true
import json
import sys
try:
    data = json.load(open(sys.argv[1], encoding="utf-8"))
    print(data.get("analysisId", ""))
except Exception:
    print("")
PY
)"
  if [ -z "$ID" ]; then
    echo "assay-state: no active analysis - run /assay status or /assay help" >&2
    exit 2
  fi
fi

if [ "$MODE" = "json" ] && [ -z "$ID" ]; then
  echo "assay-state: usage: assay-state.sh $MODE <analysis-id>" >&2
  exit 2
fi

case "$ID" in
  *[!A-Za-z0-9._-]*)
    echo "assay-state: analysis-id may use only letters, numbers, dot, underscore, and dash" >&2
    exit 2
    ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$SCRIPT_DIR/config.sh"
CONFIG="${ASSAY_CONFIG:-assay.config.jsonc}"
RECEIPTS_DIR="$(assay_config_path receiptsDir "${ASSAY_RECEIPTS_DIR:-}" ".assay/receipts" "$CONFIG")"
RULINGS_DIR="$(assay_config_path rulingsDir "${ASSAY_RULINGS_DIR:-}" ".assay/rulings" "$CONFIG")"

python3 - "$MODE" "$ID" "$RECEIPTS_DIR" "$RULINGS_DIR" "$CONFIG" "$SCRIPT_DIR" <<'PY'
import datetime
import hashlib
import json
import os
import re
import subprocess
import sys

mode, requested_id, receipts_dir, rulings_dir, config_path, script_dir = sys.argv[1:7]

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

def stage_for_next(next_step):
    step = str(next_step or "").lower()
    if "intake" in step:
        return {"number": 0, "name": "Intake"}
    if "frame" in step:
        return {"number": 1, "name": "Frame"}
    if "spec" in step:
        return {"number": 2, "name": "Spec"}
    if "plan" in step:
        return {"number": 3, "name": "Plan review"}
    if "profile" in step:
        return {"number": 4, "name": "Profile data"}
    if "discovery" in step or "ruling" in step:
        return {"number": 5, "name": "Discovery"}
    if "execute" in step:
        return {"number": 6, "name": "Execute"}
    if "validate" in step or "review" in step:
        return {"number": 7, "name": "Validate"}
    if "data-safety" in step or "deliver" in step:
        return {"number": 9, "name": "Deliver"}
    return {"number": None, "name": "Unknown"}

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

def gate_status(script, analysis_id, gate_name):
    result = subprocess.run(
        ["bash", os.path.join(script_dir, script), analysis_id, config_path],
        text=True,
        capture_output=True,
    )
    if result.returncode == 0:
        return True, None
    combined = "\n".join(part for part in (result.stdout, result.stderr) if part)
    match = re.search(r"assay-gate-failed:([A-Za-z0-9._-]+)", combined)
    token = match.group(1) if match else "gate-error"
    message = ""
    for line in result.stderr.splitlines():
        if ":" in line:
            message = line.split(":", 1)[1].strip()
            if message:
                break
    if not message:
        message = f"{gate_name} blocked this analysis."
    return False, finding(token, message, gate_name)

def data_safety_status(analysis_id):
    return gate_status("datacheck.sh", analysis_id, "datacheck")

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

    if spec_ok and latest is not None and next_step is None:
        ok, validation_finding = gate_status("validationcheck.sh", analysis_id, "validationcheck")
        if ok:
            completed.append("Stage 7 validation receipt")
            if str((spec or {}).get("kind", "")).lower() != "trivial":
                completed.append("Stage 8 adversarial review")
        else:
            findings.append(validation_finding)
            blocking_gate = validation_finding
            if validation_finding["token"] == "source-of-truth-unconfigured":
                next_step = "/assay intake"
            else:
                next_step = f"/assay validate {analysis_id}"

    if spec_ok and next_step is None:
        gov_result = subprocess.run(
            ["bash", os.path.join(script_dir, "govcheck.sh"), "check", analysis_id, config_path],
            text=True,
            capture_output=True,
        )
        if gov_result.returncode == 0:
            completed.append("governing-doc check")
        else:
            combined = "\n".join(part for part in (gov_result.stdout, gov_result.stderr) if part)
            match = re.search(r"assay-gate-failed:([A-Za-z0-9._-]+)", combined)
            token = match.group(1) if match else "governing-doc-check-failed"
            message = ""
            for line in gov_result.stderr.splitlines():
                if ":" in line:
                    message = line.split(":", 1)[1].strip()
                    if message:
                        break
            if not message:
                message = "Governing-doc check failed. Governing docs are protected rule files."
            gov_finding = finding(token, message, "govcheck")
            findings.append(gov_finding)
            blocking_gate = gov_finding
            next_step = f"resnapshot governing docs only with operator approval for {analysis_id}"

    if spec_ok and next_step is None:
        ok, data_finding = data_safety_status(analysis_id)
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

    if spec_ok and next_step is None:
        next_step = f"/assay deliver {analysis_id}"

    if blocking_gate is None:
        blockers = [f for f in findings if f.get("severity") == "blocker"]
        blocking_gate = blockers[0] if blockers else None

    stage = stage_for_next(next_step)

    return {
        "analysisId": analysis_id,
        "track": (spec or {}).get("track"),
        "stage": stage,
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
    stage = state.get("stage") or {}
    number = stage.get("number")
    name = stage.get("name") or "Unknown"
    if number is None:
        print(f"stage: {name}")
    else:
        print(f"stage: Stage {number} {name}")
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

print_text(state, finish=(mode in ("finish", "resume")))
PY
