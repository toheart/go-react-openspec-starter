import { writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';

/**
 * 注入 OpenSpec config.yaml 的项目上下文
 */
export async function injectOpenSpecContext(repoRoot, inputs) {
  const configPath = resolve(repoRoot, 'openspec/config.yaml');

  const content = `schema: spec-driven

context: |
  Project: ${inputs.displayName}
  Module: ${inputs.backendModule}
  Tech stack: Go (Gin + Cobra + Viper + slog), React 18 (TypeScript + Vite)
  Architecture: DDD (domain / application / interfaces / infrastructure)
  API style: RESTful JSON, /api/v1/ prefix
  Conventional commits required
  Backend port: 8080, Frontend dev port: 3000

rules:
  proposal:
    - Include affected DDD layers (domain / application / interfaces)
    - Reference relevant openspec/specs/ for style constraints
    - Include API endpoint changes in a summary table
  tasks:
    - Each task should map to a single DDD layer change
    - Backend tasks must include test requirements
    - Frontend tasks must reference the API contract
`;

  await writeFile(configPath, content, 'utf-8');
}
