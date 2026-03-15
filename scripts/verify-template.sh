#!/usr/bin/env bash
set -euo pipefail

module_base=""
app_name=""
display_name=""
frontend_package_name=""
env_prefix=""

usage() {
  cat <<'EOF'
Usage: ./scripts/verify-template.sh --module-base <base> --app-name <name> --display-name <name> --frontend-package-name <name> --env-prefix <prefix>
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
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

if [[ -z "$module_base" || -z "$app_name" || -z "$display_name" || -z "$frontend_package_name" || -z "$env_prefix" ]]; then
  echo "All arguments are required." >&2
  usage >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
backend_module="${module_base}/backend"
starter_slug="go-react-openspec-starter"
starter_backend_module="github.com/toheart/go-react-openspec-starter/backend"
starter_frontend_package="go-react-openspec-starter-frontend"
starter_env_prefix="GO_REACT_OPENSPEC_STARTER"

failures=()

pass() {
  printf 'PASS %s\n' "$1"
}

fail() {
  printf 'FAIL %s\n' "$1"
}

check_pattern() {
  local description="$1"
  local file_path="$2"
  local needle="$3"

  if grep -Fq "$needle" "$file_path"; then
    pass "$description"
  else
    fail "$description"
    failures+=("Missing expected ${description} in ${file_path}")
  fi
}

check_pattern "backend module path" "${repo_root}/backend/go.mod" "module ${backend_module}"
check_pattern "backend app name" "${repo_root}/backend/Makefile" "APP_NAME := ${app_name}"
check_pattern "backend env prefix" "${repo_root}/backend/conf/conf.go" "v.SetEnvPrefix(\"${env_prefix}\")"
check_pattern "backend config default" "${repo_root}/backend/conf/conf.go" "v.SetDefault(\"app.name\", \"${app_name}\")"
check_pattern "frontend package name" "${repo_root}/frontend/package.json" "\"name\": \"${frontend_package_name}\""
check_pattern "frontend title" "${repo_root}/frontend/index.html" "<title>${display_name}</title>"

metadata_files=(
  "${repo_root}/backend/go.mod"
  "${repo_root}/backend/Makefile"
  "${repo_root}/backend/cmd/main.go"
  "${repo_root}/backend/conf/conf.go"
  "${repo_root}/backend/etc/config.dev.yaml"
  "${repo_root}/backend/etc/config.prod.yaml"
  "${repo_root}/frontend/package.json"
  "${repo_root}/frontend/package-lock.json"
  "${repo_root}/frontend/index.html"
)

mapfile -t backend_source_files < <(find "${repo_root}/backend" -type f \( -name '*.go' -o -name 'go.mod' \))

check_legacy_pattern() {
  local description="$1"
  local pattern="$2"
  local should_check="$3"
  shift 3
  local paths=("$@")

  if [[ "$should_check" == "0" ]]; then
    pass "${description} (baseline value retained intentionally)"
    return
  fi

  if grep -Fq "$pattern" "${paths[@]}"; then
    fail "$description"
    failures+=("Found remaining ${description} in managed metadata files")
  else
    pass "$description"
  fi
}

check_legacy_pattern \
  "legacy backend module path" \
  "${starter_backend_module}" \
  "$([[ "$backend_module" != "$starter_backend_module" ]] && printf '1' || printf '0')" \
  "${backend_source_files[@]}"

check_legacy_pattern \
  "legacy frontend package" \
  "${starter_frontend_package}" \
  "$([[ "$frontend_package_name" != "$starter_frontend_package" ]] && printf '1' || printf '0')" \
  "${repo_root}/frontend/package.json" \
  "${repo_root}/frontend/package-lock.json"

check_legacy_pattern \
  "legacy env prefix" \
  "${starter_env_prefix}" \
  "$([[ "$env_prefix" != "$starter_env_prefix" ]] && printf '1' || printf '0')" \
  "${repo_root}/backend/conf/conf.go"

if [[ "${#failures[@]}" -gt 0 ]]; then
  printf '\nVerification failed:\n'
  for failure in "${failures[@]}"; do
    printf ' - %s\n' "$failure"
  done
  exit 1
fi

printf '\nStarter metadata verification passed.\n'
