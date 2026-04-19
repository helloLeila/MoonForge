///|
/// 文件说明：覆盖路径组展开与任务上限合并的基础行为，先用红测锁定缺失能力。
/// 输入：路径组映射与候选组名称，或两个任务上限值。
/// 输出：展开后的具体 glob 列表，或更严格的文件上限。

///|
/// 路径组展开应返回命中的具体 glob，并保持原始顺序。
test "path group expansion returns concrete globs" {
  let groups : Map[String, Array[String]] = {
    "frontend_user_pages": ["frontend/src/pages/UserList/**"],
  }
  let expanded = @infra.expand_target_groups(groups, ["frontend_user_pages"])
  assert_eq(expanded, ["frontend/src/pages/UserList/**"])
}

///|
/// 生效任务合并应把目标组展开结果并入最终允许路径。
test "effective task merge expands target groups into allowed paths" {
  let repo_rules = @domain.RepoRules::{
    protected_paths: ["infra/**"],
    approval_required_paths: ["backend/src/main/java/**/service/high-risk/**"],
    blocked_extensions: [],
    generated_artifact_paths: [],
    blocked_file_names: [],
    blocked_file_patterns: [],
    content_blocklist_patterns: [],
    default_allowed_extensions: [".ts", ".tsx", ".md"],
    max_changed_files: None,
    path_groups: {
      "frontend_user_pages": [
        "frontend/src/pages/UserList/**", "frontend/src/pages/UserDetail/**",
      ],
    },
  }
  let template = @domain.TaskTemplate::{
    task_type: "feature-change",
    allowed_paths: ["frontend/src/pages/**", "frontend/src/components/**"],
    forbidden_paths: [],
    allowed_extensions: [".ts", ".tsx", ".md"],
    required_artifacts: ["test-report.json"],
    required_commands: [],
    max_changed_files: 8,
    manual_approval_paths: [],
  }
  let current_task = @domain.CurrentTask::{
    task_type: "feature-change",
    title: "Refine user pages",
    title_source: "manual_input",
    target_groups: ["frontend_user_pages"],
    target_paths: ["frontend/src/components/UserCard/**"],
    target_path_source: "manual_input",
    staged_files: [],
    required_artifacts: [],
    required_commands: [],
    artifact_dir: ".moonforge/artifacts/current",
    check_mode: "local",
    auto_inferred_fields: [],
    notes: [],
    need_user_review: false,
    last_auto_fill_ns: "1",
  }

  let effective = @checkers.build_effective_task(
    repo_rules, template, current_task,
  )
  assert_eq(effective.allowed_paths, [
    "frontend/src/pages/UserList/**", "frontend/src/pages/UserDetail/**", "frontend/src/components/UserCard/**",
  ])
}

///|
/// 生效任务合并应拒绝任何试图越过模板默认边界的显式目标。
test "effective task merge rejects explicit targets outside template scope" {
  let repo_rules = @domain.RepoRules::{
    protected_paths: ["infra/**"],
    approval_required_paths: [],
    blocked_extensions: [],
    generated_artifact_paths: [],
    blocked_file_names: [],
    blocked_file_patterns: [],
    content_blocklist_patterns: [],
    default_allowed_extensions: [".ts", ".tsx", ".md"],
    max_changed_files: None,
    path_groups: {
      "mixed_targets": [
        "frontend/src/pages/UserList/**", "backend/src/main/java/**/service/**",
      ],
    },
  }
  let template = @domain.TaskTemplate::{
    task_type: "feature-change",
    allowed_paths: ["frontend/src/pages/**"],
    forbidden_paths: [],
    allowed_extensions: [".ts", ".tsx", ".md"],
    required_artifacts: ["test-report.json"],
    required_commands: [],
    max_changed_files: 8,
    manual_approval_paths: [],
  }
  let current_task = @domain.CurrentTask::{
    task_type: "feature-change",
    title: "Refine user page",
    title_source: "manual_input",
    target_groups: ["mixed_targets"],
    target_paths: ["frontend/src/components/UserCard/**"],
    target_path_source: "manual_input",
    staged_files: [],
    required_artifacts: [],
    required_commands: [],
    artifact_dir: ".moonforge/artifacts/current",
    check_mode: "local",
    auto_inferred_fields: [],
    notes: [],
    need_user_review: false,
    last_auto_fill_ns: "1",
  }

  try {
    ignore(@checkers.build_effective_task(repo_rules, template, current_task))
    panic()
  } catch {
    err => assert_true(err.to_string().contains("TASK_SCOPE_INVALID"))
  }
}

///|
/// 有效任务合并应保留更严格的文件数上限。
test "effective task merge keeps stricter max file count" {
  let repo_rules = @domain.RepoRules::{
    protected_paths: ["infra/**"],
    approval_required_paths: [],
    blocked_extensions: [],
    generated_artifact_paths: [],
    blocked_file_names: [],
    blocked_file_patterns: [],
    content_blocklist_patterns: [],
    default_allowed_extensions: [".ts", ".tsx", ".md"],
    max_changed_files: Some(3),
    path_groups: { "frontend_user_pages": ["frontend/src/pages/UserList/**"] },
  }
  let template = @domain.TaskTemplate::{
    task_type: "feature-change",
    allowed_paths: ["frontend/src/pages/**"],
    forbidden_paths: [],
    allowed_extensions: [".ts", ".tsx", ".md"],
    required_artifacts: ["test-report.json"],
    required_commands: [],
    max_changed_files: 8,
    manual_approval_paths: [],
  }
  let current_task = @domain.CurrentTask::{
    task_type: "feature-change",
    title: "Refine user page",
    title_source: "manual_input",
    target_groups: ["frontend_user_pages"],
    target_paths: [],
    target_path_source: "manual_input",
    staged_files: [],
    required_artifacts: [],
    required_commands: [],
    artifact_dir: ".moonforge/artifacts/current",
    check_mode: "local",
    auto_inferred_fields: [],
    notes: [],
    need_user_review: false,
    last_auto_fill_ns: "1",
  }

  let effective = @checkers.build_effective_task(
    repo_rules, template, current_task,
  )
  assert_eq(effective.max_changed_files, 3)
}

///|
/// 更严格上限 helper 应返回较小的限制值。
test "stricter limit helper picks smaller value" {
  let task_limit = @checkers.pick_stricter_limit(8, 3)
  assert_eq(task_limit, 3)
}
