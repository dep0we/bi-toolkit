#!/usr/bin/env bash
# decision-ledger.sh — standalone domain-neutral query tool for the arc decision ledger.
#
# Subcommands:
#   decision-ledger.sh query  --issue <N>           # retrieve all decisions for an issue (exact id match)
#   decision-ledger.sh query  --fork <forkId>        # retrieve a specific fork decision
#   decision-ledger.sh match-rate [--domain <d>] [--class <c>]  # rolling match-rate per decision-class per domain
#   decision-ledger.sh list   [--issue <N>] [--domain <d>]      # list all records (optional filters)
#   decision-ledger.sh append  <json-file>           # (trusted-skill use only) append one ledger record
#
# Naming rule: no code-specific words (review, build, PR, diff) in subcommand names.
# Domain-neutral subcommands: query, match-rate, list, append.
#
# Ledger location: .gstack/arc-rulings/decisions.jsonl
# Schema version: 1
#
# Schema (schemaVersion 1) — fields per JSONL record:
#   schemaVersion       : 1 (required)
#   issueId             : bare numeric id (normalized, e.g. "32")
#   issueTitle          : full human-readable issue description (optional)
#   forkId              : short kebab-case slug (required)
#   domain              : "code" | "content" (required; default "code")
#   decisionType        : "tier-a" | "tier-b" (required)
#   decisionClass       : spine class or domain subtype (required; "unclassified" if unknown)
#   options             : array of option strings
#   recommendation      : the recommendation offered to the operator
#   timestamp           : ISO-8601 (required)
#   project             : project name (optional)
#   # Prediction fields (PRODUCED by the shadow-compare workflow, not persisted by it):
#   predictedRuling     : option label the profile predicted (null if no prediction)
#   predictionConfidence: float 0.0–1.0 or null
#   challengeOutcome    : "agreed" | "pushed-back" | "unresolved" | null
#   challengeReason     : the fresh-agent challenger's stated reason (single-line; null if none)
#   challengeRan        : boolean
#   challengeRanCrossFamily : boolean
#   # Trusted ruling fields (written by /arc skill AFTER operator rules):
#   actualRuling        : the operator's chosen option (or agent's for Tier-B)
#   rationale           : one-line rationale (single-line, newlines stripped)
#   matchScore          : "exact" | "partial" | "miss" | null (null until actualRuling set)
#
# Single-writer flow (NOT two-phase):
#   shadow-compare PRODUCES (does not persist) the prediction + challenge fields and
#   RETURNS them to the trusted /arc skill. shadow-compare never touches this ledger.
#   The /arc skill, AFTER the operator rules, writes ONE complete row per fork:
#   the prediction fields from shadow-compare's return value + the trusted ruling
#   fields (actualRuling, rationale, matchScore) it owns. There is exactly one
#   writer (the skill) and one row per (issueId, forkId).
#   Defensive de-dup: the query/match-rate tools still de-duplicate on
#   (issueId, forkId) last-row-wins, so an accidental double-append (e.g. a re-run)
#   does not double-count — but the design writes each fork exactly once.
#
# Forward-compatible defaults: missing fields in older records are treated as
# their defined default (missing matchScore → null; missing challengeRan → false).
# Unknown fields are silently skipped (lenient on read, strict on write).
#
# Concurrent writes: the ledger assumes at-most-one writer (the trusted /arc skill
# serializes ledger appends). The query tool tolerates a partial last line by
# skipping lines that do not parse as valid JSON rather than hard-aborting.

set -euo pipefail

SUBCOMMAND="${1:-}"
LEDGER="${LEDGER_PATH:-.gstack/arc-rulings/decisions.jsonl}"

# Pick a JSON runner once.
# Validation runner (for record writes): python3, else node. jq is intentionally
# NOT a validation runner: it cannot enforce the integer/float bounds and enum
# membership the append validator requires without diverging from python3/node, so
# the two validators (python3, node) are the only sanctioned write gates. If NEITHER
# python3 nor node is present, append fails closed (see VALIDATE_RUNNER guard below);
# we do NOT silently fall back to a weaker jq validator.
# Query runner (for read/filter operations): prefer jq (fastest streaming), then
# python3, then node.
VALIDATE_RUNNER=""
if command -v python3 >/dev/null 2>&1; then
  VALIDATE_RUNNER="python3"
elif command -v node >/dev/null 2>&1; then
  VALIDATE_RUNNER="node"
fi

JSON_RUNNER=""
if command -v jq >/dev/null 2>&1; then
  JSON_RUNNER="jq"
elif command -v python3 >/dev/null 2>&1; then
  JSON_RUNNER="python3"
elif command -v node >/dev/null 2>&1; then
  JSON_RUNNER="node"
fi

if [ -z "$JSON_RUNNER" ]; then
  echo "decision-ledger: requires jq, python3, or node to parse JSONL records" >&2
  exit 2
fi
# NOTE: a missing VALIDATE_RUNNER (no python3 and no node) is NOT a startup error.
# The read paths (query, match-rate, list) still work on a jq-only host. Only the
# append path requires a validation runner, and it fails closed there (see
# validate_record_fields), so a jq-only host can still query but cannot write.

# ---------------------------------------------------------------------------
# Shared JSONL helpers (always use jq/python3/node — never string-interpolate
# into filter expressions; all user inputs passed as --arg variables to avoid
# injection).
# ---------------------------------------------------------------------------

