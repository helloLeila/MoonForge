///|
/// 文件说明：验证门禁主流程的集成行为，覆盖通过、拒绝、补齐后重试和人工审批四类场景。
/// 联动文件：直接调用 `src/services/commands.mbt` 的命令编排逻辑，并依赖 `src/checkers/gate.mbt` 对应的判定结果。

///|

///|
/// 为每条集成测试生成互不干扰的临时仓库目录。
fn unique_repo_root(label : String) -> String {
  @infra.join_path("tmp", "moonforge-\{label}-\{@uv.hrtime()}")
}

///|
/// 初始化最小示例仓库文件，供门禁流程读取路径上下文。
fn seed_repo(repo_root : String) -> Unit raise {
  @infra.write_text(
    @infra.join_path(repo_root, "frontend/src/pages/UserList/index.tsx"),
    "export const userListPage = true\n",
  )
  @infra.write_text(
    @infra.join_path(repo_root, "frontend/src/components/DepartmentFilter.tsx"),
    "export const departmentFilter = true\n",
  )
  @infra.write_text(
    @infra.join_path(
      repo_root, "backend/src/main/java/com/acme/common/security/AuthFilter.java",
    ),
    "public final class AuthFilter {}\n",
  )
  @infra.write_text(
    @infra.join_path(
      repo_root, "backend/src/main/java/com/acme/user/service/high-risk/UserAuditService.java",
    ),
    "public final class UserAuditService {}\n",
  )
}

///|
/// 初始化一个最小 React 首页仓库，用于覆盖 pre-commit 规则场景。
fn seed_homepage_repo(repo_root : String) -> Unit raise {
  @infra.write_text(
    @infra.join_path(repo_root, "src/components/WorkLinks.jsx"),
    "export function WorkLinks() {\n  return \"links\"\n}\n",
  )
  @infra.write_text(
    @infra.join_path(repo_root, "src/data/siteContent.js"),
    "export const siteContent = { workLinks: [] }\n",
  )
  @infra.write_text(
    @infra.join_path(repo_root, "src/core/request.js"),
    "export const request = () => \"ok\"\n",
  )
}

///|
/// 创建功能变更模板对应的当前任务，并允许测试用例注入不同目标路径。
fn feature_task(repo_root : String, paths_csv : String) -> Unit raise {
  ignore(@services.init_repo(repo_root))
  ignore(
    @services.create_task(
      repo_root, "feature-change", "Add department filter", paths_csv,
    ),
  )
}

///|
/// 构造一个完全合法的通过场景 diff。
fn pass_diff() -> String {
  let diff =
    #|diff --git a/frontend/src/pages/UserList/index.tsx b/frontend/src/pages/UserList/index.tsx
    #|index 1111111..2222222 100644
    #|--- a/frontend/src/pages/UserList/index.tsx
    #|+++ b/frontend/src/pages/UserList/index.tsx
    #|@@ -1,1 +1,2 @@
    #| export const userListPage = true
    #|+export const departmentFilterEnabled = true
    #|
    #|diff --git a/frontend/src/components/DepartmentFilter.tsx b/frontend/src/components/DepartmentFilter.tsx
    #|index 3333333..4444444 100644
    #|--- a/frontend/src/components/DepartmentFilter.tsx
    #|+++ b/frontend/src/components/DepartmentFilter.tsx
    #|@@ -1,1 +1,2 @@
    #| export const departmentFilter = true
    #|+export const renderDepartmentFilter = () => "ok"
    #|
  diff
}

///|
/// 构造一个触碰受保护目录的拒绝场景 diff。
fn reject_diff() -> String {
  let diff =
    #|diff --git a/backend/src/main/java/com/acme/common/security/AuthFilter.java b/backend/src/main/java/com/acme/common/security/AuthFilter.java
    #|index 3333333..4444444 100644
    #|--- a/backend/src/main/java/com/acme/common/security/AuthFilter.java
    #|+++ b/backend/src/main/java/com/acme/common/security/AuthFilter.java
    #|@@ -1,1 +1,2 @@
    #| public final class AuthFilter {}
    #|+public final class AuthFilter { private boolean patched = true; }
    #|
  diff
}

