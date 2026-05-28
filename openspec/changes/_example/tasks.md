# (示例) 添加用户注册功能 — 任务分解

> 此文件为 OpenSpec tasks 格式示例，初始化后可删除。

## Backend Tasks

### Domain Layer
- [ ] 创建 `internal/domain/user/user.go`（User 实体 + Repository 接口）

### Application Layer
- [ ] 创建 `internal/application/user/service.go`（UserService）
- [ ] 创建 `internal/application/user/service_test.go`（单元测试）

### Infrastructure Layer
- [ ] 创建 `internal/infrastructure/storage/memory/user_repository.go`（内存实现）

### Interface Layer
- [ ] 创建 `internal/interfaces/http/handler/user_handler.go`（RegisterHandler）
- [ ] 在 `server.go` 中注册路由 `POST /api/v1/users/register`

### Wire
- [ ] 更新 `internal/wire/container.go` 注册 UserService

## Frontend Tasks

- [ ] 创建 `src/types/user.ts`（User 类型定义）
- [ ] 创建 `src/services/userApi.ts`（注册 API 调用）
- [ ] 创建 `src/components/RegisterForm.tsx`（注册表单）
- [ ] 在 `App.tsx` 中添加注册页路由

## Ubiquitous Language 更新

- [ ] 将 proposal 中的术语（User, Username, UserRepository, UserService, Register）同步到 `docs/ubiquitous-language.md` 的 User Context 分组
