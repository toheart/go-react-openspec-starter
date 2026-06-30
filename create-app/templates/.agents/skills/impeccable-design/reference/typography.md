# 排版详细参考

## 垂直节奏

行高是所有垂直间距的基准单位。正文 `14px × line-height 1.5 = 21px`，间距取其倍数（21/42/63px）或近似的 8px 栅格值（24/48px）。文字和间距共享数学基础时，布局会有潜意识的和谐感。

## 模块化字号体系

常见错误：使用太多相近的字号（13px、14px、15px、16px）——层级模糊。

**用更少的字号、更大的对比度**：

| 角色 | 大小 | 用途 |
|------|------|------|
| xs | 11-12px | 标签、Badge、辅助标注 |
| sm | 12-13px | 次要信息、元数据、时间戳 |
| base | 14px | 正文、表格内容、表单 |
| lg | 15-16px | 卡片标题、子标题 |
| xl | 18-20px | 页面标题 |
| xxl | 24-28px | 仅 Hero 区域或统计大数字 |

推荐比例：1.25（大三度），即 `base × 1.25 = lg × 1.25 = xl`。

## 字体选择

### B 端优先用系统字体

```css
font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto,
             'Helvetica Neue', Arial, sans-serif;
```

系统字体优势：原生感、零加载时间、高可读性。B 端管理台追求效率而非个性，系统字体是最佳选择。

### 等宽字体

代码、命令、路径、API 前缀等场景：

```css
font-family: 'JetBrains Mono', 'SFMono-Regular', Consolas,
             'Liberation Mono', Menlo, monospace;
```

## 字重使用

| 场景 | 字重 | 说明 |
|------|------|------|
| 页面标题 | 600 (Semi Bold) | 不用 700，600 在中文环境更平衡 |
| 卡片/区块标题 | 600 | |
| 正文 | 400 (Regular) | |
| 次要文字 | 400 + 浅色 | 靠颜色而非字重降低层级 |
| 强调文本 | 500 (Medium) | 正文中需要强调时使用 |
| 标签/Badge | 400 | 字号已小，不需要加粗 |

## OpenType 特性

```css
/* 表格数字等宽对齐 */
.data-table td { font-variant-numeric: tabular-nums; }

/* 禁用代码区连字 */
code, pre { font-variant-ligatures: none; }

/* 字距微调 */
body { font-kerning: normal; }
```

## 可读性

- 正文行长控制在 `max-width: 65ch`（约 500px），防止阅读时视线跨度过大
- 浅色背景上的深色文字行高 1.5；深色背景上的浅色文字行高 1.6（感知字重更轻，需要更多呼吸空间）
- B 端正文最小 13px，推荐 14px
- 触控目标最小 44px（含 padding）

## 中文排版补充

- 中文不需要 `letter-spacing`（已有自然间距）
- 中英混排时英文自动加空格可通过 `text-autospace: ideograph-alpha` 实现（实验性属性，可不加）
- 标点悬挂（`hanging-punctuation`）在 B 端管理台中不必要
- 中文段落缩进不推荐（现代 Web 风格）
