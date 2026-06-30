# Runtime: Cursor

## 官方能力边界

根据 Cursor 官方 Subagents 文档与 2.4 更新说明，Cursor 已支持 subagents，并且这些 subagents：

- 在编辑器和 CLI 中可用
- 会并行运行
- 使用自己的上下文
- 可配置自定义 prompt、tool access、model

官方文档当前可确认的是“支持 custom subagents”，但我没有从可抓取的官方页面中拿到一个稳定的、可直接写死在仓库里的专用调用语法。因此这里不要编造 `Task(...)` 之类的伪 API。

## 本仓库约定的启动方式

在 Cursor 主对话里，显式要求当前 agent 使用某个 subagent。推荐句式：

```text
Use the qa-test-planner subagent to generate openspec/changes/<change-name>/test-plan.md.
```

如果 Cursor UI 当前版本支持从 subagent 列表或 @-mention 里直接选择，就优先用 UI；否则就用上面的自然语言显式委托。

## 定义文件位置

- 本仓库当前把 Cursor subagent 定义放在 `.cursor/agents/<agent-name>.md`
- 调度前，先让目标 subagent 读取自己的定义文件

## 设计阶段常用 agent

- `qa-test-planner`
- 只读调研 agent

说明：`design-review` 固定由主流程读取并执行 `.agents/skills/design-review/SKILL.md`，不要调度 Cursor subagent。

## Prompt 约束

- 明确当前阶段名称
- 明确输入文件路径
- 明确输出应写回哪个 OpenSpec 或 `.orchestrator` 文件
- 明确是否允许修改代码；设计阶段默认不允许
