#!/usr/bin/env bash
# install.sh - copy the assay spine into a target analysis project.

set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
CHECK=false
TARGET=""

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --check) CHECK=true ;;
    --check-prereqs) exec bash "$KIT/check-prereqs.sh" ;;
    -*) echo "install.sh: unknown flag '$arg'" >&2; exit 2 ;;
    *) TARGET="$arg" ;;
  esac
done

TARGET="${TARGET:-$(pwd)}"
mkdir -p "$TARGET" 2>/dev/null || true
TARGET="$(cd "$TARGET" && pwd)"

say() { printf '%s\n' "$*"; }
run() { if $DRY_RUN; then printf '  [dry-run] %q' "$1"; shift; printf ' %q' "$@"; printf '\n'; else "$@"; fi; }

if $CHECK; then
  missing=()
  for f in \
    ".claude/skills/assay/SKILL.md" \
    ".claude/hooks/governing-reminder.sh" \
    ".claude/workflows/config.sh" \
    ".claude/workflows/assay-preflight.sh" \
    ".claude/workflows/receipt.sh" \
    ".claude/workflows/report-render.sh" \
    ".claude/workflows/dashboard-render.sh" \
    ".claude/workflows/deliverable-diff.sh" \
    ".claude/workflows/driftcheck.sh" \
    ".claude/workflows/distribution-manifest.sh" \
    ".claude/workflows/rulings.sh" \
    ".claude/workflows/govcheck.sh" \
    ".claude/workflows/questioncheck.sh" \
    ".claude/workflows/validationcheck.sh" \
    ".claude/workflows/datacheck.sh" \
    ".claude/workflows/reprocheck.sh" \
    ".claude/workflows/assay-state.sh" \
    ".claude/workflows/assay-active.sh" \
    ".claude/workflows/assay-help.sh" \
    ".claude/workflows/assay-discovery.js" \
    ".claude/workflows/assay-execute.js" \
    ".claude/workflows/assay-validate.js" \
    ".claude/workflows/lesson-loader.js" \
    ".claude/workflows/decision-ledger.sh" \
    "assay.config.jsonc" \
    "data-safety.md"; do
    [ -e "$TARGET/$f" ] || missing+=("$f")
  done
  if [ "${#missing[@]}" -eq 0 ]; then
    say "assay spine is installed in $TARGET"
    exit 0
  fi
  say "assay spine is incomplete in $TARGET"
  for f in "${missing[@]}"; do say "  missing: $f"; done
  exit 1
fi

say "Installing bi-toolkit assay spine into: $TARGET"
$DRY_RUN && say "(dry run - no files written)"

copy_file() {
  local src="$1" dest="$2"
  if $DRY_RUN; then
    printf '  [dry-run] copy %s -> %s\n' "${src#"$KIT"/}" "${dest#"$TARGET"/}"
    return
  fi
  mkdir -p "$(dirname "$dest")"
  local tmp="${dest}.tmp.$$"
  rm -f "$tmp"
  cp "$src" "$tmp"
  mv -f "$tmp" "$dest"
}

copy_if_missing() {
  local src="$1" dest="$2" label="$3"
  if [ -e "$dest" ]; then
    say "  left untouched: $label"
  else
    copy_file "$src" "$dest"
    say "  created: $label"
  fi
}

