---
name: feature-exec
description: 消费 feature-design 产出的 handoff 与 OpenSpec 工件，推进实现、代码审查、测试固化、QA 验收与归档。用于用户请求 `$feature-exec change-name`、启动或恢复 feature 执行阶段、从 `.orchestrator/handoff.json` 落地已完成设计的 change 时。
---

# Feature 执行编排器

## 先读

- `AGENTS.md`
- `docs/README.md`
- `docs/quickstart.md`
- `docs/testing.md`
- `openspec/docs/orchestrator-state-convention.md`

阶段内按需读取：

- `implement`：`references/openspec-apply-change.md`
- `archive`：`references/openspec-archive-change.md`
- 任一 Gate：`references/gate-templates.md`
- 完成输出：`references/completion-template.md`
- 任一 subagent 调度：先读 `references/subagent-dispatch.md`，再按运行环境读取 `references/runtime-cursor.md`、`references/runtime-claude-code.md` 或 `references/runtime-codex.md`

## 角色边界

- 只做执行编排，不重新定义需求，不重做设计阶段。
- 负责：`implement -> code-review -> gate-code -> test-write -> gate-test-code -> test-run -> gate-test -> archive -> requirement-sync`
- 设计侧唯一正式输入是：

```text
openspec/changes/<change-name>/.orchestrator/handoff.json
```

## 状态脚本

```bash
python scripts/orchestrator-state.py validate-handoff <change-name> --check-artifacts
python scripts/orchestrator-state.py init-execution <change-name> [--trust]
python scripts/orchestrator-state.py set-stage execution <change-name> <stage> active
python scripts/orchestrator-state.py set-stage execution <change-name> <stage> completed
python scripts/orchestrator-state.py set-stage execution <change-name> <stage> failed --overall-status failed
python scripts/orchestrator-state.py set-stage execution <change-name> <stage> skipped
python scripts/orchestrator-state.py set-gate execution <change-name> <gate> passed --reason "<summary>"
python scripts/orchestrator-state.py set-gate execution <change-name> <gate> failed --reason "<summary>"
python scripts/orchestrator-state.py set-gate execution <change-name> <gate> skipped --reason "<summary>"
```

## 信任模式

如果用户消息中包含 `trust`：

- 初始化执行状态时带上 `--trust`
- Gate 阶段可以给出摘要后直接通过
- 仍然必须写 `execution-state.json`，并保留测试与归档产物

## Gate 硬约束

非信任模式下，Gate 是强制人工确认点。

进入任一 Gate 阶段时必须：

1. 按 `references/gate-templates.md` 输出 Gate 摘要。
2. 给出明确选项：通过、修改、停止。
3. 立即停止本轮响应，等待用户下一条消息。
4. 在用户明确选择“通过”之前，禁止调用：
   - `set-gate ... passed`
   - 后续阶段的 `set-stage ... active`
   - `archive`
   - `requirement-sync`

只有满足以下任一条件，才允许自动调用 `set-gate ... passed`：

- `execution-state.json` 中 `trust == true`
- 用户当前消息明确包含对该 Gate 的通过确认

如果只是上一阶段问题已经修复、构建已通过或测试已通过，但用户没有明确确认 Gate 通过，仍然必须停在 Gate 摘要处。

## 执行阶段

### 1. implement

实现前必须先读：

- `.orchestrator/handoff.json`
- `.orchestrator/brief.md`（如存在）
- `.orchestrator/explore-report.md`（如存在）
- `proposal.md`
- `design.md`
- `tasks.md`
- `test-plan.md`
- `references/openspec-apply-change.md`

然后按 `tasks.md` 的任务范围和 subagent 调度规则决定实现调度：

- `Backend Tasks` 不是 `无` 时，调度 `backend-implementer`
- `Frontend Tasks` 不是 `无` 时，调度 `frontend-implementer`
- 两端任务都为 `无` 时，停止并说明 `tasks.md` 不可执行，不要自行发明任务

要求：

- 后端只消费 `Backend Tasks`
- 前端只消费 `Frontend Tasks`
- 以 `test-plan.md` 的核心场景作为验收目标
- 如果任务拆分与实际需要改动的端不一致，先停止并说明不一致点，不默默扩大实现范围

