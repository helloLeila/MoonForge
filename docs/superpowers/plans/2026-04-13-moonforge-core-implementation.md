# MoonForge Core Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建严格匹配项目书验收要求的 `MoonForge Core`，实现 `AI 辅助编码后、git 提交前` 与 `GitHub CI 云端复核` 的统一代码准入内核，覆盖 `5 个验收域 + 12 个固定场景`，并形成可验收、可回放、可扩展、可商业化的 MoonBit 工程实现。

**Architecture:** 以现有 `domain / infra / checkers / services / adapters / cmd` 结构为主干，扩展为“规则建模层 + 输入适配层 + 检查器层 + 报告与审计层 + 命令服务层”。本地提交前与 GitHub 云端只允许在“变更来源适配器”上不同，必须共享相同的规则合并、场景判定、结论优先级和输出结构。

**Tech Stack:** MoonBit、`tonyfettes/uv`、Git staged diff、GitHub Actions、Markdown/JSON 结果文件、MoonBit 单元测试与集成测试。

---

## 范围锁定

- 本计划只实现项目书主线与必要增强，不实现 AI Agent 工作流编排
- 所有功能都必须映射到 `5 个验收域 + 12 个固定场景`
- GitHub 云端能力只做 `CI 复核执行面`，不做 SaaS 控制台
- 所有终端输出、报告和提交信息使用中文主导，保留英文编码
- 所有新增核心功能提交必须使用中文 `feat：...` 信息

## 目标文件结构

### 需要修改的现有文件

- Modify: `src/domain/types.mbt`
- Modify: `src/infra/flat_yaml.mbt`
- Modify: `src/infra/path_utils.mbt`
- Modify: `src/infra/fs_text.mbt`
- Modify: `src/checkers/gate.mbt`
- Modify: `src/adapters/mode_paths.mbt`
- Modify: `src/services/commands.mbt`
- Modify: `cmd/main/main.mbt`
- Modify: `README.mbt.md`

### 需要新增的核心源码文件

- Create: `src/domain/rule_codes.mbt`
- Create: `src/domain/rule_types.mbt`
- Create: `src/domain/task_types.mbt`
- Create: `src/domain/result_types.mbt`
- Create: `src/domain/artifact_types.mbt`
- Create: `src/domain/audit_types.mbt`
- Create: `src/domain/path_group_types.mbt`
- Create: `src/infra/yaml_schema.mbt`
- Create: `src/infra/path_groups.mbt`
- Create: `src/infra/diff_parser.mbt`
- Create: `src/infra/diff_tokens.mbt`
- Create: `src/infra/artifact_schema.mbt`
- Create: `src/infra/json_text.mbt`
- Create: `src/infra/run_store.mbt`
- Create: `src/infra/report_text.mbt`
- Create: `src/adapters/git_local_diff.mbt`
- Create: `src/adapters/git_ci_diff.mbt`
- Create: `src/adapters/github_env.mbt`
- Create: `src/adapters/material_locator.mbt`
- Create: `src/checkers/template_validator.mbt`
- Create: `src/checkers/task_validator.mbt`
- Create: `src/checkers/scope_checker.mbt`
- Create: `src/checkers/risk_path_checker.mbt`
- Create: `src/checkers/file_type_checker.mbt`
- Create: `src/checkers/artifact_checker.mbt`
- Create: `src/checkers/decision_builder.mbt`
- Create: `src/checkers/replay_checker.mbt`
- Create: `src/services/init_service.mbt`
- Create: `src/services/task_service.mbt`
- Create: `src/services/validate_service.mbt`
- Create: `src/services/check_service.mbt`
- Create: `src/services/report_service.mbt`
- Create: `src/services/replay_service.mbt`
- Create: `src/services/pack_service.mbt`
- Create: `src/services/doctor_service.mbt`

### 需要新增的测试文件

- Create: `tests/unit/rule_codes_test.mbt`
- Create: `tests/unit/template_validator_test.mbt`
- Create: `tests/unit/task_validator_test.mbt`
- Create: `tests/unit/path_group_test.mbt`
- Create: `tests/unit/diff_parser_test.mbt`
- Create: `tests/unit/scope_checker_test.mbt`
- Create: `tests/unit/risk_path_checker_test.mbt`
- Create: `tests/unit/file_type_checker_test.mbt`
- Create: `tests/unit/artifact_checker_test.mbt`
- Create: `tests/unit/decision_builder_test.mbt`
- Create: `tests/unit/replay_checker_test.mbt`
- Create: `tests/integration/validate_flow_test.mbt`
- Create: `tests/integration/task_flow_test.mbt`
- Create: `tests/integration/check_local_flow_test.mbt`
- Create: `tests/integration/check_ci_flow_test.mbt`
- Create: `tests/integration/replay_flow_test.mbt`
- Create: `tests/integration/pack_flow_test.mbt`
- Create: `tests/e2e/moon.pkg`
- Create: `tests/e2e/cli_acceptance_test.mbt`
- Create: `tests/fixtures/scenarios/pass/patch.diff`
- Create: `tests/fixtures/scenarios/reject/patch.diff`
- Create: `tests/fixtures/scenarios/retryable/patch.diff`
- Create: `tests/fixtures/scenarios/approval/patch.diff`

