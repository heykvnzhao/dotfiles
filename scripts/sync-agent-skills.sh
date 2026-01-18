#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SOURCE_DIR="$SCRIPT_DIR/../.shared/skills"
SCRIPT_NAME="$(basename "$0")"

usage() {
  printf 'Usage: %s [--dry-run] [--verbose]\n\n' "$SCRIPT_NAME"
  printf 'Options:\n'
  printf '  --dry-run    Show what would change without modifying anything\n'
  printf '  --verbose    Show skipped items\n'
  printf '  -h, --help   Show this help message\n'
}

COLOR_RESET=$'\033[0m'
COLOR_DIM=$'\033[2m'
COLOR_GREEN=$'\033[32m'
COLOR_YELLOW=$'\033[33m'
COLOR_CYAN=$'\033[36m'

color_enabled=false
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  color_enabled=true
fi

colorize() {
  local color="$1"
  shift

  if [ "$color_enabled" = true ]; then
    printf '%b%s%b' "$color" "$*" "$COLOR_RESET"
  else
    printf '%s' "$*"
  fi
}

action_label() {
  local action="$1"

  case "$action" in
    ADD)
      colorize "$COLOR_GREEN" "$action"
      ;;
    UPDATE)
      colorize "$COLOR_YELLOW" "$action"
      ;;
    PLAN)
      colorize "$COLOR_CYAN" "$action"
      ;;
    SKIP)
      colorize "$COLOR_DIM" "$action"
      ;;
    *)
      printf '%s' "$action"
      ;;
  esac
}

print_target_header() {
  if [ "$target_started" = false ]; then
    printf '%s\n' "$(colorize "$COLOR_CYAN" "Target: $current_target_label")"
    printf '  %-7s %s\n' "$(colorize "$COLOR_DIM" "ACTION")" "ITEM"
    target_started=true
  fi
}

print_action() {
  local action="$1"
  local message="$2"

  print_target_header
  printf '  %-7s %s\n' "$(action_label "$action")" "$message"
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
    if [ "$VERBOSE" = true ]; then
      skip_entries+=("$current_target_label|$message")
    fi
    return
  fi

  if [ "$DRY_RUN" = true ]; then
    print_action "PLAN" "$message"
    return
  fi

  replace_with_symlink "$skill_path" "$target_path"
  print_action "$action" "$message"
}

if [ ! -d "$SOURCE_DIR" ]; then
  printf 'Source skills directory not found: %s\n' "$SOURCE_DIR" >&2
  exit 1
fi

DRY_RUN=false
VERBOSE=false
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      ;;
    --verbose|-v)
      VERBOSE=true
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
  "OpenCode:$HOME/.config/opencode:$HOME/.config/opencode/skills"
  "Claude Code:$HOME/.claude:$HOME/.claude/skills"
  "Codex:$HOME/.codex:$HOME/.codex/skills"
  "Kiro:$HOME/.kiro:$HOME/.kiro/skills"
  "Gemini CLI:$HOME/.gemini:$HOME/.gemini/skills"
  "Antigravity:$HOME/.gemini:$HOME/.gemini/antigravity/skills"
)

add_count=0
update_count=0
skip_count=0

skip_entries=()
missing_entries=()
current_target_label=""
target_started=false

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
  local root_dir="$2"
  local target_dir="$3"

  if [ ! -d "$root_dir" ]; then
    missing_entries+=("$label|$root_dir")
    return
  fi

  if [ ! -d "$target_dir" ] && [ "$DRY_RUN" = false ]; then
    mkdir -p "$target_dir"
  fi

  current_target_label="$label"
  target_started=false

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

  if [ "$target_started" = true ]; then
    echo ""
  fi
}

for target in "${TARGETS[@]}"; do
  IFS=: read -r label root_dir target_dir <<<"$target"
  sync_target "$label" "$root_dir" "$target_dir"
done

if [ "$VERBOSE" = true ] && [ "${#skip_entries[@]}" -gt 0 ]; then
  printf 'Skipped:\n'
  for entry in "${skip_entries[@]}"; do
    IFS='|' read -r skip_label skip_message <<<"$entry"
    printf '  %-12s %s\n' "$skip_label" "$skip_message"
  done
  echo ""
fi

if [ "${#missing_entries[@]}" -gt 0 ]; then
  printf 'Missing configs:\n'
  for entry in "${missing_entries[@]}"; do
    IFS='|' read -r missing_label missing_path <<<"$entry"
    printf '  %-12s %s\n' "$missing_label" "$missing_path"
  done
  echo ""
fi

summary_label="Summary"
if [ "$DRY_RUN" = true ]; then
  summary_label="Summary (dry-run)"
fi

printf '%s: add %s, update %s, skip %s\n' "$summary_label" "$add_count" "$update_count" "$skip_count"
