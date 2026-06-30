# OpenSpec Explore 内嵌参考

本参考只服务于 `feature-design` 的 `explore` 阶段，不是独立 Skill。父 Skill 的角色边界、状态脚本、Gate 规则和完成标准优先于本文。

## 使用边界

- 只做需求探索、代码调研、方案比较和风险识别。
- 可以读取文件、搜索代码、运行只读查询命令。
- 不写业务代码，不进入实现阶段。
- 不自动替用户扩大需求范围。
- 只有父流程明确要求落盘时，才把结论整理到 `.orchestrator/explore-report.md`。

## 启动检查

探索开始时优先了解当前 OpenSpec 状态：

```bash
openspec list --json
```

如果用户指定了 change，或已有相关 change，读取已有产物作为上下文：

```text
openspec/changes/<change-name>/proposal.md
openspec/changes/<change-name>/design.md
openspec/changes/<change-name>/tasks.md
openspec/changes/<change-name>/.orchestrator/brief.md
```

缺失文件不阻塞探索，但需要在结论中说明信息缺口。

## 探索方式

- 从真实代码和现有文档出发，不只做抽象推演。
- 明确影响范围、关键文件、依赖、约束、风险和测试入口。
- 对多种方案给出取舍，避免中立堆叠。
- 发现需求边界不清时，先问关键问题，不默默选择高风险方向。
- 可以使用简单 ASCII 图、表格或短清单解释数据流、状态流或模块边界。

## 输出到父流程

`feature-design` 需要把探索结论写入：

```text
openspec/changes/<change-name>/.orchestrator/explore-report.md
```

推荐结构：

```markdown
# Explore Report

## 背景

## 影响范围

## 关键文件

## 约束

## 方案取舍

## 风险

## 测试入口
```

## 不要做

- 不输出“准备实现”作为结论；实现只能由 `feature-exec` 处理。
- 不绕过 `gate-design`。
- 不把探索中的临时想法直接写成正式需求，除非父流程处于 `propose` 或用户明确确认。
