///|
/// 文件总说：
/// 这个文件验证 bootstrap 默认偏好能正确写成 YAML，再从 YAML 读回对象。

///|
/// bootstrap 配置应支持完整往返读写。
test "bootstrap store round trips task check and report preferences" {
  let repo_root = @infra.join_path(
    "/tmp",
    @infra.unique_temp_name("moonforge-bootstrap-store"),
  )
  @infra.ensure_dir(@infra.bootstrap_dir(repo_root))
  let bundle = @services.default_bootstrap_bundle()

  @infra.write_text(
    @infra.task_defaults_path(repo_root),
    @infra.render_task_defaults(bundle.task_defaults),
  )
  @infra.write_text(
    @infra.check_preferences_path(repo_root),
    @infra.render_check_preferences(bundle.check_preferences),
  )
  @infra.write_text(
    @infra.report_preferences_path(repo_root),
    @infra.render_report_preferences(bundle.report_preferences),
  )

  let task_defaults = @infra.read_task_defaults(
    @infra.task_defaults_path(repo_root),
  )
  let check_preferences = @infra.read_check_preferences(
    @infra.check_preferences_path(repo_root),
  )
  let report_preferences = @infra.read_report_preferences(
    @infra.report_preferences_path(repo_root),
  )

  assert_eq(task_defaults.default_check_mode, "local")
  assert_eq(task_defaults.default_artifact_dir, ".moonforge/artifacts/current")
  assert_true(task_defaults.default_title_prefixes.contains("feature-change"))
  assert_true(check_preferences.auto_prepare_local_run_input)
  assert_true(
    check_preferences.artifact_search_dirs.contains(
      ".moonforge/artifacts/current",
    ),
  )
  assert_true(report_preferences.show_context)
  assert_true(report_preferences.show_metrics)
}
