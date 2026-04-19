///|
/// 文件总说：
/// 这个文件专门守住 `current-task.yml` 的最小质量底线。
/// 它不负责复杂推理，只做两件很直接的事：
/// 1. 阻止明显空白或明显错误的任务文件继续往后流
/// 2. 给出稳定错误码，方便 CLI、测试和报告统一处理

///|
/// 判断一个字符串数组里是否混进了空白项。
/// 这个检查很有必要，因为 YAML 列表里最容易出现的脏数据就是 `- ""`。
fn has_blank_item(values : Array[String]) -> Bool {
  for value in values {
    if value.trim() == "" {
      return true
    }
  }
  false
}

///|
/// 校验当前任务是否包含必要字段与至少一个目标范围。
/// 除了最基础的任务类型、标题和范围，这里还会顺手检查：
/// - 检查模式是否在允许名单里
/// - 材料列表和命令列表里是否混入空白项
pub fn validate_current_task(
  task : @domain.CurrentTask,
) -> Result[Unit, String] {
  if task.task_type.trim() == "" || task.title.trim() == "" {
    Err("TASK_FILE_INVALID")
  } else if task.target_groups.is_empty() && task.target_paths.is_empty() {
    Err("TASK_SCOPE_INVALID")
  } else if task.check_mode.trim() == "" {
    Err("TASK_MODE_INVALID")
  } else if !["local", "ci", "pr"].contains(task.check_mode) {
    Err("TASK_MODE_INVALID")
  } else if has_blank_item(task.required_artifacts) {
    Err("TASK_ARTIFACTS_INVALID")
  } else if has_blank_item(task.required_commands) {
    Err("TASK_COMMANDS_INVALID")
  } else {
    Ok(())
  }
}
