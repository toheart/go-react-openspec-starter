---
name: feature-design
description: 在 Go/React OpenSpec 项目中把功能需求推进到可执行设计：整理 brief、调研代码、生成 OpenSpec proposal/design/tasks、产出 test-plan.md，并把设计状态与 handoff 写入共享 `.orchestrator` 目录。用于用户请求 `$feature-design change-name`、启动或恢复 feature 设计阶段、需要把模糊需求收敛为可执行 OpenSpec 设计时。
---

# Feature 设计编排器

## 先读

- `AGENTS.md`
- `docs/README.md`
- `docs/quickstart.md`
- `docs/testing.md`
- `openspec/docs/orchestrator-state-convention.md`

阶段内按需读取：

- `explore`：`references/openspec-explore.md`
- `propose`：`references/openspec-propose.md`
- `design-review`：`.agents/skills/design-review/SKILL.md`
- 任一 Gate：`references/gate-templates.md`
- 任一 subagent 调度：先读 `references/subagent-dispatch.md`，再按运行环境读取 `references/runtime-cursor.md`、`references/runtime-claude-code.md` 或 `references/runtime-codex.md`

## 角色边界

- 只做设计编排，不写业务代码。
- 负责：`brief -> explore -> propose -> design-review -> gate-design -> test-design -> write-handoff`
- 不负责：`implement`、`code-review`、`test-write`、`test-run`、`archive`
- 本项目的测试设计固定写到 `openspec/changes/<change-name>/test-plan.md`

## 状态脚本

统一使用 Python 脚本维护共享状态，不再依赖 IDE 私有状态目录：

```bash
python scripts/orchestrator-state.py init-design <change-name> [--trust]
python scripts/orchestrator-state.py set-stage design <change-name> <stage> active
python scripts/orchestrator-state.py set-stage design <change-name> <stage> completed
python scripts/orchestrator-state.py set-gate design <change-name> gate-design passed --reason "<summary>"
python scripts/orchestrator-state.py set-gate design <change-name> gate-design failed --reason "<summary>"
python scripts/orchestrator-state.py write-handoff <change-name> \
  --required proposal.md \
  --required design.md \
  --required tasks.md \
  --required test-plan.md \
  --optional .orchestrator/brief.md \
  --optional .orchestrator/explore-report.md \
  --executor-note "<note>"
```

## 信任模式

如果用户消息中包含 `trust`：

- 初始化状态时带上 `--trust`
- Gate 阶段可给出摘要后直接通过
- 仍然必须写状态与交接文件，不能省略产物

## 阶段说明

### 1. brief

- 先执行 `init-design`
- 写入 `openspec/changes/<change-name>/.orchestrator/brief.md`
- 只保留最小必要信息：背景、目标、非目标、验收口径、风险

### 2. explore

- 读取 `references/openspec-explore.md`
- 如需补充事实，可调度只读型 subagent 做代码调研
- 把结论整理到 `.orchestrator/explore-report.md`
- 明确影响范围、关键文件、约束、风险、测试入口

### 3. propose

- 读取 `references/openspec-propose.md`
- 产出 `proposal.md`、`design.md`、`tasks.md`
- `tasks.md` 必须拆出 `Backend Tasks` 与 `Frontend Tasks`；没有对应端任务时也保留标题并写 `无`

### 4. design-review

- 读取并执行 `.agents/skills/design-review/SKILL.md`
- 由主流程亲自完成架构级方案评审，不委托 subagent
- 如涉及新增或修改实体、DTO、API 契约或跨层数据流，先做必要代码搜索，并可把事实整理到 `openspec/changes/<change-name>/model-validation.md`
- 固定产出：
  - `openspec/changes/<change-name>/.orchestrator/design-review.md`
  - `design.md` 中的 `错误响应契约（design-review 产出，implement 必读）` 段落
- 评审至少覆盖：
  - C1-C5 方案完整性
  - M1-M5 架构与数据模型一致性
  - 输入边界、状态冲突、依赖失败、权限边界四类 bad path
  - 验收场景到 tasks 和测试层级的覆盖矩阵

### 5. gate-design

- 按 `references/gate-templates.md` 输出摘要
- 只确认 `proposal.md`、`design.md`、`tasks.md`、`.orchestrator/design-review.md` 与剩余风险；`test-plan.md` 在通过后由 `test-design` 生成，不作为本 Gate 的前置条件
- 非信任模式下，输出通过、修改、停止三个选项后停止，等待用户确认
- 用户明确通过后，调用 `set-gate design <change-name> gate-design passed`
- 信任模式下，可输出 `[信任通过]` 摘要并调用 `set-gate ... passed` 后继续

### 6. test-design

- 按 subagent 调度规则调用 `qa-test-planner`
- 明确要求它读取：
  - `proposal.md`
  - `design.md`
  - `tasks.md`
  - `.orchestrator/brief.md`
  - `.orchestrator/explore-report.md`
  - `.orchestrator/design-review.md`
- 固定产出：

```text
openspec/changes/<change-name>/test-plan.md
```

- 本项目不额外生成 `test-guides/`，以 `test-plan.md` 作为测试设计主文档

### 7. write-handoff

- 用 `write-handoff` 命令写入 `.orchestrator/handoff.json`
- `required_artifacts` 至少包含：
  - `proposal.md`
  - `design.md`
  - `tasks.md`
  - `test-plan.md`
- `status` 必须是 `design_ready`
- 写入后运行 `python scripts/orchestrator-state.py validate-handoff <change-name> --check-artifacts`
- 最终按“结束回复”输出下一步提示

## 恢复规则

1. 恢复时优先读取 `.orchestrator/design-state.json`
2. 如果 `handoff.json.status = "design_ready"`，说明设计阶段已经完成，不要重复推进
3. 只从未完成阶段继续

## 完成标准

设计阶段完成时，至少具备以下产物：

- `openspec/changes/<change-name>/proposal.md`
- `openspec/changes/<change-name>/design.md`
- `openspec/changes/<change-name>/tasks.md`
- `openspec/changes/<change-name>/test-plan.md`
- `openspec/changes/<change-name>/.orchestrator/brief.md`
- `openspec/changes/<change-name>/.orchestrator/explore-report.md`
- `openspec/changes/<change-name>/.orchestrator/design-review.md`
- `openspec/changes/<change-name>/.orchestrator/design-state.json`
- `openspec/changes/<change-name>/.orchestrator/handoff.json`

## 结束回复

当 `handoff.json.status = "design_ready"` 后，最终回复不能只说“完成”。必须包含：

```text
设计阶段已完成，后续可以执行：

$feature-exec <change-name>

如需执行阶段自动通过人工确认 gate，请明确使用：

$feature-exec <change-name> trust
```

如果当前不是信任模式，不能替用户启动 `$feature-exec`；只提示下一步，等待用户确认。
