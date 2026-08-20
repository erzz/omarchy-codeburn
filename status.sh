#!/usr/bin/env bash
set -eo pipefail

# Export environment paths so mise/nvm/bun/user tools are resolved when executed by Quickshell
export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH:/usr/local/bin:/usr/bin"

PERIOD="${1:-today}"

# Whitelist allowed period values to ensure safe argument passing
case "$PERIOD" in
  today|week|30days|month|all|lifetime) ;;
  *) PERIOD="today" ;;
esac

ARGS=(status --format menubar-json --period "$PERIOD" --no-optimize --no-timeline)
CODEBURN_PACKAGE="codeburn@0.9.20"

if command -v codeburn >/dev/null 2>&1; then
  exec codeburn "${ARGS[@]}"
elif command -v npx >/dev/null 2>&1; then
  exec npx --yes "$CODEBURN_PACKAGE" "${ARGS[@]}"
elif command -v bunx >/dev/null 2>&1; then
  exec bunx "$CODEBURN_PACKAGE" "${ARGS[@]}"
else
  echo '{"error":"neither codeburn nor npx found in PATH"}' >&2
  exit 1
fi
