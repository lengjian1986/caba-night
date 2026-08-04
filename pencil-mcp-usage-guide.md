# Pencil 使用指南：Codex + MCP 实操手册

本文说明如何让 Codex 通过 Pencil MCP 创建、读取、修改和验收 `.pen` 设计稿。

它重点回答“Pencil 怎么操作”，与项目中的
[《任意设计图还原为 Pencil 设计稿：通用工作流》](./visual-design-to-pencil-workflow.md)
互补：

- 本文：Pencil MCP、节点、布局、图片、文字、组件和验收工具怎么使用。
- 原文：拿到一张设计图后，如何分析并逐步还原。

---

## 1. 最重要的规则

### 1.1 `.pen` 只能通过 Pencil MCP 操作

`.pen` 是 Pencil 的加密设计文件，不能使用以下方式读取或修改：

- `cat`
- `sed`
- `grep`
- `rg`
- 普通文本编辑器
- Python、Node.js 等文件读写脚本

正确方式是使用 Pencil MCP：

- `get_editor_state`
- `batch_get`
- `batch_design`
- `get_screenshot`
- `snapshot_layout`
- `get_variables`
- `get_guidelines`
- `export_nodes`
- `export_html`

图片素材、字体文件和普通项目文件仍然可以使用常规文件工具处理。

### 1.2 不要在命令行创建伪 `.pen`

不能通过 `touch demo.pen`、复制 JSON 或手写文件内容来创建可用的 Pencil 文件。

正确流程：

1. 在 Pencil 编辑器中创建或打开 `.pen`。
2. 确认 Pencil MCP 已连接。
3. 使用 `get_editor_state` 获取当前活动文件。
4. 后续通过 MCP 修改该文件。

### 1.3 每次开始都先读取编辑器状态

第一次操作当前画布前，调用：

```json
{
  "include_schema": true
}
```

对应工具：

```text
get_editor_state
```

它会返回：

- 当前打开的 `.pen` 路径
- 当前选中的节点
- 顶层节点
- 可复用组件
- 当前 Pencil Schema
- `batch_design` 的操作规则

不要凭上一次记忆直接编辑。Pencil 是协作画布，用户可能在操作期间修改节点。

### 1.4 修改顶层画板时使用 placeholder

任何新建、复制或正在修改的顶层画板，都应在工作期间设置：

```js
placeholder: true
```

完成并验收后再关闭：

```js
Update("screenId", { placeholder: false })
```

如果实际内容位于手机外框等顶层容器内，修改期间应将该顶层容器设为 placeholder。

---

## 2. Pencil 的节点模型

Pencil 画布是一棵节点树。

常见结构：

```text
Document
├── Screen / Page
│   ├── Header
│   ├── Content
│   │   ├── Image
│   │   ├── Text
│   │   └── Component
│   └── Footer
└── Reference Image
```

### 2.1 常用节点类型

| 节点 | 用途 |
|---|---|
| `frame` | 画板、容器、组件、布局区域 |
| `group` | 简单图层分组，不承担布局 |
| `rectangle` | 矩形、图片载体、色块 |
| `ellipse` | 圆形、椭圆、圆环 |
| `text` | 可编辑文字 |
| `path` | 自定义 SVG 路径 |
| `polygon` | 多边形 |
| `icon` | 图标库图标 |
| `ref` | 可复用组件的实例 |
| `script` | 通过脚本生成节点 |

### 2.2 图片不是独立节点类型

Pencil 没有 `image` 节点。

图片需要作为 `frame` 或 `rectangle` 的 Fill：

```js
imageNode = Insert(parentId, {
  type: "rectangle",
  name: "角色立绘",
  x: 200,
  y: 300,
  width: 420,
  height: 620,
  fill: {
    type: "image",
    url: "design/assets/character.png",
    mode: "fit"
  }
})
```

图片路径相对于 `.pen` 文件所在目录。

常用图片模式：

| 模式 | 效果 |
|---|---|
| `fit` | 完整显示图片，可能留空 |
| `fill` | 填满容器，可能裁切 |
| `stretch` | 强制铺满，可能拉伸 |

### 2.3 所有新节点必须有语义化名称

