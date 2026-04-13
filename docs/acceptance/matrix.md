# MoonForge Core 验收矩阵

## 说明

本矩阵把设计文档中的 `5 个验收域` 与 `12 个固定场景` 映射到当前实现中的命令入口、结果物与测试文件。

用于回答三个问题：

- 当前场景由哪个命令链路承担
- 验收时应查看哪些固定输出文件
- 目前有哪些自动化测试直接覆盖该场景

## 验收域

| 验收域 | 固定场景 |
| --- | --- |
| 规则与任务合法性 | 场景 1 / 2 / 3 |
| 变更范围合法性 | 场景 4 / 5 / 6 |
| 风险路径合法性 | 场景 7 / 8 |
| 文件类型合法性 | 场景 9 / 10 |
| 材料完整性与有效性 | 场景 11 / 12 |

## 场景矩阵

| 场景 | 验收目标 | 主命令 | 固定输出 | 主要测试 |
| --- | --- | --- | --- | --- |
| 场景 1 模板语法非法 | 拦截 YAML 结构错误与空配置 | `moonforge validate` | 终端校验摘要 | [validate_flow_test.mbt](/Users/leila/Documents/Playground%203/moonforge_gate/.worktrees/moonforge-core-impl/tests/integration/validate_flow_test.mbt:1), [template_validator_test.mbt](/Users/leila/Documents/Playground%203/moonforge_gate/.worktrees/moonforge-core-impl/tests/unit/template_validator_test.mbt:1) |
| 场景 2 模板语义非法 | 拦截文件名/类型/边界冲突 | `moonforge validate` | 终端校验摘要 | [template_validator_test.mbt](/Users/leila/Documents/Playground%203/moonforge_gate/.worktrees/moonforge-core-impl/tests/unit/template_validator_test.mbt:1) |
| 场景 3 当前任务非法 | 拦截空目标与非法任务定义 | `moonforge task` / `moonforge validate` | `current-task.yml`、终端校验摘要 | [task_validator_test.mbt](/Users/leila/Documents/Playground%203/moonforge_gate/.worktrees/moonforge-core-impl/tests/unit/task_validator_test.mbt:1), [cli_command_test.mbt](/Users/leila/Documents/Playground%203/moonforge_gate/.worktrees/moonforge-core-impl/tests/unit/cli_command_test.mbt:1) |
| 场景 4 变更越界 | 拒绝超出任务范围的文件修改 | `moonforge check` | `gate-result.json`、`scope-result.json`、`gate-report.md` | [scope_checker_test.mbt](/Users/leila/Documents/Playground%203/moonforge_gate/.worktrees/moonforge-core-impl/tests/unit/scope_checker_test.mbt:1), [gate_flow_test.mbt](/Users/leila/Documents/Playground%203/moonforge_gate/.worktrees/moonforge-core-impl/tests/integration/gate_flow_test.mbt:1) |
| 场景 5 目标区域未命中 | 识别任务声明目标未触达 | `moonforge check` | `scope-result.json` | [scope_checker_test.mbt](/Users/leila/Documents/Playground%203/moonforge_gate/.worktrees/moonforge-core-impl/tests/unit/scope_checker_test.mbt:1) |
| 场景 6 改动规模超限 | 拒绝超出文件数上限的大改动 | `moonforge check` | `scope-result.json`、`gate-result.json` | [path_group_test.mbt](/Users/leila/Documents/Playground%203/moonforge_gate/.worktrees/moonforge-core-impl/tests/unit/path_group_test.mbt:1), [scope_checker_test.mbt](/Users/leila/Documents/Playground%203/moonforge_gate/.worktrees/moonforge-core-impl/tests/unit/scope_checker_test.mbt:1), [gate_flow_test.mbt](/Users/leila/Documents/Playground%203/moonforge_gate/.worktrees/moonforge-core-impl/tests/integration/gate_flow_test.mbt:1) |
| 场景 7 受保护目录触碰 | 拒绝 security 与 infra 等红线目录改动 | `moonforge check` | `gate-result.json`、`events.jsonl` | [risk_path_checker_test.mbt](/Users/leila/Documents/Playground%203/moonforge_gate/.worktrees/moonforge-core-impl/tests/unit/risk_path_checker_test.mbt:1), [gate_flow_test.mbt](/Users/leila/Documents/Playground%203/moonforge_gate/.worktrees/moonforge-core-impl/tests/integration/gate_flow_test.mbt:1) |
| 场景 8 审批目录触碰 | 升级为人工审批而非直接放行 | `moonforge check` | `gate-result.json`、`events.jsonl` | [risk_path_checker_test.mbt](/Users/leila/Documents/Playground%203/moonforge_gate/.worktrees/moonforge-core-impl/tests/unit/risk_path_checker_test.mbt:1), [gate_flow_test.mbt](/Users/leila/Documents/Playground%203/moonforge_gate/.worktrees/moonforge-core-impl/tests/integration/gate_flow_test.mbt:1) |
| 场景 9 后缀违规 | 拒绝模板不允许的文件后缀 | `moonforge check` | `gate-result.json`、`scope-result.json` | [file_type_checker_test.mbt](/Users/leila/Documents/Playground%203/moonforge_gate/.worktrees/moonforge-core-impl/tests/unit/file_type_checker_test.mbt:1) |
| 场景 10 敏感文件提交 | 拒绝真实 `.env` 等敏感文件 | `moonforge check` | `gate-result.json`、`events.jsonl` | [file_type_checker_test.mbt](/Users/leila/Documents/Playground%203/moonforge_gate/.worktrees/moonforge-core-impl/tests/unit/file_type_checker_test.mbt:1) |
| 场景 11 材料缺失 | 进入补齐后重试分支 | `moonforge check` | `artifact-result.json`、`gate-result.json` | [artifact_checker_test.mbt](/Users/leila/Documents/Playground%203/moonforge_gate/.worktrees/moonforge-core-impl/tests/unit/artifact_checker_test.mbt:1), [gate_flow_test.mbt](/Users/leila/Documents/Playground%203/moonforge_gate/.worktrees/moonforge-core-impl/tests/integration/gate_flow_test.mbt:1) |
| 场景 12 材料无效 | 拦截空白或无效材料内容 | `moonforge check` | `artifact-result.json`、`gate-result.json` | [artifact_checker_test.mbt](/Users/leila/Documents/Playground%203/moonforge_gate/.worktrees/moonforge-core-impl/tests/unit/artifact_checker_test.mbt:1) |

