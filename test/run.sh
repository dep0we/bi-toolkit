#!/usr/bin/env bash
# run.sh - run the bi-toolkit Phase 1 test suite.

set -uo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$KIT"

fail=0

for t in test/*.test.sh; do
  [ -e "$t" ] || continue
  echo "=== $t ==="
  bash "$t" || { echo "  ^ FAILED: $t"; fail=1; }
done

echo ""
if [ "$fail" -eq 0 ]; then
  echo "test/run.sh: all suites passed"
else
  echo "test/run.sh: one or more suites FAILED"
fi
exit "$fail"
