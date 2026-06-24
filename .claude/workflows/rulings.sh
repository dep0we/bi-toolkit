#!/usr/bin/env bash
# rulings.sh - durable methodology rulings for the assay execute gate.

set -euo pipefail

SUBCOMMAND="${1:-}"
ID="${2:-}"
ARG3="${3:-}"
RULINGS_DIR="${ASSAY_RULINGS_DIR:-.assay/rulings}"

usage() {
  cat >&2 <<'USAGE'
rulings.sh: usage:
  rulings.sh discovery <analysis-id> <discovery-run-id> [fork-ids-json]
  rulings.sh write     <analysis-id> <discovery-run-id> [json-file]
  rulings.sh reaffirm  <analysis-id> [json-file]
  rulings.sh check     <analysis-id>

JSON is a structured data file. A ruling is the operator's approved method choice.
USAGE
  exit 2
}

[ -n "$SUBCOMMAND" ] && [ -n "$ID" ] || usage

case "$ID" in
  *[!A-Za-z0-9._-]*|"") echo "rulings.sh: analysis-id may use only letters, numbers, dot, underscore, and dash" >&2; exit 2 ;;
esac

need_json_runner() {
  if command -v python3 >/dev/null 2>&1; then
    echo python3
  else
    echo "rulings.sh: requires python3 to read JSON. JSON is a structured data file." >&2
    exit 2
  fi
}

gate() {
  local token="$1" message="$2"
  printf 'assay-gate-failed:%s\n' "$token"
  printf 'rulingscheck: %s\n' "$message" >&2
  exit 1
}

tmp_payload=""
cleanup() {
  if [ -n "$tmp_payload" ]; then
    rm -f "$tmp_payload"
  fi
  return 0
}
trap cleanup EXIT

payload_source() {
  local source="${1:-}"
  if [ -z "$source" ] || [ "$source" = "-" ]; then
    tmp_payload="$(mktemp "${TMPDIR:-/tmp}/assay-rulings.XXXXXX")"
    cat > "$tmp_payload"
    echo "$tmp_payload"
  else
    echo "$source"
  fi
}

RUNNER="$(need_json_runner)"
mkdir -p "$RULINGS_DIR"

case "$SUBCOMMAND" in
  discovery)
    DISCOVERY_RUN_ID="$ARG3"
    [ -n "$DISCOVERY_RUN_ID" ] || usage
    SOURCE="$(payload_source "${4:-}")"
    "$RUNNER" - "$ID" "$DISCOVERY_RUN_ID" "$RULINGS_DIR" "$SOURCE" <<'PY'
import json, os, sys, tempfile

analysis_id, discovery_run_id, rulings_dir, source = sys.argv[1:5]
raw = open(source, encoding="utf-8").read().strip()
if raw:
    data = json.loads(raw)
    fork_ids = data.get("forkIds", data) if isinstance(data, dict) else data
else:
    fork_ids = []
if not isinstance(fork_ids, list) or not all(isinstance(x, str) and x.strip() for x in fork_ids):
    print("rulings.sh: fork ids must be a JSON array of non-empty strings", file=sys.stderr)
    raise SystemExit(2)
out = {
    "schemaVersion": 1,
    "analysisId": analysis_id,
    "discoveryRunId": discovery_run_id,
    "forkIds": fork_ids,
    "recordedAt": __import__("datetime").datetime.now(__import__("datetime").timezone.utc).isoformat().replace("+00:00", "Z"),
}
os.makedirs(rulings_dir, exist_ok=True)
dest = os.path.join(rulings_dir, f"{analysis_id}-latest-discovery.json")
fd, tmp = tempfile.mkstemp(prefix=f".{analysis_id}-latest-discovery.", suffix=".tmp", dir=rulings_dir)
with os.fdopen(fd, "w", encoding="utf-8") as f:
    json.dump(out, f, indent=2)
    f.write("\n")
