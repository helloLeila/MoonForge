# MoonForge Pre-commit React 验收版设计

## 文档目的

本文档用于固化 `MoonForge` 一期增强版的设计边界，重点回答三件事：

- `MoonForge` 在真实研发中主要用在什么场景
- 哪些规则场景需要被正式支持，如何触发
- 如何在不让验收逻辑喧宾夺主的前提下，补齐最小验收包

本文档直接服务于后续 `MoonBit` 实现、双语文档改造、验收包整理和 GitHub 线上复检接入。

## 产品定位

`MoonForge` 是一个使用 `MoonBit` 实现的代码准入与治理内核，面向 `AI 辅助编码后、git 提交前以及 PR 复检前` 的规则验证场景。

它不负责：

- 生成代码
- 组织 Agent 工作流
- 替代构建系统、测试框架、Lint、格式化工具
- 成为通用审计平台或审批平台

它只负责一个核心问题：

- 当前这批待提交的代码改动，是否允许进入共享仓库

## 一期边界

一期必须严格收紧，不做泛平台叙事。

### 实现主体

一期代码主体必须落在以下正式命令背后的规则引擎上：

- `init`
- `task`
- `check`
- `report`
- `replay`
- `pack`
- `validate`
- `doctor`

### 验收入口定位

一期允许新增内部验收命令：

- `acc pass`
- `acc retry`
- `acc reject`

该命令仅用于：

- 项目验收
- 固定演示
- 最小回归验证

它不是对外主命令，不作为日常仓库用户的主要入口。

### 代码配比约束

一期目标为将 `MoonForge` 的有效 `MoonBit` 产品代码大幅扩展，其中：

- 正式命令和规则引擎相关代码必须占大头
- `acc`、React fixture、验收包相关代码总量不得超过整体实现的 `1/4`

## 使用方式

一期支持同一套规则在两个入口复用。

### 入口一：本地提交前检查

主要使用方式：

- 开发者修改代码
- 执行 `git add`
- `pre-commit` hook 调用 `moonforge check`
- `MoonForge` 只读取暂存区改动并给出结论

这是一期最重要的使用方式。

### 入口二：GitHub 线上复检

主要使用方式：

- PR 创建后自动复检
- PR 更新后自动复检
- Reviewer 手动重新触发复检
- 开发者通过命令行主动发起 PR 复检

线上复检必须和本地检查复用同一套规则模型，只允许输入来源不同：

- 本地模式读取 `staged diff`
- 线上模式读取 `PR diff`

## 正式结论模型

系统输出三种正式结论：

- `Accept / 允许放行`
- `Retryable / 修复后重试`
- `Reject / 拒绝放行`

一期不把 `NeedHumanApproval` 作为重点实现目标。若后续需要恢复，可在现有结果模型上扩展，但不进入本期主验收。

### 结论落点

- `Accept`
  - 所有规则通过
- `Retryable`
  - 不涉及硬性违规，但存在可修复且应重新执行检查的问题
- `Reject`
  - 命中硬性拦截规则，不允许提交或合并

## 配置模型

一期采用四类配置文件，全部放在 `.moonforge/` 下。

### 仓库级规则

文件：

- `.moonforge/repo-rules.yml`

职责：

- 定义仓库长期红线
- 定义全局禁止模式
- 定义保护路径
- 定义默认限制

建议字段：

- `protected_paths`
- `blocked_extensions`
- `generated_artifact_paths`
- `blocked_file_names`
- `blocked_file_patterns`
- `content_blocklist_patterns`
- `default_allowed_extensions`
- `max_changed_files`
- `path_groups`

### 任务模板规则

文件：

- `.moonforge/task-types/*.yml`

职责：

- 定义不同任务类型的默认允许范围
- 定义任务级后缀约束
- 定义任务级文件上限
- 定义必需材料
- 定义必需校验命令

建议字段：

- `task_type`
- `allowed_paths`
- `forbidden_paths`
- `allowed_extensions`
- `required_artifacts`
- `required_commands`
- `max_changed_files`

### 当前任务规则

文件：

- `.moonforge/current-task.yml`

职责：

- 固化一次具体待提交任务的边界

建议字段：

- `task_type`
- `title`
- `target_groups`
- `target_paths`

### 材料结构规则

文件：

- `.moonforge/artifact-schemas/*.yml`

职责：

- 描述材料文件的最小结构要求
- 支撑 JSON 结构检查

建议字段：

- `artifact_name`
- `required_fields`
- `optional_fields`
- `allowed_values`

## 规则触发链路

以本地 `pre-commit` 为例，统一触发链路如下：

