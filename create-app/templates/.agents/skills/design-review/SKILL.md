---
name: design-review
description: >
  架构级方案评审与 Bad Path 审查。在 feature-design 的 propose 之后、
  gate-design 之前由主流程执行。审查方案完整性、架构一致性、数据模型一致性、
  bad path 覆盖度，产出审查报告并把错误响应契约追加到 design.md。
  说"方案评审""design review""架构评审""审查方案"时触发。
---

# Design Review — 架构级方案评审与 Bad Path 审查

加载本 Skill 后，主 Agent 必须亲自执行方案评审。不要委托给 SubAgent。

## 为什么主流程执行

方案评审涉及跨模块推理、一致性判断、架构边界和 bad path 推导。这里最容易出现"看起来合理，落地时返工"的问题，所以不能只做轻量 reviewer 式扫读。

## 必读

执行前必须先读取：

- `AGENTS.md`
- `docs/README.md`
- `docs/quickstart.md`
- `docs/testing.md`
- `openspec/specs/backend-go-style/spec.md`
- `openspec/specs/frontend-typescript-style/spec.md`
- `openspec/specs/api-conventions/spec.md`
- `openspec/specs/testing-standards/spec.md`
- `openspec/changes/<change-name>/proposal.md`
- `openspec/changes/<change-name>/design.md`
- `openspec/changes/<change-name>/tasks.md`
- `openspec/changes/<change-name>/.orchestrator/brief.md`（如存在）
- `openspec/changes/<change-name>/.orchestrator/explore-report.md`（如存在）
- `openspec/changes/<change-name>/model-validation.md`（如存在）

如果某个文件不存在，记录为事实，不要臆造其内容。

## 工作流程

### Phase 1：方案完整性审查

逐项检查 `proposal.md`、`design.md` 和 `tasks.md`：

| # | 检查项 | 要回答的问题 |
|---|--------|-------------|
| C1 | 目标清晰 | 问题定义是否清晰？解决了什么用户痛点或工程痛点？ |
| C2 | 方案可行 | 设计方案在当前代码库中是否可落地？有没有忽略已有约束？ |
| C3 | 任务完整 | tasks 是否覆盖 proposal 和 design 中描述的全部变更？ |
| C4 | 复杂度分布 | 任务是否拆到可独立执行、可独立验证的粒度？ |
| C5 | 反模式清单 | design.md 是否点出容易误实现的反模式、边界和禁区？ |

### Phase 2：架构与数据模型审查

当提案涉及新增实体、修改数据结构、变更 API DTO、跨层数据流或前后端契约时执行。若存在 `model-validation.md`，必须基于调研报告回答，不能凭空推断。

| # | 检查项 | 要回答的问题 |
|---|--------|-------------|
| M1 | 同类对齐 | 本次涉及的实体或 DTO 在系统中有无同类？新模型是否对齐既有模式？ |
| M2 | 数据穿透 | Domain → Application → HTTP DTO → API → Frontend 的路径是否自然？哪里需要不自然适配？ |
| M3 | 标识一致性 | ID、key、slug、状态字段在所有消费方中的语义是否一致？ |
| M4 | 扩展性 | 未来新增同类实体或字段时，当前模型能否低成本适配？ |
| M5 | 状态归属 | 状态由哪一层写入？谁读取？是否存在同步散落或双写风险？ |

每项给出结论：`OK` / `WARN` / `BLOCKER`，并说明依据。

### Phase 3：Bad Path 四维审查

对 proposal、design 和 OpenSpec delta 中的每个功能点，系统性推导 bad path。

#### 3.1 输入边界

对每个 API 端点或表单入口，列出：

| 场景 | 输入 | 期望 HTTP Status | 期望 Error Code | 处理方式 |
|------|------|-----------------|----------------|---------|
| 必填参数缺失 | `<field>` 为空 | 400 | INVALID_PARAMS | 前端校验 + 后端兜底 |
| 参数类型错误 | `<field>` 类型错误 | 400 | INVALID_PARAMS | 绑定或解析层拦截 |
| 参数越界 | `<field>` 超出范围 | 400 | INVALID_PARAMS | 业务校验返回明确错误 |

#### 3.2 状态冲突

对每个涉及状态变更的操作，列出：

