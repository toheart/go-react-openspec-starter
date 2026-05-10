import { readdir, stat } from 'node:fs/promises';
import { resolve, extname } from 'node:path';

/**
 * 递归查找指定扩展名的文件
 */
export async function glob(dir, extensions) {
  const results = [];

  async function walk(currentDir) {
    let entries;
    try {
      entries = await readdir(currentDir, { withFileTypes: true });
    } catch {
      return;
    }
    for (const entry of entries) {
      const fullPath = resolve(currentDir, entry.name);
      if (entry.isDirectory()) {
        await walk(fullPath);
      } else if (extensions.some(ext => entry.name.endsWith(ext))) {
        results.push(fullPath);
      }
    }
  }

  await walk(dir);
  return results;
}