# ledger_records_python — emit all valid records as JSON lines, skipping
# partial/invalid lines with a stderr warning. Used by python3/node paths.
ledger_read_all_python() {
  python3 - "$LEDGER" <<'PY'
import json, sys

path = sys.argv[1]
CURRENT_SCHEMA = 1

try:
    lines = open(path, encoding="utf-8").readlines()
except FileNotFoundError:
    sys.exit(0)  # empty ledger is valid
except Exception as e:
    sys.stderr.write("decision-ledger: cannot read ledger: %s\n" % e)
    sys.exit(1)

for i, line in enumerate(lines, 1):
    line = line.rstrip("\n\r")
    if not line.strip():
        continue
    try:
        rec = json.loads(line)
    except json.JSONDecodeError as e:
        sys.stderr.write("decision-ledger: skipping malformed line %d: %s\n" % (i, e))
        continue
    # Forward-compatible: missing schemaVersion treated as 1.
    sv = rec.get("schemaVersion", 1)
    if not isinstance(sv, int):
        sys.stderr.write("decision-ledger: warning — line %d has unrecognized schemaVersion %r (processing anyway)\n" % (i, sv))
    # Forward defaults for optional fields.
    rec.setdefault("matchScore", None)
    rec.setdefault("challengeRan", False)
    rec.setdefault("predictionConfidence", None)
    rec.setdefault("predictedRuling", None)
    rec.setdefault("challengeOutcome", None)
    rec.setdefault("challengeReason", None)
    rec.setdefault("decisionClass", "unclassified")
    rec.setdefault("domain", "code")
    print(json.dumps(rec))
PY
}

ledger_read_all_node() {
  node - "$LEDGER" <<'NODE'
const fs = require("fs");
const path = process.argv[2];
let content;
try { content = fs.readFileSync(path, "utf8"); } catch (e) {
  if (e.code === "ENOENT") process.exit(0);
  process.stderr.write("decision-ledger: cannot read ledger: " + e.message + "\n");
  process.exit(1);
}
const lines = content.split("\n");
lines.forEach((line, i) => {
  line = line.trim();
  if (!line) return;
  let rec;
  try { rec = JSON.parse(line); } catch (e) {
    process.stderr.write("decision-ledger: skipping malformed line " + (i+1) + ": " + e.message + "\n");
    return;
  }
  if (!rec.schemaVersion) rec.schemaVersion = 1;
  if (rec.matchScore === undefined) rec.matchScore = null;
  if (rec.challengeRan === undefined) rec.challengeRan = false;
  if (rec.predictionConfidence === undefined) rec.predictionConfidence = null;
  if (rec.predictedRuling === undefined) rec.predictedRuling = null;
  if (rec.challengeOutcome === undefined) rec.challengeOutcome = null;
  if (rec.challengeReason === undefined) rec.challengeReason = null;
  if (rec.decisionClass === undefined) rec.decisionClass = "unclassified";
  if (rec.domain === undefined) rec.domain = "code";
  process.stdout.write(JSON.stringify(rec) + "\n");
});
NODE
}

# Emit all valid records (one JSON line each) via the chosen runner.
ledger_read_all() {
  if [ ! -f "$LEDGER" ]; then return; fi
  case "$JSON_RUNNER" in
    jq)
      # jq reads JSONL as a stream of independent inputs by default (one per line).
      # Read each line defensively (skip malformed lines), then apply the same
      # forward-compatible defaults the python/node helpers use so every reader
      # path produces records with the same shape.
      jq -Rc '
        . as $line
        | (try ($line | fromjson) catch null)
        | select(. != null)
        | .matchScore           //= null
        | .challengeRan         //= false
        | .predictionConfidence //= null
        | .predictedRuling      //= null
        | .challengeOutcome     //= null
        | .challengeReason      //= null
        | .decisionClass        //= "unclassified"
        | .domain               //= "code"
      ' "$LEDGER" 2>/dev/null || true
      ;;
    python3) ledger_read_all_python ;;
    node) ledger_read_all_node ;;
  esac
}

# ---------------------------------------------------------------------------
# Runner-agnostic per-line JSON helpers. Each reads ONE JSON record on stdin
# and dispatches on $JSON_RUNNER (jq → python3 → node), so query/list behave
# identically on every supported runner — no python3-only else branches that
# silently return wrong answers on a node-only host (AC #3).
# ---------------------------------------------------------------------------

# json_field_equals <field> <value>  — prints "yes" if record[field]==value (exact, string-compared), else "no".
json_field_equals() {
  local field="$1" value="$2"
  case "$JSON_RUNNER" in
    jq)
      jq -r --arg f "$field" --arg v "$value" 'if ((.[$f] // "") | tostring) == $v then "yes" else "no" end' 2>/dev/null || echo "no"
      ;;
    python3)
      FIELD="$field" VALUE="$value" python3 -c '
import json,os,sys
try:
  r=json.loads(sys.stdin.read())
  # Raw compare (no trim) to match the jq read path; append rejects whitespace on
  # identity fields, so stored values are already clean and all three runners agree.
  print("yes" if str(r.get(os.environ["FIELD"],""))==os.environ["VALUE"] else "no")
except Exception:
  print("no")
' 2>/dev/null || echo "no"
      ;;
    node)
      FIELD="$field" VALUE="$value" node -e '
