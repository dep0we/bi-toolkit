#!/usr/bin/env bash
# Reminder injector only: keeps rules salient, but it is not a hard block.

main() {
  printf '%s\n' 'Governing rules: route analysis through /assay; validate with an independent red-teamer sub-agent (worker agent given narrow task); do not bypass assay-preflight gates; do not rewrite protected governing docs during analysis.'

  local active_file="${ASSAY_ACTIVE_FILE:-.assay/active.json}"
  local state_script=".claude/workflows/assay-state.sh"

  if [ ! -f "$active_file" ]; then
    printf '%s\n' 'No active analysis - run /assay status or /assay help.'
    return 0
  fi

  local active
  if command -v python3 >/dev/null 2>&1; then
    active="$(python3 - "$active_file" <<'PY' 2>/dev/null || true
import json
import sys
try:
    data = json.load(open(sys.argv[1], encoding="utf-8"))
    analysis_id = str(data.get("analysisId", "")).strip()
    track = str(data.get("track", "")).strip() or "unknown"
    print(f"{analysis_id}\t{track}")
except Exception:
    print("\t")
PY
)"
  else
    active="$(awk '
      /"analysisId"[[:space:]]*:/ {
        value=$0
        sub(/^.*"analysisId"[[:space:]]*:[[:space:]]*"/, "", value)
        sub(/".*$/, "", value)
        id=value
      }
      /"track"[[:space:]]*:/ {
        value=$0
        sub(/^.*"track"[[:space:]]*:[[:space:]]*"/, "", value)
        sub(/".*$/, "", value)
        track=value
      }
      END { print id "\t" track }
    ' "$active_file" 2>/dev/null || true)"
  fi

  local analysis_id track
  IFS=$'\t' read -r analysis_id track <<EOF
$active
EOF
  case "$analysis_id" in
    *[!A-Za-z0-9._-]*|"")
      printf '%s\n' 'No active analysis - run /assay status or /assay help.'
      return 0
      ;;
  esac
  [ -n "$track" ] || track="unknown"

  if [ ! -x "$state_script" ] && [ ! -f "$state_script" ]; then
    printf 'Active analysis: %s (%s). Next required step: /assay status %s. Run /assay status.\n' "$analysis_id" "$track" "$analysis_id"
    return 0
  fi

  local state_json summary
  state_json="$(bash "$state_script" json "$analysis_id" 2>/dev/null || true)"
  if [ -n "$state_json" ] && command -v python3 >/dev/null 2>&1; then
    summary="$(ACTIVE_TRACK="$track" STATE_JSON="$state_json" python3 - <<'PY' 2>/dev/null || true
import json
import os
import sys
try:
    data = json.loads(os.environ.get("STATE_JSON", ""))
except Exception:
    raise SystemExit(0)
analysis_id = data.get("analysisId") or "unknown"
track = data.get("track") or os.environ.get("ACTIVE_TRACK") or "unknown"
stage = data.get("stage") or {}
number = stage.get("number")
stage_text = f"Stage {number}" if number is not None else "Stage unknown"
next_step = data.get("nextStep") or f"/assay status {analysis_id}"
run = "/assay resume"
if isinstance(next_step, str) and next_step.startswith("/assay "):
    parts = next_step.split()
    if len(parts) >= 2:
        run = f"/assay {parts[1]}"
print(f"Active analysis: {analysis_id} ({stage_text}, {track}). Next required step: {next_step}. Run {run}.")
PY
)"
  fi

  if [ -n "${summary:-}" ]; then
    printf '%s\n' "$summary"
  else
    printf 'Active analysis: %s (%s). Next required step: /assay status %s. Run /assay status.\n' "$analysis_id" "$track" "$analysis_id"
  fi
  return 0
}

main "$@" || true
exit 0
