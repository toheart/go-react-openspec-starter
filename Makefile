.PHONY: dev test publish clean

# 本地开发测试：创建一个临时项目
dev:
	@cd create-app && node bin/create.js ../test-project

# 运行 smoke test
test:
	@cd create-app && node bin/create.js ../.tmpbin/smoke-test

# 发布到 npm
publish:
	@cd create-app && npm publish

# 清理测试产物
clean:
	@rm -rf test-project .tmpbin
