# MoonForge Core 验收版设计方案

## 文档目的

本文档用于固化 `MoonForge Core` 的验收版设计边界，作为后续实现、测试、验收包整理与 GitHub 云端校验接入的统一依据。

设计原则只有一条：

- 严格匹配项目书验收要求，可以多做，但不能少做

## 产品定位

`MoonForge Core` 是一个面向 `AI 辅助编码后、git 提交前` 的代码变更准入与治理内核。

它不负责生成代码，不负责任务拆解，不负责 Agent 编排，也不替代构建、测试、格式化、Lint 或 CI 系统本身。它只负责回答一个问题：

- 这次待提交的代码变更，是否允许进入共享仓库

## 与项目书的严格对齐

本设计必须覆盖项目书中已经明确提出的核心能力：

- 仓库规则建模
- 变更作用域分析
- 交付证据校验
- 门禁判定
- 审计回放
- 本地与持续集成环境执行同一套逻辑

本设计不得偏离为以下方向：

- AI Agent 工作流编排器
- 通用工作流引擎
- 通用静态代码扫描平台
- ESLint、测试框架、构建系统或包管理器替代品
- GitHub App、SaaS 控制台或后台审批平台的一期重心

## 正式结论模型

系统只输出四种正式结论，中文为主，英文编码保留用于机器处理：

- `Accept / 允许放行`
- `Retryable / 补齐后重试`
- `Reject / 拒绝放行`
- `NeedHumanApproval / 需要人工审批`

结论优先级固定如下：

1. 命中范围越界、受保护目录、文件类型违规、改动规模超限，结论为 `Reject / 拒绝放行`
2. 未命中硬拒绝但命中审批目录，结论为 `NeedHumanApproval / 需要人工审批`
3. 未命中硬拒绝和审批目录，但材料缺失或无效，结论为 `Retryable / 补齐后重试`
4. 所有检查均通过，结论为 `Accept / 允许放行`

配置或任务本身非法时，不进入正式门禁结论，必须先修复配置或当前任务。

## 命令集合

### 项目书主命令

- `moonforge init`
  - 初始化 `.moonforge/`
  - 生成仓库规则文件
  - 生成五类任务模板
  - 生成当前任务样例
- `moonforge task`
  - 选择任务模板
  - 生成本次任务定义
- `moonforge check`
  - 对当前待提交变更执行门禁判定
- `moonforge report`
  - 展示最近一次门禁结果和可读报告

### 验收补齐命令

- `moonforge validate`
  - 校验仓库规则、模板和当前任务是否合法
- `moonforge replay`
  - 基于运行快照复现一次历史检查结论
- `moonforge pack`
  - 导出最小验收包和固定场景包
- `moonforge doctor`
  - 诊断仓库接入状态、缺失文件和环境问题

## 交互原则

工具必须减少开发者输入负担，不能把复杂规则维护成本转嫁给用户。

### 最少输入约束

- `init` 默认零配置启动
- `task` 以模板和路径组为主，不要求开发者反复手写大段 glob
- `check` 默认读取当前暂存区 diff
- `report` 默认读取最近一次结果
- `validate` 默认一次性校验仓库规则、模板和当前任务

### 双语输出约束

所有输出统一保留两层信息：

- 机器层：英文编码，例如 `PATH_OUT_OF_SCOPE`
- 人读层：中文说明，例如 `超出任务允许范围`

核心输出对象至少包含：

- 结论英文编码
- 结论中文说明
- 违规英文编码
- 违规中文说明
- 修复建议中文说明

## 规则模型

系统采用三层规则模型，禁止由当前任务绕过长期规则。

### 第一层：仓库长期规则

文件位置：

- `.moonforge/repo-rules.yml`

职责：

- 定义仓库级长期红线
- 定义默认允许后缀
- 定义受保护路径和审批路径
- 定义常用路径组，减少任务创建时的重复输入

核心字段：

- `protected_paths`
- `approval_required_paths`
- `default_allowed_extensions`
- `blocked_filenames`
- `sensitive_file_patterns`
- `path_groups`

### 第二层：任务模板规则

文件位置：

- `.moonforge/task-types/*.yml`

职责：

- 定义不同任务类型的默认边界和材料要求

必须覆盖的五类模板：

- `feature-change`
- `bug-fix`
- `api-change`
- `config-change`
- `test-addition`

核心字段：

- `task_type`
- `allowed_paths`
- `forbidden_paths`
- `allowed_extensions`
- `required_artifacts`
- `max_changed_files`
- `manual_approval_paths`

增强字段：