### 需要新增的文档与云端文件

- Create: `.github/workflows/moonforge-ci.yml`
- Create: `examples/expected-inputs/pass/patch.diff`
- Create: `examples/expected-inputs/reject/patch.diff`
- Create: `examples/expected-inputs/retryable/patch.diff`
- Create: `examples/expected-inputs/approval/patch.diff`
- Create: `examples/expected-outputs/pass/gate-result.json`
- Create: `examples/expected-outputs/reject/gate-result.json`
- Create: `examples/expected-outputs/retryable/gate-result.json`
- Create: `examples/expected-outputs/approval/gate-result.json`
- Create: `docs/acceptance/matrix.md`

## 核心代码预算

为满足用户要求，核心 MoonBit 代码目标如下：

- `src/domain`: 1800 行
- `src/infra`: 3200 行
- `src/checkers`: 5200 行
- `src/services`: 3400 行
- `src/adapters + cmd`: 1600 行

核心源码总目标：

- `15200+` 行 `src/ + cmd/` MoonBit 核心代码

测试代码目标：

- `4500+` 行 MoonBit 测试代码

## 90 次功能提交切片

下列提交切片用于保证实现阶段每次只交付一个真实功能点。实际执行时必须按 TDD 顺序完成后再提交。

1. `feat：补充双语结论编码模型`
2. `feat：补充双语违规项结构模型`
3. `feat：补充路径组领域对象`
4. `feat：补充材料结构描述模型`
5. `feat：补充审计事件领域对象`
6. `feat：补充运行快照领域对象`
7. `feat：补充模板规则领域对象`
8. `feat：补充当前任务领域对象`
9. `feat：补充有效任务合并结果对象`
10. `feat：补充 GitHub CI 运行上下文对象`
11. `feat：补充 YAML 结构校验器`
12. `feat：补充路径组展开器`
13. `feat：补充路径组引用合法性校验`
14. `feat：补充路径模式语法校验`
15. `feat：补充模板文件名与任务类型一致性校验`
16. `feat：补充允许与禁止路径冲突校验`
17. `feat：补充任务目标最小输入校验`
18. `feat：补充任务禁止放宽仓库规则校验`
19. `feat：补充补丁文件解析器`
20. `feat：补充暂存区差异读取适配器`
21. `feat：补充 CI 差异读取适配器`
22. `feat：补充 GitHub 环境变量识别器`
23. `feat：补充变更文件归一化逻辑`
24. `feat：补充改动文件数量统计器`
25. `feat：补充范围越界检查器`
26. `feat：补充目标区域命中检查器`
27. `feat：补充多任务混杂规模检查器`
28. `feat：补充受保护目录检查器`
29. `feat：补充人工审批路径检查器`
30. `feat：补充默认允许后缀检查器`
31. `feat：补充敏感文件模式检查器`
32. `feat：补充真实环境文件拦截器`
33. `feat：补充二进制与压缩产物拦截器`
34. `feat：补充材料存在性检查器`
35. `feat：补充材料空内容检查器`
36. `feat：补充 JSON 材料结构校验器`
37. `feat：补充 Markdown 材料最小正文校验`
38. `feat：补充功能变更材料规则`
39. `feat：补充缺陷修复材料规则`
40. `feat：补充接口修改材料规则`
41. `feat：补充配置修改材料规则`
42. `feat：补充补充测试材料规则`
43. `feat：补充正式结论优先级构建器`
44. `feat：补充双语终端摘要生成器`
45. `feat：补充 Markdown 报告生成器`
46. `feat：补充 gate-result 结构化输出`
47. `feat：补充 checked-files 清单输出`
48. `feat：补充 events 审计日志输出`
49. `feat：补充 task snapshot 归档输出`
50. `feat：补充本地 latest 输出目录布局`
51. `feat：补充 CI latest 输出目录布局`
52. `feat：补充 init 仓库规则种子生成`
53. `feat：补充五类模板种子生成`
54. `feat：补充当前任务样例生成`
55. `feat：补充交互式任务创建服务`
56. `feat：补充路径组驱动任务创建`
57. `feat：补充 validate 命令服务`
58. `feat：补充 check 命令服务`
59. `feat：补充 report 命令服务`
60. `feat：补充 replay 命令服务`
61. `feat：补充 doctor 命令服务`
62. `feat：补充 pack 命令服务`
63. `feat：补充 CLI validate 子命令`
64. `feat：补充 CLI replay 子命令`
65. `feat：补充 CLI doctor 子命令`
66. `feat：补充 CLI pack 子命令`
67. `feat：补充 CLI 双语错误输出`
68. `feat：补充 GitHub CI 模式切换参数`
69. `feat：补充本地差异与 CI 差异统一接口`
70. `feat：补充 replay 一致性检查器`
71. `feat：补充最小验收包导出器`
72. `feat：补充固定通过场景夹具`
73. `feat：补充固定拒绝场景夹具`
74. `feat：补充固定补齐后重试场景夹具`
75. `feat：补充固定人工审批场景夹具`
76. `feat：补充模板合法性单元测试`
77. `feat：补充任务合法性单元测试`
78. `feat：补充路径组展开单元测试`
79. `feat：补充补丁解析单元测试`
80. `feat：补充范围检查单元测试`
81. `feat：补充风险路径单元测试`
82. `feat：补充文件类型单元测试`
83. `feat：补充材料检查单元测试`
84. `feat：补充结论构建单元测试`
85. `feat：补充本地流程集成测试`
86. `feat：补充 CI 流程集成测试`
87. `feat：补充回放流程集成测试`
88. `feat：补充验收包流程集成测试`
89. `feat：补充 GitHub Actions 云端复核工作流`
90. `feat：补充验收矩阵与项目说明文档`

