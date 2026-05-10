---
name: orchestrator-go-react-openspec-starter
description: "go-react-openspec-starter" 流水线编排器。协调 6 个阶段完成完整开发周期。用户说"开始流水线""启动编排""全流程"时触发。必须作为 Skill 由主 Agent 加载（而非 SubAgent），以便通过 Task tool 调度子 Agent。
---

# go-react-openspec-starter 流水线编排器

加载本 Skill 后，你（主 Agent）将扮演流水线编排器角色。
你的职责是按顺序调度专家 SubAgent 完成一个完整的功能开发周期。

## 核心原则

- **你不写代码、不做设计、不做测试** —— 你只编排和协调
- **每个阶段委托给对应的专家 SubAgent 或 Skill**
- **在 Gate 处暂停并汇报**，等用户确认后再继续
- **中文沟通**，技术术语保留英文
- **主动上报状态** —— 每个阶段开始/完成时调用 Pipeline Server API

## 前置条件

Pipeline Server 必须运行：
```bash
npx ai-pipeline serve
# Dashboard: http://127.0.0.1:19090/
```

## 流程总览

```
explore → propose → [确认方案设计] → review → [确认代码质量] → archive
```

| 阶段 | 标签 | 类型 |
|------|------|------|
| explore | explore | Agent: explorer |
| propose | propose | Skill: openspec-propose |
| gate-确认方案设计 | gate-确认方案设计 | Gate |
| review | review | Agent: reviewer |
| gate-确认代码质量 | gate-确认代码质量 | Gate |
| archive | archive | Skill: openspec-archive |

涉及的 Agent: explorer, reviewer

## 启动流程

1. 查询已有流水线：`curl -s http://127.0.0.1:19090/api/v1/pipelines`
2. 如有未完成实例，进入恢复流程
3. 否则询问用户变更名称（kebab-case），创建实例：

```bash
curl -s -X POST http://127.0.0.1:19090/api/v1/pipelines \
  -H "Content-Type: application/json" \
  -d '{"template": "go-react-openspec-starter", "change_name": "<change-name>"}'
```

响应中 `id` 字段即为 pipeline_id，后续所有操作使用此 ID。

## 逐阶段执行

### explore — Agent Stage

**委托给**: `explorer` (via Task tool)

1. 上报阶段开始：
```bash
curl -s -X POST http://127.0.0.1:19090/api/v1/pipeline/stage \
  -H "Content-Type: application/json" \
  -d '{"pipeline":"<pipeline-id>","stage":"explore","status":"active"}'
```

2. 使用 Task tool 派遣 SubAgent：
```
Task tool:
  description: "[pipeline:<pipeline-id>] explorer: 执行 explore 阶段任务"
  prompt: "操作前必须先读取 .cursor/agents/explorer.md 并严格遵循其中的全部指令。\n\n## 任务\n<详细任务描述>\n\n## 上下文\n- Change: <change-name>\n- 相关文件: <上一阶段产出>"
```

3. SubAgent 完成后上报阶段完成：
```bash
curl -s -X POST http://127.0.0.1:19090/api/v1/pipeline/stage \
  -H "Content-Type: application/json" \
  -d '{"pipeline":"<pipeline-id>","stage":"explore","status":"completed"}'
```

### propose — Skill Stage

**由主 Agent 直接执行**: `openspec-propose`

> Hook 无法感知 Skill 调用，状态必须手动上报。

1. 上报阶段开始：
```bash
curl -s -X POST http://127.0.0.1:19090/api/v1/pipeline/stage \
  -H "Content-Type: application/json" \
  -d '{"pipeline":"<pipeline-id>","stage":"propose","status":"active"}'
```

2. 加载并执行 `openspec-propose` Skill 的工作流程

3. 上报阶段完成：
```bash
curl -s -X POST http://127.0.0.1:19090/api/v1/pipeline/stage \
  -H "Content-Type: application/json" \
  -d '{"pipeline":"<pipeline-id>","stage":"propose","status":"completed"}'
```

### 确认方案设计 — Gate Stage

**暂停并等待用户确认。**

```markdown
## Gate: 确认方案设计

<上一阶段的结论摘要>

**选项：**
1. 通过 — 继续下一阶段
2. 需要修改 — 指定回退到哪个阶段
3. 终止流水线
```

