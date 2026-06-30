# Subagent Dispatch

## 目标

把 subagent 调度的共性规则收敛到一个地方，避免在主 Skill 里重复写各 IDE 的调用细节。

## 什么时候调度

- `explore` 需要补充只读代码调研时，调度只读型 subagent。
- `test-design` 固定调度 `qa-test-planner`。

说明：`design-review` 是架构级方案评审，固定由主流程读取 `.agents/skills/design-review/SKILL.md` 后亲自执行，不走 subagent 调度。

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

5. 预期输出文件或结论格式。

6. 是否允许改代码。

## 输入契约

- `change-name`
- 当前阶段目标
- 需要读取的 OpenSpec 文档
- 需要读取的仓库文件
- 输出位置

## 输出契约

- `explore` 子任务：返回调研结论、影响文件、风险、测试入口
- `qa-test-planner`：返回并落盘 `test-plan.md`

## 安全边界

- 设计阶段默认不允许 subagent 修改业务代码。
- 调研型任务只读仓库，不写实现。
- 如果某个 subagent 失败，只重跑该分支，不重置整个设计流程。

## Runtime 分流

- Cursor: 读 `runtime-cursor.md`
- Claude Code: 读 `runtime-claude-code.md`
- Codex: 读 `runtime-codex.md`