1. 开发者执行 `moonforge init`
2. 仓库生成 `.moonforge/` 基础配置
3. 开发者执行 `moonforge task`
4. 当前任务文件写入 `.moonforge/current-task.yml`
5. 开发者修改代码并执行 `git add`
6. `pre-commit` hook 调用 `moonforge check`
7. `check` 读取：
   - 仓库规则
   - 任务模板
   - 当前任务
   - 暂存区 diff
   - 暂存区文件列表
   - 需要校验的材料文件
8. `check` 依次执行规则检查
9. 输出正式结论、报告和运行记录
10. 结论为 `Accept` 时放行提交，否则拦截

GitHub 线上复检与上面完全一致，只是第 7 步的输入从 `staged diff` 改为 `PR diff`。

## 十个正式规则场景

一期至少固化以下十个规则场景。这些场景不是业务页面场景，而是研发侧 AI coding 里高频出现的问题。

### 1. 单文件合规通过

- 结论：`Accept`
- 触发：
  - 暂存区只包含 1 个允许文件
  - 文件后缀合法
  - 未命中保护路径
  - 未命中内容黑名单
  - 必需命令通过
  - 材料齐全
- 配置来源：
  - `repo-rules.yml`
  - `task-types/*.yml`
  - `current-task.yml`

### 2. 双文件合规通过

- 结论：`Accept`
- 触发：
  - 暂存区刚好包含 2 个允许文件
  - 文件数未超上限
  - 其他规则全部通过
- 配置来源：
  - `repo-rules.yml`
  - `task-types/*.yml`
  - `current-task.yml`

### 3. 非法后缀拦截

- 结论：`Reject`
- 触发：
  - staged file 中出现当前任务不允许的后缀
  - 典型如 `.png`、`.svg`、`.md`、`.snap`、`.lock`、`.map`
- 配置来源：
  - `task-types/*.yml` 中的 `allowed_extensions`
  - `repo-rules.yml` 中的全局后缀限制

### 4. 越权文件拦截

- 结论：`Reject`
- 触发：
  - staged file 不属于本次任务允许范围
  - 例如任务只允许改组件文件，但实际暂存了工具文件或其他目录
- 配置来源：
  - `current-task.yml` 中的 `target_paths`
  - `task-types/*.yml` 中的 `allowed_paths`

### 5. 受保护路径拦截

- 结论：`Reject`
- 触发：
  - staged file 命中保护目录或关键文件
  - 例如 `src/core/**`、`src/auth/**`、`package.json`
- 配置来源：
  - `repo-rules.yml` 中的 `protected_paths`

### 6. 改动文件数超限

- 结论：`Reject`
- 触发：
  - staged file 数量大于当前任务允许上限
  - 典型于 AI 一次性修改过多文件
- 配置来源：
  - `task-types/*.yml` 中的 `max_changed_files`
  - 或 `repo-rules.yml` 中默认上限

### 7. 缺少预览材料需重试

- 结论：`Retryable`
- 触发：
  - 路径、后缀、文件数都合法
  - 但缺 `preview-report.json`
- 配置来源：
  - `task-types/*.yml` 中的 `required_artifacts`
  - `artifact-schemas/preview-report.yml`

### 8. 必需校验命令未通过需重试

- 结论：`Retryable`
- 触发：
  - 当前任务配置要求必须通过某些命令
  - 例如 `npm run build`、`npm run test`
  - `check` 执行命令后任意一条失败
- 配置来源：
  - `task-types/*.yml` 中的 `required_commands`

### 9. 误提交生成产物或缓存文件拦截

- 结论：`Reject`
- 触发：
  - staged file 命中生成物或缓存黑名单
  - 典型如 `dist/**`、`build/**`、`coverage/**`、`.cache/**`、`.next/**`、`.DS_Store`
- 配置来源：
  - `repo-rules.yml` 中的 `generated_artifact_paths`
  - `blocked_file_names`
  - `blocked_file_patterns`

### 10. 调试残留拦截

- 结论：`Reject`
- 触发：
  - staged file 内容命中明显的调试或临时标记
  - 一期建议先收紧为：
    - `console.log`
    - `debugger`
    - `printf`
    - `println`
    - `TODO`
    - `FIXME`
- 配置来源：
  - `repo-rules.yml` 中的 `content_blocklist_patterns`

## 核心命令增强方向

为了让 `15000` 行有效 `MoonBit` 代码主要长在正式产品能力上，一期应把代码增长集中在以下命令背后的模块化能力。

### init

重点增强：

- 生成更完整的 `.moonforge/` 目录结构
- 生成默认 `artifact-schemas/`
- 生成本地 hook 样板
- 生成 GitHub 线上复检样板
- 生成双语注释更完整的默认规则文件

### task

重点增强：

