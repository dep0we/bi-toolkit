#!/usr/bin/env bash
# check-prereqs.sh - report whether the assay kit can run in this folder.

set -uo pipefail

MODE="${1:-report}"
case "$MODE" in
  report|--quiet|--lint|"") ;;
  -h|--help)
    sed -n '2,28p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
  *)
    echo "check-prereqs: unknown argument '$MODE'" >&2
    exit 2
    ;;
esac

have() { command -v "$1" >/dev/null 2>&1; }

req_missing=0
warn_missing=0

line() {
  [ "$MODE" = "--quiet" ] || printf '%s\n' "$1"
}

check_required_cli() {
  local name="$1" hint="$2"
  if have "$name"; then
    line "ok       $name"
  else
    printf 'MISSING  %s\n         -> %s\n' "$name" "$hint"
    req_missing=$((req_missing + 1))
  fi
}

check_optional_cli() {
  local name="$1" hint="$2"
  if have "$name"; then
    line "ok       $name"
  else
    printf 'optional %s\n         -> %s\n' "$name" "$hint"
    warn_missing=$((warn_missing + 1))
  fi
}

check_required_json_runner() {
  if have python3 || have node; then
    line "ok       python3 or node"
  else
    printf 'MISSING  python3 or node\n         -> Install one JSON runner so gates can read receipt files.\n'
    req_missing=$((req_missing + 1))
  fi
}

check_required_skill_file() {
  local path="$1"
  if [ -f "$path" ]; then
    line "ok       $path"
  else
    printf 'MISSING  %s\n         -> Run ./install.sh in the target project.\n' "$path"
    req_missing=$((req_missing + 1))
  fi
}

if [ "$MODE" = "--lint" ]; then
  for cmd in assay; do
    if ! grep -R "/$cmd" -n README.md PLAYBOOK.md .claude/skills/assay/SKILL.md >/dev/null 2>&1; then
      echo "check-prereqs --lint: expected /$cmd to be documented" >&2
      exit 1
    fi
  done
  echo "check-prereqs --lint: docs mention /assay. OK"
  exit 0
fi

line "bi-toolkit prerequisite check"
line "============================="
check_required_cli bash "Install bash; macOS and Linux usually include it."
check_required_cli git "Install git so receipts and project files can be managed."
check_required_cli curl "Install curl; bootstrap uses it to download the public kit."
check_required_json_runner
check_required_skill_file ".claude/skills/assay/SKILL.md"
check_required_skill_file ".claude/workflows/questioncheck.sh"
check_required_skill_file ".claude/workflows/validationcheck.sh"
check_optional_cli codex "Optional cross-family model, meaning a second model family for review."

echo "Summary: required missing=${req_missing}, optional missing=${warn_missing}"
[ "$req_missing" -eq 0 ]
