#!/usr/bin/env bash
# config.sh - shared config lookup for assay workflow paths.

assay_config_path() {
  local key="$1"
  local env_value="${2:-}"
  local default_value="$3"
  local config="${4:-assay.config.jsonc}"
  local value=""

  if command -v python3 >/dev/null 2>&1; then
    value="$(python3 - "$config" "$key" <<'PY' 2>/dev/null || true
import json
import re
import sys

config_path, key = sys.argv[1:3]

def strip_jsonc(text):
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return "\n".join(line for line in text.splitlines() if not line.lstrip().startswith("//"))

try:
    data = json.loads(strip_jsonc(open(config_path, encoding="utf-8").read()))
except Exception:
    data = {}

value = data.get(key) if isinstance(data, dict) else None
if isinstance(value, str) and value.strip():
    print(value.strip())
PY
)"
  elif command -v node >/dev/null 2>&1; then
    value="$(node - "$config" "$key" <<'NODE' 2>/dev/null || true
const fs = require("fs");
const [configPath, key] = process.argv.slice(2);
function stripJsonc(text) {
  return text.replace(/\/\*[\s\S]*?\*\//g, "")
    .split("\n")
    .filter((line) => !line.trimStart().startsWith("//"))
    .join("\n");
}
try {
  const data = JSON.parse(stripJsonc(fs.readFileSync(configPath, "utf8")));
  const value = data && typeof data === "object" ? data[key] : "";
  if (typeof value === "string" && value.trim()) process.stdout.write(value.trim());
} catch {}
NODE
)"
  fi

  if [ -n "$value" ]; then
    printf '%s\n' "$value"
  elif [ -n "$env_value" ]; then
    printf '%s\n' "$env_value"
  else
    printf '%s\n' "$default_value"
  fi
}