let d="";process.stdin.on("data",c=>d+=c);process.stdin.on("end",()=>{
  try{const r=JSON.parse(d);const v=r[process.env.FIELD];
    // Raw compare (no trim) to match the jq read path; append rejects identity
    // whitespace, so stored values are already clean and all three runners agree.
    process.stdout.write(String(v==null?"":v)===process.env.VALUE?"yes":"no");
  }catch{process.stdout.write("no");}
});' 2>/dev/null || echo "no"
      ;;
  esac
}

# json_pretty — pretty-print one JSON record from stdin.
json_pretty() {
  case "$JSON_RUNNER" in
    jq)      jq . 2>/dev/null || cat ;;
    python3) python3 -c 'import json,sys; print(json.dumps(json.loads(sys.stdin.read()),indent=2))' 2>/dev/null || cat ;;
    node)    node -e 'let d="";process.stdin.on("data",c=>d+=c);process.stdin.on("end",()=>{try{console.log(JSON.stringify(JSON.parse(d),null,2));}catch{process.stdout.write(d);}});' 2>/dev/null || cat ;;
  esac
}

# json_project — emit a compact projection of the list-view fields from stdin.
json_project() {
  case "$JSON_RUNNER" in
    jq)
      jq -c '{issueId,forkId,domain,decisionType,decisionClass,matchScore,actualRuling,timestamp}' 2>/dev/null || cat
      ;;
    python3)
      python3 -c '
import json,sys
r=json.loads(sys.stdin.read())
out={k:r.get(k) for k in ["issueId","forkId","domain","decisionType","decisionClass","matchScore","actualRuling","timestamp"]}
print(json.dumps(out))
' 2>/dev/null || cat
      ;;
    node)
      node -e '
let d="";process.stdin.on("data",c=>d+=c);process.stdin.on("end",()=>{
  try{const r=JSON.parse(d);const keys=["issueId","forkId","domain","decisionType","decisionClass","matchScore","actualRuling","timestamp"];
    const o={};keys.forEach(k=>o[k]=r[k]===undefined?null:r[k]);console.log(JSON.stringify(o));
  }catch{process.stdout.write(d+"\n");}
});' 2>/dev/null || cat
      ;;
  esac
}

