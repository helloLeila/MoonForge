///|
/// 文件总说：
/// 这个文件验证材料目录册和材料发现服务。
/// 重点不是 JSON 结构，而是系统能不能按候选目录和别名把材料找到。

///|
/// 生成一份最小 current task 对象。
fn sample_material_task() -> @domain.CurrentTask {
  @domain.CurrentTask::{
    task_type: "feature-change",
    title: "补充UserList",
    title_source: "auto_from_staged_files",
    target_groups: ["frontend_pages"],
    target_paths: [],
    target_path_source: "auto_groups_only",
    staged_files: ["frontend/src/pages/UserList/index.tsx"],
    required_artifacts: ["test-report.json", "review-report.json"],
    required_commands: [],
    artifact_dir: ".moonforge/artifacts/current",
    check_mode: "local",
    auto_inferred_fields: ["title"],
    notes: [],
    need_user_review: false,
    last_auto_fill_ns: "1",
  }
}

///|
/// 材料目录册应支持往返读写。
test "material catalog store round trips directories and aliases" {
  let repo_root = @infra.join_path(
    "/tmp",
    @infra.unique_temp_name("moonforge-material-catalog"),
  )
  @infra.ensure_dir(@infra.dirname(@infra.material_catalog_path(repo_root)))
  let catalog = @services.default_material_catalog()

  @infra.write_text(
    @infra.material_catalog_path(repo_root),
    @infra.render_material_catalog(catalog),
  )
  let restored = @infra.read_material_catalog(
    @infra.material_catalog_path(repo_root),
  )

  assert_true(restored.has_directories())
  assert_true(restored.artifact_aliases.contains("test-report.json"))
  assert_true(restored.preferred_directory_names.contains("current"))
}

///|
/// 材料发现服务应按目录册定义搜索材料，并返回内容映射。
test "material discovery finds artifacts from configured directories" {
  let repo_root = @infra.join_path(
    "/tmp",
    @infra.unique_temp_name("moonforge-material-discovery"),
  )
  let current_dir = @infra.join_path(repo_root, ".moonforge/artifacts/current")
  let latest_dir = @infra.join_path(repo_root, ".moonforge/artifacts/latest")
  @infra.ensure_dir(current_dir)
  @infra.ensure_dir(latest_dir)
  @infra.write_text(
    @infra.join_path(current_dir, "test-report.json"),
    "{\n  \"passed\": true,\n  \"suite\": \"material\"\n}\n",
  )
  @infra.write_text(
    @infra.join_path(latest_dir, "review-report.json"),
    "{\n  \"reviewer\": \"material\",\n  \"status\": \"approved\"\n}\n",
  )
  @infra.write_text(
    @infra.material_catalog_path(repo_root),
    @infra.render_material_catalog(@services.default_material_catalog()),
  )

  let result = @services.discover_required_artifacts(
    repo_root,
    sample_material_task(),
    ["test-report.json", "review-report.json"],
  )

  assert_eq(result.found_count(), 2)
  assert_true(result.provided_artifacts.contains("test-report.json"))
  assert_true(result.provided_artifacts.contains("review-report.json"))
}
