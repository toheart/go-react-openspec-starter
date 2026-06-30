# Runtime: Cursor

## 官方能力边界

根据 Cursor 官方 Subagents 文档与 2.4 更新说明，Cursor 已支持 subagents，并且这些 subagents：

- 在编辑器和 CLI 中可用
- 会并行运行
- 使用自己的上下文
- 可配置自定义 prompt、tool access、model

但我没有从可抓取的官方页面里拿到一个稳定的专用调用语法，因此这里不要写死伪 API。

## 本仓库约定的启动方式

在 Cursor 主对话里，显式要求当前 agent 使用某个 subagent。推荐句式：

```text
Use the backend-implementer subagent to complete Backend Tasks from tasks.md.
Use the test-writer subagent to write integration tests from test-plan.md.
Use the qa-tester subagent to execute test-plan.md and write qa-report.md.
```

如果当前版本 Cursor UI 支持从 subagent 列表或 @-mention 直接选择，就优先用 UI；否则继续用自然语言显式委托。

## 定义文件位置

- 本仓库当前把 Cursor subagent 定义放在 `.cursor/agents/<agent-name>.md`
- 调度前，先让目标 subagent 读取自己的定义文件

## 执行阶段常用 agent

- `backend-implementer`
- `frontend-implementer`
- `backend-reviewer`
- `frontend-reviewer`
- `test-writer`
- `qa-tester`

## Prompt 约束

- 明确当前阶段名称
- 明确输入工件路径
- 明确输出文件或报告位置
- 实现和测试阶段可以改代码，审查和 QA 阶段默认不改业务代码