///|
/// 构造一个需要人工审批但不应直接拒绝的高风险 diff。
fn manual_approval_diff() -> String {
  let diff =
    #|diff --git a/backend/src/main/java/com/acme/user/service/high-risk/UserAuditService.java b/backend/src/main/java/com/acme/user/service/high-risk/UserAuditService.java
    #|index 5555555..6666666 100644
    #|--- a/backend/src/main/java/com/acme/user/service/high-risk/UserAuditService.java
    #|+++ b/backend/src/main/java/com/acme/user/service/high-risk/UserAuditService.java
    #|@@ -1,1 +1,2 @@
    #| public final class UserAuditService {}
    #|+public final class UserAuditService { private boolean requiresHumanApproval = true; }
    #|
  diff
}

///|
/// 根据不同测试场景写入 patch 和材料文件。
fn seed_run(
  run_dir : String,
  diff_text : String,
  include_test_report? : Bool = true,
  include_review_report? : Bool = true,
) -> Unit raise {
  @infra.write_text(@infra.join_path(run_dir, "patch.diff"), diff_text)
  if include_test_report {
    @infra.write_text(
      @infra.join_path(run_dir, "test-report.json"),
      "{\n  \"passed\": true,\n  \"suite\": \"demo\"\n}\n",
    )
  }
  if include_review_report {
    @infra.write_text(
      @infra.join_path(run_dir, "review-report.json"),
      "{\n  \"reviewer\": \"leila\",\n  \"status\": \"approved\"\n}\n",
    )
  }
}

///|
/// 写入收紧后的 React 首页规则，用于覆盖 AI coding 的高频 pre-commit 问题。
fn seed_homepage_rules(repo_root : String) -> Unit raise {
  let repo_rules =
    #|protected_paths:
    #|  - "src/core/**"
    #|approval_required_paths:
    #|default_allowed_extensions:
    #|  - ".js"
    #|  - ".jsx"
    #|blocked_extensions:
    #|  - ".map"
    #|  - ".snap"
    #|generated_artifact_paths:
    #|  - "dist/**"
    #|  - "build/**"
    #|  - "coverage/**"
    #|  - ".next/**"
    #|blocked_file_names:
    #|  - ".DS_Store"
    #|blocked_file_patterns:
    #|content_blocklist_patterns:
    #|  - "console.log"
    #|  - "debugger"
    #|  - "printf"
    #|  - "println"
    #|  - "TODO"
    #|  - "FIXME"
    #|max_changed_files: 2
    #|path_groups.homepage_links:
    #|  - "src/components/WorkLinks.jsx"
    #|  - "src/data/siteContent.js"
    #|
  let template =
    #|task_type: homepage-links
    #|
    #|allowed_paths:
    #|  - "src/components/WorkLinks.jsx"
    #|  - "src/data/siteContent.js"
    #|  - "dist/**"
    #|
    #|forbidden_paths:
    #|
    #|allowed_extensions:
    #|  - ".js"
    #|  - ".jsx"
    #|
    #|required_artifacts:
    #|  - "preview-report.json"
    #|
    #|required_commands:
    #|  - "test -f src/components/WorkLinks.jsx"
    #|
    #|max_changed_files: 2
    #|
    #|manual_approval_paths:
    #|
  let artifact_schema =
    #|artifact_name: preview-report.json
    #|
    #|required_fields:
    #|  - "section"
    #|  - "status"
    #|  - "summary"
    #|
    #|optional_fields:
    #|
    #|allowed_values:
    #|
  ignore(@services.init_repo(repo_root))
  @infra.write_text(
    @infra.join_path(repo_root, ".moonforge/repo-rules.yml"),
    repo_rules,
  )
  @infra.write_text(
    @infra.join_path(repo_root, ".moonforge/task-types/homepage-links.yml"),
    template,
  )
  @infra.write_text(
    @infra.join_path(
      repo_root, ".moonforge/artifact-schemas/preview-report.yml",
    ),
    artifact_schema,
  )
}

///|
/// 创建 React 首页链接变更任务。
fn homepage_task(repo_root : String, paths_csv : String) -> Unit raise {
  ignore(
    @services.create_task(
      repo_root, "homepage-links", "Update homepage links", paths_csv,
    ),
  )
}