推荐：

```text
创建角色标题组
中央角色 · 凌霄剑客
宗门项 · 炎宗
昵称输入框底框 · 美术素材
开始修行按钮文字
```

不推荐：

```text
Group 1
Rectangle 23
Image
Text Copy 4
```

语义化命名会直接影响后续查找、修改和开发交付效率。

---

## 3. 核心 MCP 工具

### 3.1 `get_editor_state`

用途：

- 确认当前活动 `.pen`
- 获取选中节点
- 查看顶层结构
- 获取完整 Schema 和操作规则

使用时机：

- 每轮 Pencil 工作开始时
- 用户在画布中手动修改后
- 怀疑当前节点 ID 已过期时

---

### 3.2 `get_guidelines`

Pencil 要求在设计任务开始前读取对应 guideline。

常见类型：

- `Mobile App`
- `Web App`
- `Landing Page`
- `Design System`
- `Table`
- `Slides`

示例：

```json
{
  "category": "guide",
  "name": "Mobile App"
}
```

Guideline 是设计和结构建议，不应覆盖用户明确要求。

---

### 3.3 `batch_get`

用途：

- 按节点 ID 读取结构
- 按名称、类型或 reusable 属性搜索
- 一次读取多个节点
- 在编辑前确认节点没有被用户修改

示例：

```json
{
  "filePath": "/absolute/path/all.pen",
  "nodeIds": ["screenId", "componentId"],
  "readDepth": 2
}
```

建议：

- `readDepth` 通常使用 `1` 或 `2`。
- 不要一次读取整个大型文档的深层结构。
- 如果返回 `...`，再读取具体子节点。
- 多个相关节点应合并为一次调用。

---

### 3.4 `batch_design`

所有实际修改通过 `batch_design` 完成。

支持的操作：

```text
Insert
Update
Replace
Copy
Move
Delete
SetVariables
Generate
FindEmptySpace
```

每次调用执行一小段 JavaScript。

### Insert

创建节点：

```js
panel = Insert(parentId, {
  type: "frame",
  name: "信息面板",
  x: 40,
  y: 80,
  width: 320,
  height: 240,
  layout: "none",
  fill: "#00000000"
})
```

### Update

修改现有节点：

```js
Update("nodeId", {
  x: 60,
  y: 100,
  width: 360
})
```

不能通过 `Update` 修改：

- `id`
- `type`
- `ref`
- `children`

### Replace

用新节点整体替换旧节点：

```js
newNode = Replace("oldNodeId", {
  type: "rectangle",
  name: "新图片",
  x: 0,
  y: 0,
  width: 200,
  height: 200,
  fill: {
    type: "image",
    url: "design/assets/new.png",
    mode: "fit"
  }
})
```

### Copy

复制普通节点，或实例化 reusable 组件：

```js
copy = Copy("sourceNodeId", parentId, {
  name: "复制项",
  x: 200,
  y: 0
})
```

复制组件时，返回的是关联实例。

### Move

移动节点到新父级或调整图层顺序：

```js
Move("nodeId", "newParentId", 2)
```

### Delete

删除节点：

```js
Delete("nodeId")
```

删除前应重新读取节点，避免删除用户刚刚修改的内容。

### FindEmptySpace

在文档根节点放置新画板或组件前，先查找空白区域：

```js
pos = FindEmptySpace({
  width: 1024,
  height: 1536,
  direction: "right",
  padding: 100
})
```

不要在 document 根节点随意猜坐标。

---

## 4. `batch_design` 的正确拆分方式

不要在一次调用中创建整套大型页面。

推荐拆分：

1. 创建顶层画板。
2. 创建主要区域。
3. 创建一个独立组件。
4. 获取返回的节点 ID。
5. 继续添加子节点或组件实例。
6. 完成局部截图和布局检查。

示例：

```js
Update("rootFrameId", { placeholder: true })

section = Insert("screenId", {
  type: "frame",
  name: "角色选择区",
  x: 80,
  y: 300,
  width: 860,
  height: 220,
  layout: "none",
  fill: "#00000000",
  placeholder: true
})
```

下一次调用再使用返回的 `section` ID添加内容。

完成后：

