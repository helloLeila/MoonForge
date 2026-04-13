///|
/// 文件说明：校验当前任务文件的最小语义约束，当前只覆盖基础字段和目标范围完整性。
/// 输入：当前任务对象。
/// 输出：当任务类型、标题或目标范围缺失时返回错误码，合法时返回空结果。
/// 作用：在进入后续任务合并之前，先阻止空任务描述流入检查流程。

///|
/// 校验当前任务是否包含必要字段与至少一个目标范围。
pub fn validate_current_task(
  task : @domain.CurrentTask,
) -> Result[Unit, String] {
  if task.task_type.trim() == "" || task.title.trim() == "" {
    Err("TASK_FILE_INVALID")
  } else if task.target_groups.is_empty() && task.target_paths.is_empty() {
    Err("TASK_SCOPE_INVALID")
  } else {
    Ok(())
  }
}
