#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SOURCE_DIR="$SCRIPT_DIR/../.shared/prompts"
SCRIPT_NAME="$(basename "$0")"

REQUIRED_KEYS=("description")
GLOBAL_KEYS=("description" "codex" "opencode")
NAMESPACE_KEYS_CODEX=("argument-hint")
NAMESPACE_KEYS_OPENCODE=("agent" "model" "subtask")

STRIP_FRONT_MATTER_KIRO=true
STRIP_FRONT_MATTER_CODEX=false
STRIP_FRONT_MATTER_OPENCODE=false

DROP_NAMESPACES_KIRO=("codex" "opencode")
DROP_NAMESPACES_CODEX=("opencode")
DROP_NAMESPACES_OPENCODE=("codex")

TARGETS=(
  "kiro:$HOME/.kiro:$HOME/.kiro/prompts"
  "codex:$HOME/.codex:$HOME/.codex/prompts"
  "opencode:$HOME/.config/opencode:$HOME/.config/opencode/commands"
)

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
  cp "$source_path" "$target_path"
  print_action "$action" "$message"
}

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

is_in_list() {
  local value="$1"
  shift

  local item
  for item in "$@"; do
    if [ "$item" = "$value" ]; then
      return 0
    fi
  done

  return 1
}

is_allowed_namespace_key() {
  local namespace="$1"
  local key="$2"

  case "$namespace" in
    codex)
      is_in_list "$key" "${NAMESPACE_KEYS_CODEX[@]}"
      return
      ;;
    opencode)
      is_in_list "$key" "${NAMESPACE_KEYS_OPENCODE[@]}"
      return
      ;;
  esac

  return 1
}

find_front_matter_end_line() {
  local file="$1"

  awk '
    NR == 1 {
      if ($0 != "---") {
        exit 2
      }
      in_front_matter=1
      next
    }
    in_front_matter == 1 && $0 == "---" {
      print NR
      in_front_matter=0
      exit 0
    }
    END {
      if (in_front_matter == 1) {
        exit 3
      }
    }
  ' "$file"
}

parse_front_matter() {
  local file="$1"
  local end_line

  end_line="$(find_front_matter_end_line "$file")"
  case "$?" in
    2)
      printf 'Missing front matter in %s\n' "$file" >&2
      return 1
      ;;
    3)
      printf 'Missing closing front matter fence in %s\n' "$file" >&2
      return 1
      ;;
  esac

  if [ -z "$end_line" ]; then
    printf 'Missing closing front matter fence in %s\n' "$file" >&2
    return 1
  fi

  front_matter_end_line="$end_line"
  description=""
  codex_argument_hint=""
  opencode_agent=""
  opencode_model=""
  opencode_subtask=""

  local line
  while IFS= read -r line; do
    [ -z "$line" ] && continue

    if [[ "$line" != *:* ]]; then
      printf 'Invalid front matter line in %s: %s\n' "$file" "$line" >&2
      return 1
    fi

    local key
    local value
    key="$(trim "${line%%:*}")"
    value="$(trim "${line#*:}")"

    if [ "$value" = "null" ]; then
      value=""
    fi

    if [[ "$key" == *.* ]]; then
      local namespace
      local subkey
      namespace="${key%%.*}"
      subkey="${key#*.}"

      if ! is_in_list "$namespace" "${GLOBAL_KEYS[@]}"; then
        printf 'Unknown top-level key in %s: %s\n' "$file" "$key" >&2
        return 1
      fi

      if ! is_allowed_namespace_key "$namespace" "$subkey"; then
        printf 'Unknown %s key in %s: %s\n' "$namespace" "$file" "$key" >&2
        return 1
      fi

      case "$namespace" in
        codex)
          if [ "$subkey" = "argument-hint" ]; then
            codex_argument_hint="$value"
          fi
          ;;
        opencode)
          case "$subkey" in
            agent)
              opencode_agent="$value"
              ;;
            model)
              opencode_model="$value"
              ;;
            subtask)
              opencode_subtask="$value"
              ;;
          esac
          ;;
      esac
    else
      case "$key" in
        description)
          description="$value"
          ;;
        *)
          printf 'Unknown front matter key in %s: %s\n' "$file" "$key" >&2
          return 1
          ;;
      esac
    fi
  done < <(awk -v end="$end_line" 'NR > 1 && NR < end {print}' "$file")

  if [ -z "$description" ]; then
    printf 'Missing required key in %s: %s\n' "$file" "${REQUIRED_KEYS[*]}" >&2
    return 1
  fi

  if [ -n "$opencode_subtask" ]; then
    case "$opencode_subtask" in
      true|false)
        ;;
      *)
        printf 'Invalid opencode.subtask in %s (expected true/false)\n' "$file" >&2
        return 1
        ;;
    esac
  fi

  return 0
}

