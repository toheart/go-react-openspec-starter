import { readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { glob } from './utils.js';

/**
 * 在目标目录中替换项目元数据。
 * 返回被修改的文件列表（相对路径）。
 */
export async function replaceMetadata(targetDir, inputs) {
  const {
    appName,
    displayName,
    frontendPackageName,
    envPrefix,
    backendModule,
    shortDescription,
  } = inputs;

  const updatedFiles = [];

  async function updateFile(relativePath, replacer) {
    const absPath = resolve(targetDir, relativePath);
    let content;
    try {
      content = await readFile(absPath, 'utf-8');
    } catch {
      return;
    }
    const updated = replacer(content);
    if (updated !== content) {
      await writeFile(absPath, updated, 'utf-8');
      updatedFiles.push(relativePath);
    }
  }

  // 读取模板当前 module，再替换所有 Go import 路径。
  const goModContent = await readFile(resolve(targetDir, 'backend/go.mod'), 'utf-8');
  const currentModuleMatch = goModContent.match(/^module\s+(.+)$/m);
  const currentBackendModule = currentModuleMatch ? currentModuleMatch[1].trim() : '';

  if (currentBackendModule && currentBackendModule !== backendModule) {
    const goFiles = await glob(resolve(targetDir, 'backend'), ['.go', '.mod']);
    for (const file of goFiles) {
      const relativePath = file.replace(targetDir + '/', '').replace(targetDir + '\\', '');
      await updateFile(relativePath, (content) =>
        content.replaceAll(currentBackendModule, backendModule)
      );
    }
  }

  // backend/go.mod
  await updateFile('backend/go.mod', (c) =>
    c.replace(/^module\s+.+$/m, `module ${backendModule}`)
  );

  // backend/Makefile
  await updateFile('backend/Makefile', (c) =>
    c.replace(/^APP_NAME := .+$/m, `APP_NAME := ${appName}`)
  );

  // backend/cmd/main.go
  await updateFile('backend/cmd/main.go', (c) =>
    c
      .replace(/(Use:\s+")([^"]+)(")/, `$1${appName}$3`)
      .replace(/(Short:\s+")([^"]+)(")/, `$1${shortDescription}$3`)
  );

  // backend/conf/conf.go
  await updateFile('backend/conf/conf.go', (c) =>
    c
      .replace(/(v\.SetEnvPrefix\(")([^"]+)("\))/, `$1${envPrefix}$3`)
      .replace(/(v\.SetDefault\("app\.name", ")([^"]+)("\))/, `$1${appName}$3`)
  );

  // backend/etc/config.*.yaml
  await updateFile('backend/etc/config.dev.yaml', (c) =>
    c.replace(/^(\s+name:) .+$/m, `$1 ${appName}`)
  );
  await updateFile('backend/etc/config.prod.yaml', (c) =>
    c.replace(/^(\s+name:) .+$/m, `$1 ${appName}`)
  );

  // frontend/package.json
  await updateFile('frontend/package.json', (c) =>
    c.replace(/("name":\s+")([^"]+)(")/, `$1${frontendPackageName}$3`)
  );

  // frontend/package-lock.json 只替换顶层两个 name 字段，避免误改依赖包名。
  await updateFile('frontend/package-lock.json', (c) => {
    let count = 0;
    return c.replace(/("name":\s+")([^"]+)(")/g, (match, p1, _p2, p3) => {
      if (count < 2) {
        count++;
        return `${p1}${frontendPackageName}${p3}`;
      }
      return match;
    });
  });

  // frontend/index.html
  await updateFile('frontend/index.html', (c) =>
    c.replace(/(<title>)(.*?)(<\/title>)/, `$1${displayName}$3`)
  );

  return [...new Set(updatedFiles)];
}
