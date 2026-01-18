#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SOURCE_DIR="$SCRIPT_DIR/../.config/opencode"
TARGET_DIR="$HOME/.config/opencode"
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

skip_entries=()
missing_entries=()
current_target_label="OpenCode"
target_started=false

apply_action() {
  local action="$1"
  local message="$2"
  local source_path="$3"
  local target_path="$4"

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

  mkdir -p "$(dirname "$target_path")"
  replace_with_symlink "$source_path" "$target_path"
  print_action "$action" "$message"
}

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

sync_file() {
  local source_path="$1"
  local rel_path
  local target_path

  rel_path="${source_path#"$SOURCE_DIR"/}"
  target_path="$TARGET_DIR/$rel_path"

  if [ -L "$target_path" ]; then
    local current_link
    current_link="$(readlink "$target_path")"
    if [ "$current_link" = "$source_path" ]; then
      apply_action "SKIP" "symlink ok: $rel_path" "$source_path" "$target_path"
      return
    fi

    apply_action "UPDATE" "update symlink: $rel_path" "$source_path" "$target_path"
    return
  fi

  if [ -e "$target_path" ]; then
    if is_up_to_date_copy "$source_path" "$target_path"; then
      apply_action "SKIP" "up-to-date copy: $rel_path" "$source_path" "$target_path"
      return
    fi

    apply_action "UPDATE" "replace with symlink: $rel_path" "$source_path" "$target_path"
    return
  fi

  apply_action "ADD" "add symlink: $rel_path" "$source_path" "$target_path"
}

if [ ! -d "$SOURCE_DIR" ]; then
  printf 'Source directory not found: %s\n' "$SOURCE_DIR" >&2
  exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
  missing_entries+=("OpenCode|$TARGET_DIR")
  printf 'Missing targets:\n'
  printf '  %-12s %s\n' "OpenCode" "$TARGET_DIR"
  printf 'Tip: create %s to enable OpenCode config sync.\n' "$TARGET_DIR"
  printf 'Summary: add 0, update 0, skip 0\n'
  exit 0
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


add_count=0
update_count=0
skip_count=0

source_files=()
while IFS= read -r source_file; do
  source_files+=("$source_file")
done < <(find "$SOURCE_DIR" -type f | sort)

if [ "${#source_files[@]}" -eq 0 ]; then
  printf 'No files found under %s\n' "$SOURCE_DIR"
  exit 0
fi

for source_file in "${source_files[@]}"; do
  sync_file "$source_file"
done

if [ "$target_started" = true ]; then
  echo ""
fi

if [ "$VERBOSE" = true ] && [ "${#skip_entries[@]}" -gt 0 ]; then
  printf 'Skipped:\n'
  for entry in "${skip_entries[@]}"; do
    IFS='|' read -r skip_label skip_message <<<"$entry"
    printf '  %-12s %s\n' "$skip_label" "$skip_message"
  done
  echo ""
fi

summary_label="Summary"
if [ "$DRY_RUN" = true ]; then
  summary_label="Summary (dry-run)"
fi

printf '%s: add %s, update %s, skip %s\n' "$summary_label" "$add_count" "$update_count" "$skip_count"
