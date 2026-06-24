#!/usr/bin/env bash
# assay-preflight.sh - single dispatcher for enforced assay chokepoints.

set -euo pipefail

CHECKPOINT="${1:-}"
ID="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  echo "assay-preflight: usage: assay-preflight.sh <discovery|execute|deliver> <analysis-id>" >&2
  echo "assay-preflight: checkpoint means a named stopping point in workflow." >&2
  exit 2
}

[ -n "$CHECKPOINT" ] && [ -n "$ID" ] || usage

case "$ID" in
  *[!A-Za-z0-9._-]*|"")
    echo "assay-preflight: analysis-id may use only letters, numbers, dot, underscore, and dash" >&2
    exit 2
    ;;
esac

case "$CHECKPOINT" in
  discovery)
    bash "$SCRIPT_DIR/govcheck.sh" snapshot "$ID"
    ;;
  execute)
    bash "$SCRIPT_DIR/questioncheck.sh" "$ID"
    bash "$SCRIPT_DIR/rulings.sh" check "$ID"
    ;;
  deliver)
    bash "$SCRIPT_DIR/validationcheck.sh" "$ID"
    bash "$SCRIPT_DIR/datacheck.sh" "$ID"
    bash "$SCRIPT_DIR/govcheck.sh" check "$ID"
    ;;
  *)
    usage
    ;;
esac
