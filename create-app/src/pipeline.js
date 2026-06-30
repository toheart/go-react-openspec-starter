import { execSync } from 'node:child_process';
import { copyFile, mkdir } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));

/**
 * 调用 ai-pipeline init，并把选中的流水线模板复制到生成项目的 .pipeline/。
 * 流水线模板是 CLI 包内部资源，不复制为生成项目根目录的 pipelines/。
 */
export async function initPipeline(targetDir, adapter, template) {
  // Step 1: 调用 ai-pipeline init
  try {
    execSync(`npx ai-pipeline init ${adapter}`, {
      cwd: targetDir,
      stdio: 'pipe',
      timeout: 30_000,
    });
  } catch {
    return false;
  }

  // Step 2: 复制选中的流水线模板到 .pipeline/
  if (template) {
    const srcTemplate = resolve(__dirname, '..', 'pipeline-templates', `${template}.yaml`);
    if (existsSync(srcTemplate)) {
      const pipelineDir = resolve(targetDir, '.pipeline');
      await mkdir(pipelineDir, { recursive: true });
      await copyFile(srcTemplate, resolve(pipelineDir, `${template}.yaml`));
    }
  }

  return true;
}
