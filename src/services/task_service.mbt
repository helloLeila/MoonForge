///|
/// 文件说明：实现 task 命令的独立服务层，负责解析路径字符串并生成当前任务文件。
/// 联动文件：由 `src/services/commands.mbt` 的 `create_task` 函数调用，依赖 `src/infra/path_utils.mbt` 进行路径处理。

///|
/// 将逗号分隔的路径字符串解析为去重后的路径数组，并过滤掉空白条目。
/// 入参：`paths_csv`，逗号分隔的路径字符串，如 `"frontend/src/**,backend/src/**"`。
/// 出参：去重后的路径数组。
pub fn parse_target_paths(paths_csv : String) -> Array[String] {
  paths_csv
  .split(",")
  .map(item => item.trim().to_string())
  .filter(item => item != "")
  .collect()
}

///|
/// 将任务类型、标题和目标路径数组序列化为 YAML 格式的当前任务文件文本。
/// 入参：`task_type`，任务类型标识，如 `"feature-change"`。
/// 入参：`title`，任务标题。
/// 入参：`target_paths`，已解析的目标路径数组。
/// 出参：当前任务文件的 YAML 文本内容。
pub fn render_current_task_yaml(
  task_type : String,
  title : String,
  target_paths : Array[String],
) -> String {
  let lines : Array[String] = [
    "task_type: \"\{task_type}\"",
    "title: \"\{title}\"",
    "target_paths:",
  ]
  if target_paths.is_empty() {
    lines.push("  - \"\"")
  } else {
    for path in target_paths {
      lines.push("  - \"\{path}\"")
    }
  }
  lines.join("\n") + "\n"
}

///|
/// 验证任务类型是否在已知模板列表中，不在列表中则返回错误码。
/// 入参：`task_type`，需要验证的任务类型标识。
/// 出参：`Result[Unit, String]`，有效时返回 `Ok(())`，无效时返回 `Err("TASK_TYPE_UNKNOWN")`。
pub fn validate_task_type(task_type : String) -> Result[Unit, String] {
  let known : Array[String] = [
    "feature-change", "bug-fix", "api-change", "config-change", "test-addition",
  ]
  if known.contains(task_type) {
    Ok(())
  } else {
    Err("TASK_TYPE_UNKNOWN")
  }
}
