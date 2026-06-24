#!/usr/bin/env bash
# install.test.sh — install.sh must ship ALL skills (the /assay router + the 31
# domain skills) and the engine, not just the router. Regression guard for the
# bug where only assay/SKILL.md was copied to a fresh project.
set -uo pipefail
KIT="$(cd "$(dirname "$0")/.." && pwd)"
pass=0; fail=0
check() { if eval "$2"; then echo "  PASS  $1"; pass=$((pass + 1)); else echo "  FAIL  $1"; fail=$((fail + 1)); fi; }
json_check() {
  local label="$1" file="$2" expr="$3"
  if python3 - "$file" "$expr" <<'PY'
import json
import sys

path, expr = sys.argv[1:3]
data = json.load(open(path, encoding="utf-8"))
command = "bash .claude/hooks/governing-reminder.sh"
entries = data.get("hooks", {}).get("UserPromptSubmit", [])
count = 0
for entry in entries:
    if isinstance(entry, dict):
        for hook in entry.get("hooks", []):
            if isinstance(hook, dict) and hook.get("type") == "command" and hook.get("command") == command:
                count += 1
env_keep = data.get("env", {}).get("KEEP") == "yes"
pre_tool = "PreToolUse" in data.get("hooks", {})
checks = {
    "hook_once": count == 1,
    "preserved": env_keep and pre_tool,
}
raise SystemExit(0 if checks[expr] else 1)
PY
  then
    echo "  PASS  $label"; pass=$((pass + 1))
  else
    echo "  FAIL  $label"; fail=$((fail + 1))
  fi
}

echo "install tests"
echo "============="
T="$(mktemp -d)"
bash "$KIT/install.sh" "$T" >/dev/null 2>&1
n=$(find "$T/.claude/skills" -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')
check "installs the /assay router + domain skills (>=31)" "[ \"$n\" -ge 31 ]"
check "installs the engine workflows" "[ -f \"$T/.claude/workflows/assay-execute.js\" ] && [ -f \"$T/.claude/workflows/assay-validate.js\" ]"
check "installs the gates + receipt/rulings/report writers" "[ -f \"$T/.claude/workflows/config.sh\" ] && [ -f \"$T/.claude/workflows/questioncheck.sh\" ] && [ -f \"$T/.claude/workflows/receipt.sh\" ] && [ -x \"$T/.claude/workflows/report-render.sh\" ] && [ -f \"$T/.claude/workflows/rulings.sh\" ] && [ -f \"$T/.claude/workflows/govcheck.sh\" ] && [ -f \"$T/.claude/workflows/datacheck.sh\" ] && [ -f \"$T/.claude/workflows/reprocheck.sh\" ] && [ -f \"$T/.claude/workflows/assay-state.sh\" ] && [ -f \"$T/.claude/workflows/assay-active.sh\" ] && [ -f \"$T/.claude/workflows/assay-help.sh\" ] && [ -f \"$T/.claude/workflows/assay-preflight.sh\" ]"
check "installs the data-safety policy doc" "[ -f \"$T/data-safety.md\" ]"
check "installs active lesson loader" "[ -f \"$T/.claude/workflows/lesson-loader.js\" ]"
check "installs the governing reminder hook script" "[ -x \"$T/.claude/hooks/governing-reminder.sh\" ]"
memory_bullets="$(grep -c '^- ' "$T/seed-memory/MEMORY.md" 2>/dev/null || echo 0)"
check "generates seed-memory/MEMORY.md index" "[ -f \"$T/seed-memory/MEMORY.md\" ] && [ \"$memory_bullets\" -ge 4 ]"
json_check "merges hook into fresh settings.json" "$T/.claude/settings.json" hook_once
bash "$KIT/install.sh" "$T" >/dev/null 2>&1
json_check "hook merge is idempotent on rerun" "$T/.claude/settings.json" hook_once
check "does not ship the dev-kit arc loop" "[ ! -e \"$T/.claude/skills/arc\" ]"
rm -rf "$T"

T="$(mktemp -d)"
mkdir -p "$T/seed-memory"
printf 'custom index\n' > "$T/seed-memory/MEMORY.md"
bash "$KIT/install.sh" "$T" >/dev/null 2>&1
check "does not overwrite existing seed-memory/MEMORY.md" "grep -qx 'custom index' \"$T/seed-memory/MEMORY.md\""
rm -rf "$T"

T="$(mktemp -d)"
mkdir -p "$T/.claude"
cat > "$T/.claude/settings.json" <<'JSON'
{
  "env": {
    "KEEP": "yes"
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "echo preexisting"
          }
        ]
      }
    ]
  }
}
JSON
bash "$KIT/install.sh" "$T" >/dev/null 2>&1
json_check "preserves pre-existing settings while adding hook" "$T/.claude/settings.json" preserved
json_check "pre-existing settings merge has one reminder hook" "$T/.claude/settings.json" hook_once
rm -rf "$T"
echo ""
echo "install: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
