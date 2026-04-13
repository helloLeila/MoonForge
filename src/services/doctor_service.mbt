///|
/// 文件说明：实现 doctor 命令的独立服务层，负责诊断配置问题并生成诊断报告。
/// 联动文件：由 `src/services/commands.mbt` 调用，依赖 `src/infra/yaml_parser.mbt` 读取配置文件。

///|
/// 检测缺失的必需配置文件。
/// 入参：`file_checks`，文件路径与存在性的元组数组。
/// 出参：缺失文件的问题描述数组。
pub fn diagnose_missing_files(
  file_checks : Array[(String, Bool)],
) -> Array[String] {
  let issues : Array[String] = []
  for check in file_checks {
    let (path, exists) = check
    if !exists {
      issues.push("缺失文件：\{path}")
    }
  }
  issues
}

///|
/// 检测空的配置文件。
/// 入参：`file_contents`，文件路径与内容的元组数组。
/// 出参：空文件的问题描述数组。
pub fn diagnose_empty_files(
  file_contents : Array[(String, String)],
) -> Array[String] {
  let issues : Array[String] = []
  for item in file_contents {
    let (path, content) = item
    if content.trim() == "" {
      issues.push("空文件：\{path}")
    }
  }
  issues
}

///|
/// 检测缺少必需字段的配置文件。
/// 入参：`content`，配置文件的文本内容。
/// 入参：`required_fields`，必需字段名数组。
/// 出参：缺少字段的问题描述数组。
pub fn diagnose_required_fields(
  content : String,
  required_fields : Array[String],
) -> Array[String] {
  let issues : Array[String] = []
  for field in required_fields {
    if !content.contains(field) {
      issues.push("缺少字段：\{field}")
    }
  }
  issues
}

///|
/// 渲染完整的诊断报告，包含所有问题项。
/// 入参：`issues`，问题描述数组。
/// 出参：终端可打印的诊断报告文本。
pub fn render_doctor_report(issues : Array[String]) -> String {
  if issues.is_empty() {
    "✅ 配置健康，未发现问题"
  } else {
    let lines : Array[String] = ["🩺 配置诊断报告", ""]
    for issue in issues {
      lines.push("- \{issue}")
    }
    lines.join("\n")
  }
}