## Task 1: 拆分领域模型与双语结论对象

**Files:**
- Create: `src/domain/rule_codes.mbt`
- Create: `src/domain/rule_types.mbt`
- Create: `src/domain/task_types.mbt`
- Create: `src/domain/result_types.mbt`
- Modify: `src/domain/types.mbt`
- Test: `tests/unit/rule_codes_test.mbt`

- [ ] **Step 1: Write the failing test**

```moonbit
test "decision label exposes bilingual fields" {
  let decision = @domain.DecisionView::from_decision(@domain.Reject)
  assert_eq(decision.code, "Reject")
  assert_eq(decision.text_zh, "拒绝放行")
}

test "violation view keeps code and chinese action" {
  let violation = @domain.ViolationView::{
    code: "PATH_OUT_OF_SCOPE",
    text_zh: "超出任务允许范围",
    text_en: "path out of scope",
    action_zh: "缩小改动范围后重试",
  }
  assert_eq(violation.action_zh, "缩小改动范围后重试")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `moon test tests/unit`
Expected: FAIL with missing `DecisionView` or `ViolationView`

- [ ] **Step 3: Write minimal implementation**

```moonbit
pub(all) struct DecisionView {
  code : String
  text_zh : String
  text_en : String
}

pub fn DecisionView::from_decision(decision : Decision) -> DecisionView {
  match decision {
    Accept => { code: "Accept", text_zh: "允许放行", text_en: "accept" }
    Retryable => { code: "Retryable", text_zh: "补齐后重试", text_en: "retryable" }
    Reject => { code: "Reject", text_zh: "拒绝放行", text_en: "reject" }
    NeedHumanApproval =>
      { code: "NeedHumanApproval", text_zh: "需要人工审批", text_en: "need human approval" }
  }
}