os.replace(tmp, dest)
print(f"assay-discovery-recorded:{dest}")
PY
    ;;
  write)
    DISCOVERY_RUN_ID="$ARG3"
    [ -n "$DISCOVERY_RUN_ID" ] || usage
    SOURCE="$(payload_source "${4:-}")"
    "$RUNNER" - "$ID" "$DISCOVERY_RUN_ID" "$RULINGS_DIR" "$SOURCE" <<'PY'
import json, os, sys, tempfile
from datetime import datetime, timezone

analysis_id, discovery_run_id, rulings_dir, source = sys.argv[1:5]

def fail(msg):
    print(f"rulings.sh: {msg}", file=sys.stderr)
    raise SystemExit(2)

try:
    data = json.load(open(source, encoding="utf-8"))
except Exception as exc:
    fail(f"payload is not readable JSON. JSON is a structured data file. {exc}")
if not isinstance(data, dict):
    fail("payload must be a JSON object. A JSON object is key-value data.")
fork_ids = data.get("forkIds")
rulings = data.get("rulings")
if not isinstance(fork_ids, list) or not all(isinstance(x, str) and x.strip() for x in fork_ids):
    fail("payload needs forkIds as a JSON array of non-empty strings")
if not isinstance(rulings, dict):
    fail("payload needs rulings as a JSON object keyed by fork id")
missing = []
for fork_id in fork_ids:
    value = rulings.get(fork_id)
    if isinstance(value, str):
        ok = bool(value.strip())
    elif isinstance(value, dict):
        ok = isinstance(value.get("ruling"), str) and bool(value["ruling"].strip())
    else:
        ok = False
    if not ok:
        missing.append(fork_id)
if missing:
    fail("every surfaced fork needs an operator ruling. Missing: " + ", ".join(missing))
now = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
out = {
    "schemaVersion": 1,
    "analysisId": analysis_id,
    "discoveryRunId": discovery_run_id,
    "forkIds": fork_ids,
    "rulings": rulings,
    "createdAt": data.get("createdAt") or now,
    "updatedAt": now,
}
if isinstance(data.get("operator"), str):
    out["operator"] = data["operator"]
if isinstance(data.get("note"), str):
    out["note"] = data["note"]
os.makedirs(rulings_dir, exist_ok=True)
latest = os.path.join(rulings_dir, f"{analysis_id}-latest-discovery.json")
dest = os.path.join(rulings_dir, f"{analysis_id}-rulings.json")
for path, payload in [
    (latest, {"schemaVersion": 1, "analysisId": analysis_id, "discoveryRunId": discovery_run_id, "forkIds": fork_ids, "recordedAt": now}),
    (dest, out),
]:
    fd, tmp = tempfile.mkstemp(prefix=f".{os.path.basename(path)}.", suffix=".tmp", dir=rulings_dir)
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)
        f.write("\n")
    os.replace(tmp, path)
print(f"assay-rulings-written:{dest}")
PY
    ;;
  reaffirm)
    SOURCE="$(payload_source "$ARG3")"
    "$RUNNER" - "$ID" "$RULINGS_DIR" "$SOURCE" <<'PY'
import json, os, sys, tempfile
from datetime import datetime, timezone

analysis_id, rulings_dir, source = sys.argv[1:4]

def fail(msg):
    print(f"rulings.sh: {msg}", file=sys.stderr)
    raise SystemExit(2)

latest_path = os.path.join(rulings_dir, f"{analysis_id}-latest-discovery.json")
rulings_path = os.path.join(rulings_dir, f"{analysis_id}-rulings.json")
try:
    latest = json.load(open(latest_path, encoding="utf-8"))
except Exception:
    fail("cannot reaffirm because no latest discovery run is recorded")
try:
    current = json.load(open(rulings_path, encoding="utf-8"))
except Exception:
    fail("cannot reaffirm because no rulings file exists")
raw = open(source, encoding="utf-8").read().strip()
data = json.loads(raw) if raw else {}
if not isinstance(data, dict):
    fail("reaffirm payload must be a JSON object. A JSON object is key-value data.")
