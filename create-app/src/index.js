import * as p from '@clack/prompts';
import pc from 'picocolors';
import { basename, resolve } from 'node:path';
import { resolveTargetDir, collectInputs } from './prompts.js';
import { copyTemplate } from './copy.js';
import { replaceMetadata } from './metadata.js';
import { injectOpenSpecContext } from './openspec.js';
import { initPipeline } from './pipeline.js';

export async function main(cliTargetDir) {
  p.intro(pc.bgCyan(pc.black(' create-go-react-app ')));

  // Step 0: 确定目标目录
  const rawDir = await resolveTargetDir(cliTargetDir);
  const targetDir = resolve(process.cwd(), rawDir);
  const projectDirName = basename(targetDir);

  const inputs = await collectInputs(projectDirName);

  const s = p.spinner();

  // Step 1: 复制模板
  s.start(`创建项目目录 ${projectDirName}...`);
  await copyTemplate(targetDir);
  s.stop(`项目目录创建完成: ${projectDirName}`);

  // Step 2: 替换项目元数据
  s.start('替换项目元数据...');
  const updatedFiles = await replaceMetadata(targetDir, inputs);
  s.stop(`元数据替换完成 (${updatedFiles.length} 个文件更新)`);

  // Step 3: 注入 OpenSpec 项目上下文
  s.start('注入 OpenSpec 项目上下文...');
  await injectOpenSpecContext(targetDir, inputs);
  s.stop('OpenSpec 配置已更新');

  // Step 4: README 模板变量替换
  await replaceReadmePlaceholders(targetDir, inputs);

  // Step 5: go mod tidy
  if (!inputs.skipGoModTidy) {
    s.start('运行 go mod tidy...');
    try {
      const { execSync } = await import('node:child_process');
      execSync('go mod tidy', { cwd: resolve(targetDir, 'backend'), stdio: 'pipe' });
      s.stop('go mod tidy 完成');
    } catch {
      s.stop(pc.yellow('go mod tidy 失败（可稍后手动运行）'));
    }
  }

  // Step 6: ai-pipeline init
  if (inputs.adapter) {
    s.start(`初始化 AI Pipeline (${inputs.adapter})...`);
    const ok = await initPipeline(targetDir, inputs.adapter, inputs.pipelineTemplate);
    if (ok) {
      s.stop(`AI Pipeline 编排文件已生成 (${inputs.adapter})`);
    } else {
      s.stop(pc.yellow('ai-pipeline 初始化跳过（可稍后手动运行）'));
    }
  }

  // Step 7: git init
  s.start('初始化 Git 仓库...');
  try {
    const { execSync } = await import('node:child_process');
    execSync('git init', { cwd: targetDir, stdio: 'pipe' });
    execSync('git add -A', { cwd: targetDir, stdio: 'pipe' });
    execSync('git commit -m "chore: init from create-go-react-app"', {
      cwd: targetDir,
      stdio: 'pipe',
    });
    s.stop('Git 仓库初始化完成');
  } catch {
    s.stop(pc.yellow('Git 初始化跳过（可稍后手动运行）'));
  }

  // 摘要
  p.note(
    [
      `${pc.cyan('项目目录')}:         ${targetDir}`,
      `${pc.cyan('项目名称')}:         ${inputs.projectSlug}`,
      `${pc.cyan('Go Module')}:        ${inputs.backendModule}`,
      `${pc.cyan('App Name')}:         ${inputs.appName}`,
      `${pc.cyan('Display Name')}:     ${inputs.displayName}`,
      `${pc.cyan('Frontend Pkg')}:     ${inputs.frontendPackageName}`,
      `${pc.cyan('Env Prefix')}:       ${inputs.envPrefix}`,
      `${pc.cyan('AI IDE')}:           ${inputs.adapter || '未选择'}`,
      `${pc.cyan('Pipeline 模板')}:    ${inputs.pipelineTemplate || '未选择'}`,
      '',
      `${pc.dim('更新文件:')}`,
      ...updatedFiles.map((f) => `  ${pc.green('✓')} ${f}`),
    ].join('\n'),
    '初始化摘要'
  );

  p.outro(pc.green('项目初始化完成！'));

  console.log('');
  console.log(pc.bold('下一步'));
  console.log('');
  console.log(`  ${pc.cyan(`cd ${projectDirName}`)}`);
  console.log(`  ${pc.cyan('make dev')}              启动前后端开发服务器`);
  console.log(`  ${pc.cyan('make check')}            运行 lint + test + build`);
  if (inputs.adapter) {
    console.log(`  ${pc.cyan('make pipeline-serve')}   启动 Pipeline Dashboard`);
  }
  console.log('');
}

async function replaceReadmePlaceholders(targetDir, inputs) {
  const { readFile, writeFile } = await import('node:fs/promises');
  const readmePath = resolve(targetDir, 'README.md');
  try {
    let content = await readFile(readmePath, 'utf-8');
    content = content.replace(/\{\{DISPLAY_NAME\}\}/g, inputs.displayName);
    await writeFile(readmePath, content, 'utf-8');
  } catch {
    // README 不存在则跳过
  }
}
