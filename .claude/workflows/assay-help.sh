#!/usr/bin/env bash
# assay-help.sh - operator-facing help and next-step guidance.

set -euo pipefail

ID="${1:-}"
ACTIVE_FILE="${ASSAY_ACTIVE_FILE:-.assay/active.json}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "$ID" ] && [ -f "$ACTIVE_FILE" ] && command -v python3 >/dev/null 2>&1; then
  ID="$(python3 - "$ACTIVE_FILE" <<'PY' 2>/dev/null || true
import json
import sys
try:
    data = json.load(open(sys.argv[1], encoding="utf-8"))
    print(data.get("analysisId", ""))
except Exception:
    print("")
PY
)"
fi

case "$ID" in
  *[!A-Za-z0-9._-]*)
    echo "assay-help: analysis-id may use only letters, numbers, dot, underscore, and dash" >&2
    exit 2
    ;;
esac

state_text=""
if [ -n "$ID" ]; then
  state_text="$(bash "$SCRIPT_DIR/assay-state.sh" status "$ID" 2>/dev/null || true)"
elif [ -d ".assay/receipts" ] || [ -d ".assay/rulings" ]; then
  state_text="$(bash "$SCRIPT_DIR/assay-state.sh" status 2>/dev/null || true)"
  one_id="$(printf '%s\n' "$state_text" | awk -F '\t' 'NF >= 2 {count += 1; id = $1} END {if (count == 1) print id}')"
  if [ -n "$one_id" ]; then
    state_text="$(bash "$SCRIPT_DIR/assay-state.sh" status "$one_id" 2>/dev/null || true)"
  fi
fi

cat <<'EOF'
assay help

What this kit does: it guides BI work from question to trusted answer. BI means business reporting and metrics.

Lifecycle:
Stage 0 Intake - capture your tools, data, owners, and done rules.
Stage 1 Frame - name the decision and choose analysis or data product.
Stage 2 Spec - define the question and metrics before running numbers.
Stage 5 Discovery - find method choices before results are computed.
Stage 6 Execute - run the ruled analysis or build the report.
Stage 7 Validate - reconcile to source-of-truth, meaning official comparison place.
Stage 8 Review - red-team the answer, meaning independently attack weak spots.
Stage 9 Deliver - package the answer after proof exists.
Stage 11 Document - save assumptions, queries, and checks.
Stage 12 Learn - record what should be reused next time.

Commands:
/assay intake - start a new project.
/assay frame - start or route one analysis.
/assay status - see saved progress.
/assay resume - continue the active analysis.
EOF

echo ""
if [ -n "$state_text" ]; then
  echo "Current next step:"
  printf '%s\n' "$state_text" | awk '/^next required step:/ {print; found=1} END {if (!found) print "next required step: /assay status"}'
else
  echo "Current next step:"
  echo "next required step: /assay intake"
  echo "No active analysis or receipts were found. Receipts are saved proof files."
fi