| 操作 | 当前状态 | 结果 | 幂等性 |
|------|---------|------|--------|
| `<operation>` | `<valid-state>` | 正常流转 | - |
| `<operation>` | `<invalid-state>` | 409 CONFLICT | 说明是否幂等 |

#### 3.3 依赖失败

对每个外部依赖或基础设施调用，列出：

| 依赖 | 失败场景 | Fallback | 重试 | 日志级别 |
|------|---------|----------|------|---------|
| Database | 连接超时 | 无，返回错误 | 否 | ERROR |
| External API | 请求失败 | 按设计约定处理 | 视场景 | WARN/ERROR |

#### 3.4 权限与资源边界

| 操作 | 无权限用户 | 跨资源/跨租户/越权访问 |
|------|-----------|-----------------------|
| `<operation>` | 403 FORBIDDEN | 按资源归属隔离 |

### Phase 4：验收场景覆盖矩阵

基于 `brief.md`、`explore-report.md`、proposal 和 design 中的验收口径，逐项检查：

| 验收场景 | 覆盖的 Task | 对应测试层级 | 覆盖状态 |
|---------|------------|------------|---------|
| AS-1: Happy Path | Task 1.1, 1.2 | 单元 / 接口 / UI | OK |
| AS-2: Bad Path | 无 Task 覆盖 | - | BLOCKER |

覆盖矩阵中标记为 `BLOCKER` 的场景必须在审查报告中列为阻断项。

### Phase 5：产出审查报告

审查报告必须写入：

```text
openspec/changes/<change-name>/.orchestrator/design-review.md
```

格式：

```markdown
## 方案评审报告

### 一、方案完整性
| # | 检查项 | 结果 | 说明 |
|---|--------|------|------|
| C1 | 目标清晰 | OK/WARN/BLOCKER | <详情> |

### 二、架构与数据模型
| # | 检查项 | 结果 | 说明 |
|---|--------|------|------|
| M1 | 同类对齐 | OK/WARN/BLOCKER | <详情> |

### 三、Bad Path 审查
<Phase 3 的四张表>

### 四、验收场景覆盖矩阵
<Phase 4 的覆盖表>

### 五、错误响应契约完整性检查
- [ ] design.md 是否包含"错误响应契约"段落？
- [ ] 错误响应契约是否覆盖输入边界、状态冲突、依赖失败、权限边界？
- [ ] 每个错误场景是否有明确 HTTP Status + Error Code？
- [ ] 错误响应契约中的场景是否能映射到测试计划？

### 六、结论
- BLOCKER: <如有>
- 建议修改: <如有>
- 结论: APPROVE / NEEDS_REVISION / REJECT
```

如果存在 BLOCKER，结论必须是 `NEEDS_REVISION` 或 `REJECT`。

### Phase 6：追加错误响应契约

如果 Phase 3 产出了错误响应、状态冲突、依赖失败或权限边界行为定义，必须追加写入：

```text
openspec/changes/<change-name>/design.md
```

追加格式：

```markdown
## 错误响应契约（design-review 产出，implement 必读）

### 输入边界
| 端点/入口 | 场景 | HTTP Status | Error Code | 处理方式 |
|-----------|------|-------------|------------|---------|

### 状态冲突
| 操作 | 非法前置状态 | 行为 | 幂等性 |
|------|--------------|------|--------|

### 依赖失败
| 依赖 | 失败场景 | Fallback | 重试 | 日志级别 |
|------|----------|----------|------|---------|

### 权限与资源边界
| 操作 | 无权限用户 | 越权访问 | 行为 |
|------|----------|----------|------|
```

如果 `design.md` 已有同名段落，更新该段落，不要重复追加多个同名段落。

## 约束

- 主流程执行：不委托给 SubAgent。
- 可读可写文档：可以写 `.orchestrator/design-review.md`，可以更新 `design.md` 的错误响应契约，不修改业务代码。
- 基于事实：数据模型审查优先基于 `model-validation.md` 和代码搜索，不凭空推断。
- Bad path 必须具体：至少到 `HTTP Status + Error Code + 处理方式` 的粒度。
- 不替用户拍板：只给出 `APPROVE` / `NEEDS_REVISION` / `REJECT` 和依据；Gate 仍由 `feature-design` 处理。
