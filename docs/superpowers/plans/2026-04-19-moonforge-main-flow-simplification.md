# MoonForge Main Flow Simplification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep `init / task / check / report` as the only main user-facing flow while making them work naturally inside a target project with minimal parameters and much thicker `src` capabilities.

**Architecture:** Add new domain, infra, service, and checker modules around project context, staged git input, task auto-fill, run history, and human-readable reporting. Keep CLI shape stable while moving complexity into config files and core services.

**Tech Stack:** MoonBit, libuv, git CLI, YAML-like flat config files, MoonBit test suite.

---

### Task 1: 固化设计与主入口约束

**Files:**
- Create: `docs/superpowers/specs/2026-04-19-moonforge-main-flow-simplification-design.md`
- Create: `docs/superpowers/plans/2026-04-19-moonforge-main-flow-simplification.md`

- [ ] 记录用户已确认的 4 个主命令、配置策略、自动补全方向和 `src 10000+` 目标。
- [ ] 把实现拆到 git 上下文、task 自动补全、check 编排、history/report、规则扩充几条线。

### Task 2: 让 `repo` 默认当前目录

**Files:**
- Modify: `cmd/main/main.mbt`
- Modify: `src/services/commands.mbt`
- Create: `src/services/project_context_service.mbt`
- Test: `tests/unit/cli_command_test.mbt`

- [ ] 让 CLI 的 `--repo` 变成可选，默认使用当前工作目录。
- [ ] 引入项目根目录解析服务，集中处理 cwd 与 repo 路径标准化。
- [ ] 补测试锁定“用户在目标项目目录里直接运行”的行为。

### Task 3: 扩充 git 运行上下文基础设施

**Files:**
- Modify: `src/infra/process_runner.mbt`
- Create: `src/infra/git_command_runner.mbt`
- Create: `src/infra/git_repo_reader.mbt`
- Create: `src/domain/project_context_types.mbt`
- Test: `tests/unit/git_repo_reader_test.mbt`

- [ ] 扩充同步 shell 执行能力，支持退出码、stdout、stderr。
- [ ] 提供 git 根目录、staged 文件、diff、branch 等读取能力。
- [ ] 为后续 task 自动补全和 check 自动输入打基础。

### Task 4: 扩充当前任务模型

**Files:**
- Modify: `src/domain/task_types.mbt`
- Create: `src/domain/task_autofill_types.mbt`
- Create: `src/domain/task_draft_types.mbt`
- Test: `tests/unit/task_autofill_test.mbt`

- [ ] 给 `CurrentTask` 增加自动推断相关字段。
- [ ] 增加任务自动补全过程中使用的中间对象。
- [ ] 用单测锁定 YAML 输出字段和推断标记。

### Task 5: 把 `task` 做成自动补全入口

**Files:**
- Create: `src/services/task_autofill_service.mbt`
- Modify: `src/services/task_service.mbt`
- Modify: `src/services/commands.mbt`
- Test: `tests/integration/task_flow_test.mbt`

- [ ] `task --type ...` 自动读取 staged 文件与模板。
- [ ] 自动补全 title、target_groups、target_paths、materials、commands。
- [ ] 写入更厚的 `.moonforge/current-task.yml`。

### Task 6: 扩充初始化产物

**Files:**
- Create: `src/domain/bootstrap_types.mbt`
- Create: `src/services/bootstrap_service.mbt`
- Create: `src/infra/bootstrap_store.mbt`
- Modify: `src/services/commands.mbt`
- Test: `tests/integration/task_flow_test.mbt`

- [ ] `init` 生成更完整的配置目录和默认文件。
- [ ] 生成默认任务偏好、运行偏好、材料目录等配置。
- [ ] 安装并检查 hook。

### Task 7: 本地 `check` 自动 staged diff

**Files:**
- Create: `src/domain/check_input_types.mbt`
- Create: `src/services/check_input_service.mbt`
- Create: `src/services/staged_run_service.mbt`
- Modify: `src/adapters/git_local_diff.mbt`
- Modify: `src/services/commands.mbt`
- Test: `tests/integration/gate_flow_test.mbt`

- [ ] 本地模式不再强制用户给 `--run`。
- [ ] 自动创建本次运行目录并落 patch。
- [ ] 自动把当前任务和材料绑定到本次运行。

### Task 8: 扩充材料发现与默认目录

**Files:**
- Create: `src/domain/material_catalog_types.mbt`
- Create: `src/services/material_discovery_service.mbt`
- Create: `src/infra/material_catalog_store.mbt`
- Modify: `src/services/commands.mbt`
- Test: `tests/unit/material_discovery_test.mbt`

- [ ] 自动发现常见材料目录中的结果文件。
- [ ] 支持由配置指定材料搜索目录和候选文件名。
- [ ] 让 `check` 尽量少依赖用户手工准备路径。

