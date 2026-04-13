# MoonForge Gate / 月之锻造

MoonForge Gate is a MoonBit CLI for AI coding governance before code is committed or merged.  
MoonForge Gate 是一个用 MoonBit 编写的 AI coding 准入门禁 CLI，用于在提交前和线上复检前拦截问题改动。

## What It Does / 它做什么

- `moonforge init`
  Create `.moonforge/` repo rules, task templates, artifact schemas, and a blank current task.
  生成 `.moonforge/` 规则目录、任务模板、材料 schema 和空白当前任务。

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
  Export the latest minimal acceptance bundle.
  导出最近一次最小验收包。

- `moonforge acc pass|retry|reject`
  Run the fixed internal acceptance fixture for demo/regression only.
  运行固定内部验收夹具，仅用于演示和回归。

## Main Use Cases / 主要使用场景

Local pre-commit:
本地提交前：

1. `moonforge init`
2. `moonforge task`
3. `git add`
4. `moonforge check`

PR or CI recheck:
线上 PR / CI 复检：

1. Reuse the same `.moonforge` config.
2. Run `moonforge check --mode ci`.
3. Read `gate-result.json` and `gate-report.md`.

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

## Useful Commands / 常用命令

```bash
moon build
moon test
moon run cmd/main -- init --repo ./tmp/demo
moon run cmd/main -- task --repo ./tmp/demo --type feature-change --title "Add filter" --paths "frontend/src/pages/**,frontend/src/components/**"
moon run cmd/main -- validate --repo ./tmp/demo
moon run cmd/main -- check --repo ./tmp/demo --run ./examples/runs/pass
moon run cmd/main -- check --repo ./tmp/demo --run ./examples/runs/pass --mode ci
moon run cmd/main -- report --repo ./tmp/demo
moon run cmd/main -- replay --repo ./tmp/demo --run-id run-pass
moon run cmd/main -- doctor --repo ./tmp/demo
moon run cmd/main -- pack --repo ./tmp/demo
moon run cmd/main -- acc pass
moon run cmd/main -- acc retry
moon run cmd/main -- acc reject
```
