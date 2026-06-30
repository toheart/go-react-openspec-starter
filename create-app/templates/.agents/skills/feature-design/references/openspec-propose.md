# OpenSpec Propose 内嵌参考

本参考只服务于 `feature-design` 的 `propose` 阶段，不是独立 Skill。父 Skill 的角色边界、状态脚本、Gate 规则和完成标准优先于本文。

## 输入

进入 `propose` 前应已有：

```text
openspec/changes/<change-name>/.orchestrator/brief.md
openspec/changes/<change-name>/.orchestrator/explore-report.md
```

如果 change 目录不存在，使用 OpenSpec CLI 创建：

```bash
openspec new change "<change-name>"
```

## 产物

`propose` 阶段至少生成：

```text
openspec/changes/<change-name>/proposal.md
openspec/changes/<change-name>/design.md
openspec/changes/<change-name>/tasks.md
```

`tasks.md` 必须显式拆分：

```markdown
## Backend Tasks

## Frontend Tasks
```

没有对应端任务时也保留标题，并写明 `无`，避免执行阶段误判。

## OpenSpec CLI 流程

获取当前 schema 和产物状态：

```bash
openspec status --change "<change-name>" --json
```

按依赖顺序为每个待生成 artifact 获取说明：

```bash
openspec instructions <artifact-id> --change "<change-name>" --json
```

使用返回的 `template` 作为文件结构，使用 `context` 和 `rules` 作为写作约束。不要把 `context`、`rules` 或 `<project_context>` 原文复制进产物。

每生成一个 artifact 后重新检查状态：

```bash
openspec status --change "<change-name>" --json
```

直到 schema 要求的 apply-ready artifacts 都完成。

## 写作约束

- 从 `brief.md` 和 `explore-report.md` 提炼需求，不重新发明需求。
- `proposal.md` 说明 what / why / scope / non-goals。
- `design.md` 说明模块边界、数据流、接口变化、兼容性与风险。
- `tasks.md` 写成可执行任务，不写宽泛口号。
- 明确 bad path、失败路径、权限边界、数据迁移或兼容性影响。
- 保持当前 starter 约束：Go 后端 DDD 分层、React/TypeScript 前端、API 约定、测试标准和环境配置规则。

## 输出到父流程

完成后由 `feature-design` 继续进入：

```text
design-review -> gate-design -> test-design -> write-handoff
```

不要提示用户运行通用 OpenSpec apply 命令；本项目的执行入口固定是：

```text
$feature-exec <change-name>
```
