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

### Pipeline
- Pipeline templates are in `pipelines/` directory
- Available templates: `go-react-fullstack`, `backend-only`, `hotfix`
- Choose template based on change scope: fullstack for cross-cutting, backend-only for API changes, hotfix for urgent fixes

## Skills

Skills (OpenSpec propose / apply / archive / explore 等) 由 `npx ai-pipeline init <adapter>` 根据所选 IDE 自动生成到对应目录：

| IDE | Skill 目录 |
|-----|-----------|
| Cursor | `.cursor/skills/` |
| Claude Code | `.claude/skills/` |
| Codex | `.codex/skills/` |

运行 `make init` 时选择 IDE 后会自动完成生成。如需手动生成：

```bash
npx ai-pipeline init cursor       # 或 claude-code / codex
```
