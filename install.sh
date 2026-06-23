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
    ".claude/workflows/receipt.sh" \
    ".claude/workflows/questioncheck.sh" \
    ".claude/workflows/validationcheck.sh" \
    ".claude/workflows/assay-discovery.js" \
    ".claude/workflows/assay-execute.js" \
    ".claude/workflows/assay-validate.js" \
    ".claude/workflows/decision-ledger.sh" \
    "assay.config.jsonc"; do
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

for f in receipt.sh questioncheck.sh validationcheck.sh decision-ledger.sh; do
  copy_file "$KIT/.claude/workflows/$f" "$TARGET/.claude/workflows/$f"
  $DRY_RUN || chmod +x "$TARGET/.claude/workflows/$f"
  say "  installed: .claude/workflows/$f"
done

for f in assay-discovery.js assay-execute.js assay-validate.js; do
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

if $DRY_RUN; then
  say "  [dry-run] seed memory files"
else
  mkdir -p "$TARGET/seed-memory"
  for f in "$KIT"/seed-memory/*.md; do
    [ -e "$f" ] || continue
    dest="$TARGET/seed-memory/$(basename "$f")"
    [ -e "$dest" ] || cp "$f" "$dest"
  done
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
add_ignore "*.local"
add_ignore "*.local.json"

say ""
say "Done. Next step: run /assay intake."
say "Receipts (saved proof files) will live under .assay/receipts/."
