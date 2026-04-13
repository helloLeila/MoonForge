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
