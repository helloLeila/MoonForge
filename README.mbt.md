# MoonForge Gate / 月之锻造

MoonForge Gate is a MoonBit CLI for AI coding governance before code is committed or merged.  
MoonForge Gate 是一个用 MoonBit 编写的 AI coding 准入门禁 CLI，用于在提交前和线上复检前拦截问题改动。

## Install / 安装

Standalone installer:
独立安装脚本：

```bash
curl -fsSL https://raw.githubusercontent.com/helloLeila/MoonForge/main/scripts/install.sh | bash
```

npm distribution entry:
npm 分发入口：

```bash
npm i -g @helloleila/moonforge
moonforge --help
```

The npm package is only a distribution entry. The real checker is still the standalone `moonforge` binary downloaded from GitHub Releases.
npm 包只是分发入口，真正执行检查的仍然是从 GitHub Releases 下载的独立 `moonforge` 二进制。

## Release Automation / 自动发版

Maintainers only:
仅维护者使用：

1. Add a repository secret named `NPM_TOKEN`.
2. Push a tag such as `v0.1.0`, or run the `MoonForge Release` workflow manually with `release_tag`.
3. GitHub Actions will build release assets first, then publish `npm/cli` to npm.

1. 在仓库里添加一个名为 `NPM_TOKEN` 的 Actions Secret。
2. 推送 `v0.1.0` 这类 tag，或者在 GitHub Actions 页面手动运行 `MoonForge Release`，并填写 `release_tag`。
3. GitHub 会先构建 Release 二进制，再把 `npm/cli` 自动发布到 npm。

## What It Does / 它做什么

- `moonforge init`
  Create `.moonforge/` repo rules, task templates, artifact schemas, and a blank current task.
  Also scaffold a `pre-commit` hook that locates the `moonforge` binary and calls `moonforge check`.
  生成 `.moonforge/` 规则目录、任务模板、材料 schema 和空白当前任务，同时写入一个会定位 `moonforge` 可执行文件并调用 `moonforge check` 的 `pre-commit` hook 脚手架。

- `moonforge task`
  Narrow the current change scope into explicit target paths and task type.
  将本次任务收敛到明确的目标路径和任务类型。

- `moonforge check`
  Evaluate a local staged-style diff or CI diff against path, extension, artifact, command, generated-file, and content-pattern rules.
  对本地 staged 风格 diff 或 CI diff 执行路径、后缀、材料、命令、生成物和内容模式检查。

- `moonforge report`
  Read the latest gate summary.
  读取最近一次门禁摘要。

- `moonforge replay`
  Replay a historical run from snapshots.
  从快照重放历史运行。

- `moonforge doctor`
  Diagnose onboarding and config health.
  诊断仓库接入状态和配置健康度。

- `moonforge pack`
  Export the latest run outputs together with the built-in acceptance bundle.
  导出最近一次运行结果以及内置最小验收包。

- `moonforge acc pass|retry|reject`
  Run the fixed internal acceptance fixture for demo/regression only.
  运行固定内部验收夹具，仅用于演示和回归。

## Main Use Cases / 主要使用场景

Local pre-commit:
本地提交前：

1. `moonforge init`
2. `git add`
3. `moonforge task feature-change`
4. `moonforge check`

PR or CI recheck:
线上 PR / CI 复检：

1. Reuse the same `.moonforge` config.
2. Run `moonforge check`. The CLI auto-detects local, CI, and PR environments by default.
3. Read `gate-result.json`, `gate-report.md`, and `run-context.json`.

## Repo Config / 仓库配置

- `.moonforge/repo-rules.yml`
  Repo-wide hard rules such as protected paths, blocked extensions, generated artifacts, and content blocklists.
  仓库级硬规则，例如保护路径、禁止后缀、生成物目录和内容黑名单。

- `.moonforge/task-types/*.yml`
  Task-type templates such as allowed paths, required artifacts, required commands, and max changed files.
  任务模板，定义允许路径、必需材料、必需命令和改动文件上限。

- `.moonforge/current-task.yml`
  The active task boundary for the current coding session.
  当前编码任务的活动边界。

- `.git/hooks/pre-commit`
  A generated hook scaffold that locates `moonforge` from PATH or `./node_modules/.bin`, then runs `moonforge check`.
  一个生成式 hook 脚手架，会先从 PATH 或 `./node_modules/.bin` 中定位 `moonforge`，再执行 `moonforge check`。

- `.moonforge/artifact-schemas/*.yml`
  Required JSON fields for artifacts such as `preview-report.json` or `review-report.json`.
  材料文件的必填 JSON 字段，例如 `preview-report.json`、`review-report.json`。

## First-Phase Rule Scenarios / 第一阶段规则场景

The current acceptance scope focuses on common AI agent coding failures:
当前验收范围聚焦研发中常见的 AI agent coding 问题：

- forbidden extensions / 非法后缀
- out-of-scope files / 越权文件
- protected paths / 受保护路径
- too many changed files / 改动文件数超限
- missing preview artifact / 缺少预览材料
- required commands failed / 必需命令失败
- generated artifacts committed / 误提交生成产物
- debug residue such as `console.log` / 调试残留如 `console.log`

See [docs/acceptance/matrix.md](/Users/leila/Documents/Playground%203/moonforge_gate/.worktrees/moonforge-core-impl/docs/acceptance/matrix.md) for the full 10-scenario matrix.

## Acceptance Fixture / 验收方式

- `examples/acceptance/current.yml`
  Fixed acceptance scenario config.
  固定验收场景配置。

- `examples/acceptance/react-homepage-fixture/`
  Minimal React homepage repo used only as the checked fixture.
  仅作为被检查对象的最小 React 首页夹具。

- `examples/acceptance/cases/pass|retry|reject`
  Fixed inputs and expected outputs used by `acc`.
  `acc` 命令使用的固定输入与期望输出。

## Acceptance Pack / 验收包

`moonforge pack` now exports both:
`moonforge pack` 现在会同时导出：

- the latest local, CI, or PR run outputs such as `gate-result.json`
  最近一次本地、CI 或 PR 检查输出，例如 `gate-result.json`
- the built-in acceptance bundle under `acceptance/`
  `acceptance/` 目录下的内置验收包

The exported acceptance bundle includes:
导出的验收包至少包含：

- `acceptance/current.yml`
- `acceptance/.moonforge/repo-rules.yml`
- `acceptance/.moonforge/task-types/homepage-links.yml`
- `acceptance/.moonforge/current-task.yml`
- `acceptance/react-homepage-fixture/`
- `acceptance/cases/pass|retry|reject`
- `acceptance/matrix.md`

## Useful Commands / 常用命令

For end users:
给最终用户：

```bash
moonforge init
git add .
moonforge task feature-change
moonforge check
moonforge report
```

For repository maintainers developing MoonForge itself:
给正在开发 MoonForge 本体的维护者：

```bash
moon build
moon test
moon run cmd/main -- init --repo ./tmp/demo
moon run cmd/main -- task feature-change --repo ./tmp/demo --title "Add filter" --paths "frontend/src/pages/**,frontend/src/components/**"
moon run cmd/main -- validate --repo ./tmp/demo
moon run cmd/main -- check --repo ./tmp/demo --run ./examples/runs/pass
moon run cmd/main -- report --repo ./tmp/demo
moon run cmd/main -- replay --repo ./tmp/demo --run-id run-pass
moon run cmd/main -- doctor --repo ./tmp/demo
moon run cmd/main -- pack --repo ./tmp/demo
moon run cmd/main -- acc pass
moon run cmd/main -- acc retry
moon run cmd/main -- acc reject
```