```js
Update("sectionId", { placeholder: false })
Update("rootFrameId", { placeholder: false })
```

### 4.1 变量跨调用规则

每次 `batch_design` 都是新作用域。

返回的节点 ID才是后续最可靠的引用。

不要假设上一次调用中的局部变量仍然存在。

---

## 5. 坐标与布局

### 5.1 坐标是相对父节点的

```text
child.x = 50
child.y = 100
```

表示子节点相对于父节点左上角移动 50、100。

### 5.2 `layout: "none"`

适合：

- 游戏 UI
- 海报
- HUD
- 自由叠层
- 精确截图还原

子节点可以使用 `x`、`y` 自由定位。

```js
group = Insert(parentId, {
  type: "frame",
  name: "自由叠层区",
  x: 100,
  y: 200,
  width: 500,
  height: 400,
  layout: "none"
})
```

### 5.3 横向或纵向布局

适合：

- 列表
- 导航
- 卡片组
- 表单
- 工具栏

```js
row = Insert(parentId, {
  type: "frame",
  name: "按钮行",
  layout: "horizontal",
  gap: 16,
  alignItems: "center"
})
```

布局容器中的普通子节点不应再依赖 `x`、`y`。

### 5.4 动态尺寸

常用：

```text
fit_content
fill_container
```

规则：

- 父节点由内容撑开：`fit_content`
- 子节点填满布局父级：`fill_container`
- 避免父子相互依赖导致循环尺寸
- Pencil 不支持百分比和 `calc()`

错误：

```js
width: "100%"
height: "50vh"
width: "calc(100% - 20px)"
```

---

## 6. 文字节点

文字必须显式设置 Fill，否则不可见。

```js
title = Insert(parentId, {
  type: "text",
  name: "页面标题",
  content: "创建角色",
  fontFamily: "Noto Serif SC",
  fontSize: 48,
  fontWeight: "900",
  fill: "#F4DC93"
})
```

### 6.1 `textGrowth`

| 值 | 用途 |
|---|---|
| `auto` | 单行文字，尺寸由内容决定 |
| `fixed-width` | 固定宽度，自动计算高度并换行 |
| `fixed-width-height` | 固定宽高，用于精确对齐 |

固定宽高文字：

```js
label = Insert(parentId, {
  type: "text",
  name: "按钮文字",
  x: 80,
  y: 30,
  width: 320,
  height: 90,
  textGrowth: "fixed-width-height",
  content: "开始修行",
  fontFamily: "Ma Shan Zheng",
  fontSize: 68,
  textAlign: "center",
  textAlignVertical: "middle",
  fill: "#A42D1D"
})
```

### 6.2 文字描边的近似方式

Pencil Text 没有直接的文字 Stroke，可使用外阴影近似：

```js
effect: {
  type: "shadow",
  shadowType: "outer",
  offset: { x: 0, y: 0 },
  spread: 2,
  blur: 0,
  color: "#3A1E0EF0"
}
```

需要描边和投影时可使用多个 Effect。

### 6.3 中文字体建议

| 风格 | 可尝试字体 |
|---|---|
| 正式宋体、标题 | `Noto Serif SC` |
| 现代黑体、正文 | `Noto Sans SC` |
| 毛笔、书法按钮 | `Ma Shan Zheng` |

字体只是起点，仍需对照参考图调整字号、字重、字距和颜色。

---

## 7. 图片素材与分层

复杂美术不要强行用 Pencil 形状重画，也不要把整张页面截图放进画板冒充还原。

推荐拆分：

```text
独立美术底框
+ 独立图标或角色图
+ Pencil 文字
+ 必要的状态外框
+ 装饰连接件
```

例如头像选择项：

```text
头像项
├── 独立头像内图
└── 未选中外框 / 选中外框
```

宗门选择项：

```text
宗门项
├── 宗门内图
├── 选中或未选中外框
└── Pencil 宗门名称
```

按钮：

```text
主按钮组
├── 空按钮底框
├── Pencil 按钮文字
├── 宝石挂扣
└── 流苏
```

这样可以独立替换文字、状态和图片，不需要重新生成整张 UI。

---

## 8. 可复用组件

将节点设置为：

