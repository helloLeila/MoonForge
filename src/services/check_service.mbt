///|
/// 文件说明：实现 check 命令的独立服务层，负责将检查结果格式化为终端输出和命令返回值。
/// 联动文件：由 `src/services/commands.mbt` 的 `run_check` 函数调用，依赖 `src/checkers/gate.mbt` 和 `src/domain/result_types.mbt`。

///|
/// 将检查结果渲染为终端摘要，供 CLI 直接打印给开发者。
/// 入参：`decision_label`，结论的中文标签。
/// 入参：`decision_summary`，结论的简要说明。
/// 入参：`violation_count`，本次检查发现的违规数量。
/// 入参：`checked_file_count`，本次检查覆盖的文件数量。
/// 出参：终端可打印的中文摘要文本。
pub fn render_check_summary(
  decision_label : String,
  decision_summary : String,
  violation_count : Int,
  checked_file_count : Int,
) -> String {
  let status = if violation_count == 0 { "✅" } else { "❌" }
  "\{status} 门禁检查完成\n结论：\{decision_label} — \{decision_summary}\n覆盖文件：\{checked_file_count} 个，发现违规：\{violation_count} 条"
}

///|
/// 将违规项列表渲染为简洁的终端错误列表文本。
/// 入参：`violations`，包含编码和中文说明的违规项描述数组。
/// 出参：多行文本，每条违规项单独一行，适合终端输出。
pub fn render_violations_text(violations : Array[String]) -> String {
  if violations.is_empty() {
    "无违规项"
  } else {
    violations.join("\n")
  }
}

///|
/// 检查本次运行是否应退出非零状态码，用于 CI 模式失败传播。
/// 入参：`decision_code`，检查结论的编码字符串。
/// 出参：`true` 表示应以非零状态码退出（Reject、Retryable、NeedHumanApproval）。
pub fn should_exit_nonzero(decision_code : String) -> Bool {
  decision_code != "Accept"
}

///|
/// 生成本次检查的运行标识符，格式为 `check-{nanoseconds}`。
/// 入参：`timestamp_ns`，纳秒级时间戳，通常来自 `@uv.hrtime()`。
/// 出参：形如 `"check-1744512345678901234"` 的唯一运行 ID。
pub fn make_run_id(timestamp_ns : UInt64) -> String {
  "check-\{timestamp_ns}"
}