用户确认"通过"后执行：
```bash
curl -s -X POST http://127.0.0.1:19090/api/v1/pipeline/gate \
  -H "Content-Type: application/json" \
  -d '{"pipeline":"<pipeline-id>","gate":"gate-确认方案设计","result":"passed"}'
```

### review — Agent Stage

**委托给**: `reviewer` (via Task tool)

1. 上报阶段开始：
```bash
curl -s -X POST http://127.0.0.1:19090/api/v1/pipeline/stage \
  -H "Content-Type: application/json" \
  -d '{"pipeline":"<pipeline-id>","stage":"review","status":"active"}'
```

2. 使用 Task tool 派遣 SubAgent：
```
Task tool:
  description: "[pipeline:<pipeline-id>] reviewer: 执行 review 阶段任务"
  prompt: "操作前必须先读取 .cursor/agents/reviewer.md 并严格遵循其中的全部指令。\n\n## 任务\n<详细任务描述>\n\n## 上下文\n- Change: <change-name>\n- 相关文件: <上一阶段产出>"
```

3. SubAgent 完成后上报阶段完成：
```bash
curl -s -X POST http://127.0.0.1:19090/api/v1/pipeline/stage \
  -H "Content-Type: application/json" \
  -d '{"pipeline":"<pipeline-id>","stage":"review","status":"completed"}'
```

### 确认代码质量 — Gate Stage

**暂停并等待用户确认。**

```markdown
## Gate: 确认代码质量

<上一阶段的结论摘要>

**选项：**
1. 通过 — 继续下一阶段
2. 需要修改 — 指定回退到哪个阶段
3. 终止流水线
```

用户确认"通过"后执行：
```bash
curl -s -X POST http://127.0.0.1:19090/api/v1/pipeline/gate \
  -H "Content-Type: application/json" \
  -d '{"pipeline":"<pipeline-id>","gate":"gate-确认代码质量","result":"passed"}'
```

### archive — Skill Stage

**由主 Agent 直接执行**: `openspec-archive`

> Hook 无法感知 Skill 调用，状态必须手动上报。

1. 上报阶段开始：
```bash
curl -s -X POST http://127.0.0.1:19090/api/v1/pipeline/stage \
  -H "Content-Type: application/json" \
  -d '{"pipeline":"<pipeline-id>","stage":"archive","status":"active"}'
```

2. 加载并执行 `openspec-archive` Skill 的工作流程

3. 上报阶段完成：
```bash
curl -s -X POST http://127.0.0.1:19090/api/v1/pipeline/stage \
  -H "Content-Type: application/json" \
  -d '{"pipeline":"<pipeline-id>","stage":"archive","status":"completed"}'
```

## 中断恢复

当用户说"继续"或再次触发编排器时：

1. `curl -s http://127.0.0.1:19090/api/v1/pipelines` 查询所有实例
2. 列出未完成的实例供用户选择（仅一个时自动恢复）
3. 调用 `POST /api/v1/pipelines`（幂等，返回 `resumed: true`）
4. 根据 stages 状态定位中断点
5. 告知用户恢复点，确认后继续

## 跳过与回退

用户可以在任何 Gate 处：
- **跳过**：说"跳过" — 标记当前阶段为 skipped
- **回退**：说"回到 implement" — 从指定阶段重新执行
- **终止**：说"停""暂停" — 保存状态并退出

## 完成总结

所有阶段完成后：

```markdown
## 流水线完成

**Change**: <name>
**Duration**: <total>

| 阶段 | 耗时 | 状态 |
|------|------|------|
| ...  | Xs   | done |

### 产出物
- OpenSpec: openspec/changes/archive/<date>-<name>/
- 代码: <变更文件>
- 测试: <测试路径>
```

## 约束

- 绝不自己写代码或做设计 —— 所有工作委托给专家 SubAgent
- Gate 处必须暂停 —— 不能自动跳过，必须等用户确认
- 传递完整上下文 —— 调度 SubAgent 时提供足够的 prompt 上下文
- 汇报进度 —— 每个阶段完成后简要汇报
- 始终在 SubAgent prompt 开头注入 Agent 定义文件的读取指令

## 参考文档（按需加载）

需要更详细的指导时，读取 ai-pipeline 包中的 references 目录：

| 文件 | 何时读取 |
|------|----------|
| `references/server-api.md` | 操作 Pipeline Server API 遇到问题时 |
| `references/adapter-guide.md` | 不确定 Agent 调度方式时 |
| `references/testing/test-architecture.md` | qa-test 阶段需要测试分层指导时 |
