# Project Agents Guide / 项目代理指南

This repository is a [MoonBit](https://docs.moonbitlang.com) project.  
本仓库是一个 [MoonBit](https://docs.moonbitlang.com) 项目。

## Project Focus / 项目重点

MoonForge Gate is not a generic demo anymore. It is a rule-driven gate for AI coding workflows, centered on:
MoonForge Gate 现在不是宽泛 demo，而是面向 AI coding 工作流的规则驱动门禁，重点包括：

- pre-commit style local checks / 本地 pre-commit 风格检查
- CI or PR diff recheck / CI 或 PR diff 复检
- task-scoped repo governance / 任务边界约束
- fixed acceptance fixtures / 固定验收夹具

## Project Structure / 项目结构

- `src/domain`
  Domain types for rules, tasks, decisions, and serialized results.
  规则、任务、结论和结果序列化的领域类型。

- `src/checkers`
  Core checkers for scope, file type, artifacts, command execution, and content patterns.
  核心检查器，覆盖范围、文件类型、材料、命令执行和内容模式。

- `src/services`
  Command orchestration, acceptance runner, reporting, replay, doctor, and pack.
  命令编排、验收 runner、报告、回放、诊断和打包。

- `src/infra`
  Minimal YAML parsing, file I/O, diff parsing, path utilities, and process execution.
  最小 YAML 解析、文件 I/O、diff 解析、路径工具和进程执行。

- `cmd/main`
  CLI entry.
  CLI 入口。

- `examples/acceptance`
  Fixed acceptance config, React fixture, and `pass/retry/reject` cases.
  固定验收配置、React 夹具和 `pass/retry/reject` 用例。

## MoonBit Conventions / MoonBit 约定

- Keep MoonBit files in block style separated by `///|`.
  MoonBit 文件保持 `///|` 分块风格。

- Prefer small, composable functions and explicit structs.
  优先小函数、可组合逻辑和显式结构体。

- When extending rules, add tests first and keep behavior deterministic.
  扩规则时先补测试，并保持行为可复现。

## Rule-Engine Conventions / 规则引擎约定

- Repository-wide hard rules belong in `.moonforge/repo-rules.yml`.
  仓库级硬规则放在 `.moonforge/repo-rules.yml`。

- Task-scoped boundaries belong in `.moonforge/task-types/*.yml` and `.moonforge/current-task.yml`.
  任务边界放在 `.moonforge/task-types/*.yml` 和 `.moonforge/current-task.yml`。

- JSON artifact required fields belong in `.moonforge/artifact-schemas/*.yml`.
  JSON 材料必填字段放在 `.moonforge/artifact-schemas/*.yml`。

- Internal acceptance scenario config belongs in `examples/acceptance/current.yml`.
  内部验收场景配置放在 `examples/acceptance/current.yml`。

- Do not expose fixture-specific filenames in public commands.
  不要把夹具里的具体文件名直接暴露进公共命令参数。

## Tooling / 工具链

- `moon fmt`
  Format code.
  格式化代码。

- `moon info`
  Refresh generated package interfaces after public API changes.
  在公共接口变化后刷新生成的包接口文件。

- `moon test`
  Run all tests.
  运行全部测试。

- `moon test tests/unit`
  Fast checker/service regression loop.
  快速回归 checker 和 service。

- `moon test tests/integration`
  Verify full `init/task/check/report/pack` flows.
  验证完整 `init/task/check/report/pack` 链路。

- `moon test tests/e2e`
  Verify acceptance docs and `acc` fixture cases.
  验证验收文档和 `acc` 固定用例。

## Contributor Notes / 贡献说明

- Keep acceptance-specific code as a minority of the whole project.
  验收专用代码只占项目少数部分。

- Grow the main codebase through `init`, `task`, `check`, `report`, `replay`, and `pack`.
  主要代码量增长应落在 `init`、`task`、`check`、`report`、`replay`、`pack`。

- When adding a new AI coding rule, document:
  新增 AI coding 规则时要同时写清：

1. where it is configured / 配置在哪里
2. how it is triggered / 怎么触发
3. what result it produces / 产生什么结果
4. how it is tested / 如何测试
