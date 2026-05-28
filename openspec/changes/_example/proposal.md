# (示例) 添加用户注册功能

> 此目录为 OpenSpec 变更格式示例，初始化后可删除。

## Why

当前系统没有用户管理功能，无法区分不同用户的数据。需要添加基础的用户注册能力作为后续权限、个性化功能的基础。

## What

- 新增 `User` 领域实体（domain 层）
- 新增 `UserService` 应用服务（application 层）
- 新增 `POST /api/v1/users/register` 接口（interfaces 层）
- 前端新增注册表单页面

## Non-goals

- 不包含登录/JWT 认证（后续提案）
- 不包含邮箱验证

## API Changes

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/users/register` | 用户注册 |

## Ubiquitous Language

本次变更引入的领域术语：

| 中文 | English (代码命名) | 定义 | DDD 构件类型 |
|------|-------------------|------|-------------|
| 用户 | User | 系统中可注册和登录的参与者，拥有唯一的邮箱和用户名 | Entity |
| 用户名 | Username | 用户的唯一标识名称，由字母和数字组成 | Value Object |
| 用户仓储 | UserRepository | 用户实体的持久化接口，定义在 domain 层 | Repository |
| 用户服务 | UserService | 处理用户注册等业务逻辑的应用服务 | Application Service |
| 注册 | Register | 创建新用户账号的业务动作 | Command |

## Ubiquitous Language

> 本次变更涉及的新增/变更领域术语，完成后需同步更新 `docs/ubiquitous-language.md`。

| 中文 | English (代码命名) | 定义 | DDD 构件类型 |
|------|-------------------|------|-------------|
| 用户 | User | 系统中的注册用户，持有邮箱和密码凭证 | Entity |
| 用户仓储 | UserRepository | 用户实体的持久化接口，定义在 domain 层 | Repository |
| 用户服务 | UserService | 处理用户注册等业务逻辑的应用服务 | Application Service |
| 邮箱 | Email | 用户的登录邮箱地址，全局唯一 | Value Object |
