---
name: antd-design-system
description: Ant Design B 端管理台设计规范。为使用 antd + React + TypeScript 的企业后台项目提供组件使用规范、布局模式、主题 Token 体系和高频组件最佳实践。当编写或审查前端 UI 代码时自动应用。
---

# Antd Design System

本项目使用 **Ant Design 6 + React 18 + TypeScript + Vite** 构建企业 B 端管理平台。本 Skill 提供具体落地规范，确保 AI 生成的代码与现有设计体系一致。

## 主题 Token

项目主题定义在 `frontend/src/theme/index.ts`：

```typescript
const theme: ThemeConfig = {
  token: {
    colorPrimary: "#4f46e5",    // indigo-600
    borderRadius: 6,
    colorBgLayout: "#f5f5f5",
  },
  components: {
    Layout: { headerBg: "#1e3050", headerHeight: 48, siderBg: "#fff" },
    Menu: { itemBorderRadius: 6, itemHeight: 38 },
  },
};
```

**规则**：
- 所有颜色引用 antd Token 或上述变量，禁止硬编码 `#1890ff` 等旧版默认色
- 主色 `#4f46e5` 用于主按钮、链接、活跃态；辅助色通过 antd 内置语义色（success/warning/error）
- 圆角统一 6px，通过 Token 控制

## 布局体系

三栏固定布局：`Header(48px) + Sidebar + Content`。

```
┌─────────────────────────────────────────┐
│  Header (#1e3050, h=48px, z=10)         │
├────────┬────────────────────────────────┤
│Sidebar │  Content (padding: 24px)       │
│(白底)   │  overflow: auto               │
│        │                                │
└────────┴────────────────────────────────┘
```

**规则**：
- Content 区域 `padding: 24px`，内部组件不再额外加外层 padding
- 页面标题用 antd `Typography.Title level={4}`，不用裸 `<h1>`
- 页面间距：标题与内容区 `marginBottom: 16px`

## 组件使用规范

### 高频组件

| 场景 | 组件 | 要求 |
|------|------|------|
| 卡片列表 | `Card` + `Row/Col` 或 flex | hoverable 属性；body padding 20px |
| 数据表格 | `Table` | 固定表头；数字右对齐；操作列固定右侧 |
| 表单 | `Form` + `Form.Item` | 垂直布局；label 在上；inline 验证 |
| 弹窗 | `Modal` | 必须有关闭按钮；宽度 520px（默认）或 720px（复杂表单）|
| 状态标签 | `Tag` | 语义化颜色：success/green、warning/orange、error/red、default/gray |
| 操作按钮 | `Button` | 每区域最多一个 `type="primary"`；动词开头（"创建"而非"新建按钮"）|
| 加载态 | `Spin` / `Skeleton` | 页面级用 Spin；列表/卡片用 Skeleton |
| 空状态 | `Empty` | 配描述文案 + 主操作按钮 |
| 消息反馈 | `App.useApp()` 的 message/notification | 成功消息 3s 自动消失；错误不自动消失 |

### 图标

使用 `@ant-design/icons`，不引入其他图标库。图标尺寸通过 `style={{ fontSize }}` 控制。

### Tag 颜色规范

```typescript
// 状态类
const STATUS_COLORS = {
  active: "green",
  pending: "orange",
  disabled: "default",
  error: "red",
} as const;

// 分类类（如 scope）
const SCOPE_COLORS = {
  enterprise: "purple",
  team: "blue",
  personal: "default",
} as const;
```

## 样式方案

项目以 **inline style** 为主，全局样式在 `frontend/src/styles/index.css`。

**规则**：
- 简单样式用 inline style（与现有代码保持一致）
- 复杂或复用的样式用 antd `styles` prop（如 `Card` 的 `styles={{ body: { padding: 20 } }}`）
- 伪类/伪元素/媒体查询写 CSS，不写 inline
- 禁止引入 CSS-in-JS 库（styled-components / emotion）
- 禁止引入 Tailwind CSS

### 间距规范

基于 8px 栅格：

| 用途 | 值 |
|------|-----|
| 紧凑间距 | 4px |
| 组件内间距 | 8px |
| 元素间距 | 12px / 16px |
| 区块间距 | 24px |
| 大区块间距 | 32px / 48px |

### 字体规范

```css
/* 系统字体栈，不引入外部字体 */
font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;

/* 等宽字体（代码/路径/命令）*/
font-family: 'JetBrains Mono', 'SFMono-Regular', Consolas, monospace;
```

| 用途 | 大小 | 字重 |
|------|------|------|
| 页面标题 | 20px | 600 |
| 卡片标题 | 15-16px | 600 |
| 正文 | 14px | 400 |
| 辅助文字 | 12-13px | 400 |
| 标签/Badge | 11-12px | 400 |

### 颜色语义

```typescript
const COLORS = {
  textPrimary: "rgba(0,0,0,0.85)",
  textSecondary: "#64748b",     // slate-500
  textTertiary: "#94a3b8",      // slate-400
  bgPage: "#f5f5f5",
  bgCard: "#fff",
  bgSubtle: "#f1f5f9",          // slate-100，图标底色等
  border: "#f0f0f0",
  primary: "#4f46e5",           // indigo-600
};
```

## 反模式

生成 UI 代码时避免：

- **Card 嵌套 Card** — 扁平化层级
- **每个按钮都 `type="primary"`** — 建立主次层级
- **Modal 里开 Modal** — 复杂流程用新页面或 Drawer
- **状态标签用随机颜色** — 严格按语义色
- **大段 loading 文本** — 用 Skeleton 占位
- **表格无固定表头** — B 端表格数据多，必须固定
- **超过 7 个 Tab** — 超出时考虑二级导航或分组

## 参考文件

编写前端代码时，优先参考以下文件了解现有模式：
- `frontend/src/App.tsx` — 路由结构和布局
- `frontend/src/theme/index.ts` — 主题配置
- `frontend/src/styles/index.css` — 全局样式
- `frontend/src/components/mcp/MCPCard.tsx` — 典型卡片组件
- `frontend/src/components/common/PageHeader.tsx` — Header 组件
