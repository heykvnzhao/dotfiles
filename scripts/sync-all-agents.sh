#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

"$SCRIPT_DIR/sync-agent-skills.sh" "$@"
"$SCRIPT_DIR/sync-agents-md.sh" "$@"
"$SCRIPT_DIR/sync-agent-prompts.sh" "$@"
"$SCRIPT_DIR/sync-opencode-config.sh" "$@"
