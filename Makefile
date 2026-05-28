.PHONY: init dev dev-backend dev-frontend check clean pipeline-serve pipeline-status

init:
	@cd create-app && npm install --silent && node bin/create.js

dev:
	@echo "Starting backend (:8080) and frontend (:3000)..."
	@$(MAKE) -j2 dev-backend dev-frontend

dev-backend:
	@cd backend && make run

dev-frontend:
	@cd frontend && npm run dev

check:
	@cd backend && make check
	@cd frontend && npm run lint && npm run build

pipeline-serve:
	@npx ai-pipeline serve

pipeline-status:
	@npx ai-pipeline status

clean:
	@rm -rf backend/bin frontend/dist