# Validate mandatory fields for a record about to be appended.
# Exits non-zero with an error message if invalid.
#
# Validation runs on python3 OR node ONLY. The two validators below enforce
# IDENTICAL rules so the accept/reject verdict is the same regardless of which host
# tool is present (see the parity-fixture battery in shadow-compare.test.sh). jq is
# NOT a validation runner (it cannot enforce integer-vs-float schemaVersion, reject
# numeric-string predictionConfidence, or check the domain/challengeOutcome enums
# without diverging), so if neither python3 nor node is available, append fails
# closed here with a non-zero exit rather than falling back to a weaker gate.
validate_record_fields() {
  local rec_file="$1"
  if [ -z "$VALIDATE_RUNNER" ]; then
    echo "decision-ledger append: record validation requires python3 or node, but neither is installed; refusing to append (fail closed). jq cannot validate the schema bounds/enums and is not used for validation." >&2
    exit 2
  fi
  if [ "$VALIDATE_RUNNER" = "python3" ]; then
    python3 - "$rec_file" <<'PY'
import json, sys
try:
    rec = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception as e:
    sys.stderr.write("decision-ledger: record is not valid JSON: %s\n" % e)
    sys.exit(1)
required = ["schemaVersion", "issueId", "forkId", "domain", "decisionType", "decisionClass", "timestamp"]
for f in required:
    if f not in rec or rec[f] is None:
        sys.stderr.write("decision-ledger: record missing required field '%s'\n" % f)
        sys.exit(1)
# Required fields must be present AND non-empty (after trimming).
for f in required:
    if str(rec.get(f, "")).strip() == "":
        sys.stderr.write("decision-ledger: required field '%s' must be non-empty\n" % f)
        sys.exit(1)
# Identity/grouping fields must NOT carry leading/trailing whitespace: the stored
# value must equal its trimmed form (raw == trimmed). This keeps stored ids clean so
# the query path (which may or may not trim) cannot diverge. An empty issueId/forkId
# also defeats the (issueId,forkId) dedup key.
for f in ("issueId", "forkId", "domain", "decisionClass"):
    raw = rec.get(f)
    if not isinstance(raw, str):
        sys.stderr.write("decision-ledger: identity field '%s' must be a string\n" % f)
        sys.exit(1)
    if raw != raw.strip():
        sys.stderr.write("decision-ledger: identity field '%s' has leading/trailing whitespace (store trimmed values)\n" % f)
        sys.exit(1)
# schemaVersion value must be numerically 1: accept 1, 1.0, 1e0; reject 1.5, 2,
# strings ("1"), bools, non-numbers. Value-based (not type-based) so python3 (which
# splits int/float) and node (one number type) reach the SAME verdict. bool is an int
# subclass in Python, so exclude it explicitly.
sv = rec["schemaVersion"]
if isinstance(sv, bool) or not isinstance(sv, (int, float)) or sv != 1:
    sys.stderr.write("decision-ledger: schemaVersion value must be 1\n")
    sys.exit(1)
# domain enum.
if rec.get("domain") not in ("code", "content"):
    sys.stderr.write("decision-ledger: domain must be 'code' or 'content'\n")
    sys.exit(1)
# decisionType enum.
if rec.get("decisionType") not in ("tier-a", "tier-b"):
    sys.stderr.write("decision-ledger: decisionType must be 'tier-a' or 'tier-b'\n")
    sys.exit(1)
# matchScore enum (or null/absent).
ms = rec.get("matchScore")
if ms is not None and ms not in ("exact", "partial", "miss"):
    sys.stderr.write("decision-ledger: matchScore must be 'exact', 'partial', 'miss', or null\n")
    sys.exit(1)
# challengeOutcome enum (or null/absent).
co = rec.get("challengeOutcome")
if co is not None and co not in ("agreed", "pushed-back", "unresolved"):
    sys.stderr.write("decision-ledger: challengeOutcome must be 'agreed', 'pushed-back', 'unresolved', or null\n")
    sys.exit(1)
# predictionConfidence: a JSON number in [0.0, 1.0], or null/absent. No string
# coercion on either runner (reject "0.5"); bool is rejected as a non-number.
pc = rec.get("predictionConfidence")
if pc is not None:
    if isinstance(pc, bool) or not isinstance(pc, (int, float)):
        sys.stderr.write("decision-ledger: predictionConfidence must be a JSON number or null (no string coercion)\n")
        sys.exit(1)
    if not (0.0 <= float(pc) <= 1.0):
        sys.stderr.write("decision-ledger: predictionConfidence out of range [0.0,1.0]: %r\n" % pc)
        sys.exit(1)
# Validate all free-text fields are single-line (no embedded CR/LF).
for field in ("rationale", "predictedRuling", "actualRuling", "recommendation", "challengeReason"):
    v = rec.get(field)
    if isinstance(v, str) and ("\n" in v or "\r" in v):
        sys.stderr.write("decision-ledger: field '%s' contains embedded newline, strip before writing\n" % field)
        sys.exit(1)
sys.exit(0)
PY
  else
    node - "$rec_file" <<'NODE'
const fs = require("fs");
let rec;
try { rec = JSON.parse(fs.readFileSync(process.argv[2], "utf8")); } catch (e) {
  process.stderr.write("decision-ledger: record is not valid JSON: " + e.message + "\n");
  process.exit(1);
}
const req = ["schemaVersion","issueId","forkId","domain","decisionType","decisionClass","timestamp"];
for (const f of req) {
  if (!(f in rec) || rec[f] === null || rec[f] === undefined) {
    process.stderr.write("decision-ledger: record missing required field '" + f + "'\n");
    process.exit(1);
  }
}
// Required fields must be present AND non-empty (after trimming).
for (const f of req) {
  if (String(rec[f]).trim() === "") {
    process.stderr.write("decision-ledger: required field '" + f + "' must be non-empty\n");
    process.exit(1);
  }
}
// Identity/grouping fields must NOT carry leading/trailing whitespace: raw === trimmed.
// Keeps stored ids clean so the query path cannot diverge; an empty issueId/forkId
// also defeats the (issueId,forkId) dedup key.
for (const f of ["issueId","forkId","domain","decisionClass"]) {
  const raw = rec[f];
  if (typeof raw !== "string") {
    process.stderr.write("decision-ledger: identity field '" + f + "' must be a string\n"); process.exit(1);
  }
  if (raw !== raw.trim()) {
    process.stderr.write("decision-ledger: identity field '" + f + "' has leading/trailing whitespace (store trimmed values)\n"); process.exit(1);
  }
}
// schemaVersion value must be numerically 1: accept 1, 1.0, 1e0; reject 1.5, 2,
// strings, non-numbers. Value-based (sv === 1), matching the python3 path, so the two
// runners agree despite different number models.
const sv = rec.schemaVersion;
if (typeof sv !== "number" || sv !== 1) {
  process.stderr.write("decision-ledger: schemaVersion value must be 1\n"); process.exit(1);
}
// domain enum.
if (rec.domain !== "code" && rec.domain !== "content") {
  process.stderr.write("decision-ledger: domain must be 'code' or 'content'\n"); process.exit(1);
}
// decisionType enum.
if (!["tier-a","tier-b"].includes(rec.decisionType)) {
  process.stderr.write("decision-ledger: decisionType must be 'tier-a' or 'tier-b'\n"); process.exit(1);
}
// matchScore enum (or null/absent).
const ms = rec.matchScore;
if (ms !== null && ms !== undefined && !["exact","partial","miss"].includes(ms)) {
  process.stderr.write("decision-ledger: matchScore must be 'exact', 'partial', 'miss', or null\n");
  process.exit(1);
}
// challengeOutcome enum (or null/absent).
const co = rec.challengeOutcome;
if (co !== null && co !== undefined && !["agreed","pushed-back","unresolved"].includes(co)) {
  process.stderr.write("decision-ledger: challengeOutcome must be 'agreed', 'pushed-back', 'unresolved', or null\n");
  process.exit(1);
}
// predictionConfidence: a JSON number in [0.0,1.0], or null/absent. No string
// coercion (reject "0.5"); reject booleans and non-finite.
const pc = rec.predictionConfidence;
if (pc !== null && pc !== undefined) {
  if (typeof pc !== "number" || !isFinite(pc)) {
    process.stderr.write("decision-ledger: predictionConfidence must be a JSON number or null (no string coercion)\n");
    process.exit(1);
  }
  if (pc < 0 || pc > 1) {
    process.stderr.write("decision-ledger: predictionConfidence out of range [0.0,1.0]: " + pc + "\n");
    process.exit(1);
  }
}
for (const f of ["rationale","predictedRuling","actualRuling","recommendation","challengeReason"]) {
  const v = rec[f];
  if (typeof v === "string" && (v.includes("\n") || v.includes("\r"))) {
    process.stderr.write("decision-ledger: field '" + f + "' contains embedded newline\n"); process.exit(1);
  }
}
process.exit(0);
NODE
  fi
}

