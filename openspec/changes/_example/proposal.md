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
