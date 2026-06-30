import { cp, rename, access, mkdir } from 'node:fs/promises';
import { resolve, dirname, basename, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import { existsSync } from 'node:fs';

const __dirname = dirname(fileURLToPath(import.meta.url));

const SKIP_PATTERNS = ['node_modules', 'npm-cache', '.tmpbin', 'dist'];

function shouldSkip(src) {
  const parts = src.split(sep);
  return SKIP_PATTERNS.some((p) => parts.includes(p));
}

/**
 * 将内嵌的 templates/ 目录复制到目标路径，
 * 并将 gitignore 重命名为 .gitignore（npm publish 会吞掉 .gitignore）
 */
export async function copyTemplate(targetDir) {
  const templatesDir = resolve(__dirname, '..', 'templates');

  if (existsSync(targetDir)) {
    throw new Error(`目标目录已存在: ${targetDir}`);
  }

  await mkdir(targetDir, { recursive: true });

  await cp(templatesDir, targetDir, {
    recursive: true,
    filter: (src) => !shouldSkip(src),
  });

  const gitignoreSrc = resolve(targetDir, 'gitignore');
  const gitignoreDst = resolve(targetDir, '.gitignore');
  try {
    await access(gitignoreSrc);
    await rename(gitignoreSrc, gitignoreDst);
  } catch {
    // gitignore 不存在则跳过
  }
}
