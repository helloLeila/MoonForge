///|
/// 文件说明：提供门禁报告文本渲染能力，负责将 CheckResult 转换为可读的 Markdown 摘要。
/// 联动文件：被 `src/services/commands.mbt` 在结果写出阶段调用，依赖 `src/domain/result_types.mbt`。

///|
/// 将检查结果渲染为带章节标题的 Markdown 报告文本。
/// 入参：`decision_label`，结论的中文标签。
/// 入参：`decision_summary`，结论的简要说明。
/// 入参：`next_action`，给开发者的下一步操作建议。
/// 入参：`task_type`，当前任务类型。
/// 入参：`title`，当前任务标题。
/// 入参：`changed_file_count`，本次变更的文件数量。
/// 入参：`violations`，违规项描述数组，每项格式为"代码: 说明"。
/// 出参：Markdown 格式的门禁报告文本。
pub fn render_gate_report(
  decision_label : String,
  decision_summary : String,
  next_action : String,
  task_type : String,
  title : String,
  changed_file_count : Int,
  violations : Array[String],
) -> String {
  let lines : Array[String] = [
    "## 最终结论",
    decision_label,
    "",
    "## 结论说明",
    decision_summary,
    "",
    "## 任务摘要",
    "- task_type: \{task_type}",
    "- title: \{title}",
    "- changed_files: \{changed_file_count}",
    "",
    "## 命中的问题",
  ]
  if violations.is_empty() {
    lines.push("- 无")
  } else {
    for v in violations {
      lines.push("- \{v}")
    }
  }
  lines.push("")
  lines.push("## 下一步")
  lines.push(next_action)
  lines.push("")
  lines.join("\n")
}

///|
/// 将检查结果中的终端摘要渲染为简短的中文文本，适合 CLI 直接输出。
/// 入参：`decision_label`，结论的中文标签。
/// 入参：`decision_summary`，结论的简要说明。
/// 入参：`violation_count`，违规项总数。
/// 出参：单行或少行的终端摘要文本。
pub fn render_terminal_summary(
  decision_label : String,
  decision_summary : String,
  violation_count : Int,
) -> String {
  if violation_count == 0 {
    "✅ 门禁结论：\{decision_label} — \{decision_summary}"
  } else {
    "❌ 门禁结论：\{decision_label} — \{decision_summary}（\{violation_count} 条违规）"
  }
}
