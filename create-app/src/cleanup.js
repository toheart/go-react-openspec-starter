import { rm, readFile, writeFile } from "node:fs/promises";
import { resolve } from "node:path";

/**
 * init 完成后的 README.md 内容（项目视角，非模板视角）
 */
function generateReadme(inputs) {
  return `# ${inputs.displayName}

${inputs.shortDescription || `${inputs.displayName} 全栈应用`}，基于 Go + React + DDD 架构。

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
${inputs.projectSlug}/
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
`;
}

/**
 * init 完成后的 Makefile 内容（移除 init target）
 */
function generateMakefile() {
  return `.PHONY: dev dev-backend dev-frontend check clean pipeline-serve pipeline-status

dev:
\t@echo "Starting backend (:8080) and frontend (:3000)..."
\t@$(MAKE) -j2 dev-backend dev-frontend

dev-backend:
\t@cd backend && make run

dev-frontend:
\t@cd frontend && npm run dev

check:
\t@cd backend && make check
\t@cd frontend && npm run lint && npm run build

pipeline-serve:
\t@npx ai-pipeline serve

pipeline-status:
\t@npx ai-pipeline status

clean:
\t@rm -rf backend/bin frontend/dist
`;
}

/**
 * init 完成后的 docs/README.md（移除 starter 文档引用）
 */
function generateDocsReadme() {
  return `# Project conventions

This repository uses the following implementation rules:

- \`go-style.md\` — Go 后端编码规范
- \`typescript-style.md\` — TypeScript/React 前端编码规范
- \`api-conventions.md\` — API 设计规范
- \`testing.md\` — 测试标准
- \`ubiquitous-language.md\` — DDD 统一语言词汇表
`;
}

/**
 * 清理脚手架文件并更新 Makefile / README / docs/README
 */
export async function cleanupScaffold(repoRoot, inputs) {
  const scaffoldPaths = [
    "create-app",
    "scripts",
    "TEMPLATE_USAGE.md",
    "docs/starter-metadata.md",
    "docs/starter-release-checklist.md",
  ];

  for (const p of scaffoldPaths) {
    await rm(resolve(repoRoot, p), { recursive: true, force: true });
  }

  // 重写 Makefile、README、docs/README 为项目视角
  await writeFile(resolve(repoRoot, "Makefile"), generateMakefile(), "utf-8");
  await writeFile(
    resolve(repoRoot, "README.md"),
    generateReadme(inputs),
    "utf-8",
  );
  await writeFile(
    resolve(repoRoot, "docs/README.md"),
    generateDocsReadme(),
    "utf-8",
  );

  return scaffoldPaths;
}
