#!/usr/bin/env bash
set -euo pipefail

target="all"
mode="auto"

usage() {
  cat <<'EOF'
Usage:
  scripts/sync-ide-skills.sh [-t all|cursor|claude] [-m auto|symlink|copy]
  scripts/sync-ide-skills.sh --target all --mode auto

Examples:
  scripts/sync-ide-skills.sh --target all --mode auto
  scripts/sync-ide-skills.sh --target cursor --mode copy
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--target)
      target="${2:-}"
      shift 2
      ;;
    -m|--mode)
      mode="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

case "$target" in
  all|cursor|claude) ;;
  *)
    echo "ERROR: Unsupported target: $target" >&2
    exit 1
    ;;
esac

case "$mode" in
  auto|symlink|copy) ;;
  *)
    echo "ERROR: Unsupported mode: $mode" >&2
    exit 1
    ;;
esac

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
source_root="$repo_root/.agents/skills"

if [[ ! -d "$source_root" ]]; then
  echo "ERROR: Source skills directory not found: $source_root" >&2
  exit 1
fi

if [[ "$target" == "all" ]]; then
  targets=(cursor claude)
else
  targets=("$target")
fi

target_root_for() {
  case "$1" in
    cursor) printf '%s\n' "$repo_root/.cursor/skills" ;;
    claude) printf '%s\n' "$repo_root/.claude/skills" ;;
    *)
      echo "ERROR: Unknown target: $1" >&2
      exit 1
      ;;
  esac
}

assert_within_path() {
  local child_path="$1"
  local parent_path="$2"
  local parent_abs
  local child_abs

  parent_abs="$(cd -- "$parent_path" && pwd -P)"
  if [[ -e "$child_path" ]]; then
    child_abs="$(cd -- "$(dirname -- "$child_path")" && pwd -P)/$(basename -- "$child_path")"
  else
    child_abs="$(cd -- "$(dirname -- "$child_path")" && pwd -P)/$(basename -- "$child_path")"
  fi

  case "$child_abs" in
    "$parent_abs"/*) ;;
    *)
      echo "ERROR: Refusing to modify path outside target root: $child_abs" >&2
      exit 1
      ;;
  esac
}

reset_target_directory() {
  local path_to_reset="$1"
  local target_root="$2"

  assert_within_path "$path_to_reset" "$target_root"
  if [[ -e "$path_to_reset" || -L "$path_to_reset" ]]; then
    rm -rf -- "$path_to_reset"
  fi
}

copy_skill() {
  local skill_source="$1"
  local skill_target="$2"

  mkdir -p -- "$skill_target"
  cp -R -- "$skill_source"/. "$skill_target"/
}

new_skill_projection() {
  local skill_source="$1"
  local skill_target="$2"
  local projection_mode="$3"

  case "$projection_mode" in
    symlink)
      ln -s -- "$skill_source" "$skill_target"
      printf '%s\n' "symlink"
      ;;
    copy)
      copy_skill "$skill_source" "$skill_target"
      printf '%s\n' "copy"
      ;;
    auto)
      if ln -s -- "$skill_source" "$skill_target" 2>/dev/null; then
        printf '%s\n' "symlink"
      else
        rm -rf -- "$skill_target"
        copy_skill "$skill_source" "$skill_target"
        printf '%s\n' "copy"
      fi
      ;;
    *)
      echo "ERROR: Unsupported mode: $projection_mode" >&2
      exit 1
      ;;
  esac
}

mapfile -t skill_dirs < <(find "$source_root" -mindepth 1 -maxdepth 1 -type d | sort)

if [[ "${#skill_dirs[@]}" -eq 0 ]]; then
  echo "No skills found under $source_root"
  exit 0
fi

for target_name in "${targets[@]}"; do
  target_root="$(target_root_for "$target_name")"
  mkdir -p -- "$target_root"
  echo "Sync target: $target_name -> $target_root"

  for skill_dir in "${skill_dirs[@]}"; do
    skill_name="$(basename -- "$skill_dir")"
    skill_target="$target_root/$skill_name"
    reset_target_directory "$skill_target" "$target_root"
    used_mode="$(new_skill_projection "$skill_dir" "$skill_target" "$mode")"
    printf '  [%s] %s\n' "$used_mode" "$skill_name"
  done
done

echo ""
echo "Done. Source of truth remains .agents/skills/."
echo "Examples:"
echo "  scripts/sync-ide-skills.sh --target all --mode auto"
echo "  scripts/sync-ide-skills.sh --target cursor --mode copy"
