#!/usr/bin/env bash
set -euo pipefail

project_slug="starter-smoke-app"
module_base="github.com/example/starter-smoke-app"
display_name="Starter Smoke App"
skip_go_mod_tidy=0
skip_openspec_list=0

usage() {
  cat <<'EOF'
Usage: ./scripts/smoke-starter.sh [options]

Options:
  --project-slug <slug>       Smoke project slug
  --module-base <module>      Smoke repository module base
  --display-name <name>       Smoke display name
  --skip-go-mod-tidy          Skip go mod tidy in the smoke copy
  --skip-openspec-list        Skip openspec list --json in the smoke copy
  --help                      Show this message
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-slug)
      project_slug="${2:-}"
      shift 2
      ;;
    --module-base)
      module_base="${2:-}"
      shift 2
      ;;
    --display-name)
      display_name="${2:-}"
      shift 2
      ;;
    --skip-go-mod-tidy)
      skip_go_mod_tidy=1
      shift
      ;;
    --skip-openspec-list)
      skip_openspec_list=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! "$project_slug" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "Invalid --project-slug: $project_slug" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
tmp_root="${repo_root}/.tmpbin"
stamp="$(date +%Y%m%d%H%M%S)"
smoke_root="${tmp_root}/starter-smoke-${stamp}"

mkdir -p "$smoke_root"

copy_starter_path() {
  local relative_path="$1"
  local source_path="${repo_root}/${relative_path}"
  if [[ ! -e "$source_path" ]]; then
    echo "Starter path not found: $relative_path" >&2
    exit 1
  fi

  mkdir -p "$(dirname "${smoke_root}/${relative_path}")"
  cp -R "$source_path" "${smoke_root}/${relative_path}"
}

paths_to_copy=(
  "backend"
  "frontend"
  "scripts"
  "docs"
  "openspec"
  "README.md"
  "TEMPLATE_USAGE.md"
  ".gitignore"
  "AGENTS.md"
)

for path_to_copy in "${paths_to_copy[@]}"; do
  copy_starter_path "$path_to_copy"
done

paths_to_remove=(
  "${smoke_root}/frontend/node_modules"
  "${smoke_root}/frontend/dist"
  "${smoke_root}/backend/bin"
  "${smoke_root}/backend/cmd.exe"
  "${smoke_root}/.tmpbin"
  "${smoke_root}/openspec/changes"
)

for path_to_remove in "${paths_to_remove[@]}"; do
  if [[ -e "$path_to_remove" ]]; then
    rm -rf "$path_to_remove"
  fi
done

init_args=(
  --project-slug "$project_slug"
  --module-base "$module_base"
  --display-name "$display_name"
)

if [[ "$skip_go_mod_tidy" -eq 1 ]]; then
  init_args+=(--skip-go-mod-tidy)
fi

"${smoke_root}/scripts/init.sh" "${init_args[@]}"

openspec_config_path="${smoke_root}/openspec/config.yaml"
openspec_specs_path="${smoke_root}/openspec/specs"
openspec_changes_path="${smoke_root}/openspec/changes"

if [[ ! -f "$openspec_config_path" ]]; then
  echo "OpenSpec smoke check failed: missing openspec/config.yaml in smoke copy." >&2
  exit 1
fi

if [[ ! -d "$openspec_specs_path" ]]; then
  echo "OpenSpec smoke check failed: missing openspec/specs in smoke copy." >&2
  exit 1
fi

mapfile -t spec_files < <(find "$openspec_specs_path" -type f -name 'spec.md')
if [[ "${#spec_files[@]}" -eq 0 ]]; then
  echo "OpenSpec smoke check failed: no baseline spec files found in smoke copy." >&2
  exit 1
fi

if [[ "$skip_openspec_list" -eq 0 ]]; then
  mkdir -p "$openspec_changes_path"
  if command -v openspec >/dev/null 2>&1; then
    printf '\nOpenSpec list output\n'
    printf '%s\n' '--------------------'
    (
      cd "$smoke_root"
      openspec list --json
    )
  else
    printf 'SKIP OpenSpec CLI list check (openspec command not found).\n'
  fi
fi

printf '\nStarter smoke directory\n'
printf '%s\n' '-----------------------'
printf '%s\n' "$smoke_root"
printf 'OpenSpec config: %s\n' "$openspec_config_path"
printf 'OpenSpec specs:  %s files\n' "${#spec_files[@]}"
