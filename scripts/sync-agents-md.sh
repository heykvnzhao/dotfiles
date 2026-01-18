#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SOURCE_FILE="$SCRIPT_DIR/../.shared/AGENTS.md"
SCRIPT_NAME="$(basename "$0")"

usage() {
  printf 'Usage: %s [--dry-run]\n\n' "$SCRIPT_NAME"
  printf 'Options:\n'
  printf '  --dry-run   Show what would change without modifying anything\n'
  printf '  -h, --help  Show this help message\n'
}

log_action() {
  printf '  %-6s %s\n' "$1" "$2"
}

apply_action() {
  local action="$1"
  local message="$2"
  local source_path="${3:-}"
  local target_path="${4:-}"

  case "$action" in
    ADD)
      add_count=$((add_count + 1))
      ;;
    UPDATE)
      update_count=$((update_count + 1))
      ;;
    SKIP)
      skip_count=$((skip_count + 1))
      ;;
  esac

  if [ "$action" = "SKIP" ]; then
    log_action "$action" "$message"
    return
  fi

  if [ "$DRY_RUN" = true ]; then
    log_action "PLAN" "$message"
    return
  fi

  replace_with_symlink "$source_path" "$target_path"
  log_action "$action" "$message"
}

if [ ! -f "$SOURCE_FILE" ]; then
  printf 'Source file not found: %s\n' "$SOURCE_FILE" >&2
  exit 1
fi

DRY_RUN=false
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

TARGETS=(
  "OpenCode:$HOME/.config/opencode"
  "Claude Code:$HOME/.claude"
  "Codex:$HOME/.codex"
  "Kiro:$HOME/.kiro"
  "Gemini CLI:$HOME/.gemini"
  "Antigravity:$HOME/.gemini/antigravity"
)

add_count=0
update_count=0
skip_count=0

replace_with_symlink() {
  local source_path="$1"
  local target_path="$2"

  rm -rf "$target_path"
  ln -s "$source_path" "$target_path"
}

is_up_to_date_copy() {
  local source_path="$1"
  local target_path="$2"

  diff -q "$source_path" "$target_path" >/dev/null 2>&1
}

sync_target() {
  local label="$1"
  local target_dir="$2"
  local target_path="$target_dir/AGENTS.md"

  if [ ! -d "$target_dir" ]; then
    printf 'SKIP missing target (%s): %s\n' "$label" "$target_dir"
    return
  fi

  printf 'Syncing to %s: %s\n' "$label" "$target_dir"

  if [ -L "$target_path" ]; then
    local current_link
    current_link="$(readlink "$target_path")"
    if [ "$current_link" = "$SOURCE_FILE" ]; then
      apply_action "SKIP" "symlink ok: AGENTS.md"
      return
    fi

    apply_action "UPDATE" "update symlink: AGENTS.md" "$SOURCE_FILE" "$target_path"
    return
  fi

  if [ -e "$target_path" ]; then
    if is_up_to_date_copy "$SOURCE_FILE" "$target_path"; then
      apply_action "SKIP" "up-to-date copy: AGENTS.md"
      return
    fi

    apply_action "UPDATE" "replace with symlink: AGENTS.md" "$SOURCE_FILE" "$target_path"
    return
  fi

  apply_action "ADD" "add symlink: AGENTS.md" "$SOURCE_FILE" "$target_path"
}

for target in "${TARGETS[@]}"; do
  IFS=: read -r label target_dir <<<"$target"
  sync_target "$label" "$target_dir"
  echo ""
done

summary_label="Summary"
if [ "$DRY_RUN" = true ]; then
  summary_label="Summary (dry-run)"
fi

printf '%s: add %s, update %s, skip %s\n' "$summary_label" "$add_count" "$update_count" "$skip_count"
printf 'Tip: create %s if you want personal info included.\n' "$HOME/.local/PROFILE.md"