## 命令与结果物

| 命令 | 主要结果物 | 说明 |
| --- | --- | --- |
| `moonforge init` | `.moonforge/repo-rules.yml`、`.moonforge/task-types/*.yml`、`.moonforge/current-task.yml` | 初始化仓库治理配置与空白任务样例 |
| `moonforge task` | `.moonforge/current-task.yml` | 生成当前任务边界，支持路径组与自定义模板 |
| `moonforge validate` | 终端校验摘要 | 面向接入前检查 |
| `moonforge check` | `gate-result.json`、`scope-result.json`、`artifact-result.json`、`checked-files.txt`、`events.jsonl`、`gate-report.md` | 门禁主链路 |
| `moonforge report` | 终端中文摘要 | 读取最近一次检查结果 |
| `moonforge replay` | 终端回放摘要 | 读取运行快照中的任务信息 |
| `moonforge pack` | `.moonforge/out/<mode>/packs/latest/` | 导出最小验收包目录，归档文件仍待补齐 |
| `moonforge doctor` | 终端诊断摘要 | 检查接入状态与配置健康度 |

## 当前缺口提示

- `validate` 已覆盖空白样例、自定义模板、未知任务类型与多类 YAML/语义错误；剩余待补是更深层的模板规则语义与非法 glob 模式。
- `pack` 当前导出的是固定文件目录，还没有真正压成 `.tar.gz` 归档包。
- GitHub Actions 已有基础工作流，但还缺显式的 `validate` / `check --mode ci` 执行面与对应的独立集成测试。
