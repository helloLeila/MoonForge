///|
/// 文件说明：实现 report 命令的独立服务层，负责读取最近一次检查结果并生成可读报告。
/// 联动文件：由 `src/services/commands.mbt` 的 `report_latest` 函数调用，依赖 `src/infra/run_store.mbt` 读取结果文件。

///|
/// 从 gate-result.json 文件中提取结论标签字段。
/// 入参：`json_text`，gate-result.json 的原始文本。
/// 出参：结论标签字符串，解析失败时返回 `"Unknown"`。
pub fn extract_decision_label(json_text : String) -> String {
  if json_text.contains("\"decision\"") {
    let lines = json_text.split("\n").map(l => l.trim().to_string()).collect()
    for line in lines {
      if line.has_prefix("\"decision\"") {
        let parts = line.split(":").map(p => p.trim().to_string()).collect()
        if parts.length() >= 2 {
          let value = parts[1].trim_start(chars="\"").trim_end(chars="\",").to_string()
          return value
        }
      }
    }
  }
  "Unknown"
}

///|
/// 生成 report 命令的终端输出摘要文本。
/// 入参：`decision_label`，检查结论的中文标签。
/// 入参：`mode`，运行模式，`"local"` 或 `"ci"`。
/// 出参：终端可打印的报告摘要文本。
pub fn render_report_summary(decision_label : String, mode : String) -> String {
  "📋 最近一次检查结论（\{mode} 模式）：\{decision_label}"
}

///|
/// 当最近一次检查结果不存在时，生成提示文本。
/// 入参：`mode`，运行模式。
/// 出参：提示用户先执行 check 的中文文本。
pub fn render_no_result_message(mode : String) -> String {
  "⚠️  未找到最近一次检查结果（\{mode} 模式），请先执行 check 命令。"
}