# ---------------------------------------------------------------------------
# Subcommand: query — retrieve decisions by issueId or forkId (exact match)
# Usage: decision-ledger.sh query --issue <N>
#        decision-ledger.sh query --fork <forkId>
# ---------------------------------------------------------------------------
cmd_query() {
  local filter_issue="" filter_fork=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --issue) filter_issue="$2"; shift 2 ;;
      --fork)  filter_fork="$2";  shift 2 ;;
      *) echo "decision-ledger query: unknown option '$1'" >&2; exit 2 ;;
    esac
  done

  if [ -z "$filter_issue" ] && [ -z "$filter_fork" ]; then
    echo "decision-ledger query: requires --issue <N> or --fork <forkId>" >&2
    exit 2
  fi

  if [ ! -f "$LEDGER" ]; then
    echo "decision-ledger: no ledger found at $LEDGER" >&2
    exit 1
  fi

  local found=0
  # Iterate normalized records (ledger_read_all works on jq/python3/node alike).
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    # Exact field match — NOT a grep on raw text. Runner-agnostic.
    local matches=true

    if [ -n "$filter_issue" ]; then
      local got_issue; got_issue="$(printf '%s' "$line" | json_field_equals issueId "$filter_issue")"
      [ "$got_issue" != "yes" ] && matches=false
    fi

    if [ -n "$filter_fork" ]; then
      local got_fork; got_fork="$(printf '%s' "$line" | json_field_equals forkId "$filter_fork")"
      [ "$got_fork" != "yes" ] && matches=false
    fi

    if [ "$matches" = "true" ]; then
      printf '%s' "$line" | json_pretty
      found=$((found + 1))
    fi
  done < <(ledger_read_all)

  if [ "$found" -eq 0 ]; then
    echo "decision-ledger: no records found for the given filter" >&2
    exit 1
  fi
  echo "---"
  echo "decision-ledger: $found record(s) found"
}

# ---------------------------------------------------------------------------
# Subcommand: match-rate — rolling match-rate grouped by domain + decisionClass
# Usage: decision-ledger.sh match-rate [--domain code|content] [--class <spine>]
#
# Only records with actualRuling AND predictedRuling AND matchScore are scored.
# Reports: count of ran/not-ran challenger states, exact/partial/miss per group.
# ---------------------------------------------------------------------------
cmd_match_rate() {
  local filter_domain="" filter_class=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --domain) filter_domain="$2"; shift 2 ;;
      --class)  filter_class="$2";  shift 2 ;;
      *) echo "decision-ledger match-rate: unknown option '$1'" >&2; exit 2 ;;
    esac
  done

  if [ ! -f "$LEDGER" ]; then
    echo "decision-ledger: no ledger found at $LEDGER" >&2
    echo "match-rate: 0 scorable records"
    exit 0
  fi

  # Prefer python3, then node, then jq for match-rate aggregation. All three paths
  # produce the SAME report (Total-records, per-group exact/partial/miss, Challenger
  # availability, Overall summary) and all skip a malformed middle line individually
  # rather than aborting the whole stream (the ledger is append-only and a crash can
  # leave a partial last line — one bad line must not zero out the report).
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$LEDGER" "$filter_domain" "$filter_class" <<'PY'
import json, sys
from collections import defaultdict

path, fdom, fcls = sys.argv[1], sys.argv[2], sys.argv[3]

records = []
try:
    for i, line in enumerate(open(path, encoding="utf-8"), 1):
        line = line.strip()
        if not line: continue
        try:
            r = json.loads(line)
        except:
            sys.stderr.write("decision-ledger: skipping malformed line %d\n" % i)
            continue
        r.setdefault("matchScore", None)
        r.setdefault("domain", "code")
        r.setdefault("decisionClass", "unclassified")
        r.setdefault("challengeRan", False)
        records.append(r)
except FileNotFoundError:
    pass

# Dedup on (issueId, forkId) — last-row-wins (later rows have ruling info).
# Key is a 2-tuple (collision-proof: two fields never flatten into one ambiguous
# string), matching the NUL-joined keys the jq/node paths use.
seen = {}
for r in records:
    key = (str(r.get("issueId","")), str(r.get("forkId","")))
    seen[key] = r
records = list(seen.values())

# Apply filters.
if fdom:
    records = [r for r in records if r.get("domain") == fdom]
if fcls:
    records = [r for r in records if r.get("decisionClass") == fcls]

# Only Tier-A records with a matchScore are scorable.
scorable = [r for r in records if r.get("decisionType") == "tier-a" and r.get("matchScore") in ("exact","partial","miss")]

if not records:
    print("match-rate: no records (empty or filtered ledger)")
    sys.exit(0)

print("match-rate report")
print("=================")
print("Total records: %d (after dedup)" % len(records))

# Check for required field presence — flag missing rather than silently skip.
for r in records:
    if not r.get("decisionClass"):
        sys.stderr.write("decision-ledger: record forkId=%r is missing decisionClass — counted as 'unclassified'\n" % r.get("forkId"))
    if not r.get("domain"):
        sys.stderr.write("decision-ledger: record forkId=%r is missing domain — counted as 'code' (default)\n" % r.get("forkId"))

# Group scorable by (domain, decisionClass).
groups = defaultdict(lambda: {"exact": 0, "partial": 0, "miss": 0, "total": 0})
for r in scorable:
    key = (r.get("domain","code"), r.get("decisionClass","unclassified"))
    groups[key][r["matchScore"]] += 1
    groups[key]["total"] += 1

