import { writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';

/**
 * 注入生成项目的 OpenSpec 上下文。
 */
export async function injectOpenSpecContext(targetDir, inputs) {
  const configPath = resolve(targetDir, 'openspec/config.yaml');

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
    - Include a "Ubiquitous Language" section listing new/changed domain terms with Chinese name, English name, definition, and DDD building block type
  tasks:
    - Each task should map to a single DDD layer change
    - Backend tasks must include test requirements
    - Frontend tasks must reference the API contract
    - After all tasks are completed, update docs/ubiquitous-language.md with the new/changed terms from the proposal
`;

  await writeFile(configPath, content, 'utf-8');
}
