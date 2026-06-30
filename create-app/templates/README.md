# {{DISPLAY_NAME}}

Go + React 全栈项目，基于 DDD 分层架构、OpenSpec 规范驱动和 AI Pipeline 编排。

## Quick Start

```bash
make dev    # 启动 backend(:8080) + frontend(:3000)
```

## What You Get

- **Go 后端**：Cobra CLI + Gin HTTP + Viper 配置 + `log/slog` 日志，DDD 四层分层
- **React 前端**：TypeScript + Vite，共享 API Service 层
- **OpenSpec**：4 套工程规范（Go Style / TS Style / API Conventions / Testing），context 自动注入
- **AI Pipeline**：YAML 流水线模板 + IDE 编排文件自动生成
- **CI/CD**：GitHub Actions 流水线
- **容器化**：Dockerfile + docker-compose

## Structure

```
├── Makefile                          # make dev / check
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
│   └── changes/_example/             # 格式示例
└── .github/workflows/ci.yml
```

## Commands

| Command | Description |
|---------|-------------|
| `make dev` | 启动前后端开发服务器 |
| `make check` | 运行 lint + test + build |
| `make pipeline-serve` | 启动 Pipeline Dashboard |
| `make pipeline-status` | 查看 Pipeline 状态 |
| `make clean` | 清理构建产物 |

## Pipeline Templates

| Template | Stages |
|----------|--------|
| `go-react-fullstack` | propose → test-design → review → **Gate** → implement(BE∥FE) → code-review → **Gate** → test → **Gate** → archive |
| `backend-only` | propose → review → **Gate** → implement → code-review → **Gate** → test → archive |
| `hotfix` | implement → code-review → **Gate** → test → archive |

## OpenSpec Workflow

```
# 提出变更
→ AI 在 openspec/changes/{id}/ 下生成 proposal.md + tasks.md

# 实现变更
→ AI 按 tasks.md 逐项实现

# 归档变更
→ 合并 spec delta，移至 archive/
```

示例格式见 `openspec/changes/_example/`。

## Docker

```bash
docker compose up --build
# backend → localhost:8080
# frontend → localhost:3000
```

## License

MIT
