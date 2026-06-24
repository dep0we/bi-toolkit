#!/usr/bin/env bash
# govcheck.sh - protects governing docs during one assay analysis.
#
# This gate compares today's governing docs against the baseline, meaning the
# saved starting copy for comparison, captured when discovery starts. A deliberate
# rules update can be re-snapshotted only with ASSAY_GOVCHECK_APPROVED=1.

set -euo pipefail

MODE="check"
ID="${1:-}"
CONFIG="${2:-assay.config.jsonc}"

case "$ID" in
  snapshot|resnapshot|check)
    MODE="$ID"
    ID="${2:-}"
    CONFIG="${3:-assay.config.jsonc}"
    ;;
esac

if [ -z "$ID" ]; then
  echo "govcheck: usage: govcheck.sh [snapshot|resnapshot|check] <analysis-id> [assay.config.jsonc]" >&2
  exit 2
fi

case "$ID" in
  *[!A-Za-z0-9._-]*|"")
    echo "govcheck: analysis-id may use only letters, numbers, dot, underscore, and dash" >&2
    exit 2
    ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$SCRIPT_DIR/config.sh"
RECEIPTS_DIR="$(assay_config_path receiptsDir "${ASSAY_RECEIPTS_DIR:-}" ".assay/receipts" "$CONFIG")"

if command -v python3 >/dev/null 2>&1; then
  python3 - "$MODE" "$ID" "$CONFIG" "$RECEIPTS_DIR" "${ASSAY_GOVCHECK_APPROVED:-}" <<'PY'
import datetime
import hashlib
import json
import os
import re
import sys
import tempfile

mode, analysis_id, config_path, receipts_dir, approved = sys.argv[1:6]

DEFAULT_DOCS = ["CLAUDE.md", "methodology.md", "docs/DECISIONS.md", "docs/spec/assay-spec.md"]

def gate(token, message):
    print(f"assay-gate-failed:{token}")
    print(f"govcheck: {message}", file=sys.stderr)
    raise SystemExit(1)

def usage(message):
    print(f"govcheck: {message}", file=sys.stderr)
    raise SystemExit(2)

def ok(label):
    print(f"assay-gate-ok:{label}", file=sys.stderr)

def strip_jsonc(text):
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    lines = []
    for line in text.splitlines():
        if line.lstrip().startswith("//"):
            continue
        lines.append(line)
    return "\n".join(lines)

def load_governing_docs():
    try:
        raw = open(config_path, encoding="utf-8").read()
    except FileNotFoundError:
        return DEFAULT_DOCS
    try:
        data = json.loads(strip_jsonc(raw))
    except Exception as exc:
        usage(f"could not read governingDocs from {config_path}. JSONC means JSON with comments. {exc}")
    docs = data.get("governingDocs", DEFAULT_DOCS) if isinstance(data, dict) else DEFAULT_DOCS
    if isinstance(docs, dict):
        docs = docs.get("paths", DEFAULT_DOCS)
    if not isinstance(docs, list) or not all(isinstance(p, str) and p.strip() for p in docs):
        usage("governingDocs must be a list of file paths, meaning repo-relative protected files.")
    clean = []
    seen = set()
    for path in docs:
        path = path.strip().replace("\\", "/")
        parts = [p for p in path.split("/") if p]
        if path.startswith("/") or ".." in parts or not parts:
            usage(f"governingDocs path '{path}' must stay inside this project folder.")
        normalized = "/".join(parts)
        if normalized not in seen:
            seen.add(normalized)
            clean.append(normalized)
    return clean

def fingerprint(path):
    if not os.path.exists(path):
        return {"path": path, "exists": False, "sha256": None}
    if not os.path.isfile(path):
        usage(f"governing doc '{path}' is not a regular file.")
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return {"path": path, "exists": True, "sha256": h.hexdigest()}

def make_baseline(paths):
    return {
        "kind": "govbaseline",
        "analysisId": analysis_id,
        "createdAt": datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z"),
        "governingDocs": paths,
        "docs": [fingerprint(p) for p in paths],
    }

