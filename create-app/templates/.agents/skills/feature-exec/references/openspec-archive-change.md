# OpenSpec Archive 内嵌参考

本参考只服务于 `feature-exec` 的 `archive` 阶段，不是独立 Skill。父 Skill 的角色边界、状态脚本、Gate 规则和完成标准优先于本文。

## 归档前置条件

进入 `archive` 前必须确认：

- `design-state.json` 已完成设计阶段。
- `execution-state.json` 已完成执行阶段的实现、代码审查、测试写作和 QA 验收。
- `qa-report.md` 已存在。
- `gate-test` 已通过；非 trust 模式下必须有用户明确确认。
- 需要保留的测试资产已经落盘。

如果任何条件不满足，不允许归档。

## 状态检查

检查 OpenSpec artifact 状态：

```bash
openspec status --change "<change-name>" --json
```

检查 `tasks.md` 是否仍有未完成任务。若存在未完成任务，必须在 Gate 摘要中说明，并等待父流程决策；不要直接归档。

## 归档命令

优先使用 OpenSpec CLI：

```bash
openspec archive <change-name> --yes
```

如果 CLI 不可用，才考虑手动移动目录；手动归档前必须说明原因，并保持 `.openspec.yaml` 随 change 一起移动。

## 输出给父流程

归档完成后返回以下信息给 `feature-exec`：

```text
change name
archive location
artifact completion summary
task completion summary
qa report path
```

归档后由父 Skill 决定是否进入 `requirement-sync`。当前项目默认将 `requirement-sync` 标记为 `skipped`，除非用户明确要求并且外部依赖可用。
