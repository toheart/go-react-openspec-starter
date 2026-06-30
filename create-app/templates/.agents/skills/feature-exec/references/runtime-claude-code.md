# Runtime: Claude Code

## 官方启动方式

Claude Code 官方文档给了三种明确路径：

1. 用 `/agents` 管理和创建 subagent
2. 在主对话里用自然语言显式调用
3. 用 `@` 直接点名某个 subagent

官方示例：

```text
Use the test-runner subagent to fix failing tests
Have the code-reviewer subagent look at my recent changes
@"code-reviewer (agent)" look at the auth changes
```

## 定义文件位置

官方约定：

- 项目级：`.claude/agents/`
- 用户级：`~/.claude/agents/`

Claude Code 会从当前工作目录一路向上扫描 `.claude/agents/`。如果你是手改磁盘文件，需重启 session 才会生效；如果通过 `/agents` 创建，则立即生效。

## 本仓库建议

`feature-exec` 是编排型 Skill，需要在不同阶段调度多个 subagent，不适合把整个 Skill 配成单一 `context: fork` agent。

在 Claude Code 中，Skill 不能像脚本一样直接执行函数调用。需要调度 subagent 时，主 Claude 必须使用 Agent 工具，并绑定 `.claude/agents/` 中的目标 agent。不要只在 prompt 中写“你是 xxx 专家”来模拟角色。

如果当前 Claude Code UI 支持 `@` 点名 agent，优先使用 `@`，因为它能保证指定 subagent 执行：

```text
@"backend-reviewer (agent)" review backend changes for change `<change-name>`.
@"backend-arch-reviewer (agent)" review backend architecture changes for change `<change-name>`.
@"frontend-reviewer (agent)" review frontend changes for change `<change-name>`.
```

如果是在 Skill 自动编排中，无法交互式选择 `@`，则用显式自然语言要求 Claude 调用同名 subagent：

```text
Use the backend-implementer subagent to complete Backend Tasks from tasks.md.
Use the frontend-implementer subagent to complete Frontend Tasks from tasks.md.
Use the backend-reviewer subagent to review backend changes.
Use the backend-arch-reviewer subagent to review backend structural changes.
Use the frontend-reviewer subagent to review frontend changes.
Use the test-writer subagent to write integration tests from test-plan.md.
Use the qa-tester subagent to execute test-plan.md and write qa-report.md.
```

调度后必须检查实际 Agent tool input：目标必须是对应的自定义 subagent，例如 `backend-reviewer`，而不是 `general-purpose` 或主 Claude 自己扮演的临时 prompt。

如果 Claude 没有使用目标 subagent，应停止当前阶段并重新调度。

本仓库配置了 Claude Code subagent 审计 hook，运行时日志写入：

```text
.claude/hooks/state/subagent-audit.jsonl
```

检查该文件中的 `SubagentStart` / `SubagentStop` 记录，确认 `agent_type` 是否等于阶段期望的 agent。

## 执行阶段常用 agent

阶段到 agent 映射，及每个 agent 对应的定义文件：

| 阶段 | agent 名 | 定义文件 |
|------|----------|----------|
| implement | `backend-implementer` | `.claude/agents/backend-implementer.md` |
| implement | `frontend-implementer` | `.claude/agents/frontend-implementer.md` |
| code-review | `backend-reviewer` | `.claude/agents/backend-reviewer.md` |
| code-review | `backend-arch-reviewer` | `.claude/agents/backend-arch-reviewer.md` |
| code-review | `frontend-reviewer` | `.claude/agents/frontend-reviewer.md` |
| test-write | `test-writer` | `.claude/agents/test-writer.md` |
| test-run | `qa-tester` | `.claude/agents/qa-tester.md` |

## 调度前置步骤（强制）

调用 Agent 工具前，必须先 Read 目标 agent 的定义文件。例如 code-review 阶段调度 `frontend-reviewer` 前：

```
Read .claude/agents/frontend-reviewer.md
```

读完后在 prompt 中引用 agent 定义中的具体步骤名称和检查命令，不要只泛泛写”审查前端代码”。目的是让 subagent 直接执行定义中的步骤，不需要自己再探索。读 agent 定义只需执行一次，同阶段多个 agent 可并行 Read。
