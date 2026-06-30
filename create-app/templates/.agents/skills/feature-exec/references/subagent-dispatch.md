# Subagent Dispatch

## 目标

把执行阶段的 subagent 调度规则集中管理，主 Skill 只保留阶段边界与工件契约。

## 什么时候调度

- `implement`：调度 `backend-implementer`、`frontend-implementer`
- `code-review`：调度 `backend-reviewer`、`frontend-reviewer`；后端结构性变更额外调度 `backend-arch-reviewer`
- `test-write`：调度 `test-writer`
- `test-run`：调度 `qa-tester`

## 调度前强制步骤

调度任一 subagent 前，必须执行以下步骤，不得跳过：

1. **Read subagent 定义文件**，了解它的系统提示、职责边界、必须执行的检查步骤：
   - `.claude/agents/<agent-name>.md`（Claude Code）
   - `.codex/agents/<agent-name>.toml`（Codex）
   - `.cursor/agents/<agent-name>.md`（Cursor）

   读定义的目的：让编排器知道 subagent 能做什么、需要什么输入、输出什么格式，据此写出精确的委托 prompt，避免 subagent 自己再花 token 探索自己的职责范围。

2. 当前阶段名称。

3. subagent 角色名称。

4. 输入工件路径。

5. 预期输出文件或报告格式。

6. 是否允许改代码。

支持命名 subagent 的 runtime，必须把调度绑定到对应 agent 类型；不能只在 prompt 中写”你是 xxx 专家”来模拟角色。

如果 runtime 提供可检查的 Agent tool input，阶段摘要中必须记录实际使用的 agent 名称。实际 agent 与阶段映射不一致时，停止当前阶段并重新调度。

## 输入契约

- `change-name`
- 当前阶段目标
- `handoff.json`
- 对应的 OpenSpec 与 `.orchestrator` 文件
- 输出路径

## 输出契约

- implementer：代码实现与自检结果
- reviewer：审查问题与阻断项
- backend-arch-reviewer：后端包结构、依赖方向、DDD 分层和 DI 复杂度审查报告
- test-writer：测试代码与执行报告
- qa-tester：`qa-report.md`

## 安全边界

- `implement`、`test-write` 允许改代码，其余阶段只修改约定产物
- 如果某个 subagent 失败，只重跑该分支，不重置整个执行流程
- 所有关键信息都要落盘，不要只停留在会话里

## Runtime 分流

- Cursor: 读 `runtime-cursor.md`
- Claude Code: 读 `runtime-claude-code.md`
- Codex: 读 `runtime-codex.md`
