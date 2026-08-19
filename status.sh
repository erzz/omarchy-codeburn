#!/usr/bin/env bash
set -eo pipefail

# Export environment paths so mise/nvm/bun/user tools are resolved when executed by Quickshell
export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH:/usr/local/bin:/usr/bin"

if command -v codeburn >/dev/null 2>&1; then
  exec codeburn status --format menubar-json
elif command -v npx >/dev/null 2>&1; then
  exec npx --yes codeburn status --format menubar-json
elif command -v bunx >/dev/null 2>&1; then
  exec bunx codeburn status --format menubar-json
else
  echo '{"error":"neither codeburn nor npx found in PATH"}' >&2
  exit 1
fi
