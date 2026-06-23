#!/usr/bin/env bash
# bootstrap.sh - public curl|bash installer for bi-toolkit.

set -euo pipefail

REPO_URL="${BI_TOOLKIT_URL:-https://github.com/dep0we/bi-toolkit/archive/refs/heads/main.tar.gz}"
TARGET="$(pwd)"

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "bootstrap: missing '$1'. Install it, then rerun this command." >&2
    exit 1
  fi
}

need curl
need tar
need mktemp

TMP="$(mktemp -d "${TMPDIR:-/tmp}/bi-toolkit.XXXXXX")"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

echo "Downloading bi-toolkit..."
curl -fsSL "$REPO_URL" | tar -xz -C "$TMP"
KIT_DIR="$(find "$TMP" -maxdepth 1 -type d -name 'bi-toolkit-*' -print -quit)"
if [ -z "$KIT_DIR" ] || [ ! -f "$KIT_DIR/install.sh" ]; then
  echo "bootstrap: download did not contain install.sh" >&2
  exit 1
fi

echo "Installing into $TARGET..."
bash "$KIT_DIR/install.sh" "$TARGET"

echo ""
echo "bi-toolkit is installed."
echo "Open Claude Code in this folder and run: /assay intake"
