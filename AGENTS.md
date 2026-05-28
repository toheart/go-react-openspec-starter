## Project Rules

### Architecture
- Backend follows DDD layering: `domain` → `application` → `interfaces` → `infrastructure`
- Domain layer MUST NOT depend on infrastructure or interfaces
- All new API endpoints must have corresponding handler tests
- Frontend API calls go through `src/services/` layer, never call fetch directly in components

### Ubiquitous Language（统一语言）
- 项目统一语言词汇表维护在 `docs/ubiquitous-language.md`
- 新增领域概念时，**必须先更新词汇表**，再编写代码
- 代码命名（实体、值对象、服务、事件等）必须使用词汇表中定义的 English 名称
- API 字段名、前端类型定义必须与词汇表保持一致
- OpenSpec proposal 涉及新领域概念时，必须包含 `## Ubiquitous Language` 章节，列出新增/变更的术语
- OpenSpec tasks 完成后，必须同步更新 `docs/ubiquitous-language.md`

### Code Style
- Go: follow `openspec/specs/backend-go-style/spec.md`
- TypeScript/React: follow `openspec/specs/frontend-typescript-style/spec.md`
- API design: follow `openspec/specs/api-conventions/spec.md`
- Testing: follow `openspec/specs/testing-standards/spec.md`

### Workflow
- New features should start with OpenSpec proposal before coding
- Commit messages follow Conventional Commits format
- Backend changes require `make check` to pass before committing
- Frontend changes require `npm run lint` to pass before committing

### Pipeline
- Pipeline templates are in `pipelines/` directory
- Available templates: `go-react-fullstack`, `backend-only`, `hotfix`
- Choose template based on change scope: fullstack for cross-cutting, backend-only for API changes, hotfix for urgent fixes

## AI Pipeline 编排

本项目使用 [ai-pipeline](https://github.com/toheart/ai-pipeline) 进行 AI 开发流水线编排。

### 初始化（Skill 驱动，推荐）

在 Cursor / Claude Code 中加载 `ai-pipeline` Skill，它会自动：
1. 扫描项目技术栈（Go + React + OpenSpec）
2. 生成 Agent 定义（explorer / go-implementer / frontend-implementer / reviewer）
3. 生成 Orchestrator Skill
4. 部署 Hook 和配置
5. 启动 Pipeline Server + Dashboard

### 初始化（CLI 向后兼容）

```bash
npx ai-pipeline init cursor       # 或 claude-code / codex
npx ai-pipeline serve              # 启动 Dashboard
```

### 流水线使用

初始化完成后，说"开始流水线"或"启动编排"触发 orchestrator-feature Skill。

| IDE | Agent 目录 | Skill 目录 |
|-----|-----------|-----------|
| Cursor | `.cursor/agents/` | `.cursor/skills/` |
| Claude Code | `.claude/agents/` | `.claude/skills/` |
| Codex | `.codex/agents/` | `.codex/skills/` |

- 流水线定义：`.pipeline/*.ts`
- Dashboard：`http://127.0.0.1:19090/`
