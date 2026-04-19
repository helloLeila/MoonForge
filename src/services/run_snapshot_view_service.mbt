///|
/// 文件总说：
/// 这个文件负责把“单次运行快照”整理成更容易复用的摘要文本。
/// 它主要服务两个地方：
/// 1. `replay` 想快速给出一段人能看懂的历史重放摘要
/// 2. `pack` 想把最近一次运行的重点压缩成一页说明

///|
/// 渲染单次运行的快照卡片。
pub fn render_run_snapshot_card(
  result : @domain.CheckResult,
  context_summary : String,
  history_hint : String,
) -> String {
  let missing_artifacts_text = result.missing_artifacts.join("，")
  let command_failures_text = result.command_failures.join("；")
  let lines : Array[String] = [
    "# MoonForge 运行快照",
    "",
    "- 运行编号：\{result.run_id}",
    "- 结论：\{result.decision.label()}",
    "- 任务类型：\{result.effective_task.task_type}",
    "- 任务标题：\{result.effective_task.title}",
    "- 检查文件数：\{result.checked_files.length()}",
  ]
  if context_summary.trim() != "" {
    lines.push("- 来源：\{context_summary}")
  }
  if history_hint.trim() != "" {
    lines.push("- 历史：\{history_hint}")
  }
  if !result.missing_artifacts.is_empty() {
    lines.push("- 缺少材料：\{missing_artifacts_text}")
  }
  if !result.command_failures.is_empty() {
    lines.push("- 命令失败：\{command_failures_text}")
  }
  lines.join("\n") + "\n"
}

///|
/// 给 replay 命令渲染更完整的详情列表。
pub fn render_replay_detail_lines(
  result : @domain.CheckResult,
  context_summary : String,
) -> Array[String] {
  let lines : Array[String] = [
    "运行编号：\{result.run_id}",
    "任务类型：\{result.effective_task.task_type}",
    "结论：\{result.decision.label()}",
    "检查文件数：\{result.checked_files.length()}",
    "违规数：\{result.violations.length()}",
  ]
  if context_summary.trim() != "" {
    lines.push("来源：\{context_summary}")
  }
  return lines
}

///|
/// 给 pack 生成一段最近运行说明。
pub fn render_pack_run_highlight(
  result : @domain.CheckResult,
  history_hint : String,
) -> String {
  let lines : Array[String] = [
    "最近一次运行是 \{result.run_id}",
    "结论为 \{result.decision.label()}",
    "任务类型是 \{result.effective_task.task_type}",
  ]
  if history_hint.trim() != "" {
    lines.push("历史提示：\{history_hint}")
  }
  lines.join("；")
}