print("\nMatch-rate by domain + decision-class (Tier-A, scored only):")
if not groups:
    print("  No scored Tier-A records yet.")
else:
    for (dom, cls), counts in sorted(groups.items()):
        total = counts["total"]
        exact = counts["exact"]
        pct = int(100 * exact / total) if total else 0
        print("  [%s / %s] exact=%d partial=%d miss=%d total=%d (exact-rate=%d%%)" % (
            dom, cls, exact, counts["partial"], counts["miss"], total, pct))

# Challenger availability report.
tier_a_all = [r for r in records if r.get("decisionType") == "tier-a"]
ch_ran = sum(1 for r in tier_a_all if r.get("challengeRan") is True)
ch_notran = sum(1 for r in tier_a_all if r.get("challengeRan") is False)
ch_unclear = len(tier_a_all) - ch_ran - ch_notran
print("\nChallenger availability (Tier-A records):")
print("  ran: %d   not-ran: %d   unclear: %d" % (ch_ran, ch_notran, ch_unclear))

# Overall summary.
if scorable:
    total_sc = len(scorable)
    total_exact = sum(1 for r in scorable if r.get("matchScore") == "exact")
    total_partial = sum(1 for r in scorable if r.get("matchScore") == "partial")
    total_miss = sum(1 for r in scorable if r.get("matchScore") == "miss")
    pct = int(100 * total_exact / total_sc) if total_sc else 0
    print("\nOverall: exact=%d partial=%d miss=%d / %d scored (exact-rate=%d%%)" % (
        total_exact, total_partial, total_miss, total_sc, pct))
else:
    print("\nOverall: no scored records yet.")