reason = data.get("reason")
if not isinstance(reason, str) or not reason.strip():
    fail("reaffirm needs reason. A reason explains the approved re-use.")
rulings = data.get("rulings", current.get("rulings"))
fork_ids = latest.get("forkIds", [])
missing = []
for fork_id in fork_ids:
    value = rulings.get(fork_id) if isinstance(rulings, dict) else None
    if isinstance(value, str):
        ok = bool(value.strip())
    elif isinstance(value, dict):
        ok = isinstance(value.get("ruling"), str) and bool(value["ruling"].strip())
    else:
        ok = False
    if not ok:
        missing.append(fork_id)
if missing:
    fail("cannot reaffirm until every current fork has a ruling. Missing: " + ", ".join(missing))
now = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
current.update({
    "schemaVersion": 1,
    "analysisId": analysis_id,
    "discoveryRunId": latest.get("discoveryRunId"),
    "forkIds": fork_ids,
    "rulings": rulings,
    "updatedAt": now,
    "reaffirmedAt": now,
    "reaffirmationReason": reason.strip(),
})
fd, tmp = tempfile.mkstemp(prefix=f".{analysis_id}-rulings.", suffix=".tmp", dir=rulings_dir)
with os.fdopen(fd, "w", encoding="utf-8") as f:
    json.dump(current, f, indent=2)
    f.write("\n")
os.replace(tmp, rulings_path)
print(f"assay-rulings-reaffirmed:{rulings_path}")
PY
    ;;
  check)
    "$RUNNER" - "$ID" "$RULINGS_DIR" <<'PY'
import json, os, sys

analysis_id, rulings_dir = sys.argv[1:3]
latest_path = os.path.join(rulings_dir, f"{analysis_id}-latest-discovery.json")
rulings_path = os.path.join(rulings_dir, f"{analysis_id}-rulings.json")

def result(token, message):
    print(f"assay-gate-failed:{token}")
    print(f"rulingscheck: {message}", file=sys.stderr)
    raise SystemExit(1)

if not os.path.exists(rulings_path):
    result("missing-rulings", f"Stage 6 is blocked because no methodology rulings file exists at {rulings_path}. A ruling is the operator's approved method choice.")
if not os.path.exists(latest_path):
    result("missing-discovery", f"Stage 6 is blocked because no latest discovery run is recorded at {latest_path}. Discovery run means one pass that surfaced method choices.")
try:
    rulings = json.load(open(rulings_path, encoding="utf-8"))
    latest = json.load(open(latest_path, encoding="utf-8"))
except Exception:
    result("invalid-rulings", "Stage 6 is blocked because the rulings files are not readable JSON. JSON is a structured data file.")
if rulings.get("discoveryRunId") != latest.get("discoveryRunId"):
    result("stale-rulings", "Stage 6 is blocked because methodology rulings are stale: they came from an older discovery run. Stale means not from the newest review.")
fork_ids = latest.get("forkIds")
if not isinstance(fork_ids, list):
    result("invalid-rulings", "Stage 6 is blocked because the latest discovery file has no forkIds list. Fork ids are method-choice names.")
ruling_map = rulings.get("rulings")
if not isinstance(ruling_map, dict):
    result("incomplete-rulings", "Stage 6 is blocked because the rulings file has no rulings object. Rulings object means choices keyed by fork.")
missing = []
for fork_id in fork_ids:
    value = ruling_map.get(fork_id)
    if isinstance(value, str):
        ok = bool(value.strip())
    elif isinstance(value, dict):
        ok = isinstance(value.get("ruling"), str) and bool(value["ruling"].strip())
    else:
        ok = False
    if not ok:
        missing.append(fork_id)
if missing:
    result("incomplete-rulings", "Stage 6 is blocked because surfaced methodology forks have no operator ruling: " + ", ".join(missing) + ". Surfaced means discovery found it.")
PY
    printf 'assay-gate-ok:rulingscheck\n' >&2
    ;;
  ""|--help|-h)
    usage
    ;;
  *)
    usage
    ;;
esac