### Task 9: 增加运行历史索引

**Files:**
- Create: `src/domain/run_history_types.mbt`
- Create: `src/services/run_history_service.mbt`
- Create: `src/infra/run_history_store.mbt`
- Modify: `src/infra/run_store.mbt`
- Modify: `src/services/commands.mbt`
- Test: `tests/integration/replay_flow_test.mbt`

- [ ] 为每次运行生成历史索引。
- [ ] 支持最近运行列表和 run-id 查询。
- [ ] 让 report/replay 可以复用统一历史结构。

### Task 10: 扩充报告结构

**Files:**
- Create: `src/domain/report_view_types.mbt`
- Create: `src/services/report_view_service.mbt`
- Modify: `src/services/report_service.mbt`
- Modify: `src/services/commands.mbt`
- Test: `tests/unit/report_service_test.mbt`

- [ ] 让报告既能给结论，也能给原因、建议和上下文。
- [ ] 增加“任务摘要 / 输入摘要 / 风险摘要 / 下一步建议”。
- [ ] 保持终端输出简单清楚。

### Task 11: 扩充规则解释链路

**Files:**
- Create: `src/domain/decision_explanation_types.mbt`
- Create: `src/services/decision_explanation_service.mbt`
- Modify: `src/domain/result_types.mbt`
- Modify: `src/checkers/gate.mbt`
- Test: `tests/unit/rule_codes_test.mbt`

- [ ] 把规则命中理由统一解释成更好懂的中文。
- [ ] 把“为什么 reject / retryable / approval”说完整。
- [ ] 为 report 和 pack 复用解释结构。

### Task 12: 新增任务聚焦与输入一致性检查

**Files:**
- Create: `src/checkers/task_focus_checker.mbt`
- Create: `src/checkers/run_consistency_checker.mbt`
- Modify: `src/checkers/gate.mbt`
- Test: `tests/unit/task_focus_checker_test.mbt`

- [ ] 检查 staged 输入与 current-task 之间是否明显偏离。
- [ ] 检查推断路径与实际变更是否一致。
- [ ] 提高自动补全后的安全性。

### Task 13: 新增材料政策检查

**Files:**
- Create: `src/checkers/material_policy_checker.mbt`
- Modify: `src/checkers/gate.mbt`
- Modify: `src/domain/result_types.mbt`
- Test: `tests/unit/material_policy_checker_test.mbt`

- [ ] 把材料缺失、材料目录错误、材料命名不一致拆开检查。
- [ ] 输出更明确的修复建议。

### Task 14: 新增标题与任务描述质量检查

**Files:**
- Create: `src/checkers/task_description_checker.mbt`
- Modify: `src/checkers/gate.mbt`
- Test: `tests/unit/task_description_checker_test.mbt`

- [ ] 检查自动生成标题是否为空、过短、过泛。
- [ ] 提示用户是否需要手工修正 `current-task.yml`。

### Task 15: 扩充 pack/report/replay 共享视图

**Files:**
- Create: `src/services/run_snapshot_view_service.mbt`
- Modify: `src/services/replay_service.mbt`
- Modify: `src/services/pack_service.mbt`
- Test: `tests/integration/pack_flow_test.mbt`

- [ ] 把快照读取、结果解释、历史索引统一起来。
- [ ] 让 pack 与 replay 输出更容易看懂。

### Task 16: 完整补齐中文解释性注释

**Files:**
- Modify: `src/domain/*`
- Modify: `src/services/*`
- Modify: `src/infra/*`
- Modify: `src/checkers/*`

- [ ] 文件先总说，再分说。
- [ ] 每个新增函数都写清楚输入、输出、主要步骤。
- [ ] 保持中学生级别可读性。

### Task 17: 让 CLI 帮助同步真实使用方式

**Files:**
- Modify: `cmd/main/main.mbt`
- Modify: `README.mbt.md`
- Test: `tests/unit/cli_command_test.mbt`

- [ ] 把帮助文本改成当前目录默认化的用法。
- [ ] 让 README 直接展示 4 步主路径。

### Task 18: 整体回归测试

**Files:**
- Modify: `tests/unit/*`
- Modify: `tests/integration/*`
- Modify: `tests/e2e/*`

- [ ] 让测试覆盖新的主路径与自动补全逻辑。
- [ ] 确保 `moon test`、`acc pass/retry/reject` 都通过。

### Task 19: 统计 `src` 行数

**Files:**
- Modify: `docs/superpowers/context/*` if needed

- [ ] 统计 `src` 下 `.mbt` 行数是否超过 `10000`。
- [ ] 如果不足，继续沿上述主线补核心模块，不靠空文件凑数。

### Task 20: 拆成 20 次中文提交

**Files:**
- Commit only

- [ ] 按功能切提交，不做空提交。
- [ ] 提交信息保持中文、主动、具体、可读。