```js
reusable: true
```

即可成为组件。

实例化：

```js
instance = Insert(parentId, {
  type: "ref",
  name: "头像项实例",
  ref: componentId,
  x: 200,
  y: 100
})
```

适合组件化：

- 多次出现的按钮
- 列表项
- 卡片
- 标签
- 状态徽章
- 头像项

不必组件化：

- 只出现一次的大型自由构图
- 强依赖独特叠层的单次装饰
- 临时参考图

### 8.1 实例覆盖

组件实例可以通过 `descendants` 修改内部节点：

```js
instance = Insert(parentId, {
  type: "ref",
  name: "用户卡片",
  ref: cardComponentId,
  descendants: {
    [titleNodeId]: {
      content: "新的标题"
    }
  }
})
```

复制组件后，不要继续使用母组件内部旧 ID去修改复制结果。

---

## 9. Variables

读取现有变量：

```text
get_variables
```

设置变量：

```js
SetVariables({
  "color-gold": {
    type: "color",
    value: "#D9A84E"
  },
  "spacing-md": {
    type: "number",
    value: 16
  },
  "font-title": {
    type: "string",
    value: "Noto Serif SC"
  }
})
```

引用变量：

```js
fill: "$color-gold"
gap: "$spacing-md"
fontFamily: "$font-title"
```

适合变量化：

- 多次使用的颜色
- 字体家族
- 间距
- 统一圆角
- 主题值

不要为只出现一次的数值创建大量变量。

---

## 10. 验收工具

### 10.1 `get_screenshot`

用于视觉检查：

- 颜色
- 字体
- 图片裁切
- 叠层
- 对齐
- 整体比例

优先截图最小的完整区域：

```text
单个组件 → 一个区块 → 整个页面 → 设备外框
```

不要每新增一个节点就截图，完整区块完成后再截图。

### 10.2 `snapshot_layout`

用于结构检查：

- 节点溢出
- 部分裁切
- 容器折叠
- 尺寸异常

推荐：

```json
{
  "filePath": "/absolute/path/all.pen",
  "parentId": "sectionId",
  "maxDepth": 3,
  "problemsOnly": true
}
```

理想结果：

```text
No layout problems.
```

如果文字部分溢出，不要忽略。应调整文字框或父容器尺寸。

### 10.3 `export_nodes`

将指定节点导出为：

- PNG
- JPEG
- WebP
- PDF

适合：

- 最终预览
- 与参考图并排对比
- 交付开发
- OCR 或视觉测量

### 10.4 `export_html`

可以将节点导出为：

- HTML + Tailwind
- HTML + CSS

适合结构交付和开发参考，不代表导出结果自动具备完整业务逻辑。

---

## 11. 从空画板到完成页面的标准顺序

```text
1. 在 Pencil 中创建或打开 .pen
2. get_editor_state(include_schema: true)
3. get_guidelines
4. batch_get 读取当前结构
5. 顶层画板 placeholder: true
6. 创建页面或局部容器
7. 分批加入结构、图片和文字
8. 每完成一个区块截图检查
9. snapshot_layout(problemsOnly: true)
10. 修复问题
11. 关闭局部和顶层 placeholder
12. 整屏截图与最终布局检查
13. 必要时 export_nodes
```

---

## 12. 一个最小完整示例

第一批：创建画板和容器。

```js
pos = FindEmptySpace({
  width: 390,
  height: 844,
  direction: "right",
  padding: 80
})

screen = Insert(document, {
  type: "frame",
  name: "登录页",
  x: pos.x,
  y: pos.y,
  width: 390,
  height: 844,
  layout: "none",
  clip: true,
  fill: "#F7F4ED",
  placeholder: true
})

card = Insert(screen, {
  type: "frame",
  name: "登录卡片",
  x: 24,
  y: 220,
  width: 342,
  height: 320,
  layout: "vertical",
  gap: 20,
  padding: 24,
  fill: "#FFFFFF",
  cornerRadius: 24
})
```

第二批：使用上一步返回的 ID 添加文字。