### 2. code-review

按任务范围、实际 diff 和 subagent 调度规则决定审查调度：

- 后端有任务或实际 diff 涉及 `backend/` 时，调度 `backend-reviewer`
- 后端 diff 涉及新增/修改包结构、跨层依赖、接口定义、依赖注入或 DTO/domain/entity 映射时，额外调度 `backend-arch-reviewer`
- 前端有任务或实际 diff 涉及 `frontend/` 时，调度 `frontend-reviewer`
- 没有相关 diff 的一端不调度 reviewer

汇总需要人工判断的问题后进入 `gate-code`。

### 3. gate-code

- 按 `references/gate-templates.md` 输出摘要
- 非信任模式下必须输出选项后停止，不得调用 `set-gate ... passed`
- 用户明确通过或信任模式下，调用 `set-gate execution <change-name> gate-code passed`
- 用户要求停止或存在阻断且不能继续时，调用 `set-gate execution <change-name> gate-code failed`

### 4. test-write

先运行：

```bash
python scripts/check-test-env.py integration
```

然后按 subagent 调度规则调用 `test-writer`，要求它：

- 以 `test-plan.md` 为主输入
- 必要时参考 `design.md`
- 在受影响 Go package 旁新增或更新 `*_test.go`
- 自己运行 `go test` 并修到通过
- 输出测试写作报告

### 5. gate-test-code

- 审查 `test-writer` 的新增文件、覆盖场景、执行结果
- 非信任模式下输出是否进入 QA 验收的建议后停止，等待用户确认
- 用户明确通过或信任模式下，调用 `set-gate execution <change-name> gate-test-code passed`
- 测试代码无法满足 `test-plan.md` 时，调用 `set-gate execution <change-name> gate-test-code failed`

### 6. test-run

先运行：

```bash
python scripts/check-test-env.py qa
```

环境就绪后按 subagent 调度规则调用 `qa-tester`，要求它：

  - 严格按 `openspec/changes/<change-name>/test-plan.md` 执行
  - 把报告写到 `openspec/changes/<change-name>/.orchestrator/qa-report.md`
  - 本地入口统一使用：
  - 前端：`http://localhost:3000/`
  - 后端：`http://localhost:8080`

### 7. gate-test

- 基于 `qa-report.md` 与 `test-writer` 报告做最终测试判断
- 即使在信任模式下，只要有失败项，也必须调用 `set-gate execution <change-name> gate-test failed`
- 非信任模式下输出归档建议后停止，等待用户确认
- 用户明确通过或信任模式下且无失败项时，调用 `set-gate execution <change-name> gate-test passed`

### 8. archive

归档前确认：

- 设计与执行阶段都已完成
- `qa-report.md` 已存在
- 需要保留的测试资产已经落盘
- 已读取 `references/openspec-archive-change.md`

归档时优先使用 OpenSpec CLI：

```bash
openspec archive <change-name> --yes
```

### 9. requirement-sync

当前项目没有稳定的本地 `requirement-sync` Skill 时：

- 默认运行 `python scripts/orchestrator-state.py set-stage execution <change-name> requirement-sync skipped`
- 只有用户明确要求且外部依赖可用时，才执行回写

## 恢复规则

1. 启动时先读取 `.orchestrator/execution-state.json` 是否存在
2. 首次启动执行阶段时，校验 `handoff.json.status = "design_ready"`，并运行 `validate-handoff <change-name> --check-artifacts`
3. 已存在 `execution-state.json` 时，允许 `handoff.json.status = "execution_in_progress"` 并从未完成阶段继续
4. 如果 `handoff.json.status = "completed"`，提示执行阶段已经完成，不要重复推进
5. 如果 `handoff.json.status` 是 `draft`、`needs_design_revision` 或缺少 required artifacts，停止并回到设计侧

## 完成输出

完成后按 `references/completion-template.md` 输出收尾摘要，至少包含：

- `openspec/changes/<change-name>/.orchestrator/execution-state.json`
- `openspec/changes/<change-name>/.orchestrator/qa-report.md`
- 新增或更新的 `*_test.go`
