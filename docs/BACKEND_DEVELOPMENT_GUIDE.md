# CABAKURA 后台开发文档

## 1. 开发原则

LikeAdmin 只作为后台底座，不使用它自带的页面创建/代码生成器。

本项目后台按业务流程手写：

- 页面按业务场景设计，不做数据库字段映射页。
- 接口按业务动作设计，不做通用 `add/edit/delete` 套壳。
- 状态流转、金额计算、审核、权限范围、审计日志放在后端业务层。
- 前端只负责展示、输入和触发动作，不在页面里拼业务规则。

可复用 LikeAdmin：

- 登录态、管理员、角色、菜单、按钮权限。
- 后台布局、路由加载、请求封装。
- Element Plus、分页、上传、素材选择、导出、富文本、字典组件。
- 文件存储配置、短信配置、支付配置的基础能力。

不可复用 LikeAdmin：

- 代码生成器生成业务页面。
- 代码生成器生成的通用 CRUD 接口。
- 直接把数据库字段映射成后台表单。

## 2. 目录约定

后端：

```text
server/app/adminapi/controller/cabakura/
server/app/adminapi/logic/cabakura/
server/app/adminapi/lists/cabakura/
server/app/adminapi/validate/cabakura/

server/app/api/controller/cabakura/
server/app/api/logic/cabakura/
server/app/api/lists/cabakura/
server/app/api/validate/cabakura/

server/app/common/model/cabakura/
server/app/common/enum/cabakura/
server/app/common/service/cabakura/
```

前端：

```text
admin/src/api/cabakura/
admin/src/enums/cabakura/
admin/src/views/cabakura/
```

## 3. 后端分层

Controller：

- 只接收请求、调用 Validate、调用 Logic/Service、返回响应。
- 不写业务判断。

Validate：

- 校验参数必填、类型、枚举值、动作所需字段。

Lists：

- 只处理后台列表查询、搜索条件、分页、导出字段。

Logic：

- 组织一个后台动作，例如店铺审核通过、订单确认、退款处理。

Service：

- 可复用业务能力，例如订单状态机、退款试算、数据范围、审计日志。

Model：

- 表模型、关联、搜索器、获取器。

Enum：

- 所有状态、类型、渠道、审核动作都放这里。

## 4. 接口命名

接口按业务动作命名。

示例：

```text
GET  /cabakura.dashboard/summary
GET  /cabakura.shop/lists
GET  /cabakura.shop/detail
POST /cabakura.shop/saveDraft
POST /cabakura.shop/submitReview
POST /cabakura.shop/approve
POST /cabakura.shop/reject
POST /cabakura.shop/requestSupplement
POST /cabakura.shop/suspend

GET  /cabakura.order/lists
GET  /cabakura.order/detail
POST /cabakura.order/confirm
POST /cabakura.order/reject
POST /cabakura.order/checkIn

POST /cabakura.cancel/quote
POST /cabakura.cancel/approve
POST /cabakura.refund/markSuccess
POST /cabakura.refund/markFailed
```

不要为核心业务使用只有数据库含义的接口，例如 `shop/add`、`shop/edit`、`refund/edit`。

## 5. 首批菜单

第一批先开发支撑主链路的菜单：

业务菜单直接作为项目后台一级菜单，不放在单独的 `CABAKURA` 容器下。LikeAdmin 默认业务/演示菜单隐藏，只保留权限管理、系统设置等底层能力。

```text
工作台
会员管理 / 会员列表
会员管理 / 身份认证审核
店铺管理 / 店铺列表
店铺管理 / 店铺审核
店铺管理 / 营业执照管理
店铺管理 / 套餐管理
Cast 管理 / Cast 列表
Cast 管理 / 出勤排班
预约订单 / 订单列表
预约订单 / 取消申请
财务管理 / 支付记录
财务管理 / 退款记录
客服中心 / FAQ 内容
客服中心 / 客服工单
```

系统管理只保留 LikeAdmin 的底层能力，例如权限、管理员、角色、存储、支付、日志。

## 6. 状态机

店铺审核：

```text
draft -> submitted -> reviewing -> approved
draft -> submitted -> reviewing -> rejected
draft -> submitted -> reviewing -> supplement_required -> submitted
approved -> suspended
```

订单：

```text
requesting -> confirmed -> paid -> visited -> completed
requesting -> rejected
confirmed -> cancel_requested -> cancelled -> refund_pending -> refunded
refund_pending -> refund_failed
```

身份认证：

```text
not_started -> phone_verified -> document_pending -> reviewing -> approved
reviewing -> rejected
```

客服工单：

```text
open -> pending_operator -> pending_user -> resolved -> closed
```

## 7. 页面设计约定

列表页：

- 顶部筛选区。
- 中部数据表格。
- 右侧操作按钮。
- 状态用 `el-tag`。
- 详情用抽屉或独立详情页。

审核页：

- 左侧业务资料。
- 右侧审核记录和操作。
- 驳回/补充资料必须填写原因。

订单详情：

- 基本信息、预约信息、金额信息、支付/退款记录、状态时间线分区展示。

客服工单：

- 左侧工单列表。
- 中间消息流。
- 右侧订单/会员摘要。

## 8. 数据安全

- 手机号、证件号、卡号默认脱敏。
- 营业执照、证件图片、收据 PDF 必须鉴权访问。
- 审核、退款、订单状态变更必须写审计日志。
- 店铺管理员的数据范围必须在后端查询层限制。

## 9. 当前开发顺序

1. 搭建 `cabakura` 后端业务骨架。
2. 搭建前端 API 和页面骨架。
3. 先用 Mock/静态服务数据跑通页面和接口形态。
4. 再补数据库表、模型、真实查询。
5. 最后接菜单权限、数据范围和审计日志。
