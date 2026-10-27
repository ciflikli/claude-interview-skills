#!/usr/bin/env bash
# Codex adversarial review of everything since <base>, read-only. Run with Bash run_in_background.
#   codex-review.sh <base-ref> "<focus text>"
set -eu
root=$(ls -d ~/.claude/plugins/cache/openai-codex/codex/*/ 2>/dev/null | sort -V | tail -1)
root=${CODEX_COMPANION_DIR:-$root}  # override if your plugin lives elsewhere
root="${root%/}/"
[ -f "${root}scripts/codex-companion.mjs" ] || { echo "Codex plugin not found: run /codex:setup or set CODEX_COMPANION_DIR" >&2; exit 1; }
base=${1:?usage: codex-review.sh <base-ref> "<focus>"}; shift
exec node "${root}scripts/codex-companion.mjs" adversarial-review --wait --base "$base" "$@"
