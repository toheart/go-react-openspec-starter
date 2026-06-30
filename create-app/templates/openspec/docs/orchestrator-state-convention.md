## Orchestrator Shared State Convention

本约定定义 `Cursor` 与 `Claude Code` 之间共享的编排状态、交接文件和恢复规则。

目标：
1. 不再依赖 `pipeline-server`、Bun 服务或 `curl` 上报流水线状态。
2. 不再把编排真相放在 `.cursor/` 或 `.claude/` 的私有状态目录。
3. 让设计阶段与执行阶段围绕同一个 OpenSpec change 目录协作。

### 公共目录

每个 change 的共享状态目录固定为：

```text
openspec/changes/<change-name>/.orchestrator/
```

这个目录中的文件是跨 IDE 的共享事实，不属于某一个 IDE 的私有缓存。

### 标准文件

```text
openspec/changes/<change-name>/.orchestrator/
├── brief.md
├── explore-report.md
├── design-state.json
├── execution-state.json
├── handoff.json
├── qa-report.md
└── requirement-sync.json
```

说明：
- `brief.md`：设计侧写入的轻量需求摘要。
- `explore-report.md`：设计侧调研结论。
- `design-state.json`：`feature-design` 维护。
- `execution-state.json`：`feature-exec` 维护。
- `handoff.json`：设计到执行的正式交接契约。
- `qa-report.md`：执行侧 QA 验收报告。
- `requirement-sync.json`：执行侧需求回写状态，可选。

### `design-state.json`

```json
{
  "schema_version": 1,
  "change_name": "example-change",
  "role": "design",
  "owner_ide": "cursor",
  "skill": "feature-design",
  "trust": false,
  "status": "active",
  "current_stage": "test-design",
  "stages": {
    "brief": "completed",
    "explore": "completed",
    "propose": "completed",
    "design-review": "completed",
    "gate-design": "completed",
    "test-design": "active",
    "write-handoff": "pending"
  },
  "updated_at": "2026-06-27T02:00:00Z"
}
```

### `execution-state.json`

```json
{
  "schema_version": 1,
  "change_name": "example-change",
  "role": "execution",
  "owner_ide": "claude-code",
  "skill": "feature-exec",
  "trust": false,
  "status": "active",
  "current_stage": "test-run",
  "stages": {
    "implement": "completed",
    "code-review": "completed",
    "gate-code": "completed",
    "test-write": "completed",
    "gate-test-code": "completed",
    "test-run": "active",
    "gate-test": "pending",
    "archive": "pending",
    "requirement-sync": "pending"
  },
  "updated_at": "2026-06-27T03:00:00Z"
}
```

阶段状态统一使用：
- `pending`
- `active`
- `completed`
- `failed`
- `skipped`

### `handoff.json`

设计阶段通过 `gate-design` 且完成 `test-design` 后，必须写入该文件。执行阶段启动前必须先读取并校验它。

```json
{
  "schema_version": 1,
  "change_name": "example-change",
  "status": "design_ready",
  "design_gate_passed": true,
  "producer": {
    "ide": "cursor",
    "skill": "feature-design",
    "updated_at": "2026-06-27T02:30:00Z"
  },
  "required_artifacts": [
    "proposal.md",
    "design.md",
    "tasks.md",
    "test-plan.md"
  ],
  "optional_artifacts": [
    ".orchestrator/brief.md",
    ".orchestrator/explore-report.md"
  ],
  "executor_notes": [
    "先读 test-plan.md，再进入实现和测试写作阶段。",
    "统一以 http://localhost:8080 和 http://localhost:3000/ 作为本地开发入口。"
  ],
  "pending_risks": [],
  "gate_decisions": [
    "design-review passed",
    "test-design completed"
  ]
}
```

`handoff.json.status` 允许值：
- `draft`
- `design_ready`
- `execution_in_progress`
- `needs_design_revision`
- `completed`

### `test-plan.md`

本项目保留：

```text
openspec/changes/<change-name>/test-plan.md
```

这是 QA 设计与执行之间的主契约：
- `qa-test-planner` 负责生成。
- `qa-tester` 严格按它执行。
- `test-writer` 以它为主要输入，固化黑盒集成测试。

### 写入规则

1. 设计编排器只写 `design-state.json`、`handoff.json` 以及设计产物。
2. 执行编排器只写 `execution-state.json`，必要时更新 `handoff.json.status`。
3. QA 阶段完成后，执行侧把验收报告写到 `.orchestrator/qa-report.md`。
4. 任一阶段开始时更新 `current_stage` 并把对应 stage 标记为 `active`。
5. 任一阶段完成时把对应 stage 标记为 `completed`。
6. Gate 未通过时：
   - 设计侧：`handoff.json.status = "needs_design_revision"`
   - 执行侧：在 `execution-state.json` 中记录失败阶段

### 读取规则

1. `feature-design` 恢复时优先读取 `design-state.json`。
2. `feature-exec` 启动时必须先读取并校验 `handoff.json`。
3. 如果缺少 `handoff.json`，或 `status != "design_ready"`，执行编排器必须停止并提示回到设计侧。
4. 不再读取 `.cursor/hooks/state/`、`.claude/hooks/state/` 作为编排真相。

### 约束

1. `handoff.json` 是设计与执行之间唯一正式交接契约。
2. 执行侧可以补充实现细节，但不能绕过 `design.md`、`tasks.md`、`test-plan.md` 重做需求定义。
3. 若要新增阶段或状态字段，优先扩展 `scripts/orchestrator-state.py`，不要重新引入独立状态目录。