///|
/// 构造一个合法的首页链接更新 diff。
fn homepage_pass_diff() -> String {
  let diff =
    #|diff --git a/src/components/WorkLinks.jsx b/src/components/WorkLinks.jsx
    #|index 1111111..2222222 100644
    #|--- a/src/components/WorkLinks.jsx
    #|+++ b/src/components/WorkLinks.jsx
    #|@@ -1,3 +1,4 @@
    #| export function WorkLinks() {
    #|+  const links = ["github"]
    #|   return "links"
    #| }
    #|
  diff
}

///|
/// 构造一个包含调试残留的首页 diff。
fn homepage_debug_diff() -> String {
  let diff =
    #|diff --git a/src/components/WorkLinks.jsx b/src/components/WorkLinks.jsx
    #|index 1111111..2222222 100644
    #|--- a/src/components/WorkLinks.jsx
    #|+++ b/src/components/WorkLinks.jsx
    #|@@ -1,3 +1,4 @@
    #| export function WorkLinks() {
    #|+  console.log("debug links")
    #|   return "links"
    #| }
    #|
  diff
}

///|
/// 构造一个误提交生成产物的 diff。
fn homepage_generated_artifact_diff() -> String {
  let diff =
    #|diff --git a/dist/assets/index.js b/dist/assets/index.js
    #|new file mode 100644
    #|--- /dev/null
    #|+++ b/dist/assets/index.js
    #|@@ -0,0 +1,1 @@
    #|+console.log("built")
    #|
  diff
}

///|
/// 写入 React 首页运行目录的 patch 和预览材料。
fn seed_homepage_run(
  run_dir : String,
  diff_text : String,
  preview_content? : String = "{\n  \"section\": \"worklinks\",\n  \"status\": \"ok\",\n  \"summary\": \"preview checked\"\n}\n",
) -> Unit raise {
  @infra.write_text(@infra.join_path(run_dir, "patch.diff"), diff_text)
  @infra.write_text(
    @infra.join_path(run_dir, "preview-report.json"),
    preview_content,
  )
}

///|
/// 验证合法变更且材料齐全时，会输出允许放行结论和结果文件。
test "feature change pass flow writes accept outputs" {
  let repo_root = unique_repo_root("pass")
  let run_dir = @infra.join_path(repo_root, "fixture-runs/pass")
  try {
    seed_repo(repo_root)
    feature_task(repo_root, "frontend/src/pages/**,frontend/src/components/**")
    seed_run(run_dir, pass_diff())

    let result = @services.run_check(repo_root, run_dir)
    assert_true(result.decision == @domain.Accept)
    assert_true(
      @infra.path_exists(
        @infra.join_path(
          repo_root, ".moonforge/out/local/latest/gate-result.json",
        ),
      ),
    )
    let report = @services.report_latest(repo_root)
    assert_true(report.contains("Accept"))
  } catch {
    err => {
      println(err.to_string())
      panic()
    }
  }
}

///|
/// 验证必需校验命令失败时，会进入 Retryable 分支而不是直接拒绝。
test "required command failure becomes retryable" {
  let repo_root = unique_repo_root("command-retry")
  let run_dir = @infra.join_path(repo_root, "fixture-runs/command-retry")
  let failing_template =
    #|task_type: homepage-links
    #|
    #|allowed_paths:
    #|  - "src/components/WorkLinks.jsx"
    #|  - "src/data/siteContent.js"
    #|
    #|forbidden_paths:
    #|
    #|allowed_extensions:
    #|  - ".js"
    #|  - ".jsx"
    #|
    #|required_artifacts:
    #|  - "preview-report.json"
    #|
    #|required_commands:
    #|  - "test -f missing.file"
    #|
    #|max_changed_files: 2
    #|
    #|manual_approval_paths:
    #|
  try {
    seed_homepage_repo(repo_root)
    seed_homepage_rules(repo_root)
    @infra.write_text(
      @infra.join_path(repo_root, ".moonforge/task-types/homepage-links.yml"),
      failing_template,
    )
    homepage_task(
      repo_root, "src/components/WorkLinks.jsx,src/data/siteContent.js",
    )
    seed_homepage_run(run_dir, homepage_pass_diff())

    let result = @services.run_check(repo_root, run_dir)
    assert_true(result.decision == @domain.Retryable)
    assert_true(
      result.violations.any(fn(item) { item.code == "REQUIRED_COMMAND_FAILED" }),
    )
  } catch {
    err => {
      println(err.to_string())
      panic()
    }
  }
}