def load_baseline(path):
    try:
        data = json.load(open(path, encoding="utf-8"))
    except FileNotFoundError:
        gate("missing-govbaseline", f"Delivery is blocked because no governing-doc baseline exists for {analysis_id}. A baseline is a saved starting copy for comparison. Run discovery preflight first.")
    except Exception as exc:
        usage(f"baseline is not readable JSON. JSON is a structured data file. {exc}")
    if data.get("kind") != "govbaseline" or data.get("analysisId") != analysis_id or not isinstance(data.get("docs"), list):
        usage("baseline does not match this analysis. Recreate it only after operator approval.")
    return data

def changed_docs(expected_docs, current_docs):
    current_by_path = {d.get("path"): d for d in current_docs}
    changed = []
    for old in expected_docs:
        path = old.get("path")
        new = current_by_path.get(path)
        if old != new:
            changed.append(path or "(unknown path)")
    return changed

os.makedirs(receipts_dir, exist_ok=True)
baseline_path = os.path.join(receipts_dir, f"{analysis_id}-govbaseline.json")

if mode in ("snapshot", "resnapshot"):
    paths = load_governing_docs()
    new_baseline = make_baseline(paths)
    if os.path.exists(baseline_path) and approved != "1":
        old = load_baseline(baseline_path)
        changed = changed_docs(old["docs"], new_baseline["docs"])
        if changed or mode == "resnapshot":
            gate("governing-doc-edit", "A guarded governing doc changed since the analysis started: " + ", ".join(changed or old.get("governingDocs", [])) + ". Governing docs are rule files the model may not rewrite mid-analysis. If a person approved the rule update, run ASSAY_GOVCHECK_APPROVED=1 bash .claude/workflows/govcheck.sh resnapshot " + analysis_id + ".")
        ok("govcheck")
        raise SystemExit(0)
    fd, tmp = tempfile.mkstemp(prefix=f".{analysis_id}-govbaseline.", suffix=".tmp", dir=receipts_dir)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(new_baseline, f, indent=2)
            f.write("\n")
        os.replace(tmp, baseline_path)
    except Exception:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise
    ok("govcheck-snapshot")
    raise SystemExit(0)

if mode != "check":
    usage(f"unknown mode '{mode}'. Use snapshot, resnapshot, or check.")

baseline = load_baseline(baseline_path)
paths = []
for doc in baseline["docs"]:
    path = doc.get("path")
    if not isinstance(path, str) or not path:
        usage("baseline contains an invalid governing doc path.")
    paths.append(path)
current = [fingerprint(p) for p in paths]
changed = changed_docs(baseline["docs"], current)
if changed:
    gate("governing-doc-edit", "Delivery is blocked because a guarded governing doc changed during this analysis: " + ", ".join(changed) + ". Governing docs are rule files the model may not rewrite mid-analysis. If a person approved the rule update, run ASSAY_GOVCHECK_APPROVED=1 bash .claude/workflows/govcheck.sh resnapshot " + analysis_id + ".")
ok("govcheck")
PY
elif command -v node >/dev/null 2>&1; then
  node - "$MODE" "$ID" "$CONFIG" "$RECEIPTS_DIR" "${ASSAY_GOVCHECK_APPROVED:-}" <<'NODE'
const crypto = require("crypto");
const fs = require("fs");
const path = require("path");
const [mode, analysisId, configPath, receiptsDir, approved] = process.argv.slice(2);
const DEFAULT_DOCS = ["CLAUDE.md", "methodology.md", "docs/DECISIONS.md", "docs/spec/assay-spec.md"];

