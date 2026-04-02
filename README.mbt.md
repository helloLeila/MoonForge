# MoonForge Gate

> One patch. One scope. One verdict.

MoonForge Gate 是一个使用 MoonBit 实现的代码变更准入内核，用于在 AI 辅助开发场景下，对代码进入共享仓库前的变更进行范围校验、材料校验、风险判定和审计留痕。

它关注的不是“模型会不会写代码”，而是“这次改动应不应该进入仓库”。项目通过任务模板、仓库规则和当前变更集的组合判定，为一次待提交补丁输出正式结论：

- `Accept`
- `Retryable`
- `Reject`
- `NeedHumanApproval`

## At a Glance

- MoonBit 实现的工程化 CLI，而不是脚本拼装 Demo
- 面向共享仓库准入，不是单纯 lint 或 test wrapper
- 支持任务模板、路径边界、材料校验和审计输出
- 同一套判定逻辑可复用于本地检查和 CI 检查
- 当前基础版本已经具备可构建、可测试、可演示能力

## Why

在真实研发流程里，AI 生成代码后最难的不是生成本身，而是治理：

- 本次改动是否超出了当前任务边界
- 是否触碰了安全目录、受保护模块或高风险服务
- 测试报告、接口说明、审查结论是否齐全
- 本地检查与 CI 检查能否保持一致
- 结果是否可回放、可审计、可解释

MoonForge Gate 的目标就是把这些原本依赖经验的约束，变成稳定、可复现、可自动执行的门禁规则。

## Core Capabilities

- `moonforge init`
  初始化 `.moonforge/` 目录、仓库规则和五类任务模板
- `moonforge task`
  基于模板生成当前任务文件 `.moonforge/current-task.yml`
- `moonforge check`
  对当前补丁和材料执行门禁判定
- `moonforge report`
  读取最近一次结果并输出可读报告

当前内置模板覆盖：

- `feature-change`
- `bug-fix`
- `api-change`
- `config-change`
- `test-addition`

当前已支持的检查维度：

- 目标路径是否越界
- 是否触碰受保护目录
- 是否命中人工审批目录
- 文件后缀是否符合模板要求
- 改动文件数是否超过上限
- 必要材料是否缺失

## Run Flow

一次标准运行流程可以概括为：

1. `init`
   初始化 `.moonforge` 配置目录和默认模板
2. `task`
   选择模板并生成当前任务边界
3. `check`
   读取补丁、材料和任务约束并做门禁判定
4. `report`
   输出最近一次可读报告，便于评审和复盘

## Architecture

项目目录遵循分层结构：

- `src/domain`
  核心对象定义，如任务、规则、违规项、门禁结果
- `src/services`
  任务装配、规则合并、流程编排、结果落盘
- `src/checkers`
  门禁判定逻辑
- `src/adapters`
  本地与 CI 运行模式相关的路径和输出适配
- `src/infra`
  YAML 读取、路径匹配、文件系统读写等基础设施
- `cmd/main`
  CLI 入口
- `tests/unit`
  规则级单元测试
- `tests/integration`
  流程级集成测试
- `examples`
  示例仓库和固定输入夹具

## Demo Scenarios

当前 Demo 可稳定演示 4 类典型结果：

- 合法变更且材料齐全，输出 `Accept`
- 改动范围合法但材料缺失，输出 `Retryable`
- 触碰受保护目录，输出 `Reject`
- 命中高风险路径但仍在任务范围内，输出 `NeedHumanApproval`

输出结果会写入：

- `.moonforge/out/local/latest/gate-result.json`
- `.moonforge/out/local/latest/gate-report.md`
- `.moonforge/out/local/latest/checked-files.txt`
- `.moonforge/out/local/latest/events.jsonl`
- `.moonforge/runs/<run-id>/task.snapshot.json`

## Quick Start

```bash
moon build
moon test

moon run cmd/main -- init --repo ./tmp/demo
moon run cmd/main -- task \
  --repo ./tmp/demo \
  --type feature-change \
  --title "Add department filter" \
  --paths "frontend/src/pages/**,frontend/src/components/**,backend/src/main/java/com/acme/user/service/**"
moon run cmd/main -- check --repo ./tmp/demo --run ./examples/runs/pass
moon run cmd/main -- report --repo ./tmp/demo
```

也可以直接运行完整演示：

```bash
./scripts/run_demo.sh
```

## Test Status

当前测试覆盖包含：

- 路径 glob 匹配
- 最小 YAML 解析
- git patch 文件抽取
- Accept / Retryable / Reject / NeedHumanApproval 四类流程判定

本地验证命令：

```bash
moon test
```

## Current Status

这是一个可构建、可测试、可演示的基础版本，已经完成了门禁主链路和最小审计输出。后续可继续扩展：

- 本地 git 暂存区 diff 适配器
- CI 分支差异适配器
- 更细粒度的 checker 策略拆分
- e2e 回归测试
- HTML 报告与审计回放能力

## Project Positioning

MoonForge Gate 适合被理解为：

- AI 原生软件工程中的代码变更治理组件

## License

Apache-2.0
