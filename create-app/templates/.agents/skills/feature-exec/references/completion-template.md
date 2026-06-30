# 完成输出模板

```text
**Change**: <name>

### 结果
- 设计交接：openspec/changes/<name>/.orchestrator/handoff.json
- 执行状态：openspec/changes/<name>/.orchestrator/execution-state.json
- QA 报告：openspec/changes/<name>/.orchestrator/qa-report.md
- 测试代码：<新增或更新的 *_test.go>
- OpenSpec：openspec/changes/archive/<date>-<name>/

### 摘要
<1-2 段说明这次变更完成了什么、测试如何、是否有 residual risk>

### 关键决定
- gate-code: <decision>
- gate-test-code: <decision>
- gate-test: <decision>
```
