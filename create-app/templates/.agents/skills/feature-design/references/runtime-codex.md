# Runtime: Codex

## 官方启动方式

Codex 官方文档明确说明：

- Codex 只有在你“显式要求”时才会 spawn subagent
- 内置 agent 有 `default`、`worker`、`explorer`
- 自定义 agent 定义文件位置是 `.codex/agents/*.toml` 或 `~/.codex/agents/*.toml`
- 可用 `/agent` 查看和切换活动 agent 线程

官方示例句式：

```text
Review this branch against main. Have pr_explorer map the affected code paths, reviewer find real risks, and docs_researcher verify the framework APIs that the patch relies on.
```

## 重要区分

- `.agents/skills/` 是 Codex 的 skill 目录
- `.codex/agents/` 才是 Codex 的自定义 subagent 目录

两者不是一回事，不能拿 `.cursor/agents/*.md` 或 `.claude/agents/*.md` 直接当 Codex subagent 用。

## 本仓库当前状态

本仓库已经补齐了一批 Codex 自定义 agents，位于：

- `.codex/agents/qa-test-planner.toml`
- `.codex/agents/explorer.toml`

因此设计阶段已经可以显式要求 Codex 使用这些角色。

## 设计阶段建议

- `explore` 可直接在主线程完成；需要独立探索线程时，显式要求使用 `explorer`
- `design-review` 固定由主线程读取并执行 `.agents/skills/design-review/SKILL.md`，不要交给 Codex subagent
- `test-design` 可显式要求使用 `qa-test-planner`
- 所有结论仍然写回 OpenSpec 与 `.orchestrator`

## Prompt 约束

- 说明当前阶段
- 说明输入工件
- 说明输出文件
- 设计阶段默认不实现业务代码