PY
  elif [ "$JSON_RUNNER" = "jq" ]; then
    # jq path, brought to full parity with python3/node. Source records from
    # ledger_read_all (which reads each line defensively and SKIPS a malformed line
    # individually, so one bad middle line no longer zeroes out the whole report -
    # the previous [inputs] slurp aborted the stream on the first parse error).
    # Then slurp the normalized stream with -s and emit the same report shape:
    # Total-records, per-group lines, Challenger availability, and Overall summary.
    ledger_read_all | jq -s -r --arg fd "$filter_domain" --arg fc "$filter_class" '
      # Dedup key joins (issueId, forkId) with a NUL byte that cannot appear in a
      # normalized id, so two distinct forks never collide into one ambiguous string
      # (a bare or space separator collides on multi-token ids like "1 2"/"3").
      (reduce .[] as $r ({}; .[(($r.issueId|tostring) + "\u0000" + ($r.forkId|tostring))] = $r) | [.[]]) as $allDeduped
      # Apply the domain/class filter to the FULL deduped set BEFORE deriving Total,
      # Challenger-availability, and scorable — so every reported line covers the same
      # filtered population (matches the python3 path; jq/node previously filtered only
      # $scorable, so Total + Challenger-availability ignored the filter).
      | ($allDeduped
         | map(select($fd == "" or .domain == $fd)
               | select($fc == "" or .decisionClass == $fc))) as $deduped
      | ($deduped
         | map(select(.decisionType == "tier-a")
               | select((.matchScore // null) != null))) as $scorable
      | ($deduped | map(select(.decisionType == "tier-a"))) as $tierA
      | "match-rate report",
        "=================",
        "Total records: \($deduped | length) (after dedup)",
        "",
        "Match-rate by domain + decision-class (Tier-A, scored only):",
        ( if ($scorable | length) == 0 then "  No scored Tier-A records yet."
          else
            ( $scorable
              | group_by((.domain // "code") + " / " + (.decisionClass // "unclassified"))
              | .[]
              | {
                  key: ((.[0].domain // "code") + " / " + (.[0].decisionClass // "unclassified")),
                  exact: (map(select(.matchScore=="exact")) | length),
                  partial: (map(select(.matchScore=="partial")) | length),
                  miss: (map(select(.matchScore=="miss")) | length),
                  total: length
                }
              | "  [\(.key)] exact=\(.exact) partial=\(.partial) miss=\(.miss) total=\(.total) (exact-rate=\(if .total>0 then (100*.exact/.total|floor) else 0 end)%)" )
          end ),
        "",
        "Challenger availability (Tier-A records):",
        "  ran: \($tierA | map(select(.challengeRan == true)) | length)   not-ran: \($tierA | map(select(.challengeRan == false)) | length)   unclear: \($tierA | map(select(.challengeRan != true and .challengeRan != false)) | length)",
        "",
        ( if ($scorable | length) == 0 then "Overall: no scored records yet."
          else
            "Overall: exact=\($scorable | map(select(.matchScore=="exact")) | length) partial=\($scorable | map(select(.matchScore=="partial")) | length) miss=\($scorable | map(select(.matchScore=="miss")) | length) / \($scorable | length) scored (exact-rate=\(if ($scorable|length)>0 then (100 * ($scorable | map(select(.matchScore=="exact")) | length) / ($scorable | length) | floor) else 0 end)%)"
          end )
    ' 2>/dev/null || echo "(jq aggregation unavailable — ledger may be empty)"
  else
    # node path: dedup + group identically to python3/jq.
    node - "$LEDGER" "$filter_domain" "$filter_class" <<'NODE'
const fs = require("fs");
const [,, ledger, fd, fc] = process.argv;
let lines;
try { lines = fs.readFileSync(ledger, "utf8").split("\n"); } catch { console.log("match-rate: no ledger"); process.exit(0); }
const records = [];
lines.forEach((line, i) => {
  line = line.trim(); if (!line) return;
  try { const r = JSON.parse(line); records.push(r); } catch { process.stderr.write("skip line " + (i+1) + "\n"); }
});
// Dedup on (issueId, forkId) last-row-wins — match the python3/jq paths.
// Join the two id fields with a NUL byte that cannot appear in a normalized id, so
// two distinct forks never collapse to the same key (a bare "" separator collides:
// issueId "1"+forkId "23" and issueId "12"+forkId "3" both keyed to "123").
const seen = {};
records.forEach(r => { seen[String(r.issueId) + "\u0000" + String(r.forkId)] = r; });
// Apply the domain/class filter to the FULL deduped set BEFORE deriving Total,
// Challenger-availability, and scorable — so every reported line covers the same
// filtered population (matches python3; previously only $scorable was filtered, so
// Total + Challenger-availability ignored the filter).
const deduped = Object.values(seen)
  .filter(r => !fd || r.domain === fd)
  .filter(r => !fc || r.decisionClass === fc);
console.log("match-rate report");
console.log("=================");
console.log("Total records: " + deduped.length + " (after dedup)");
const scorable = deduped
  .filter(r => r.decisionType === "tier-a" && ["exact","partial","miss"].includes(r.matchScore));
const groups = {};
scorable.forEach(r => {
  const k = (r.domain||"code") + " / " + (r.decisionClass||"unclassified");
  if (!groups[k]) groups[k] = {exact:0,partial:0,miss:0,total:0};
  groups[k][r.matchScore]++; groups[k].total++;
});
console.log("");
console.log("Match-rate by domain + decision-class (Tier-A, scored only):");
const gkeys = Object.keys(groups).sort();
if (gkeys.length === 0) {
  console.log("  No scored Tier-A records yet.");
} else {
  gkeys.forEach(k => {
    const c = groups[k];
    const pct = c.total ? Math.floor(100*c.exact/c.total) : 0;
    console.log("  [" + k + "] exact=" + c.exact + " partial=" + c.partial + " miss=" + c.miss + " total=" + c.total + " (exact-rate=" + pct + "%)");
  });
}
// Challenger availability — match the python3/jq paths.
const tierA = deduped.filter(r => r.decisionType === "tier-a");
const chRan = tierA.filter(r => r.challengeRan === true).length;
const chNot = tierA.filter(r => r.challengeRan === false).length;
const chUnclear = tierA.length - chRan - chNot;
console.log("");
console.log("Challenger availability (Tier-A records):");
console.log("  ran: " + chRan + "   not-ran: " + chNot + "   unclear: " + chUnclear);
// Overall summary.
console.log("");
if (scorable.length === 0) {
  console.log("Overall: no scored records yet.");
} else {
  const ex = scorable.filter(r => r.matchScore === "exact").length;
  const pa = scorable.filter(r => r.matchScore === "partial").length;
  const mi = scorable.filter(r => r.matchScore === "miss").length;
  const pct = Math.floor(100*ex/scorable.length);
  console.log("Overall: exact=" + ex + " partial=" + pa + " miss=" + mi + " / " + scorable.length + " scored (exact-rate=" + pct + "%)");
}
NODE
  fi
}

# ---------------------------------------------------------------------------
# Subcommand: list — enumerate records with optional filters
# Usage: decision-ledger.sh list [--issue <N>] [--domain code|content]
# ---------------------------------------------------------------------------
cmd_list() {
  local filter_issue="" filter_domain=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --issue) filter_issue="$2"; shift 2 ;;
      --domain) filter_domain="$2"; shift 2 ;;
      *) echo "decision-ledger list: unknown option '$1'" >&2; exit 2 ;;
    esac
  done

  if [ ! -f "$LEDGER" ]; then
    echo "decision-ledger: no ledger found at $LEDGER"
    exit 0
  fi

  local count=0
  # Iterate normalized records (runner-agnostic, like cmd_query).
  while IFS= read -r line; do
    [ -z "${line// /}" ] && continue
    local include=true

    if [ -n "$filter_issue" ]; then
      local got; got="$(printf '%s' "$line" | json_field_equals issueId "$filter_issue")"
      [ "$got" != "yes" ] && include=false
    fi

    if [ -n "$filter_domain" ]; then
      local got; got="$(printf '%s' "$line" | json_field_equals domain "$filter_domain")"
      [ "$got" != "yes" ] && include=false
    fi

    if [ "$include" = "true" ]; then
      printf '%s' "$line" | json_project
      count=$((count + 1))
    fi
  done < <(ledger_read_all)

  echo "---"
  echo "decision-ledger: $count record(s)"
}

# ---------------------------------------------------------------------------
# Subcommand: append — write one complete, validated ledger record (atomic).
# For TRUSTED /arc SKILL use only. The skill passes a JSON file containing the
# full record; this tool validates it and appends atomically.
# Usage: decision-ledger.sh append <json-file>
# ---------------------------------------------------------------------------
cmd_append() {
  local rec_file="${1:-}"
  if [ -z "$rec_file" ]; then
    echo "decision-ledger append: requires <json-file> argument" >&2
    exit 2
  fi
  if [ ! -f "$rec_file" ]; then
    echo "decision-ledger append: file not found: $rec_file" >&2
    exit 2
  fi

  # Validate before writing.
  validate_record_fields "$rec_file"

  # Serialize to a single-line JSON string (no embedded newlines).
  local json_line
  if [ "$JSON_RUNNER" = "jq" ]; then
    json_line="$(jq -c . "$rec_file")"
  elif [ "$JSON_RUNNER" = "python3" ]; then
    json_line="$(python3 -c "import json,sys; print(json.dumps(json.load(open(sys.argv[1],'r',encoding='utf-8'))))" "$rec_file")"
  else
    json_line="$(node -e "process.stdout.write(JSON.stringify(JSON.parse(require('fs').readFileSync(process.argv[2],'utf8'))))" - "$rec_file")"
  fi

  if [ -z "$json_line" ]; then
    echo "decision-ledger append: failed to serialize record" >&2
    exit 1
  fi

  # Atomic append: write to temp file on same filesystem, then cat-append.
  # This keeps each record on a single complete line (POSIX O_APPEND is atomic
  # for pipe-buf-sized writes on local filesystems, but JSON.stringify output
  # can exceed PIPE_BUF for large rationale fields, so we use the safer pattern).
  local ledger_dir; ledger_dir="$(dirname "$LEDGER")"
  mkdir -p "$ledger_dir"

  local tmp; tmp="$(mktemp "$ledger_dir/.decision-ledger-append.XXXXXX")"
  # Guarantee the temp file is removed on ANY exit path (cat failure, signal),
  # so a write error can't leak temp files into the ledger dir indefinitely.
  trap 'rm -f "$tmp"' EXIT
  printf '%s\n' "$json_line" > "$tmp"

  # Validate the written line round-trips correctly (every runner gets the check).
  case "$JSON_RUNNER" in
    jq)      jq -e . "$tmp" >/dev/null 2>&1 || { echo "decision-ledger append: written line failed round-trip validation" >&2; exit 1; } ;;
    python3) python3 -c "import json,sys; json.loads(open(sys.argv[1]).read())" "$tmp" >/dev/null 2>&1 || { echo "decision-ledger append: written line failed round-trip validation" >&2; exit 1; } ;;
    node)    node -e "JSON.parse(require('fs').readFileSync(process.argv[2],'utf8'))" - "$tmp" >/dev/null 2>&1 || { echo "decision-ledger append: written line failed round-trip validation" >&2; exit 1; } ;;
  esac

  # Atomic append, serialized against concurrent writers. The schema is
  # at-most-one-writer by design (the trusted skill serializes appends), but a
  # flock guard makes an accidental concurrent append safe rather than relying on
  # POSIX O_APPEND atomicity (which does not hold for >PIPE_BUF lines). flock is
  # Linux/util-linux; on hosts without it (e.g. stock macOS) we fall back to the
  # plain append, which the single-writer invariant already makes safe.
  if command -v flock >/dev/null 2>&1; then
    local lockfile="$ledger_dir/.decision-ledger.lock"
    (
      flock 9 || { echo "decision-ledger append: could not acquire write lock" >&2; exit 1; }
      cat "$tmp" >> "$LEDGER"
    ) 9>"$lockfile"
  else
    cat "$tmp" >> "$LEDGER"
  fi
  rm -f "$tmp"
  trap - EXIT
  # Extract forkId for the confirmation line via $JSON_RUNNER (covers node-only
  # hosts too — the previous jq||python3 form left forkId= empty when only node
  # was present, which was the tell that the node append path had no test).
  local _forkid
  case "$JSON_RUNNER" in
    jq)      _forkid="$(jq -r '.forkId // "?"' "$rec_file" 2>/dev/null || echo '?')" ;;
    python3) _forkid="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('forkId','?'))" "$rec_file" 2>/dev/null || echo '?')" ;;
    node)    _forkid="$(node -e "process.stdout.write(String(JSON.parse(require('fs').readFileSync(process.argv[2],'utf8')).forkId||'?'))" - "$rec_file" 2>/dev/null || echo '?')" ;;
    *)       _forkid="?" ;;
  esac
  echo "decision-ledger: appended record for forkId=$_forkid"
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------

