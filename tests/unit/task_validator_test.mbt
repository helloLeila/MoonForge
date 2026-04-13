///|
/// 文件说明：覆盖当前任务合法性校验器的基础失败场景，确保任务范围字段不能为空。
/// 输入：构造一个同时缺少目标组与目标路径的当前任务。
/// 输出：当目标组和目标路径都为空时，应返回错误。

///|
/// 当前任务校验器应拒绝目标组和目标路径都为空的任务。
test "task validator rejects empty target groups and paths" {
  let task = @domain.CurrentTask::{
    task_type: "feature-change",
    title: "Add filter",
    target_groups: [],
    target_paths: [],
  }
  let result = @checkers.validate_current_task(task)
  assert_eq(result, Err("TASK_SCOPE_INVALID"))
}

///|
/// 当前任务校验器应拒绝纯空白的任务类型或标题，并保留成功路径。
test "task validator rejects blank task type or title" {
  let blank_task_type = @domain.CurrentTask::{
    task_type: "   ",
    title: "Add filter",
    target_groups: [],
    target_paths: ["frontend/src/pages/**"],
  }
  let blank_title = @domain.CurrentTask::{
    task_type: "feature-change",
    title: "   ",
    target_groups: ["frontend"],
    target_paths: [],
  }

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
  let task = @domain.CurrentTask::{
    task_type: "feature-change",
    title: "Add filter",
    target_groups: ["frontend"],
    target_paths: [],
  }
  let result = @checkers.validate_current_task(task)
  assert_eq(result, Ok(()))
}
