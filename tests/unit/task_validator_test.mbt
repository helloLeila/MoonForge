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
  assert_true(result is Err(_))
}
