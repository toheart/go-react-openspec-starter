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
    # 兼容 macOS 默认的 Bash 3.2（不支持 ${var,,} / ${var^}）
    local lower
    lower="$(printf '%s' "$segment" | tr '[:upper:]' '[:lower:]')"
    local first_char
    first_char="$(printf '%s' "$lower" | cut -c1 | tr '[:lower:]' '[:upper:]')"
    local rest
    rest="$(printf '%s' "$lower" | cut -c2-)"
    if [[ -n "$result" ]]; then
      result+=" "
    fi
    result+="${first_char}${rest}"
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
  for existing in "${updated_files[@]+"${updated_files[@]}"}"; do
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

current_backend_module="$(sed -n -E 's/^module[[:space:]]+//p' "${repo_root}/backend/go.mod" | head -n 1)"
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

# 注入 OpenSpec 项目上下文
cat > "${repo_root}/openspec/config.yaml" <<OPENSPEC_EOF
schema: spec-driven

context: |
  Project: ${display_name}
  Module: ${backend_module}
  Tech stack: Go (Gin + Cobra + Viper + slog), React 18 (TypeScript + Vite)
  Architecture: DDD (domain / application / interfaces / infrastructure)
  API style: RESTful JSON, /api/v1/ prefix
  Conventional commits required
  Backend port: 8080, Frontend dev port: 3000

rules:
  proposal:
    - Include affected DDD layers (domain / application / interfaces)
    - Reference relevant openspec/specs/ for style constraints
    - Include API endpoint changes in a summary table
    - Include a "Ubiquitous Language" section listing new/changed domain terms with Chinese name, English name, definition, and DDD building block type
  tasks:
    - Each task should map to a single DDD layer change
    - Backend tasks must include test requirements
    - Frontend tasks must reference the API contract
    - After all tasks are completed, update docs/ubiquitous-language.md with the new/changed terms from the proposal
OPENSPEC_EOF
add_updated_file "openspec/config.yaml"

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
for updated_file in "${updated_files[@]+"${updated_files[@]}"}"; do
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

# 清理脚手架文件
printf '\nCleaning scaffold files...\n'
rm -rf "${repo_root}/create-app"
rm -f "${repo_root}/TEMPLATE_USAGE.md"
rm -f "${repo_root}/docs/starter-metadata.md"
rm -f "${repo_root}/docs/starter-release-checklist.md"

# 重写 Makefile（直接生成项目视角，不含 init target）
cat > "${repo_root}/Makefile" <<'MAKEFILE_EOF'
.PHONY: dev dev-backend dev-frontend check clean pipeline-serve pipeline-status

dev:
	@echo "Starting backend (:8080) and frontend (:3000)..."
	@$(MAKE) -j2 dev-backend dev-frontend

dev-backend:
	@cd backend && make run

dev-frontend:
	@cd frontend && npm run dev

check:
	@cd backend && make check
	@cd frontend && npm run lint && npm run build

pipeline-serve:
	@npx ai-pipeline serve

pipeline-status:
	@npx ai-pipeline status

clean:
	@rm -rf backend/bin frontend/dist
MAKEFILE_EOF

# 重写 README.md（项目视角）
cat > "${repo_root}/README.md" <<README_EOF
# ${display_name}

${short_description}，基于 Go + React + DDD 架构。

## 快速开始

\`\`\`bash
make dev    # 启动 backend(:8080) + frontend(:3000)
\`\`\`

打开浏览器访问 \`http://localhost:3000\`。

## 技术栈

- **Go 后端**：Cobra CLI + Gin HTTP + Viper 配置 + \`log/slog\` 日志，DDD 四层分层
- **React 前端**：TypeScript + Vite，共享 API Service 层
- **OpenSpec**：规范驱动开发，4 套工程规范
- **CI/CD**：GitHub Actions
- **容器化**：Dockerfile + docker-compose

## 目录结构

\`\`\`
${project_slug}/
├── Makefile
├── docker-compose.yml
├── backend/
│   ├── Dockerfile
│   ├── Makefile
│   ├── cmd/                          # Cobra 入口
│   ├── conf/                         # Viper 配置
│   ├── etc/                          # YAML 配置文件
│   └── internal/
│       ├── domain/sample/            # 领域层
│       ├── application/sample/       # 应用层
│       ├── infrastructure/storage/   # 基础设施层
│       ├── interfaces/http/          # 接口层
│       ├── logging/
│       └── wire/                     # 依赖注入
├── frontend/
│   ├── Dockerfile
│   ├── src/
│   │   ├── components/
│   │   ├── hooks/
│   │   ├── services/                 # API 调用层
│   │   └── types/
│   └── vite.config.ts
├── openspec/
│   ├── config.yaml                   # 项目上下文
│   ├── specs/                        # 工程规范
│   └── changes/                      # 变更记录
├── pipelines/                        # 流水线模板
├── docs/
│   └── ubiquitous-language.md        # DDD 统一语言词汇表
└── .github/workflows/ci.yml
\`\`\`

## 常用命令

| 命令 | 说明 |
|------|------|
| \`make dev\` | 启动前后端开发服务器 |
| \`make check\` | 运行 lint + test + build |
| \`make pipeline-serve\` | 启动 Pipeline Dashboard |
| \`make pipeline-status\` | 查看 Pipeline 状态 |
| \`make clean\` | 清理构建产物 |

## OpenSpec 工作流

\`\`\`
# 提出变更
→ AI 在 openspec/changes/{id}/ 下生成 proposal.md + tasks.md

# 实现变更
→ AI 按 tasks.md 逐项实现

# 归档变更
→ 合并 spec delta，移至 archive/
\`\`\`

## Docker

\`\`\`bash
docker compose up --build
# backend → localhost:8080
# frontend → localhost:3000
\`\`\`

## License

MIT
README_EOF

# 重写 docs/README.md（移除 starter 文档引用）
cat > "${repo_root}/docs/README.md" <<DOCSREADME_EOF
# Project conventions

This repository uses the following implementation rules:

- \`go-style.md\` — Go 后端编码规范
- \`typescript-style.md\` — TypeScript/React 前端编码规范
- \`api-conventions.md\` — API 设计规范
- \`testing.md\` — 测试标准
- \`ubiquitous-language.md\` — DDD 统一语言词汇表
DOCSREADME_EOF

printf 'Cleaned:\n'
printf ' - create-app/\n'
printf ' - scripts/\n'
printf ' - TEMPLATE_USAGE.md\n'
printf ' - docs/starter-metadata.md\n'
printf ' - docs/starter-release-checklist.md\n'
printf 'Updated:\n'
printf ' - Makefile\n'
printf ' - README.md\n'
printf ' - docs/README.md\n'

# scripts/ 目录最后删除（当前脚本在其中）
rm -rf "${repo_root}/scripts"