pub(all) struct ViolationView {
  code : String
  text_zh : String
  text_en : String
  action_zh : String
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `moon test tests/unit`
Expected: PASS and zero failure count for the new bilingual view assertions

- [ ] **Step 5: Commit**

```bash
git add src/domain tests/unit
git commit -m "feat：补充双语结论与违规项领域模型"
```

## Task 2: 完成模板与任务合法性校验器

**Files:**
- Create: `src/infra/yaml_schema.mbt`
- Create: `src/checkers/template_validator.mbt`
- Create: `src/checkers/task_validator.mbt`
- Test: `tests/unit/template_validator_test.mbt`
- Test: `tests/unit/task_validator_test.mbt`

- [ ] **Step 1: Write the failing test**

```moonbit
test "template validator rejects file name mismatch" {
  let template = @domain.TaskTemplate::{
    task_type: "bug-fix",
    allowed_paths: ["src/**"],
    forbidden_paths: [],
    allowed_extensions: [".mbt"],
    required_artifacts: ["test-report.json"],
    max_changed_files: 8,
    manual_approval_paths: [],
  }
  let result = @checkers.validate_template_semantics("feature-change.yml", template)
  assert_true(result is Err(_))
}

test "task validator rejects empty target groups and paths" {
  let task = @domain.CurrentTask::{
    task_type: "feature-change",
    title: "Add filter",
    target_groups: [],
    target_paths: [],
  }
  let result = @checkers.validate_current_task(task)
  assert_true(result is Err(_))
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `moon test tests/unit`
Expected: FAIL because `validate_template_semantics` and `validate_current_task` are undefined

- [ ] **Step 3: Write minimal implementation**

```moonbit
pub fn validate_template_semantics(
  file_name : String,
  template : @domain.TaskTemplate,
) -> Result[Unit, String] {
  if file_name != template.task_type + ".yml" {
    Err("CONFIG_SCHEMA_INVALID")
  } else if template.max_changed_files <= 0 {
    Err("RULE_SEMANTIC_INVALID")
  } else {
    Ok(())
  }
}

pub fn validate_current_task(
  task : @domain.CurrentTask,
) -> Result[Unit, String] {
  if task.task_type == "" || task.title == "" {
    Err("TASK_FILE_INVALID")
  } else if task.target_groups.is_empty() && task.target_paths.is_empty() {
    Err("TASK_SCOPE_INVALID")
  } else {
    Ok(())
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `moon test tests/unit`
Expected: PASS and explicit assertions for file-name mismatch and empty targets

- [ ] **Step 5: Commit**

```bash
git add src/checkers src/infra tests/unit
git commit -m "feat：补充模板与当前任务合法性校验"
```

## Task 3: 实现路径组与有效任务合并

**Files:**
- Create: `src/infra/path_groups.mbt`
- Modify: `src/checkers/gate.mbt`
- Modify: `src/domain/task_types.mbt`
- Test: `tests/unit/path_group_test.mbt`

- [ ] **Step 1: Write the failing test**

```moonbit
test "path group expansion returns concrete globs" {
  let groups : Map[String, Array[String]] = {
    "frontend_user_pages": ["frontend/src/pages/UserList/**"],
  }
  let expanded = @infra.expand_target_groups(groups, ["frontend_user_pages"])
  assert_eq(expanded, ["frontend/src/pages/UserList/**"])
}

test "effective task merge keeps stricter max file count" {
  let task_limit = @checkers.pick_stricter_limit(8, 3)
  assert_eq(task_limit, 3)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `moon test tests/unit`
Expected: FAIL with missing group expander and stricter limit helper

- [ ] **Step 3: Write minimal implementation**

```moonbit
pub fn expand_target_groups(
  groups : Map[String, Array[String]],
  names : Array[String],
) -> Array[String] raise {
  let output : Array[String] = []
  for name in names {
    guard groups.get(name) is Some(paths) else {
      raise Failure::Failure("PATH_GROUP_NOT_FOUND")
    }
    output.push_all(paths)
  }
  @infra.unique_strings(output)
}

pub fn pick_stricter_limit(left : Int, right : Int) -> Int {
  if left <= right { left } else { right }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `moon test tests/unit`
Expected: PASS for path group expansion and stricter limit merge

- [ ] **Step 5: Commit**

```bash
git add src/domain src/infra src/checkers tests/unit
git commit -m "feat：补充路径组展开与有效任务合并"
```

## Task 4: 实现本地与 CI 差异读取适配器

**Files:**
- Create: `src/infra/diff_parser.mbt`
- Create: `src/adapters/git_local_diff.mbt`
- Create: `src/adapters/git_ci_diff.mbt`
- Create: `src/adapters/github_env.mbt`
- Test: `tests/unit/diff_parser_test.mbt`

- [ ] **Step 1: Write the failing test**

```moonbit
test "diff parser extracts touched files from git diff" {
  let diff =
    #|diff --git a/src/foo.mbt b/src/foo.mbt
    #|index 111..222 100644
    #|--- a/src/foo.mbt
    #|+++ b/src/foo.mbt
    #|@@ -1,1 +1,1 @@
    #|-old
    #|+new
  let files = @infra.parse_changed_files(diff)
  assert_eq(files, ["src/foo.mbt"])
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `moon test tests/unit`
Expected: FAIL because `parse_changed_files` does not exist

- [ ] **Step 3: Write minimal implementation**

```moonbit
pub fn parse_changed_files(diff_text : String) -> Array[String] {
  let files : Array[String] = []
  for line in diff_text.split("\n") {
    if line.has_prefix("diff --git a/") {
      let parts = line.split(" ").map(item => item.to_string()).collect()
      files.push(parts[2][2:parts[2].length()].to_string())
    }
  }
  @infra.unique_strings(files)
}

pub fn read_ci_diff(env : Map[String, String], path : String) -> String raise {
  if env.contains("GITHUB_ACTIONS") { @infra.read_text(path) } else { raise Failure::Failure("CI_CONTEXT_NOT_FOUND") }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `moon test tests/unit`
Expected: PASS and parsed file list equals `["src/foo.mbt"]`

- [ ] **Step 5: Commit**

```bash
git add src/infra src/adapters tests/unit
git commit -m "feat：补充本地与 CI 差异读取适配器"
```

## Task 5: 实现范围检查器

**Files:**
- Create: `src/checkers/scope_checker.mbt`
- Test: `tests/unit/scope_checker_test.mbt`

- [ ] **Step 1: Write the failing test**

```moonbit
test "scope checker rejects out of scope files" {
  let task = @domain.EffectiveTask::{
    task_type: "feature-change",
    title: "Add filter",
    allowed_paths: ["frontend/src/pages/**"],
    forbidden_paths: [],
    approval_required_paths: [],
    allowed_extensions: [".tsx"],
    required_artifacts: [],
    max_changed_files: 8,
  }
  let result = @checkers.check_scope(task, ["backend/src/main/java/App.java"])
  assert_eq(result.out_of_scope_files, ["backend/src/main/java/App.java"])
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `moon test tests/unit`
Expected: FAIL because `check_scope` is missing

- [ ] **Step 3: Write minimal implementation**

```moonbit
pub(all) struct ScopeCheckResult {
  out_of_scope_files : Array[String]
  target_paths_hit : Array[String]
  file_count_exceeded : Bool
}

pub fn check_scope(
  task : @domain.EffectiveTask,
  changed_files : Array[String],
) -> ScopeCheckResult {
  let out_of_scope_files : Array[String] = []
  for file in changed_files {
    if !@infra.matches_any(file, task.allowed_paths) {
      out_of_scope_files.push(file)
    }
  }
  {
    out_of_scope_files,
    target_paths_hit: [],
    file_count_exceeded: changed_files.length() > task.max_changed_files,
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `moon test tests/unit`
Expected: PASS and out-of-scope list contains the backend file

- [ ] **Step 5: Commit**

```bash
git add src/checkers tests/unit
git commit -m "feat：补充范围越界与规模超限检查器"
```

## Task 6: 实现风险路径与文件类型检查器

**Files:**
- Create: `src/checkers/risk_path_checker.mbt`
- Create: `src/checkers/file_type_checker.mbt`
- Test: `tests/unit/risk_path_checker_test.mbt`
- Test: `tests/unit/file_type_checker_test.mbt`

- [ ] **Step 1: Write the failing test**

```moonbit
test "risk checker marks protected path as reject" {
  let result = @checkers.check_risk_paths(
    protected_paths: ["backend/src/main/java/**/security/**"],
    approval_paths: ["backend/src/main/java/**/service/high-risk/**"],
    changed_files: ["backend/src/main/java/com/acme/common/security/AuthFilter.java"],
  )
  assert_eq(result.protected_files.length(), 1)
}

test "file type checker blocks env file" {
  let result = @checkers.check_file_types(
    allowed_extensions: [".mbt", ".md", ".json"],
    blocked_filenames: [".env"],
    changed_files: [".env"],
  )
  assert_eq(result.sensitive_files, [".env"])
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `moon test tests/unit`
Expected: FAIL because risk/file type checkers are undefined

- [ ] **Step 3: Write minimal implementation**

```moonbit
pub(all) struct RiskPathResult {
  protected_files : Array[String]
  approval_files : Array[String]
}

pub fn check_risk_paths(
  protected_paths : Array[String],
  approval_paths : Array[String],
  changed_files : Array[String],
) -> RiskPathResult {
  let protected_files : Array[String] = []
  let approval_files : Array[String] = []
  for file in changed_files {
    if @infra.matches_any(file, protected_paths) {
      protected_files.push(file)
    } else if @infra.matches_any(file, approval_paths) {
      approval_files.push(file)
    }
  }
  { protected_files, approval_files }
}

pub(all) struct FileTypeResult {
  forbidden_extension_files : Array[String]
  sensitive_files : Array[String]
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `moon test tests/unit`
Expected: PASS and `.env` is classified as a sensitive blocked file

- [ ] **Step 5: Commit**

```bash
git add src/checkers tests/unit
git commit -m "feat：补充风险路径与文件类型检查器"
```

## Task 7: 实现材料存在性与有效性检查器

**Files:**
- Create: `src/infra/artifact_schema.mbt`
- Create: `src/checkers/artifact_checker.mbt`
- Test: `tests/unit/artifact_checker_test.mbt`

- [ ] **Step 1: Write the failing test**

```moonbit
test "artifact checker reports missing file" {
  let result = @checkers.check_artifacts(
    required_artifacts: ["test-report.json"],
    provided_artifacts: {},
  )
  assert_eq(result.missing_artifacts, ["test-report.json"])
}

test "artifact checker rejects empty markdown body" {
  let result = @checkers.validate_markdown_artifact("# API\n")
  assert_true(result is Err(_))
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `moon test tests/unit`
Expected: FAIL because artifact checker helpers are missing

- [ ] **Step 3: Write minimal implementation**

```moonbit
pub(all) struct ArtifactCheckResult {
  missing_artifacts : Array[String]
  invalid_artifacts : Array[String]
}

pub fn check_artifacts(
  required_artifacts : Array[String],
  provided_artifacts : Map[String, String],
) -> ArtifactCheckResult {
  let missing_artifacts : Array[String] = []
  for artifact in required_artifacts {
    if !provided_artifacts.contains(artifact) {
      missing_artifacts.push(artifact)
    }
  }
  { missing_artifacts, invalid_artifacts: [] }
}

pub fn validate_markdown_artifact(text : String) -> Result[Unit, String] {
  if text.trim().split("\n").length() <= 1 { Err("ARTIFACT_INVALID") } else { Ok(()) }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `moon test tests/unit`
Expected: PASS with one missing artifact and one invalid markdown artifact

- [ ] **Step 5: Commit**

```bash
git add src/infra src/checkers tests/unit
git commit -m "feat：补充材料缺失与材料无效检查器"
```

## Task 8: 实现正式结论构建器与结果物输出

**Files:**
- Create: `src/checkers/decision_builder.mbt`
- Create: `src/infra/run_store.mbt`
- Create: `src/infra/report_text.mbt`
- Test: `tests/unit/decision_builder_test.mbt`

- [ ] **Step 1: Write the failing test**

```moonbit
test "decision builder prefers reject over retryable" {
  let result = @checkers.build_decision(
    has_scope_reject=true,
    has_protected_path=false,
    has_approval=false,
    has_missing_artifacts=true,
  )
  assert_eq(result.code, "Reject")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `moon test tests/unit`
Expected: FAIL because `build_decision` is undefined

- [ ] **Step 3: Write minimal implementation**

```moonbit
pub fn build_decision(
  has_scope_reject : Bool,
  has_protected_path : Bool,
  has_approval : Bool,
  has_missing_artifacts : Bool,
) -> @domain.DecisionView {
  let decision =
    if has_scope_reject || has_protected_path {
      @domain.Reject
    } else if has_approval {
      @domain.NeedHumanApproval
    } else if has_missing_artifacts {
      @domain.Retryable
    } else {
      @domain.Accept
    }
  @domain.DecisionView::from_decision(decision)
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `moon test tests/unit`
Expected: PASS and reject takes priority over retryable

- [ ] **Step 5: Commit**

```bash
git add src/checkers src/infra tests/unit
git commit -m "feat：补充正式结论构建与结果物输出"
```

## Task 9: 实现 init 与 task 命令服务

**Files:**
- Create: `src/services/init_service.mbt`
- Create: `src/services/task_service.mbt`
- Modify: `src/services/commands.mbt`
- Test: `tests/integration/task_flow_test.mbt`

- [ ] **Step 1: Write the failing test**

```moonbit
test "init creates repo rules and five templates" {
  let repo = "tmp/init-service"
  ignore(@services.init_repo(repo))
  assert_true(@infra.path_exists(@infra.join_path(repo, ".moonforge/repo-rules.yml")))
  assert_true(@infra.path_exists(@infra.join_path(repo, ".moonforge/task-types/feature-change.yml")))
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `moon test tests/integration`
Expected: FAIL if template count or file paths are missing

- [ ] **Step 3: Write minimal implementation**

```moonbit
pub fn init_repo(repo_root : String) -> String raise {
  @infra.ensure_dir(@infra.join_path(repo_root, ".moonforge/task-types"))
  @infra.write_text(@infra.join_path(repo_root, ".moonforge/repo-rules.yml"), @services.render_default_repo_rules())
  for template in @services.default_templates() {
    @infra.write_text(
      @infra.join_path(repo_root, ".moonforge/task-types/\{template.name}.yml"),
      @services.render_task_template(template.template),
    )
  }
  "initialized"
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `moon test tests/integration`
Expected: PASS and all five templates are created

- [ ] **Step 5: Commit**

```bash
git add src/services tests/integration
git commit -m "feat：补充初始化与任务创建服务"
```

## Task 10: 实现 validate 与 check 命令服务

**Files:**
- Create: `src/services/validate_service.mbt`
- Create: `src/services/check_service.mbt`
- Modify: `src/services/commands.mbt`
- Test: `tests/integration/validate_flow_test.mbt`
- Test: `tests/integration/check_local_flow_test.mbt`

- [ ] **Step 1: Write the failing test**

```moonbit
test "validate rejects empty current task" {
  let repo = "tmp/validate-service"
  ignore(@services.init_repo(repo))
  @infra.write_text(@infra.join_path(repo, ".moonforge/current-task.yml"), "task_type: \"\"\n")
  let result = @services.validate_repo(repo)
  assert_true(result.contains("当前任务"))
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `moon test tests/integration`
Expected: FAIL because `validate_repo` is not implemented

- [ ] **Step 3: Write minimal implementation**

```moonbit
pub fn validate_repo(repo_root : String) -> String raise {
  let repo_rules = @services.load_repo_rules(repo_root)
  let current_task = @services.load_current_task(repo_root)
  ignore(repo_rules)
  @checkers.validate_current_task(current_task) catch {
    _ => raise Failure::Failure("当前任务非法")
  }
  "配置校验通过"
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `moon test tests/integration`
Expected: PASS and invalid task surfaces a Chinese validation message

- [ ] **Step 5: Commit**

```bash
git add src/services tests/integration
git commit -m "feat：补充仓库校验与本地检查服务"
```

## Task 11: 实现 report 与 replay 命令服务

**Files:**
- Create: `src/services/report_service.mbt`
- Create: `src/services/replay_service.mbt`
- Create: `src/checkers/replay_checker.mbt`
- Test: `tests/integration/replay_flow_test.mbt`

- [ ] **Step 1: Write the failing test**

```moonbit
test "replay reproduces latest decision" {
  let repo = "tmp/replay-service"
  let result = @services.replay_latest(repo, mode="local")
  assert_true(result.contains("回放"))
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `moon test tests/integration`
Expected: FAIL because replay service is missing

- [ ] **Step 3: Write minimal implementation**

```moonbit
pub fn replay_latest(repo_root : String, mode~ : String = "local") -> String raise {
  let latest_dir = @adapters.latest_output_dir(repo_root, mode)
  let gate_result = @infra.read_text(@infra.join_path(latest_dir, "gate-result.json"))
  if gate_result.contains("\"decision\"") {
    "回放完成"
  } else {
    raise Failure::Failure("回放失败")
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `moon test tests/integration`
Expected: PASS once replay reads a persisted result and returns `回放完成`

- [ ] **Step 5: Commit**

```bash
git add src/services src/checkers tests/integration
git commit -m "feat：补充报告读取与审计回放服务"
```

## Task 12: 实现 pack 与 doctor 命令服务

**Files:**
- Create: `src/services/pack_service.mbt`
- Create: `src/services/doctor_service.mbt`
- Test: `tests/integration/pack_flow_test.mbt`

- [ ] **Step 1: Write the failing test**

```moonbit
test "pack exports acceptance bundle" {
  let repo = "tmp/pack-service"
  let output = @services.export_acceptance_pack(repo, "tmp/out-pack")
  assert_true(output.contains("验收包"))
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `moon test tests/integration`
Expected: FAIL because pack service is undefined

- [ ] **Step 3: Write minimal implementation**

```moonbit
pub fn export_acceptance_pack(repo_root : String, out_dir : String) -> String raise {
  @infra.ensure_dir(out_dir)
  @infra.write_text(@infra.join_path(out_dir, "README.md"), "# 最小验收包\n")
  ignore(repo_root)
  "验收包导出完成"
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `moon test tests/integration`
Expected: PASS and acceptance pack contains a README marker

- [ ] **Step 5: Commit**

```bash
git add src/services tests/integration
git commit -m "feat：补充验收包导出与接入诊断服务"
```

## Task 13: 扩展 CLI 并接入双语终端输出

**Files:**
- Modify: `cmd/main/main.mbt`
- Test: `tests/e2e/cli_acceptance_test.mbt`

- [ ] **Step 1: Write the failing test**

```moonbit
test "cli exposes validate replay doctor and pack commands" {
  let help_text = @main.render_cli_help()
  assert_true(help_text.contains("validate"))
  assert_true(help_text.contains("replay"))
  assert_true(help_text.contains("doctor"))
  assert_true(help_text.contains("pack"))
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `moon test tests/e2e`
Expected: FAIL because the help renderer does not include the new commands

- [ ] **Step 3: Write minimal implementation**

```moonbit
fn cli() -> @argparse.Command {
  @argparse.Command(
    "moonforge",
    about="MoonForge Core 提交前门禁内核",
    version="0.2.0",
    arg_required_else_help=true,
    subcommand_required=true,
    subcommands=[
      @argparse.Command("init", about="初始化仓库规则与模板"),
      @argparse.Command("task", about="创建当前任务"),
      @argparse.Command("check", about="执行本地或 CI 门禁检查"),
      @argparse.Command("report", about="读取最近一次门禁结果"),
      @argparse.Command("validate", about="校验仓库规则、模板与当前任务"),
      @argparse.Command("replay", about="回放最近一次门禁结果"),
      @argparse.Command("doctor", about="诊断当前仓库接入状态"),
      @argparse.Command("pack", about="导出最小验收包"),
    ],
  )
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `moon test tests/e2e`
Expected: PASS and CLI help includes all new subcommands

- [ ] **Step 5: Commit**

```bash
git add cmd/main tests/e2e
git commit -m "feat：补充命令行扩展与双语终端输出"
```

## Task 14: 接入 GitHub 云端复核

**Files:**
- Create: `.github/workflows/moonforge-ci.yml`
- Create: `tests/integration/check_ci_flow_test.mbt`
- Modify: `src/adapters/git_ci_diff.mbt`
- Modify: `src/services/check_service.mbt`

- [ ] **Step 1: Write the failing test**

```moonbit
test "ci flow writes outputs under ci latest" {
  let repo = "tmp/ci-flow"
  let result = @services.run_check(repo, "tests/fixtures/scenarios/pass", mode="ci")
  assert_eq(result.decision.code, "Accept")
  assert_true(@infra.path_exists(@infra.join_path(repo, ".moonforge/out/ci/latest/gate-result.json")))
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `moon test tests/integration`
Expected: FAIL because CI mode does not yet write to `ci/latest`

- [ ] **Step 3: Write minimal implementation**

```yaml
name: moonforge-ci
on:
  pull_request:
  push:

jobs:
  gate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install MoonBit
        run: curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
      - name: Run MoonForge validate
        run: moon run cmd/main -- validate
      - name: Run MoonForge CI check
        run: moon run cmd/main -- check --mode ci --run tests/fixtures/scenarios/pass
```

- [ ] **Step 4: Run test to verify it passes**

Run: `moon test tests/integration`
Expected: PASS and CI mode writes outputs to `.moonforge/out/ci/latest`

- [ ] **Step 5: Commit**

```bash
git add .github/workflows src/adapters src/services tests/integration
git commit -m "feat：补充 GitHub 云端复核执行面"
```

## Task 15: 完成固定验收包与项目文档

**Files:**
- Create: `examples/expected-inputs/pass/patch.diff`
- Create: `examples/expected-inputs/reject/patch.diff`
- Create: `examples/expected-inputs/retryable/patch.diff`
- Create: `examples/expected-inputs/approval/patch.diff`
- Create: `examples/expected-outputs/pass/gate-result.json`
- Create: `examples/expected-outputs/reject/gate-result.json`
- Create: `examples/expected-outputs/retryable/gate-result.json`
- Create: `examples/expected-outputs/approval/gate-result.json`
- Create: `docs/acceptance/matrix.md`
- Modify: `README.mbt.md`

- [ ] **Step 1: Write the failing test**

```moonbit
test "acceptance matrix covers four official outcomes" {
  let matrix = @infra.read_text("docs/acceptance/matrix.md")
  assert_true(matrix.contains("Accept"))
  assert_true(matrix.contains("Retryable"))
  assert_true(matrix.contains("Reject"))
  assert_true(matrix.contains("NeedHumanApproval"))
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `moon test tests/e2e`
Expected: FAIL because acceptance matrix and fixtures are missing

- [ ] **Step 3: Write minimal implementation**

```markdown
# MoonForge Core 验收矩阵

| 场景 | 预期结论 |
| --- | --- |
| 范围合法且材料齐全 | Accept |
| 范围合法但材料缺失 | Retryable |
| 命中受保护目录 | Reject |
| 命中审批目录 | NeedHumanApproval |
```

- [ ] **Step 4: Run test to verify it passes**

Run: `moon test tests/e2e`
Expected: PASS and acceptance matrix documents all four official outcomes

- [ ] **Step 5: Commit**

```bash
git add examples docs/acceptance README.mbt.md tests/e2e
git commit -m "feat：补充最小验收包与验收矩阵文档"
```

## 规格覆盖自检

### 与规格文档逐项映射

- 项目书四主命令由 Task 9、Task 10、Task 11、Task 13 覆盖
- `validate / replay / pack / doctor` 由 Task 10、Task 11、Task 12、Task 13 覆盖
- `5 个验收域 + 12 个固定场景` 由 Task 2 到 Task 8 的检查器与验证器覆盖
- GitHub 云端复核由 Task 4、Task 10、Task 14 覆盖
- 审计结果物由 Task 8、Task 11 覆盖
- 最小验收包由 Task 12、Task 15 覆盖
- 双语输出由 Task 1、Task 8、Task 13 覆盖
- 低交互路径组与默认工作流由 Task 3、Task 9、Task 13 覆盖

### 占位符扫描

- 无 `TODO`
- 无 `TBD`
- 无“稍后补充”
- 每个任务都包含实际文件路径、测试命令和提交命令

### 类型一致性检查

- 所有正式结论统一通过 `DecisionView` 暴露
- 所有违规项统一保留英文编码和中文解释
- `CurrentTask` 同时支持 `target_groups` 与 `target_paths`
- `check` 本地与 CI 只通过适配器分流，不复制结论逻辑
