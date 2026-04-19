///|
/// 文件总说：
/// 这个文件专门验证“本地 check 自动补输入”这层服务。
/// 我们不关心最终门禁是 Accept 还是 Reject，只关心系统有没有把输入目录整理好。

///|
/// 生成一份最小可用的当前任务对象，供本地输入服务测试复用。
fn sample_local_task() -> @domain.CurrentTask {
  @domain.CurrentTask::{
    task_type: "feature-change",
    title: "补充UserList",
    title_source: "auto_from_staged_files",
    target_groups: ["frontend_pages"],
    target_paths: [],
    target_path_source: "auto_groups_only",
    staged_files: ["frontend/src/pages/UserList/index.tsx"],
    required_artifacts: ["test-report.json"],
    required_commands: [],
    artifact_dir: ".moonforge/artifacts/current",
    check_mode: "local",
    auto_inferred_fields: ["title", "target_groups"],
    notes: [],
    need_user_review: false,
    last_auto_fill_ns: "1",
  }
}

///|
/// 生成一份最小 git 快照，供本地输入服务测试复用。
fn sample_local_snapshot() -> @domain.GitProjectSnapshot {
  @domain.GitProjectSnapshot::{
    repo_root: "/tmp/local-check-input",
    branch_name: "feature/demo",
    staged_files: ["frontend/src/pages/UserList/index.tsx"],
    unstaged_files: [],
    untracked_files: [],
    status_entries: [],
    staged_diff: "diff --git a/frontend/src/pages/UserList/index.tsx b/frontend/src/pages/UserList/index.tsx\n",
  }
}

///|
/// 本地输入服务应自动创建 patch、说明文件和默认材料目录。
test "staged run service prepares local check input" {
  let repo_root = @infra.join_path(
    "/tmp",
    @infra.unique_temp_name("moonforge-local-input"),
  )
  @infra.ensure_dir(repo_root)

  let input = @services.prepare_local_check_input(
    repo_root,
    sample_local_task(),
    sample_local_snapshot(),
  )

  assert_true(@infra.path_exists(input.patch_path))
  assert_true(
    @infra.path_exists(@infra.join_path(input.run_dir, "staged-files.txt")),
  )
  assert_true(
    @infra.path_exists(@infra.join_path(input.run_dir, "input-summary.md")),
  )
  assert_true(@infra.path_exists(input.artifact_source_dir))
}