render_output() {
  local target="$1"
  local source_file="$2"
  local output_file="$3"
  local body_start=$((front_matter_end_line + 1))

  if [ "$target" = "kiro" ]; then
    awk -v start="$body_start" 'NR >= start {print}' "$source_file" > "$output_file"
    return
  fi

  {
    printf '%s\n' "---"
    printf 'description: %s\n' "$description"

    if [ "$target" = "codex" ]; then
      if [ -n "$codex_argument_hint" ]; then
        printf 'codex.argument-hint: %s\n' "$codex_argument_hint"
      fi
    else
      if [ -n "$opencode_agent" ]; then
        printf 'opencode.agent: %s\n' "$opencode_agent"
      fi
      if [ -n "$opencode_model" ]; then
        printf 'opencode.model: %s\n' "$opencode_model"
      fi
      if [ -n "$opencode_subtask" ]; then
        printf 'opencode.subtask: %s\n' "$opencode_subtask"
      fi
    fi

    printf '%s\n' "---"
    awk -v start="$body_start" 'NR >= start {print}' "$source_file"
  } > "$output_file"
}

if [ ! -d "$SOURCE_DIR" ]; then
  printf 'Source prompts directory not found: %s\n' "$SOURCE_DIR" >&2
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


add_count=0
update_count=0
skip_count=0

skip_entries=()
missing_entries=()
current_target_label=""
target_started=false

if ! command -v mktemp >/dev/null 2>&1; then
  printf 'mktemp is required for this script.\n' >&2
  exit 1
fi

shopt -s nullglob

prompt_files=()
while IFS= read -r prompt_file; do
  prompt_files+=("$prompt_file")
done < <(find "$SOURCE_DIR" -type f -name "*.md" | sort)

if [ "${#prompt_files[@]}" -eq 0 ]; then
  printf 'No prompt files found under %s\n' "$SOURCE_DIR"
  exit 0
fi

for target in "${TARGETS[@]}"; do
  IFS=: read -r target_name root_dir target_dir <<<"$target"

  if [ ! -d "$root_dir" ]; then
    missing_entries+=("$target_name|$root_dir")
    continue
  fi

  current_target_label="$target_name"
  target_started=false

  for prompt_file in "${prompt_files[@]}"; do
    if ! parse_front_matter "$prompt_file"; then
      exit 1
    fi

    rel_path="${prompt_file#"$SOURCE_DIR"/}"
    target_path="$target_dir/$rel_path"
    temp_file="$(mktemp)"
    render_output "$target_name" "$prompt_file" "$temp_file"

    if [ -e "$target_path" ]; then
      if diff -q "$temp_file" "$target_path" >/dev/null 2>&1; then
        apply_action "SKIP" "$target_name up-to-date: $rel_path" "$temp_file" "$target_path"
        rm -f "$temp_file"
        continue
      fi

      apply_action "UPDATE" "$target_name update: $rel_path" "$temp_file" "$target_path"
      rm -f "$temp_file"
      continue
    fi

    apply_action "ADD" "$target_name add: $rel_path" "$temp_file" "$target_path"
    rm -f "$temp_file"
  done

  if [ "$target_started" = true ]; then
    echo ""
  fi
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