- `required_target_groups`
- `forbidden_target_groups`
- `required_artifact_schema`
- `patch_risk_rules`
- `min_target_hit_count`
- `max_unscoped_files`

### 第三层：当前任务规则

文件位置：

- `.moonforge/current-task.yml`

职责：

- 固化一次具体待提交变更任务的边界

核心字段：

- `task_type`
- `title`
- `target_groups`
- `target_paths`
- `artifacts_context`
- `risk_acknowledged`

### 规则合并原则

检查执行前需要将三层规则合并为一次真正生效的约束，遵循以下原则：

- 禁止项取更严
- 审批项取并集
- 材料要求取并集
- 允许范围只能收紧，不能放宽
- 改动文件上限取更严格值

## 最终场景模型

场景采用双层模型：

- 第一层为 `5 个验收域`
- 第二层为 `12 个固定场景`

### 第一层：5 个验收域

- 规则与任务合法性
- 变更范围合法性
- 风险路径合法性
- 文件类型合法性
- 材料完整性与有效性

### 第二层：12 个固定场景

#### A. 规则与任务合法性

`场景 1：模板语法非法`

- YAML 无法解析
- 列表字段写成标量
- 数值字段类型错误

处理方式：

- 中止后续检查
- 输出配置非法错误

`场景 2：模板语义非法`

- 模板文件名与 `task_type` 不一致
- `allowed_paths` 与 `forbidden_paths` 冲突
- 路径模式不可解析
- `max_changed_files` 非正整数

处理方式：

- 中止后续检查
- 输出规则语义错误

`场景 3：当前任务非法`

- 缺少 `task_type`
- 缺少 `title`
- `target_groups` 与 `target_paths` 同时为空
- 当前任务试图绕过模板或仓库规则

处理方式：

- 中止后续检查
- 输出任务定义非法错误

#### B. 变更范围合法性

`场景 4：变更越界`

- 变更文件不在允许范围内
- 前端任务混入后端改动
- 补测试任务混入业务实现改动

处理方式：

- 输出 `PATH_OUT_OF_SCOPE / 超出任务允许范围`
- 结论为 `Reject / 拒绝放行`

`场景 5：目标区域未命中`

- 当前任务声明的目标区域未被真正改动
- 只改动了旁路目录或其他模块

处理方式：

- 输出 `TARGET_PATH_NOT_TOUCHED / 未命中任务目标区域`
- 结论为 `Reject / 拒绝放行`

`场景 6：改动规模超限`

- 改动文件数超过模板上限
- 明显不是单一任务而是多任务混杂

处理方式：

- 输出 `CHANGED_FILE_COUNT_EXCEEDED / 改动文件数超出上限`
- 结论为 `Reject / 拒绝放行`

#### C. 风险路径合法性

`场景 7：受保护目录触碰`

- 命中安全目录
- 命中支付或账单目录
- 命中运维或基础设施目录
- 命中核心共享模块目录

处理方式：

- 输出 `PROTECTED_PATH_TOUCHED / 触碰受保护目录`
- 结论为 `Reject / 拒绝放行`

`场景 8：审批目录触碰`

- 命中需要人工审批的高风险路径

处理方式：

- 输出 `MANUAL_APPROVAL_REQUIRED / 命中人工审批路径`
- 结论为 `NeedHumanApproval / 需要人工审批`

#### D. 文件类型合法性

`场景 9：后缀违规`

- 模板不允许的后缀文件
- 与当前任务无关的二进制、压缩包或本地产物

处理方式：

- 输出 `FORBIDDEN_EXTENSION / 文件类型不允许`
- 结论为 `Reject / 拒绝放行`

`场景 10：敏感文件提交`

- 提交真实 `.env`
- 提交带密钥配置
- 提交临时缓存或不应入库文件

处理方式：

- 输出 `SENSITIVE_FILE_BLOCKED / 敏感文件禁止提交`
- 结论为 `Reject / 拒绝放行`

#### E. 材料完整性与有效性

`场景 11：材料缺失`

- 缺少 `test-report.json`
- 缺少 `review-report.json`
- 缺少 `bug-context.md`
- 缺少 `api-spec.md`
- 缺少 `config-impact.md`
- 缺少 `coverage-report.json`

处理方式：

- 输出 `MISSING_ARTIFACT / 缺少必需材料`
- 结论为 `Retryable / 补齐后重试`

`场景 12：材料无效`

- 文件为空
- JSON 结构非法
- 关键字段缺失
- Markdown 仅有标题没有正文

处理方式：

