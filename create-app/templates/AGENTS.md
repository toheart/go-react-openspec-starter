## Project Rules

### Architecture
- Backend follows DDD layering: `domain` → `application` → `interfaces` → `infrastructure`
- Domain layer MUST NOT depend on infrastructure or interfaces
- All new API endpoints must have corresponding handler tests
- Frontend API calls go through `src/services/` layer, never call fetch directly in components

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

### Feature Skills
- `.agents/skills/feature-design/` is the design-stage orchestrator: `brief -> explore -> propose -> design-review -> gate-design -> test-design -> write-handoff`
- `.agents/skills/design-review/` is the architecture-level design reviewer for C1-C5 completeness, M1-M5 architecture/data model checks, bad path review, and error response contracts
- `.agents/skills/feature-exec/` is the execution-stage orchestrator: `implement -> code-review -> gate-code -> test-write -> gate-test-code -> test-run -> gate-test -> archive -> requirement-sync`
- Design and execution share state through `openspec/changes/<change-name>/.orchestrator/`
- The shared state contract is documented in `openspec/docs/orchestrator-state-convention.md`

### Skill Sync
- `.agents/skills/` is the single source of truth for project skills
- Codex reads `.agents/skills/` directly and uses custom subagents from `.codex/agents/`
- Claude Code uses project subagents from `.claude/agents/`
- Cursor / Claude Code skill folders are local projections generated from `.agents/skills/`
- Do not manually edit `.cursor/skills/` or `.claude/skills/`; update `.agents/skills/` and run one of:

```bash
scripts/sync-ide-skills.sh --target all --mode auto
```

```powershell
powershell -ExecutionPolicy Bypass -File scripts/sync-ide-skills.ps1 -Target all -Mode auto
```

### Pipeline
- Pipeline templates are bundled by the scaffold CLI, not stored in the generated project root
- When AI IDE orchestration is enabled, the selected pipeline is written to `.pipeline/`
- Available template choices: `go-react-fullstack`, `backend-only`, `hotfix`
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