case "$SUBCOMMAND" in
  query)      shift; cmd_query "$@" ;;
  match-rate) shift; cmd_match_rate "$@" ;;
  list)       shift; cmd_list "$@" ;;
  append)     shift; cmd_append "$@" ;;
  ""|--help|-h)
    cat <<USAGE
decision-ledger.sh — arc decision ledger query tool (domain-neutral)

Subcommands:
  query      --issue <N>           Retrieve all decisions for issue N (exact id match)
  query      --fork <forkId>       Retrieve a specific fork decision
  match-rate [--domain code|content] [--class <spine>]
                                   Rolling match-rate per decision-class per domain
  list       [--issue <N>] [--domain code|content]
                                   List all records (optional filters)
  append     <json-file>           (trusted /arc skill only) Append one ledger record

Ledger: .gstack/arc-rulings/decisions.jsonl (gitignored runtime state)

Examples (per AC #3 and AC #4):
  bash .claude/workflows/decision-ledger.sh query --issue 32
  bash .claude/workflows/decision-ledger.sh match-rate
  bash .claude/workflows/decision-ledger.sh match-rate --domain code --class tech-choice
  bash .claude/workflows/decision-ledger.sh list --issue 32

Schema: schemaVersion 1. See file header for full field list.
USAGE
    exit 0
    ;;
  *)
    echo "decision-ledger: unknown subcommand '$SUBCOMMAND'. Run with --help for usage." >&2
    exit 2
    ;;
esac