merge_governing_hook() {
  local settings="$TARGET/.claude/settings.json"
  local command='bash .claude/hooks/governing-reminder.sh'

  if $DRY_RUN; then
    say "  [dry-run] merge UserPromptSubmit hook into .claude/settings.json"
    return
  fi

  mkdir -p "$TARGET/.claude"
  if command -v python3 >/dev/null 2>&1; then
    if result="$(python3 - "$settings" "$command" <<'PY'
import json
import os
import sys
import tempfile

path, command = sys.argv[1:3]
if os.path.exists(path):
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
    except Exception as exc:
        print(f"skip: existing .claude/settings.json is not readable JSON. JSON is a structured data file. {exc}")
        raise SystemExit(3)
    if not isinstance(data, dict):
        print("skip: existing .claude/settings.json is not a JSON object. A JSON object is key-value data.")
        raise SystemExit(3)
else:
    data = {}

hooks = data.setdefault("hooks", {})
if not isinstance(hooks, dict):
    print("skip: existing hooks setting is not a JSON object. A JSON object is key-value data.")
    raise SystemExit(3)
entries = hooks.setdefault("UserPromptSubmit", [])
if not isinstance(entries, list):
    print("skip: existing UserPromptSubmit hooks setting is not a list.")
    raise SystemExit(3)

for entry in entries:
    if isinstance(entry, dict):
        for hook in entry.get("hooks", []):
            if isinstance(hook, dict) and hook.get("type") == "command" and hook.get("command") == command:
                print("already present: UserPromptSubmit governing reminder hook")
                raise SystemExit(0)

entries.append({"hooks": [{"type": "command", "command": command}]})
os.makedirs(os.path.dirname(path), exist_ok=True)
fd, tmp = tempfile.mkstemp(prefix=".settings.", suffix=".tmp", dir=os.path.dirname(path))
try:
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    os.replace(tmp, path)
except Exception:
    try:
        os.unlink(tmp)
    except OSError:
        pass
    raise
print("installed: UserPromptSubmit governing reminder hook")
PY
)"; then
      say "  $result"
    else
      say "  hook merge skipped: $result"
    fi
  elif command -v node >/dev/null 2>&1; then
    if result="$(node - "$settings" "$command" <<'NODE'
const fs = require("fs");
const os = require("os");
const path = require("path");
const [settingsPath, command] = process.argv.slice(2);

let data = {};
if (fs.existsSync(settingsPath)) {
  try {
    data = JSON.parse(fs.readFileSync(settingsPath, "utf8"));
  } catch (e) {
    console.log(`skip: existing .claude/settings.json is not readable JSON. JSON is a structured data file. ${e.message}`);
    process.exit(3);
  }
  if (!data || Array.isArray(data) || typeof data !== "object") {
    console.log("skip: existing .claude/settings.json is not a JSON object. A JSON object is key-value data.");
    process.exit(3);
  }
}
if (data.hooks === undefined) data.hooks = {};
if (!data.hooks || Array.isArray(data.hooks) || typeof data.hooks !== "object") {
  console.log("skip: existing hooks setting is not a JSON object. A JSON object is key-value data.");
  process.exit(3);
}
if (data.hooks.UserPromptSubmit === undefined) data.hooks.UserPromptSubmit = [];
if (!Array.isArray(data.hooks.UserPromptSubmit)) {
  console.log("skip: existing UserPromptSubmit hooks setting is not a list.");
  process.exit(3);
}
const exists = data.hooks.UserPromptSubmit.some((entry) =>
  entry && typeof entry === "object" && Array.isArray(entry.hooks) &&
  entry.hooks.some((hook) => hook && hook.type === "command" && hook.command === command)
);
if (exists) {
  console.log("already present: UserPromptSubmit governing reminder hook");
  process.exit(0);
}
data.hooks.UserPromptSubmit.push({ hooks: [{ type: "command", command }] });
fs.mkdirSync(path.dirname(settingsPath), { recursive: true });
const tmp = path.join(path.dirname(settingsPath), `.settings.${process.pid}.${Date.now()}.tmp`);
fs.writeFileSync(tmp, `${JSON.stringify(data, null, 2)}\n`);
fs.renameSync(tmp, settingsPath);
console.log("installed: UserPromptSubmit governing reminder hook");
NODE
)"; then
      say "  $result"
    else
      say "  hook merge skipped: $result"
    fi
  else
    say "  hook merge skipped: python3 or node is required to merge .claude/settings.json without clobbering existing settings."
  fi
}

