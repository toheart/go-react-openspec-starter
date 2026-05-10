import { execSync } from 'node:child_process';
import { copyFile, mkdir } from 'node:fs/promises';
import { resolve, dirname } from 'node:path';
import { existsSync } from 'node:fs';

/**
 * 调用 ai-pipeline init 并复制流水线模板
 * 返回 true 表示成功
 */
export async function initPipeline(repoRoot, adapter, template) {
  // ── Step 1: 调用 ai-pipeline init ──
  try {
    execSync(`npx ai-pipeline init ${adapter}`, {
      cwd: repoRoot,
      stdio: 'pipe',
      timeout: 30_000,
    });
  } catch {
    return false;
  }

  // ── Step 2: 复制流水线模板到 .pipeline/ ──
  if (template) {
    const srcTemplate = resolve(repoRoot, 'pipelines', `${template}.yaml`);
    if (existsSync(srcTemplate)) {
      const pipelineDir = resolve(repoRoot, '.pipeline');
      await mkdir(pipelineDir, { recursive: true });
      await copyFile(srcTemplate, resolve(pipelineDir, `${template}.yaml`));
    }
  }

  return true;
}
