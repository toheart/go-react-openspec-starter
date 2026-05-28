# Ubiquitous Language（统一语言）

本文档维护项目的统一语言词汇表。所有代码命名（实体、值对象、服务、事件、接口等）和文档描述必须使用本词汇表中的术语，确保领域专家与开发团队之间的沟通零歧义。

## 维护规则

- 新增领域概念时，**必须先在此文档中定义术语**，再编写代码
- 每个术语包含：中文名、英文名（即代码中的命名）、定义、所属上下文
- 术语变更需同步更新所有引用处（代码命名、API 字段、前端文案）
- OpenSpec proposal 中涉及新领域概念时，必须在 proposal 的 Ubiquitous Language 章节中列出新增/变更的术语

## 词汇表

> 按 Bounded Context 分组，字母序排列。

### Sample Context（示例上下文）

| 中文 | English (代码命名) | 定义 | DDD 构件类型 |
|------|-------------------|------|-------------|
| 样例 | Sample | 系统中的示例实体，用于演示 DDD 分层结构 | Entity |
| 样例仓储 | SampleRepository | 样例实体的持久化接口，定义在 domain 层 | Repository |
| 样例服务 | SampleService | 处理样例相关业务逻辑的应用服务 | Application Service |

<!--
### <新的 Bounded Context>

| 中文 | English (代码命名) | 定义 | DDD 构件类型 |
|------|-------------------|------|-------------|
| ... | ... | ... | Entity / Value Object / Repository / Application Service / Domain Service / Domain Event / Aggregate Root |
-->