# Copy every skill the kit ships — the /assay router AND the 31 domain skills —
# not just the router. (arc is the dev-kit's machine-local loop, never shipped.)
skill_count=0
for d in "$KIT"/.claude/skills/*/; do
  [ -d "$d" ] || continue
  name="$(basename "$d")"
  [ "$name" = "arc" ] && continue
  if $DRY_RUN; then
    say "  [dry-run] copy .claude/skills/$name/"
  else
    mkdir -p "$TARGET/.claude/skills/$name"
    cp -R "$d." "$TARGET/.claude/skills/$name/"
  fi
  skill_count=$((skill_count + 1))
done
say "  installed: .claude/skills/ ($skill_count skills, incl. the /assay router)"

if [ -d "$KIT/.claude/hooks" ]; then
  if $DRY_RUN; then
    say "  [dry-run] copy .claude/hooks/"
  else
    mkdir -p "$TARGET/.claude/hooks"
    cp -R "$KIT/.claude/hooks/." "$TARGET/.claude/hooks/"
    chmod +x "$TARGET/.claude/hooks/governing-reminder.sh" 2>/dev/null || true
  fi
  say "  installed: .claude/hooks/"
fi
merge_governing_hook

for f in config.sh assay-preflight.sh receipt.sh report-render.sh dashboard-render.sh deliverable-diff.sh driftcheck.sh distribution-manifest.sh rulings.sh govcheck.sh questioncheck.sh validationcheck.sh datacheck.sh reprocheck.sh assay-state.sh assay-active.sh assay-help.sh decision-ledger.sh; do
  copy_file "$KIT/.claude/workflows/$f" "$TARGET/.claude/workflows/$f"
  $DRY_RUN || chmod +x "$TARGET/.claude/workflows/$f"
  say "  installed: .claude/workflows/$f"
done

for f in lesson-loader.js assay-discovery.js assay-execute.js assay-validate.js; do
  copy_file "$KIT/.claude/workflows/$f" "$TARGET/.claude/workflows/$f"
  say "  installed: .claude/workflows/$f"
done

if [ -d "$KIT/.claude/agents" ]; then
  if $DRY_RUN; then
    say "  [dry-run] copy .claude/agents/"
  else
    mkdir -p "$TARGET/.claude/agents"
    cp -R "$KIT/.claude/agents/." "$TARGET/.claude/agents/"
  fi
  say "  installed: .claude/agents/"
fi

copy_if_missing "$KIT/assay.config.example.jsonc" "$TARGET/assay.config.jsonc" "assay.config.jsonc"
copy_if_missing "$KIT/CLAUDE.starter.md" "$TARGET/CLAUDE.md" "CLAUDE.md"
copy_if_missing "$KIT/PLAYBOOK.md" "$TARGET/PLAYBOOK.md" "PLAYBOOK.md"
copy_if_missing "$KIT/methodology.md" "$TARGET/methodology.md" "methodology.md"
copy_if_missing "$KIT/model-dial.md" "$TARGET/model-dial.md" "model-dial.md"
copy_if_missing "$KIT/claude-md-guide.md" "$TARGET/claude-md-guide.md" "claude-md-guide.md"
copy_if_missing "$KIT/data-safety.md" "$TARGET/data-safety.md" "data-safety.md"

if $DRY_RUN; then
  say "  [dry-run] seed memory files"
else
  mkdir -p "$TARGET/seed-memory"
  for f in "$KIT"/seed-memory/*.md; do
    [ -e "$f" ] || continue
    dest="$TARGET/seed-memory/$(basename "$f")"
    [ -e "$dest" ] || cp "$f" "$dest"
  done
  if [ ! -e "$TARGET/seed-memory/MEMORY.md" ]; then
    {
      printf '# BI Toolkit Memory Index\n\n'
      for f in "$TARGET"/seed-memory/*.md; do
        [ -e "$f" ] || continue
        [ "$(basename "$f")" = "MEMORY.md" ] && continue
        title="$(awk '/^# / { sub(/^# /, ""); print; exit }' "$f")"
        [ -n "$title" ] || title="$(basename "$f" .md)"
        summary="$(awk 'BEGIN{seen=0} /^#/ {next} /^[[:space:]]*$/ {next} {print; exit}' "$f")"
        if [ -n "$summary" ]; then
          printf -- '- [%s](%s): %s\n' "$title" "$(basename "$f")" "$summary"
        else
          printf -- '- [%s](%s)\n' "$title" "$(basename "$f")"
        fi
      done
    } > "$TARGET/seed-memory/MEMORY.md"
    say "  created: seed-memory/MEMORY.md"
  else
    say "  left untouched: seed-memory/MEMORY.md"
  fi
fi
say "  seeded: seed-memory/"

GI="$TARGET/.gitignore"
add_ignore() {
  local pat="$1"
  if [ -f "$GI" ] && grep -qxF "$pat" "$GI"; then return; fi
  if $DRY_RUN; then
    say "  [dry-run] gitignore: $pat"
  else
    printf '%s\n' "$pat" >> "$GI"
    say "  gitignore: $pat"
  fi
}

add_ignore ".assay/receipts/"
add_ignore ".assay/rulings/"
add_ignore ".assay/active.json"
add_ignore "*.local"
add_ignore "*.local.json"

say ""
say "Done. Next step: run /assay help, then /assay intake."
say "Receipts (saved proof files) will live under .assay/receipts/."