- 从模板生成当前任务约束
- 路径组展开
- 模板字段校验
- 任务边界提示
- 自动补全任务级默认配置

### check

重点增强：

- staged diff 读取
- PR diff 读取
- 规则触发器拆分
- 文件级与内容级检查分层
- 材料检查
- 命令执行检查
- 结果归并
- 双语摘要输出

### report

重点增强：

- 双语终端摘要
- 可读性更强的规则命中说明
- 修复建议生成
- 最近一次与指定一次运行的区分展示

### replay

重点增强：

- 运行快照读取
- 指定运行回放
- 指定规则命中回放
- 基于固定输入重放结论

### pack

重点增强：

- 导出最小验收包
- 导出固定输入
- 导出标准输出
- 导出运行摘要
- 导出回放所需最小文件集

### validate

重点增强：

- 规则文件语义检查
- 路径模式检查
- 材料结构规则检查
- 模板与仓库规则一致性检查

### doctor

重点增强：

- 仓库接入状态诊断
- 缺失 hook 诊断
- 缺失规则文件诊断
- GitHub 模式接入提示

## GitHub 线上复检

一期应明确支持线上复检，但规则不分叉。

### 接入方式

建议支持两种方式：

- GitHub Actions 自动触发
- 命令行手动复检触发

### 线上模式输入

线上模式至少需要支持读取：

- base 分支
- head 分支
- PR diff
- 仓库内 `.moonforge/` 配置

### 线上模式输出

至少包括：

- 终端摘要
- `gate-result.json`
- `gate-report.md`
- `checked-files.txt`
- 运行事件记录

## 最小验收包

一期最小验收包用于向评审证明：

- 可构建
- 可运行
- 可复现
- 规则场景真实且具体

### 验收包边界

验收包只占产品整体的一小部分，不应成为实现主体。

### 验收包内容

建议至少包含：

- 固定 React fixture 仓库
- 固定 `.moonforge` 规则配置
- 固定 staged diff 或 patch 输入
- 三类固定验收命令入口
- 固定预期输出

### 验收命令

为了减轻记忆负担，一期内部验收命令建议为：

- `moonforge acc pass`
- `moonforge acc retry`
- `moonforge acc reject`

这里：

- `pass` 对应通过场景
- `retry` 对应可修复后重试场景
- `reject` 对应硬拒绝场景

业务细节、具体规则和具体 fixture 路径全部藏在配置文件里，而不是暴露在命令参数上。

## 双语文档要求

一期必须将以下文档补为中英双语：

- `README`
- `AGENTS.md`

同时建议统一以下输出中的中英层次：

- CLI 帮助文本
- `report` 摘要
- `doctor` 输出
- `pack` 导出说明

原则是：

- 机器读取优先保留英文编码
- 人读说明以中文为主，同时提供英文对应表述

## 测试策略

测试必须围绕规则验证，而不是围绕抽象功能名。

### 单元测试

覆盖：

- 路径匹配
- 后缀匹配
- 文件数上限
- 材料存在性
- 材料结构检查
- 内容黑名单命中
- 生成物路径命中
- 必需命令结果解析

### 集成测试

覆盖：

- `init`
- `task`
- `check`
- `report`
- `replay`
- `pack`
- `validate`
- `doctor`

重点验证正式命令是否正确装配规则。

### 验收测试

覆盖：

- `acc pass`
- `acc retry`
- `acc reject`

重点验证最小验收入口是否可复现。

## 实现节奏建议

一期实现建议按以下顺序推进：

1. 补齐规则配置模型
2. 细化 `init` 与 `task`
3. 重构 `check` 为多触发器结构
4. 补齐 `report / replay / pack / validate / doctor`
5. 新增 `acc`
6. 整理 React fixture 与最小验收包
7. 补齐 README 与 AGENTS 双语文档

## 非目标

以下方向不进入一期：

- 通用 AI Agent 编排平台
- 复杂审批流平台
- 多仓库集中控制台
- 智能语义级代码审查
- 复杂 UI 后台
- 不受约束的场景泛化

## 一期最终标准

一期完成的判断标准不是“功能名变多”，而是以下问题能被稳定回答：

- AI 生成了不允许的后缀，能否拦住
- AI 改了不该改的文件，能否拦住
- AI 改了保护路径，能否拦住
- AI 一次改太多文件，能否拦住
- AI 没通过必须的校验命令，能否要求修复后重试
- AI 把缓存和产物也提交了，能否拦住
- AI 留下了明显调试残留，能否拦住
- 同一套规则是否既能本地 pre-commit 使用，也能在 GitHub 线上复检使用

只有这些问题被稳定回答，`MoonForge` 才算真正落在项目书要求的“代码变更治理与准入内核”上。