function gate(token, message) {
  console.log(`assay-gate-failed:${token}`);
  console.error(`govcheck: ${message}`);
  process.exit(1);
}
function usage(message) {
  console.error(`govcheck: ${message}`);
  process.exit(2);
}
function ok(label) {
  console.error(`assay-gate-ok:${label}`);
}
function stripJsonc(text) {
  text = text.replace(/\/\*[\s\S]*?\*\//g, "");
  return text.split("\n").filter((line) => !line.trimStart().startsWith("//")).join("\n");
}
function loadGoverningDocs() {
  let data;
  try {
    data = JSON.parse(stripJsonc(fs.readFileSync(configPath, "utf8")));
  } catch (e) {
    if (e.code === "ENOENT") return DEFAULT_DOCS;
    usage(`could not read governingDocs from ${configPath}. JSONC means JSON with comments. ${e.message}`);
  }
  let docs = data && typeof data === "object" ? (data.governingDocs || DEFAULT_DOCS) : DEFAULT_DOCS;
  if (docs && typeof docs === "object" && !Array.isArray(docs)) docs = docs.paths || DEFAULT_DOCS;
  if (!Array.isArray(docs) || !docs.every((p) => typeof p === "string" && p.trim())) {
    usage("governingDocs must be a list of file paths, meaning repo-relative protected files.");
  }
  const out = [];
  const seen = new Set();
  for (let raw of docs) {
    raw = raw.trim().replace(/\\/g, "/");
    const parts = raw.split("/").filter(Boolean);
    if (raw.startsWith("/") || parts.includes("..") || parts.length === 0) {
      usage(`governingDocs path '${raw}' must stay inside this project folder.`);
    }
    const clean = parts.join("/");
    if (!seen.has(clean)) {
      seen.add(clean);
      out.push(clean);
    }
  }
  return out;
}
function fingerprint(p) {
  if (!fs.existsSync(p)) return { path: p, exists: false, sha256: null };
  if (!fs.statSync(p).isFile()) usage(`governing doc '${p}' is not a regular file.`);
  return { path: p, exists: true, sha256: crypto.createHash("sha256").update(fs.readFileSync(p)).digest("hex") };
}
function makeBaseline(paths) {
  return { kind: "govbaseline", analysisId, createdAt: new Date().toISOString(), governingDocs: paths, docs: paths.map(fingerprint) };
}
function loadBaseline(file) {
  let data;
  try {
    data = JSON.parse(fs.readFileSync(file, "utf8"));
  } catch (e) {
    if (e.code === "ENOENT") gate("missing-govbaseline", `Delivery is blocked because no governing-doc baseline exists for ${analysisId}. A baseline is a saved starting copy for comparison. Run discovery preflight first.`);
    usage(`baseline is not readable JSON. JSON is a structured data file. ${e.message}`);
  }
  if (data.kind !== "govbaseline" || data.analysisId !== analysisId || !Array.isArray(data.docs)) {
    usage("baseline does not match this analysis. Recreate it only after operator approval.");
  }
  return data;
}
function changedDocs(expected, current) {
  const byPath = new Map(current.map((d) => [d.path, d]));
  return expected.filter((old) => JSON.stringify(old) !== JSON.stringify(byPath.get(old.path))).map((d) => d.path || "(unknown path)");
}

fs.mkdirSync(receiptsDir, { recursive: true });
const baselinePath = path.join(receiptsDir, `${analysisId}-govbaseline.json`);

if (mode === "snapshot" || mode === "resnapshot") {
  const newBaseline = makeBaseline(loadGoverningDocs());
  if (fs.existsSync(baselinePath) && approved !== "1") {
    const old = loadBaseline(baselinePath);
    const changed = changedDocs(old.docs, newBaseline.docs);
    if (changed.length || mode === "resnapshot") {
      gate("governing-doc-edit", `A guarded governing doc changed since the analysis started: ${(changed.length ? changed : old.governingDocs).join(", ")}. Governing docs are rule files the model may not rewrite mid-analysis. If a person approved the rule update, run ASSAY_GOVCHECK_APPROVED=1 bash .claude/workflows/govcheck.sh resnapshot ${analysisId}.`);
    }
    ok("govcheck");
    process.exit(0);
  }
  const tmp = path.join(receiptsDir, `.${analysisId}-govbaseline.${process.pid}.${Date.now()}.tmp`);
  fs.writeFileSync(tmp, `${JSON.stringify(newBaseline, null, 2)}\n`);
  fs.renameSync(tmp, baselinePath);
  ok("govcheck-snapshot");
  process.exit(0);
}

if (mode !== "check") usage(`unknown mode '${mode}'. Use snapshot, resnapshot, or check.`);
const baseline = loadBaseline(baselinePath);
const current = baseline.docs.map((d) => fingerprint(d.path));
const changed = changedDocs(baseline.docs, current);
if (changed.length) {
  gate("governing-doc-edit", `Delivery is blocked because a guarded governing doc changed during this analysis: ${changed.join(", ")}. Governing docs are rule files the model may not rewrite mid-analysis. If a person approved the rule update, run ASSAY_GOVCHECK_APPROVED=1 bash .claude/workflows/govcheck.sh resnapshot ${analysisId}.`);
}
ok("govcheck");
NODE
else
  echo "govcheck: requires python3 or node to read governing docs" >&2
  exit 2
fi
