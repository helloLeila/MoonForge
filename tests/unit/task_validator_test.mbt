///|
/// 文件说明：覆盖当前任务合法性校验器的基础失败场景，确保任务范围字段不能为空。
/// 输入：构造一个同时缺少目标组与目标路径的当前任务。
/// 输出：当目标组和目标路径都为空时，应返回错误。

///|
/// 生成一份最小可用的当前任务对象。
/// 这样每条测试只改自己关心的字段，读起来会更直白。
fn sample_task() -> @domain.CurrentTask {
  @domain.CurrentTask::{
    task_type: "feature-change",
    title: "Add filter",
    title_source: "manual_input",
    target_groups: ["frontend"],
    target_paths: [],
    target_path_source: "manual_input",
    staged_files: ["frontend/src/pages/UserList/index.tsx"],
    required_artifacts: ["test-report.json"],
    required_commands: [],
    artifact_dir: ".moonforge/artifacts/current",
    check_mode: "local",
    auto_inferred_fields: [],
    notes: [],
    need_user_review: false,
    last_auto_fill_ns: "1",
  }
}

///|
/// 当前任务校验器应拒绝目标组和目标路径都为空的任务。
test "task validator rejects empty target groups and paths" {
  let task = { ..sample_task(), target_groups: [], target_paths: [] }
  let result = @checkers.validate_current_task(task)
  assert_eq(result, Err("TASK_SCOPE_INVALID"))
}

///|
/// 当前任务校验器应拒绝纯空白的任务类型或标题，并保留成功路径。
test "task validator rejects blank task type or title" {
  let blank_task_type = {
    ..sample_task(),
    task_type: "   ",
    target_groups: [],
    target_paths: ["frontend/src/pages/**"],
  }
  let blank_title = { ..sample_task(), title: "   " }

  assert_eq(
    @checkers.validate_current_task(blank_task_type),
    Err("TASK_FILE_INVALID"),
  )
  assert_eq(
    @checkers.validate_current_task(blank_title),
    Err("TASK_FILE_INVALID"),
  )
}

///|
/// 当前任务校验器应接受包含有效目标范围的任务。
test "task validator accepts valid task" {
  let task = sample_task()
  let result = @checkers.validate_current_task(task)
  assert_eq(result, Ok(()))
}

///|
/// 当前任务校验器应拒绝未知检查模式和空白材料项。
test "task validator rejects invalid check mode and blank artifacts" {
  let invalid_mode = { ..sample_task(), check_mode: "desktop" }
  let blank_artifacts = {
    ..sample_task(),
    required_artifacts: ["test-report.json", "   "],
  }

  assert_eq(
    @checkers.validate_current_task(invalid_mode),
    Err("TASK_MODE_INVALID"),
  )
  assert_eq(
    @checkers.validate_current_task(blank_artifacts),
    Err("TASK_ARTIFACTS_INVALID"),
  )
}