```js
title = Insert("cardId", {
  type: "text",
  name: "登录标题",
  content: "欢迎回来",
  fontFamily: "Noto Sans SC",
  fontSize: 28,
  fontWeight: "700",
  fill: "#24211D"
})

subtitle = Insert("cardId", {
  type: "text",
  name: "登录说明",
  textGrowth: "fixed-width",
  width: "fill_container",
  content: "登录后继续使用应用",
  fontFamily: "Noto Sans SC",
  fontSize: 15,
  fill: "#746F68"
})
```

完成后：

```js
Update("screenId", {
  placeholder: false
})
```

最后分别执行：

```text
get_screenshot(screenId)
snapshot_layout(screenId, problemsOnly: true)
```

---

## 13. 常见错误

### 错误 1：直接读取 `.pen`

原因：`.pen` 是加密文件。

正确做法：使用 Pencil MCP。

### 错误 2：图片使用不存在的 `image` 节点

正确做法：创建 rectangle 或 frame，并设置 image Fill。

### 错误 3：没有先读取 Schema

后果：

- 使用不存在的属性
- 设置不支持的布局值
- 调用错误的节点类型

正确做法：先 `get_editor_state(include_schema: true)`。

### 错误 4：在布局容器中继续依赖 x/y

横向或纵向布局会忽略普通子节点的 x/y。

正确做法：

- 使用 gap、padding 和对齐属性
- 或将父级改为 `layout: "none"`

### 错误 5：文字设置宽高却没有 textGrowth

正确做法：固定宽度或宽高时显式设置 `textGrowth`。

### 错误 6：文字没有 Fill

后果：文字节点存在但不可见。

### 错误 7：把所有内容放进一次 batch_design

后果：

- 难以定位错误
- 节点 ID不易管理
- 失败时整批回滚
- 用户长时间看不到进度

正确做法：按区块分批。

### 错误 8：凭记忆修改旧节点 ID

用户可能已经修改或删除节点。

正确做法：编辑前重新 `batch_get`。

### 错误 9：只看截图，不检查布局

截图看起来正常，节点仍可能溢出。

正确做法：同时使用 `get_screenshot` 和 `snapshot_layout`。

### 错误 10：完成后忘记关闭 placeholder

正确做法：最终批次中明确关闭局部和顶层 placeholder。

---

## 14. 推荐交付检查清单

### 文件

- [ ] 当前 `.pen` 路径正确
- [ ] 没有通过命令行直接修改 `.pen`
- [ ] 图片素材路径稳定
- [ ] 不再使用临时候选图

### 结构

- [ ] document 根节点保持干净
- [ ] 页面和主要区域有容器
- [ ] 图层名称具有语义
- [ ] 复杂美术与文字分层
- [ ] 重复元素结构一致

### 视觉

- [ ] 图片没有错误裁切
- [ ] 文字颜色、字体和字号正确
- [ ] 选中与未选中状态可区分
- [ ] 图层遮挡顺序正确
- [ ] 页面整体比例接近参考

### 验收

- [ ] 局部组件已截图检查
- [ ] 整页已截图检查
- [ ] `snapshot_layout` 无问题
- [ ] 所有 placeholder 已关闭
- [ ] 用户可继续独立修改文字、状态和图片

---

## 15. 本项目中的推荐文件

```text
all.pen
visual-design-to-pencil-workflow.md
pencil-mcp-usage-guide.md
design/
├── final/
└── assets/
    └── p03/
        ├── background/
        ├── characters/
        └── ui/
```

建议：

- `.pen` 放在项目根目录或统一的设计目录。
- 页面最终参考图放在 `design/final/`。
- Pencil 使用的开发素材放在 `design/assets/`。
- 候选图、原始裁图和最终透明组件分目录保存。
- `.pen` 中只引用稳定的最终素材路径。

---

## 结论

正确使用 Pencil 的核心不是“一次把图画出来”，而是：

```text
先读状态与 Schema
→ 再读现有结构
→ 分批创建语义化节点
→ 图片使用 Fill
→ 文字保持可编辑
→ 重复内容合理复用
→ 每个区块及时截图
→ 最后检查布局并关闭 placeholder
```

只要遵守这套顺序，Pencil 设计稿就能同时保持视觉还原、结构清晰和后续可编辑性。
