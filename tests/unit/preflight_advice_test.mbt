///|
/// 文件总说：
/// 这个文件验证额外提醒包确实会把任务、输入、材料这些提醒汇总起来。
fn sample_current_task() -> @domain.CurrentTask {
  @domain.CurrentTask::{
    task_type: "feature-change",
    title: "修改",
    title_source: "auto_from_staged_files",
    target_groups: [],
    target_paths: ["frontend/src/**"],
    target_path_source: "auto_groups_and_paths",
    staged_files: ["frontend/src/pages/UserList/index.tsx"],
    required_artifacts: ["test-report.json", "review-report.json"],
    required_commands: ["moon test"],
    artifact_dir: ".moonforge/artifacts/current",
    check_mode: "local",
    auto_inferred_fields: ["title", "target_paths"],
    notes: [],
    need_user_review: true,
    last_auto_fill_ns: "1",
  }
}

///|
fn sample_effective_task() -> @domain.EffectiveTask {
  @domain.EffectiveTask::{
    task_type: "feature-change",
    title: "修改",
    allowed_paths: ["frontend/src/**"],
    forbidden_paths: [],
    approval_required_paths: [],
    allowed_extensions: [".ts", ".tsx"],
    blocked_extensions: [],
    generated_artifact_paths: [],
    blocked_file_names: [],
    blocked_file_patterns: [],
    content_blocklist_patterns: [],
    required_artifacts: ["test-report.json", "review-report.json"],
    required_commands: ["moon test"],
    max_changed_files: 8,
  }
}

///|
fn sample_discovery() -> @domain.MaterialDiscoveryResult {
  @domain.MaterialDiscoveryResult::{
    provided_artifacts: {
      "test-report.json": "{\n  \"passed\": true,\n  \"suite\": \"preflight\"\n}\n",
    },
    records: [
      @domain.MaterialDiscoveryRecord::{
        artifact_name: "test-report.json",
        searched_directories: ["/tmp/repo/.moonforge/artifacts/current"],
        matched_path: Some(
          "/tmp/repo/.moonforge/artifacts/current/test-report.json",
        ),
        matched_name: Some("test-report.json"),
        note: "ok",
      },
      @domain.MaterialDiscoveryRecord::{
        artifact_name: "review-report.json",
        searched_directories: ["/tmp/repo/.moonforge/artifacts/current"],
        matched_path: None,
        matched_name: None,
        note: "missing",
      },
    ],
    searched_directories: ["/tmp/repo/.moonforge/artifacts/current"],
  }
}

///|
test "preflight advice bundle aggregates task and material hints" {
  let bundle = @services.build_preflight_advice_bundle(
    "/tmp/repo",
    sample_current_task(),
    sample_effective_task(),
    ["frontend/src/pages/UserList/index.tsx"],
    sample_discovery(),
  )

  assert_true(bundle.has_items())
  assert_true(bundle.need_user_review)
  assert_true(bundle.warning_count() >= 1)
}
