# 5 分钟上手

## 前置条件

- Go 1.23+
- Node.js 18+
- 你常用的 AI IDE（Cursor / Claude Code / Codex）

## Step 1: 克隆 & 初始化

```bash
git clone https://github.com/toheart/go-react-openspec-starter.git my-project
cd my-project
make init
```

CLI 会问你 4 个问题：

```
◆ 项目名称 (slug)
│ order-center
│
◆ Go module 路径
│ github.com/acme/order-center
│
◆ 选择 AI IDE（生成编排文件）
│ ● Cursor
│ ○ Claude Code
│ ○ Codex
│ ○ 跳过
│
◆ 选择流水线模板
│ ● Go+React 全栈
│ ○ 纯后端
│ ○ 热修复
```

自动推导的配置会请你确认，一键完成。

## Step 2: 启动开发

```bash
make dev
```

打开浏览器访问 `http://localhost:3000`，看到前端页面即成功。

后端 API：`http://localhost:8080/api/v1/samples`

## Step 3: 开始第一个功能

在你的 AI IDE 中说：

> "实现用户注册功能"

Orchestrator Skill 会按流水线自动驱动：

1. **propose** — 在 `openspec/changes/` 下生成 proposal + tasks
2. **Gate** — 你确认方案
3. **implement** — 前后端并行实现
4. **Gate** — 你确认代码
5. **test** — 自动运行测试
6. **archive** — 归档变更

## 目录导航

| 你要做什么 | 去哪里看 |
|-----------|---------|
| 改后端代码 | `backend/internal/` |
| 改前端页面 | `frontend/src/` |
| 看工程规范 | `openspec/specs/` |
| 看流水线模板 | `pipelines/` |
| 看 OpenSpec 示例 | `openspec/changes/_example/` |