- 输出 `ARTIFACT_INVALID / 材料内容无效`
- 结论为 `Retryable / 补齐后重试`

## 工作流

### 节点 1：仓库接入

执行命令：

- `moonforge init`
- `moonforge validate`

职责：

- 生成规则、模板和任务样例
- 校验仓库规则和模板本身是否合法

### 节点 2：开始任务

执行命令：

- `moonforge task`
- `moonforge validate`

职责：

- 固化本次任务类型、标题和目标区域
- 校验当前任务是否与模板和仓库规则一致

### 节点 3：AI 编码后、git 提交前

执行顺序：

1. AI 生成代码
2. 开发者人工修正
3. `git add`
4. `moonforge check`
5. `moonforge report`
6. 若通过再 `git commit`

职责：

- 对当前暂存区变更执行正式门禁判定

### 节点 4：GitHub 云端复核

执行方式：

- GitHub Actions 触发 `moonforge check --mode ci`
- GitHub Actions 触发 `moonforge report --mode ci`

职责：

- 在远端重复执行与本地一致的检查逻辑
- 输出正式审计结果和运行快照
- 防止仅依赖本地结果造成绕过

## 本地与 GitHub 云端的关系

系统采用 `一套内核 + 两个执行面`：

- 本地执行面：提交前读取 staged diff
- GitHub 云端执行面：读取 PR diff、分支差异或补丁文件

两者必须保持以下一致性：

- 同一套规则模型
- 同一套违规编码
- 同一套结论优先级
- 同一套结果文件结构

两者允许不同的只有：

- 变更来源适配器

### GitHub 云端的一期边界

必须交付：

- GitHub Actions 工作流
- PR、push 或手动触发的远端检查
- `ci/latest` 输出目录
- 结果文件上传为 artifact
- 审计结果可复现

不作为一期重点：

- GitHub App
- PR 自动修复机器人
- Web 控制台
- SaaS 后台

## 与 AI Agent 工作流的严格区别

MoonForge 不关心：

- Agent 如何拆任务
- Agent 如何协作
- Prompt 如何流转
- 代码如何生成

MoonForge 只关心：

- AI Agent 或开发者已经改出的代码，在当前任务和当前规则下，是否允许提交

因此，MoonForge 的定位是：

- `AI Agent 产出代码之后、git 提交之前和 GitHub 合并之前的准入门禁内核`

而不是：

- `AI Agent 工作流编排器`

## 与 ESLint 等工具的严格区别

ESLint 等工具主要关注：

- 单文件静态规则
- 语法问题
- 风格问题
- 局部最佳实践

MoonForge 关注：

- 一次待提交变更集是否越界
- 是否触碰受保护目录
- 是否缺少交付材料
- 是否需要人工审批
- 是否应进入共享仓库

它们的边界必须严格区分，避免功能雷同。

## 结果文件

系统必须稳定输出以下文件：

- `gate-result.json`
- `gate-report.md`
- `checked-files.txt`
- `events.jsonl`
- `task.snapshot.json`

其中：

- `gate-result.json` 用于结构化结论输出
- `gate-report.md` 用于面向开发者和评审者的人类可读报告
- `checked-files.txt` 用于明确本次实际检查范围
- `events.jsonl` 用于调试、审计和回放
- `task.snapshot.json` 用于固化本次真正生效的合并后任务约束

## 验收包要求

为满足项目书中的固定场景验收，系统必须能导出最小验收包，至少包含：

- 最小示例仓库
- 固定输入文件集合
- 固定预期输出文件集合
- 固定命令链

固定场景至少覆盖：

- 通过场景
- 拒绝场景
- 补齐后重试场景
- 需要人工审批场景

## 测试策略

测试必须覆盖以下层次：

- 规则解析与校验单元测试
- 路径匹配与范围判定单元测试
- 材料完整性与有效性测试
- 四类正式结论集成测试
- GitHub CI 模式回归测试
- 审计回放一致性测试
- 最小验收包固定场景测试

## 代码规模与提交策略约束

后续实现必须满足以下用户约束：

- 核心 MoonBit 代码不少于 `15000` 行
- 不依靠配置、样例或夹具灌水
- 每次新增真实功能点后进行一次中文 `feat：...` 提交
- 累计形成 `90` 次真实功能提交

## 自检结论

本规格文档满足以下要求：

- 无占位符
- 无未定字段
- 设计边界与项目书一致
- 核心场景已收敛为可实现、可验收、可测试的固定集合
- GitHub 云端能力作为项目书要求的远端执行面纳入设计，但未扩展为无关平台