///|
/// 验证误提交生成产物时，会命中生成物拦截而直接拒绝。
test "generated artifact path becomes reject" {
  let repo_root = unique_repo_root("generated-artifact")
  let run_dir = @infra.join_path(repo_root, "fixture-runs/generated-artifact")
  try {
    seed_homepage_repo(repo_root)
    seed_homepage_rules(repo_root)
    homepage_task(
      repo_root, "src/components/WorkLinks.jsx,src/data/siteContent.js",
    )
    seed_homepage_run(run_dir, homepage_generated_artifact_diff())

    let result = @services.run_check(repo_root, run_dir)
    assert_true(result.decision == @domain.Reject)
    assert_true(
      result.violations.any(fn(item) {
        item.code == "GENERATED_ARTIFACT_TOUCHED"
      }),
    )
  } catch {
    err => {
      println(err.to_string())
      panic()
    }
  }
}

///|
/// 验证调试残留会在提交前被直接拦截。
test "debug residue becomes reject" {
  let repo_root = unique_repo_root("debug-residue")
  let run_dir = @infra.join_path(repo_root, "fixture-runs/debug-residue")
  try {
    seed_homepage_repo(repo_root)
    seed_homepage_rules(repo_root)
    homepage_task(
      repo_root, "src/components/WorkLinks.jsx,src/data/siteContent.js",
    )
    seed_homepage_run(run_dir, homepage_debug_diff())

    let result = @services.run_check(repo_root, run_dir)
    assert_true(result.decision == @domain.Reject)
    assert_true(
      result.violations.any(fn(item) { item.code == "CONTENT_PATTERN_BLOCKED" }),
    )
  } catch {
    err => {
      println(err.to_string())
      panic()
    }
  }
}

///|
/// 验证预览材料存在但结构不合法时，会要求修复后重试。
test "invalid preview artifact becomes retryable" {
  let repo_root = unique_repo_root("artifact-invalid")
  let run_dir = @infra.join_path(repo_root, "fixture-runs/artifact-invalid")
  try {
    seed_homepage_repo(repo_root)
    seed_homepage_rules(repo_root)
    homepage_task(
      repo_root, "src/components/WorkLinks.jsx,src/data/siteContent.js",
    )
    seed_homepage_run(
      run_dir,
      homepage_pass_diff(),
      preview_content="{\n  \"section\": \"worklinks\",\n  \"summary\": \"missing status\"\n}\n",
    )

    let result = @services.run_check(repo_root, run_dir)
    assert_true(result.decision == @domain.Retryable)
    assert_true(
      result.violations.any(fn(item) { item.code == "ARTIFACT_INVALID" }),
    )
  } catch {
    err => {
      println(err.to_string())
      panic()
    }
  }
}

///|
/// 验证缺少审查材料时，会进入补齐后重试分支。
test "feature change missing artifact becomes retryable" {
  let repo_root = unique_repo_root("retry")
  let run_dir = @infra.join_path(repo_root, "fixture-runs/retry")
  try {
    seed_repo(repo_root)
    feature_task(repo_root, "frontend/src/pages/**,frontend/src/components/**")
    seed_run(run_dir, pass_diff(), include_review_report=false)

    let result = @services.run_check(repo_root, run_dir)
    assert_true(result.decision == @domain.Retryable)
    assert_eq(result.missing_artifacts, ["review-report.json"])
  } catch {
    err => {
      println(err.to_string())
      panic()
    }
  }
}

