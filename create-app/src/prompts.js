import * as p from '@clack/prompts';
import pc from 'picocolors';
import { basename } from 'node:path';

function toDisplayName(slug) {
  return slug
    .split('-')
    .filter(Boolean)
    .map((s) => s.charAt(0).toUpperCase() + s.slice(1).toLowerCase())
    .join(' ');
}

function toEnvPrefix(slug) {
  return slug.toUpperCase().replace(/-/g, '_');
}

function toSlug(dirName) {
  return dirName.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
}

/**
 * 解析目标目录：优先使用命令行参数，否则交互式询问
 */
export async function resolveTargetDir(cliArg) {
  if (cliArg) return cliArg;

  const dirName = await p.text({
    message: '项目目录名',
    placeholder: 'my-project',
    validate: (v) => {
      if (!v) return '必填';
      if (/[<>:"|?*]/.test(v)) return '包含非法字符';
    },
  });

  if (p.isCancel(dirName)) {
    p.cancel('操作已取消');
    process.exit(0);
  }

  return dirName;
}

export async function collectInputs(projectDirName) {
  const defaultSlug = toSlug(projectDirName);

  const group = await p.group(
    {
      projectSlug: () =>
        p.text({
          message: '项目名称 (slug)',
          initialValue: defaultSlug,
          placeholder: defaultSlug,
          validate: (v) => {
            if (!v) return '必填';
            if (!/^[a-z0-9]+(-[a-z0-9]+)*$/.test(v))
              return '只允许小写字母、数字和连字符 (如 order-center)';
          },
        }),

      moduleBase: () =>
        p.text({
          message: 'Go module 路径',
          placeholder: `github.com/acme/${defaultSlug}`,
          validate: (v) => {
            if (!v) return '必填';
            if (!v.includes('/')) return '需要完整路径 (如 github.com/org/repo)';
          },
        }),

      adapter: () =>
        p.select({
          message: '选择 AI IDE（生成编排文件）',
          options: [
            { value: 'cursor', label: 'Cursor', hint: '.cursor/ + hooks.json + Task tool' },
            { value: 'claude-code', label: 'Claude Code', hint: '.claude/ + CLAUDE.md + Agent tool' },
            { value: 'codex', label: 'Codex', hint: '.codex/ + AGENTS.md + spawn agent' },
            { value: '', label: '跳过', hint: '稍后手动运行 npx ai-pipeline init <adapter>' },
          ],
        }),

      pipelineTemplate: ({ results }) => {
        if (!results.adapter) return Promise.resolve('');
        return p.select({
          message: '选择流水线模板',
          options: [
            {
              value: 'go-react-fullstack',
              label: 'Go+React 全栈',
              hint: 'propose → test-design → implement(BE∥FE) → test → archive',
            },
            {
              value: 'backend-only',
              label: '纯后端',
              hint: 'propose → implement → test → archive',
            },
            {
              value: 'hotfix',
              label: '热修复',
              hint: 'implement → test → archive（跳过 propose）',
            },
          ],
        });
      },
    },
    {
      onCancel: () => {
        p.cancel('操作已取消');
        process.exit(0);
      },
    }
  );

  const projectSlug = group.projectSlug;
  const moduleBase = group.moduleBase;
  const appName = projectSlug;
  const displayName = toDisplayName(projectSlug);
  const frontendPackageName = `${projectSlug}-frontend`;
  const envPrefix = toEnvPrefix(projectSlug);
  const backendModule = `${moduleBase}/backend`;
  const shortDescription = `${displayName} backend service`;

  p.note(
    [
      `${pc.cyan('App Name')}:         ${appName}`,
      `${pc.cyan('Display Name')}:     ${displayName}`,
      `${pc.cyan('Frontend Pkg')}:     ${frontendPackageName}`,
      `${pc.cyan('Env Prefix')}:       ${envPrefix}`,
      `${pc.cyan('Backend Module')}:   ${backendModule}`,
    ].join('\n'),
    '自动推导配置'
  );

  const confirmed = await p.confirm({
    message: '确认以上配置？',
    initialValue: true,
  });

  if (p.isCancel(confirmed) || !confirmed) {
    p.cancel('操作已取消');
    process.exit(0);
  }

  return {
    projectSlug,
    moduleBase,
    appName,
    displayName,
    frontendPackageName,
    envPrefix,
    backendModule,
    shortDescription,
    adapter: group.adapter,
    pipelineTemplate: group.pipelineTemplate,
    skipGoModTidy: false,
  };
}
