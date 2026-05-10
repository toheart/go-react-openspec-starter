import * as p from '@clack/prompts';
import pc from 'picocolors';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { collectInputs } from './prompts.js';
import { replaceMetadata } from './metadata.js';
import { injectOpenSpecContext } from './openspec.js';
import { initPipeline } from './pipeline.js';

const __dirname = dirname(fileURLToPath(import.meta.url));

export async function main() {
  p.intro(pc.bgCyan(pc.black(' create-go-react-app ')));

  const inputs = await collectInputs();

  const repoRoot = resolve(process.cwd());

  const s = p.spinner();

  // ── Step 1: 元数据替换 ──
  s.start('替换项目元数据...');
  const updatedFiles = await replaceMetadata(repoRoot, inputs);
  s.stop(`元数据替换完成 (${updatedFiles.length} 个文件更新)`);

  // ── Step 2: OpenSpec context 注入 ──
  s.start('注入 OpenSpec 项目上下文...');
  await injectOpenSpecContext(repoRoot, inputs);
  s.stop('OpenSpec 配置已更新');

  // ── Step 3: go mod tidy ──
  if (!inputs.skipGoModTidy) {
    s.start('运行 go mod tidy...');
    try {
      const { execSync } = await import('node:child_process');
      execSync('go mod tidy', { cwd: resolve(repoRoot, 'backend'), stdio: 'pipe' });
      s.stop('go mod tidy 完成');
    } catch {
      s.stop(pc.yellow('go mod tidy 失败（可稍后手动运行）'));
    }
  }

  // ── Step 4: ai-pipeline init ──
  if (inputs.adapter) {
    s.start(`初始化 AI Pipeline (${inputs.adapter})...`);
    const ok = await initPipeline(repoRoot, inputs.adapter, inputs.pipelineTemplate);
    if (ok) {
      s.stop(`AI Pipeline 编排文件已生成 (${inputs.adapter})`);
    } else {
      s.stop(pc.yellow('ai-pipeline 初始化跳过（可稍后手动运行）'));
    }
  }

  // ── 摘要 ──
  p.note(
    [
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
      ...updatedFiles.map(f => `  ${pc.green('✓')} ${f}`),
    ].join('\n'),
    '初始化摘要'
  );

  p.outro(pc.green('项目初始化完成！'));

  console.log('');
  console.log(pc.bold('下一步:'));
  console.log('');
  console.log(`  ${pc.cyan('make dev')}              启动前后端开发服务器`);
  console.log(`  ${pc.cyan('make check')}            运行 lint + test + build`);
  if (inputs.adapter) {
    console.log(`  ${pc.cyan('make pipeline-serve')}   启动 Pipeline Dashboard`);
  }
  console.log('');
}