///|
/// 验证默认 config-change 模板允许提交 `.env.example`，不应被后缀规则误杀。
test "config change allows dot example file" {
  let repo_root = unique_repo_root("config-example")
  let run_dir = @infra.join_path(repo_root, "fixture-runs/config-example")
  let diff =
    #|diff --git a/.env.example b/.env.example
    #|index 7777777..8888888 100644
    #|--- a/.env.example
    #|+++ b/.env.example
    #|@@ -1,1 +1,2 @@
    #| APP_NAME=MoonForge
    #|+APP_MODE=demo
    #|
  try {
    seed_repo(repo_root)
    @infra.write_text(
      @infra.join_path(repo_root, ".env.example"),
      "APP_NAME=MoonForge\n",
    )
    ignore(@services.init_repo(repo_root))
    ignore(
      @services.create_task(
        repo_root, "config-change", "Adjust env example", ".env.example",
      ),
    )
    @infra.write_text(@infra.join_path(run_dir, "patch.diff"), diff)
    @infra.write_text(
      @infra.join_path(run_dir, "config-impact.md"),
      "# Config Impact\n\nUpdate env example.\n",
    )

    let result = @services.run_check(repo_root, run_dir)
    assert_true(result.decision == @domain.Accept)
    assert_eq(result.forbidden_extension_files, [])
  } catch {
    err => {
      println(err.to_string())
      panic()
    }
  }
}

///|
/// 验证 repo-rules 中的路径组和更严格文件上限，会通过加载链路影响最终门禁结果。
test "repo rules path groups and stricter max file count affect run check" {
  let repo_root = unique_repo_root("repo-rules")
  let run_dir = @infra.join_path(repo_root, "fixture-runs/repo-rules")
  try {
    seed_repo(repo_root)
    ignore(@services.init_repo(repo_root))
    let repo_rules_text =
      #|protected_paths:
      #|  - "backend/src/main/java/**/security/**"
      #|  - "infra/**"
      #|approval_required_paths:
      #|  - "backend/src/main/java/**/service/high-risk/**"
      #|default_allowed_extensions:
      #|  - ".java"
      #|  - ".ts"
      #|  - ".tsx"
      #|  - ".md"
      #|  - ".json"
      #|max_changed_files: 1
      #|path_groups.frontend_user_pages:
      #|  - "frontend/src/pages/**"
      #|path_groups.frontend_components:
      #|  - "frontend/src/components/**"
      #|
    @infra.write_text(
      @infra.join_path(repo_root, ".moonforge/repo-rules.yml"),
      repo_rules_text,
    )
    let current_task_text =
      #|task_type: feature-change
      #|title: "Group scoped task"
      #|target_groups:
      #|  - "frontend_user_pages"
      #|  - "frontend_components"
      #|target_paths:
      #|
    @infra.write_text(
      @infra.join_path(repo_root, ".moonforge/current-task.yml"),
      current_task_text,
    )
    seed_run(run_dir, pass_diff())

    let result = @services.run_check(repo_root, run_dir)
    assert_true(result.decision == @domain.Reject)
    assert_true(result.changed_file_count_exceeded)
    assert_eq(result.effective_task.allowed_paths, [
      "frontend/src/pages/**", "frontend/src/components/**",
    ])
    assert_eq(result.effective_task.max_changed_files, 1)
  } catch {
    err => {
      println(err.to_string())
      panic()
    }
  }
}

///|
/// 验证 CI 模式会通过 GitHub 环境与 CI 适配器读取补丁输入。
test "ci mode reads diff through ci adapter" {
  let repo_root = unique_repo_root("ci")
  let run_dir = @infra.join_path(repo_root, "fixture-runs/ci")
  try {
    seed_repo(repo_root)
    feature_task(repo_root, "frontend/src/pages/**,frontend/src/components/**")
    seed_run(run_dir, pass_diff())

    @env.set_env_var("GITHUB_ACTIONS", "true")
    let result = @services.run_check(repo_root, run_dir, mode="ci")
    @env.unset_env_var("GITHUB_ACTIONS")

    assert_true(result.decision == @domain.Accept)
  } catch {
    err => {
      @env.unset_env_var("GITHUB_ACTIONS")
      println(err.to_string())
      panic()
    }
  }
}

