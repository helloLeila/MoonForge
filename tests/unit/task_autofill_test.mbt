///|
/// 文件总说：
/// 这个文件直接测试 task 自动补全服务本身。
/// 我们不走完整 CLI，只验证最关键的几件事：
/// 1. 命令行草稿能不能正确拆成标题、路径组和显式路径
/// 2. 系统能不能根据暂存文件自动猜出标题和范围
/// 3. 用户手工指定内容时，系统会不会乱改

///|
/// 生成一份最小仓库规则，供自动补全测试复用。
fn sample_repo_rules() -> @domain.RepoRules {
  @domain.RepoRules::{
    protected_paths: [],
    approval_required_paths: [],
    blocked_extensions: [],
    generated_artifact_paths: [],
    blocked_file_names: [],
    blocked_file_patterns: [],
    content_blocklist_patterns: [],
    default_allowed_extensions: [".ts", ".tsx", ".md", ".json"],
    path_groups: {
      "frontend_pages": ["frontend/src/pages/**"],
      "frontend_components": ["frontend/src/components/**"],
    },
    max_changed_files: None,
  }
}

///|
/// 生成一份最小任务模板，供自动补全测试复用。
fn sample_template() -> @domain.TaskTemplate {
  @domain.TaskTemplate::{
    task_type: "feature-change",
    allowed_paths: ["frontend/src/pages/**", "frontend/src/components/**"],
    forbidden_paths: [],
    allowed_extensions: [".ts", ".tsx", ".json"],
    required_artifacts: ["test-report.json", "review-report.json"],
    required_commands: ["moon test"],
    max_changed_files: 8,
    manual_approval_paths: [],
  }
}

///|
/// 生成一份包含两个暂存文件的 git 快照。
fn sample_snapshot() -> @domain.GitProjectSnapshot {
  @domain.GitProjectSnapshot::{
    repo_root: "/tmp/project",
    branch_name: "feature/demo",
    staged_files: [
      "frontend/src/pages/UserList/index.tsx", "frontend/src/components/UserCard.tsx",
    ],
    unstaged_files: [],
    untracked_files: [],
    status_entries: [],
    staged_diff: "diff --git a/frontend/src/pages/UserList/index.tsx b/frontend/src/pages/UserList/index.tsx",
  }
}

///|
/// task 草稿种子应把 `@group` 和普通路径拆清楚。
test "task draft seed splits groups and paths" {
  let seed = @services.build_current_task_draft_seed(
    "feature-change", "", "@frontend_pages,frontend/src/components/**",
  )

  assert_eq(seed.manual_target_groups, ["frontend_pages"])
  assert_eq(seed.manual_target_paths, ["frontend/src/components/**"])
  assert_true(!seed.has_manual_title())
  assert_true(seed.has_manual_scope())
}

///|
/// 自动补全应根据暂存文件生成标题、路径组和默认材料。
test "task autofill plan infers title scope artifacts and commands" {
  let seed = @services.build_current_task_draft_seed("feature-change", "", "")
  let plan = @services.build_task_autofill_plan(
    seed,
    sample_repo_rules(),
    sample_template(),
    sample_snapshot(),
    "42",
  )
  let task = plan.to_current_task()

  assert_true(task.title != "")
  assert_eq(task.title_source, "auto_from_staged_files")
  assert_true(task.target_groups.contains("frontend_pages"))
  assert_true(task.target_groups.contains("frontend_components"))
  assert_eq(task.required_artifacts, ["test-report.json", "review-report.json"])
  assert_eq(task.required_commands, ["moon test"])
  assert_eq(task.check_mode, "local")
  assert_eq(task.artifact_dir, ".moonforge/artifacts/current")
  assert_true(task.auto_inferred_fields.contains("title"))
}

///|
/// 用户手工给出标题和范围时，系统应保留人工输入，不要自作主张覆盖。
test "task autofill plan keeps manual title and scope" {
  let seed = @services.build_current_task_draft_seed(
    "feature-change", "手工标题", "@frontend_pages",
  )
  let plan = @services.build_task_autofill_plan(
    seed,
    sample_repo_rules(),
    sample_template(),
    sample_snapshot(),
    "43",
  )
  let task = plan.to_current_task()

  assert_eq(task.title, "手工标题")
  assert_eq(task.title_source, "manual_input")
  assert_eq(task.target_groups, ["frontend_pages"])
  assert_true(task.notes.contains("当前标题来自命令行输入"))
  assert_true(task.notes.contains("当前范围来自命令行输入"))
}
