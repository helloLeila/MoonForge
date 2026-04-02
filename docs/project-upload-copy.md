# Project Upload Copy

这份文案用于 GitHub 仓库介绍、比赛提交页、项目展示页或 README 摘要区。

## 一句话介绍

MoonForge Gate 是一个使用 MoonBit 实现的代码变更准入内核，用于在 AI 辅助开发场景下对补丁范围、风险路径、材料完整性和最终入库结论进行自动判定。

## 风格化标题

- One patch. One scope. One verdict.
- 从 AI 生成代码，到 AI 代码可信入库
- 面向共享仓库的 MoonBit 准入门禁内核
- 不是让模型多写代码，而是让代码更安全地进入仓库

## 短介绍

MoonForge Gate 聚焦 AI 辅助编码之后最关键但常被忽略的一环：代码进入共享仓库前的治理与准入。项目使用 MoonBit 实现统一门禁内核，将任务模板、仓库规则和当前变更集组合为可执行约束，对一次待提交变更输出 `Accept`、`Retryable`、`Reject` 或 `NeedHumanApproval` 结论，并同步生成审计结果与可读报告。

## 中等介绍

MoonForge Gate 是一个基于 MoonBit 的 AI 原生软件工程项目，核心目标不是“让模型生成代码”，而是“让 AI 生成的代码能以安全、可控、可验证、可审计的方式进入共享仓库”。系统围绕仓库规则建模、任务模板约束、补丁范围分析、材料完整性检查和门禁结果输出构建统一执行链路。当前 Demo 已实现 `init`、`task`、`check`、`report` 四个命令，支持功能变更、缺陷修复、接口修改、配置修改和补充测试五类模板，并可稳定演示通过、拒绝、补齐后重试和人工审批四种门禁结果。

## 详细介绍

在 AI 辅助开发场景中，代码生成速度提升非常明显，但共享仓库中的工程风险也随之放大。传统测试、格式化工具和分支保护能回答“代码是否可运行”，却很难直接回答“这次改动是否超出当前任务范围”“是否碰到了高风险目录”“是否补齐了测试报告和审查材料”“是否应当直接放行或转人工审批”。

MoonForge Gate 解决的正是这类准入问题。项目使用 MoonBit 构建代码变更准入内核，以一次待提交的变更任务为最小判定单元，统一读取仓库长期规则、任务模板约束、当前任务目标路径和实际补丁文件，并输出结构化门禁结论。系统可用于本地提交前检查，也可用于持续集成环境中的统一裁决，从而让 AI 辅助编码从“会生成代码”进一步迈向“生成结果能否被可信入库”。

当前项目已具备以下能力：

- 初始化 `.moonforge` 规则目录和五类模板
- 生成当前任务文件 `current-task.yml`
- 对 `patch.diff` 和材料文件执行门禁判定
- 输出 `gate-result.json`、`gate-report.md`、`checked-files.txt`、`events.jsonl`
- 支持 `Accept`、`Retryable`、`Reject`、`NeedHumanApproval` 四种正式结论
- 通过单元测试和集成测试验证关键规则链路

从工程结构上，项目采用 `domain / services / checkers / adapters / infra` 分层设计：`domain` 负责门禁对象建模，`services` 负责编排与装配，`checkers` 负责规则执行，`adapters` 负责运行模式适配，`infra` 负责 YAML、路径匹配与文件系统读写。这种结构适合后续继续扩展更多 checker、真实 CI 适配器、审计回放和可视化报告能力。

## GitHub About 文案

MoonBit-based admission gate for AI-generated code changes. It validates patch scope, protected paths, required artifacts, and review outcomes before code enters a shared repository.

## GitHub 仓库描述

基于 MoonBit 的 AI 代码变更准入内核，面向共享仓库的范围校验、材料校验、风险判定与审计输出。

## 建议 Topics

- `moonbit`
- `ai-coding`
- `code-governance`
- `code-review`
- `repository-gate`
- `devtools`
- `cli`
- `static-analysis`
- `software-engineering`