///|
/// 验证 PR 复检模式会记录 base/head 信息，并把上下文写入独立输出目录。
test "pr mode writes run context and report summary" {
  let repo_root = unique_repo_root("pr")
  let run_dir = @infra.join_path(repo_root, "fixture-runs/pr")
  try {
    seed_repo(repo_root)
    feature_task(repo_root, "frontend/src/pages/**,frontend/src/components/**")
    seed_run(run_dir, pass_diff())

    @env.set_env_var("GITHUB_ACTIONS", "true")
    @env.set_env_var("GITHUB_EVENT_NAME", "pull_request")
    @env.set_env_var("GITHUB_BASE_REF", "main")
    @env.set_env_var("GITHUB_HEAD_REF", "feature/search")

    let result = @services.run_check(repo_root, run_dir, mode="pr")
    let context_text = @infra.read_text(
      @infra.join_path(repo_root, ".moonforge/out/pr/latest/run-context.json"),
    )
    let summary = @services.report_summary(repo_root, mode="pr")

    @env.unset_env_var("GITHUB_ACTIONS")
    @env.unset_env_var("GITHUB_EVENT_NAME")
    @env.unset_env_var("GITHUB_BASE_REF")
    @env.unset_env_var("GITHUB_HEAD_REF")

    assert_true(result.decision == @domain.Accept)
    assert_true(context_text.contains("\"mode\": \"pr\""))
    assert_true(context_text.contains("\"base_ref\": \"main\""))
    assert_true(context_text.contains("\"head_ref\": \"feature/search\""))
    assert_true(summary.contains("main"))
    assert_true(summary.contains("feature/search"))
    assert_true(summary.contains("变更文件：2"))
  } catch {
    err => {
      @env.unset_env_var("GITHUB_ACTIONS")
      @env.unset_env_var("GITHUB_EVENT_NAME")
      @env.unset_env_var("GITHUB_BASE_REF")
      @env.unset_env_var("GITHUB_HEAD_REF")
      println(err.to_string())
      panic()
    }
  }
}

///|
/// 验证缺少材料的重试结果会在 report 摘要里展示缺失数量。
test "retry summary shows missing artifact count" {
  let repo_root = unique_repo_root("retry-summary")
  let run_dir = @infra.join_path(repo_root, "fixture-runs/retry-summary")
  try {
    seed_repo(repo_root)
    feature_task(repo_root, "frontend/src/pages/**,frontend/src/components/**")
    seed_run(run_dir, pass_diff(), include_review_report=false)

    let result = @services.run_check(repo_root, run_dir)
    let summary = @services.report_summary(repo_root)

    assert_true(result.decision == @domain.Retryable)
    assert_true(summary.contains("Retryable"))
    assert_true(summary.contains("缺失材料：1"))
  } catch {
    err => {
      println(err.to_string())
      panic()
    }
  }
}

///|
/// 验证触碰安全目录时，会命中受保护路径拒绝规则。
test "touching protected path becomes reject" {
  let repo_root = unique_repo_root("reject")
  let run_dir = @infra.join_path(repo_root, "fixture-runs/reject")
  try {
    seed_repo(repo_root)
    feature_task(repo_root, "frontend/src/pages/**,frontend/src/components/**")
    seed_run(run_dir, reject_diff())

    let result = @services.run_check(repo_root, run_dir)
    assert_true(result.decision == @domain.Reject)
    assert_true(
      result.protected_files.contains(
        "backend/src/main/java/com/acme/common/security/AuthFilter.java",
      ),
    )
  } catch {
    err => {
      println(err.to_string())
      panic()
    }
  }
}

///|
/// 验证高风险服务目录在任务范围内时，会进入人工审批而不是直接拒绝。
test "high risk path becomes need human approval" {
  let repo_root = unique_repo_root("approval")
  let run_dir = @infra.join_path(repo_root, "fixture-runs/approval")
  try {
    seed_repo(repo_root)
    feature_task(
      repo_root, "frontend/src/pages/**,frontend/src/components/**,backend/src/main/java/com/acme/user/service/**",
    )
    seed_run(run_dir, manual_approval_diff())

    let result = @services.run_check(repo_root, run_dir)
    assert_true(result.decision == @domain.NeedHumanApproval)
    assert_true(
      result.approval_required_files.contains(
        "backend/src/main/java/com/acme/user/service/high-risk/UserAuditService.java",
      ),
    )
  } catch {
    err => {
      println(err.to_string())
      panic()
    }
  }
}
