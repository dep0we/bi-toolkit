#!/usr/bin/env bash
# govcheck.test.sh - governing-doc baseline and change protection.

set -uo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$KIT/.claude/workflows/govcheck.sh"

PASS=0
FAIL=0
pass() { printf '  PASS  %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf '  FAIL  %s\n' "$1"; FAIL=$((FAIL + 1)); }

run_gate() {
  local dir="$1"; shift
  local errf
  errf="$(mktemp "${TMPDIR:-/tmp}/govcheck.err.XXXXXX")"
  OUT="$(cd "$dir" && bash "$SCRIPT" "$@" 2>"$errf")"
  RC=$?
  ERR="$(cat "$errf")"
  rm -f "$errf"
}

write_project() {
  local dir="$1"
  printf 'rule: keep methods stable\n' > "$dir/GOV.md"
  cat > "$dir/assay.config.jsonc" <<'JSON'
{
  "governingDocs": ["GOV.md"]
}
JSON
}

echo "govcheck tests"
echo "=============="

T="$(mktemp -d "${TMPDIR:-/tmp}/govcheck.XXXXXX")"
write_project "$T"
run_gate "$T" snapshot retention-q2
run_gate "$T" check retention-q2
if [ "$RC" -eq 0 ]; then
  pass "passes when guarded docs are unchanged"
else
  fail "expected unchanged governing docs to pass (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/govcheck.XXXXXX")"
write_project "$T"
run_gate "$T" snapshot retention-q2
printf 'rule: changed during analysis\n' > "$T/GOV.md"
run_gate "$T" check retention-q2
if [ "$RC" -eq 1 ] && printf '%s\n' "$OUT" | grep -qx 'assay-gate-failed:governing-doc-edit'; then
  pass "blocks changed guarded doc"
else
  fail "expected governing-doc-edit block (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

T="$(mktemp -d "${TMPDIR:-/tmp}/govcheck.XXXXXX")"
write_project "$T"
run_gate "$T" snapshot retention-q2
printf 'rule: operator-approved update\n' > "$T/GOV.md"
run_gate "$T" resnapshot retention-q2
if [ "$RC" -eq 1 ] && printf '%s\n' "$OUT" | grep -qx 'assay-gate-failed:governing-doc-edit'; then
  pass "blocks resnapshot without operator approval flag"
else
  fail "expected resnapshot without approval to block (rc=$RC stdout=$OUT stderr=$ERR)"
fi
errf="$(mktemp "${TMPDIR:-/tmp}/govcheck.err.XXXXXX")"
OUT="$(cd "$T" && ASSAY_GOVCHECK_APPROVED=1 bash "$SCRIPT" resnapshot retention-q2 2>"$errf")"
RC=$?
ERR="$(cat "$errf")"
rm -f "$errf"
run_gate "$T" check retention-q2
if [ "$RC" -eq 0 ]; then
  pass "approved resnapshot establishes a new baseline"
else
  fail "expected approved resnapshot to pass later check (rc=$RC stdout=$OUT stderr=$ERR)"
fi
rm -rf "$T"

echo ""
echo "govcheck: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
