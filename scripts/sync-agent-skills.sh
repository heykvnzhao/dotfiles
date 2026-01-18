#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SOURCE_DIR="$SCRIPT_DIR/../.shared/skills"
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
  local skill_path="${3:-}"
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

  replace_with_symlink "$skill_path" "$target_path"
  log_action "$action" "$message"
}

if [ ! -d "$SOURCE_DIR" ]; then
  printf 'Source skills directory not found: %s\n' "$SOURCE_DIR" >&2
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

shopt -s nullglob

TARGETS=(
  "OpenCode:$HOME/.config/opencode/skills"
  "Claude Code:$HOME/.claude/skills"
  "Codex:$HOME/.codex/skills"
  "Kiro:$HOME/.kiro/skills"
  "Gemini CLI:$HOME/.gemini/skills"
  "Antigravity:$HOME/.gemini/antigravity/skills"
)

add_count=0
update_count=0
skip_count=0

replace_with_symlink() {
  local skill_path="$1"
  local target_path="$2"

  rm -rf "$target_path"
  ln -s "$skill_path" "$target_path"
}

is_up_to_date_copy() {
  local skill_path="$1"
  local target_path="$2"

  diff -qr "$skill_path" "$target_path" >/dev/null 2>&1
}

sync_target() {
  local label="$1"
  local target_dir="$2"

  if [ ! -d "$target_dir" ]; then
    printf 'SKIP missing target (%s): %s\n' "$label" "$target_dir"
    return
  fi

  printf 'Syncing to %s: %s\n' "$label" "$target_dir"

  for skill_dir in "$SOURCE_DIR"/*; do
    if [ ! -d "$skill_dir" ]; then
      continue
    fi

    local skill_name
    local skill_path
    local target_path

    skill_name="$(basename "$skill_dir")"
    skill_path="$(cd "$skill_dir" && pwd -P)"
    target_path="$target_dir/$skill_name"

    if [ -L "$target_path" ]; then
      local current_link
      current_link="$(readlink "$target_path")"
      if [ "$current_link" = "$skill_path" ]; then
        apply_action "SKIP" "symlink ok: $skill_name"
        continue
      fi

      apply_action "UPDATE" "update symlink: $skill_name" "$skill_path" "$target_path"
      continue
    fi

    if [ -e "$target_path" ]; then
      if is_up_to_date_copy "$skill_path" "$target_path"; then
        apply_action "SKIP" "up-to-date copy: $skill_name"
        continue
      fi

      apply_action "UPDATE" "replace with symlink: $skill_name" "$skill_path" "$target_path"
      continue
    fi

    apply_action "ADD" "add symlink: $skill_name" "$skill_path" "$target_path"
  done
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
