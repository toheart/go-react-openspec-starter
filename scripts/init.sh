#!/usr/bin/env bash
set -euo pipefail

project_slug=""
module_base=""
app_name=""
display_name=""
frontend_package_name=""
env_prefix=""
skip_go_mod_tidy=0
skip_verification=0

usage() {
  cat <<'EOF'
Usage: ./scripts/init.sh --project-slug <slug> --module-base <module-base> [options]

Options:
  --project-slug <slug>           Starter project slug, e.g. order-center
  --module-base <module-base>     Repository module base, e.g. github.com/acme/order-center
  --app-name <name>               Override backend app name and CLI name
  --display-name <name>           Override UI title and backend short description
  --frontend-package-name <name>  Override frontend package name
  --env-prefix <prefix>           Override uppercase environment prefix
  --skip-go-mod-tidy              Skip go mod tidy
  --skip-verification             Skip verify-template.sh
  --help                          Show this message
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
    --app-name)
      app_name="${2:-}"
      shift 2
      ;;
    --display-name)
      display_name="${2:-}"
      shift 2
      ;;
    --frontend-package-name)
      frontend_package_name="${2:-}"
      shift 2
      ;;
    --env-prefix)
      env_prefix="${2:-}"
      shift 2
      ;;
    --skip-go-mod-tidy)
      skip_go_mod_tidy=1
      shift
      ;;
    --skip-verification)
      skip_verification=1
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

if [[ -z "$project_slug" || -z "$module_base" ]]; then
  echo "Both --project-slug and --module-base are required." >&2
  usage >&2
  exit 1
fi

if [[ ! "$project_slug" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "Invalid --project-slug: $project_slug" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
backend_module="${module_base}/backend"

to_display_name() {
  local slug="$1"
  local result=""
  local segment=""
  IFS='-' read -r -a parts <<< "$slug"
  for segment in "${parts[@]}"; do
    [[ -z "$segment" ]] && continue
    local lower="${segment,,}"
    local upper_first="${lower^}"
    if [[ -n "$result" ]]; then
      result+=" "
    fi
    result+="$upper_first"
  done
  printf '%s' "$result"
}

if [[ -z "$app_name" ]]; then
  app_name="$project_slug"
fi

if [[ -z "$display_name" ]]; then
  display_name="$(to_display_name "$project_slug")"
fi

if [[ -z "$frontend_package_name" ]]; then
  frontend_package_name="${project_slug}-frontend"
fi

if [[ -z "$env_prefix" ]]; then
  env_prefix="$(printf '%s' "$project_slug" | tr '[:lower:]-' '[:upper:]_')"
fi

short_description="${display_name} backend service"
updated_files=()

add_updated_file() {
  local candidate="$1"
  local existing=""
  for existing in "${updated_files[@]}"; do
    if [[ "$existing" == "$candidate" ]]; then
      return
    fi
  done

  updated_files+=("$candidate")
}

update_file() {
  local relative_path="$1"
  local perl_expr="$2"
  local absolute_path="${repo_root}/${relative_path}"

  if [[ ! -f "$absolute_path" ]]; then
    echo "Managed metadata file not found: $relative_path" >&2
    exit 1
  fi

  local before
  before="$(cat "$absolute_path")"
  perl -0pi -e "$perl_expr" "$absolute_path"
  local after
  after="$(cat "$absolute_path")"
  if [[ "$before" != "$after" ]]; then
    add_updated_file "$relative_path"
  fi
}

current_backend_module="$(sed -n 's/^module[[:space:]]\+//p' "${repo_root}/backend/go.mod" | head -n 1)"
if [[ -z "$current_backend_module" ]]; then
  echo "Unable to determine the current backend module path from backend/go.mod" >&2
  exit 1
fi

if [[ "$current_backend_module" != "$backend_module" ]]; then
  while IFS= read -r -d '' backend_source_file; do
    relative_path="${backend_source_file#${repo_root}/}"
    before="$(cat "$backend_source_file")"
    perl -0pi -e "s{\Q${current_backend_module}\E}{${backend_module}}g" "$backend_source_file"
    after="$(cat "$backend_source_file")"
    if [[ "$before" != "$after" ]]; then
      add_updated_file "$relative_path"
    fi
  done < <(find "${repo_root}/backend" -type f \( -name '*.go' -o -name 'go.mod' \) -print0)
fi

update_file "backend/go.mod" "s{^module\\s+.+\$}{module $backend_module}m"
update_file "backend/Makefile" "s{^APP_NAME := .+\$}{APP_NAME := $app_name}m"
update_file "backend/cmd/main.go" \
  "s{(Use:\\s+\")([^\"]+)(\")}{\$1$app_name\$3}m; s{(Short:\\s+\")([^\"]+)(\")}{\$1$short_description\$3}m"
update_file "backend/conf/conf.go" \
  "s{(v\\.SetEnvPrefix\\(\")([^\"]+)(\"\\))}{\$1$env_prefix\$3}m; s{(v\\.SetDefault\\(\"app\\.name\", \")([^\"]+)(\"\\))}{\$1$app_name\$3}m"
update_file "backend/etc/config.dev.yaml" "s{^  name: .+\$}{  name: $app_name}m"
update_file "backend/etc/config.prod.yaml" "s{^  name: .+\$}{  name: $app_name}m"
update_file "frontend/package.json" "s{(\"name\":\\s+\")([^\"]+)(\")}{\$1$frontend_package_name\$3}"
update_file "frontend/package-lock.json" "s{(\"name\":\\s+\")([^\"]+)(\")}{\$1$frontend_package_name\$3}g"
update_file "frontend/index.html" "s{(<title>)(.*?)(</title>)}{\$1$display_name\$3}m"

if [[ "$skip_go_mod_tidy" -eq 0 ]]; then
  (
    cd "${repo_root}/backend"
    go mod tidy
  )
fi

printf '\n'
printf 'Starter initialization summary\n'
printf '%s\n' '------------------------------'
printf 'Project slug:           %s\n' "$project_slug"
printf 'Module base:            %s\n' "$module_base"
printf 'Backend module:         %s\n' "$backend_module"
printf 'App name:               %s\n' "$app_name"
printf 'Display name:           %s\n' "$display_name"
printf 'Frontend package name:  %s\n' "$frontend_package_name"
printf 'Environment prefix:     %s\n' "$env_prefix"
printf 'Updated files:\n'
for updated_file in "${updated_files[@]}"; do
  printf ' - %s\n' "$updated_file"
done

if [[ "$skip_verification" -eq 0 ]]; then
  "${script_dir}/verify-template.sh" \
    --module-base "$module_base" \
    --app-name "$app_name" \
    --display-name "$display_name" \
    --frontend-package-name "$frontend_package_name" \
    --env-prefix "$env_prefix"
fi
