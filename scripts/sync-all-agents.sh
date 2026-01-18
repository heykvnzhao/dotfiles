#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

printf '==> Agent skills\n'
"$SCRIPT_DIR/sync-agent-skills.sh" "$@"

printf '\n==> AGENTS.md\n'
"$SCRIPT_DIR/sync-agents-md.sh" "$@"

printf '\n==> Prompts\n'
"$SCRIPT_DIR/sync-agent-prompts.sh" "$@"

printf '\n==> OpenCode config\n'
"$SCRIPT_DIR/sync-opencode-config.sh" "$@"
