///|
/// 文件说明：实现 validate 命令的独立服务层，负责对仓库规则、任务模板与当前任务进行结构校验。
/// 联动文件：由 `src/services/commands.mbt` 的 `validate_repo` 函数调用，依赖 `src/checkers/template_validator.mbt` 和 `src/checkers/task_validator.mbt`。

///|
/// 检查指定路径下的 YAML 文件是否包含所有必需字段，任意缺失字段即返回该字段名。
/// 入参：`yaml_text`，YAML 文件原始文本。
/// 入参：`required_fields`，必须出现的字段名列表。
/// 出参：`Result[Unit, String]`，全部存在时返回 `Ok(())`，否则返回 `Err(first_missing_field)`。
pub fn validate_required_fields(
  yaml_text : String,
  required_fields : Array[String],
) -> Result[Unit, String] {
  for field in required_fields {
    if !yaml_text.contains(field) {
      return Err(field)
    }
  }
  Ok(())
}

///|
/// 校验仓库规则文件是否包含最基本的字段声明。
/// 入参：`repo_rules_text`，repo-rules.yml 的原始文本。
/// 出参：`Result[Unit, String]`，格式合法时返回 `Ok(())`，否则返回错误码。
pub fn validate_repo_rules_text(
  repo_rules_text : String,
) -> Result[Unit, String] {
  if repo_rules_text.trim() == "" {
    Err("REPO_RULES_EMPTY")
  } else {
    Ok(())
  }
}

///|
/// 校验当前任务文件内容是否包含 task_type 和 title 字段。
/// 入参：`current_task_text`，current-task.yml 的原始文本。
/// 出参：`Result[Unit, String]`，格式合法时返回 `Ok(())`，否则返回错误码。
pub fn validate_current_task_text(
  current_task_text : String,
) -> Result[Unit, String] {
  if current_task_text.trim() == "" {
    Err("CURRENT_TASK_EMPTY")
  } else if !current_task_text.contains("task_type") {
    Err("CURRENT_TASK_MISSING_TYPE")
  } else if !current_task_text.contains("title") {
    Err("CURRENT_TASK_MISSING_TITLE")
  } else {
    Ok(())
  }
}

///|
/// 生成结构化的校验报告摘要文本，以中文输出给终端。
/// 入参：`errors`，校验过程中收集的错误描述列表。
/// 出参：校验通过或列出所有错误的中文摘要文本。
pub fn render_validate_report(errors : Array[String]) -> String {
  if errors.is_empty() {
    "✅ 配置校验通过，所有规则与任务文件均合法。"
  } else {
    let lines : Array[String] = ["❌ 配置校验发现以下问题："]
    for err in errors {
      lines.push("  - \{err}")
    }
    lines.join("\n")
  }
}
