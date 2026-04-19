///|
/// 文件总说：
/// 这个文件负责为 `.moonforge/out/<mode>/latest` 生成一份“目录导航”。
/// 这份导航的核心价值不是机器消费，而是给人看：
/// - 先看什么
/// - 遇到什么问题该看哪个文件
/// - 哪些文件是结果，哪些文件是解释，哪些文件是辅助说明
///
/// 这正好契合当前项目的目标：
/// 让没看过 MoonForge 的人也能快速知道输出目录在表达什么。

///|
/// 构造单个目录条目。
fn entry(
  file_name : String,
  title : String,
  purpose : String,
  when_to_read : String,
) -> @domain.OutputCatalogEntry {
  @domain.OutputCatalogEntry::{ file_name, title, purpose, when_to_read }
}

///|
/// 返回一组最核心的结果文件说明。
fn core_result_entries() -> Array[@domain.OutputCatalogEntry] {
  [
    entry(
      "gate-result.json", "最终结论 JSON", "给程序读取的正式门禁结论，里面有 decision、violations、next_action。",
      "你想确认最终是否 Accept / Retryable / Reject 时先看它。",
    ),
    entry(
      "gate-report.md", "基础门禁报告", "这是最早的一份 Markdown 报告，按结论、任务、违规项做基本展开。",
      "你想快速浏览一份原始报告时看它。",
    ),
    entry(
      "scope-result.json", "范围结果", "这里记录检查到了哪些文件、有没有越界、有没有触碰保护路径。",
      "你怀疑任务范围不对时看它。",
    ),
    entry(
      "artifact-result.json", "材料结果", "这里记录材料缺失、材料无效、命令失败等和证明文件相关的情况。",
      "你想知道为什么变成 Retryable 时看它。",
    ),
    entry(
      "run-context.json", "运行上下文", "这里记录本次运行来自 local、ci 还是 pr，以及 diff 路径等上下文。",
      "你想确认这次检查的来源时看它。",
    ),
  ]
}

///|
/// 返回“解释和辅助说明”文件说明。
fn explanation_entries() -> Array[@domain.OutputCatalogEntry] {
  [
    entry(
      "decision-explanation.md", "结论解释", "把 violations 按主题分组，解释这次为什么得到当前结论。",
      "你想知道“为什么是这个结论”时看它。",
    ),
    entry(
      "report-view.md", "人类视角报告", "比基础报告更像面向人的最终说明，包含任务、范围、材料、历史和提醒。",
      "你想看一份最完整、最容易读懂的报告时看它。",
    ),
    entry(
      "report-summary.txt", "终端摘要", "这是给命令行直接展示的一小段摘要文本。",
      "你只想快速知道结论和下一步时看它。",
    ),
    entry(
      "preflight-advice.md", "额外提醒", "这里放的是不会直接改判定，但非常值得你再看一眼的提醒。",
      "你觉得“虽然过了，但心里还是不踏实”时看它。",
    ),
    entry(
      "run-snapshot.md", "运行快照", "把本次运行压成一页卡片，方便放进 pack 或者发给别人。",
      "你想转述这次运行重点时看它。",
    ),
  ]
}

///|
/// 返回“输入和任务理解”文件说明。
fn task_and_input_entries() -> Array[@domain.OutputCatalogEntry] {
  [
    entry(
      "task-profile.md", "任务画像", "解释系统最后把 current-task.yml 理解成了什么任务。",
      "你想确认 task 自动补全是不是猜对了时看它。",
    ),
    entry(
      "run-input-story.md", "输入来源说明", "解释 patch、材料目录、材料搜索过程到底是怎么来的。",
      "你怀疑系统拿错输入或没找到材料时看它。",
    ),
    entry(
      "checked-files.txt", "检查文件清单", "一行一个文件，最适合肉眼快速确认系统到底碰了哪些文件。",
      "你只想肉眼核对文件列表时看它。",
    ),
    entry(
      "events.jsonl", "事件日志", "按时间记录规则加载、文件检查、结论生成等关键事件。",
      "你想做审计或调试时看它。",
    ),
  ]
}

///|
/// 构造完整的输出目录导航。
pub fn build_output_catalog_view(mode : String) -> @domain.OutputCatalogView {
  let entries : Array[@domain.OutputCatalogEntry] = []
  for item in core_result_entries() {
    entries.push(item)
  }
  for item in explanation_entries() {
    entries.push(item)
  }
  for item in task_and_input_entries() {
    entries.push(item)
  }
  @domain.OutputCatalogView::{
    headline: "这份目录导航告诉你：当前输出目录里的每个文件分别在讲什么、什么时候应该先看它。",
    mode,
    entries,
  }
}

///|
/// 把目录导航渲染成 Markdown。
pub fn render_output_catalog_markdown(
  view : @domain.OutputCatalogView,
) -> String {
  let lines : Array[String] = [
    "# MoonForge 输出目录导航",
    "",
    "## 总说",
    view.headline,
    "",
    view.summary(),
    "",
    "## 文件说明",
  ]
  for item in view.entries {
    lines.push("")
    lines.push("### \{item.file_name}")
    lines.push("- 标题：\{item.title}")
    lines.push("- 用途：\{item.purpose}")
    lines.push("- 什么时候看：\{item.when_to_read}")
  }
  lines.join("\n") + "\n"
}

///|
/// 渲染一段超短的“输出快速入口”文本。
/// 这段文本适合放到终端、README 片段或者结果目录入口文件里。
pub fn render_output_catalog_quickstart(
  view : @domain.OutputCatalogView,
) -> String {
  let lines : Array[String] = [
    "MoonForge 输出快速入口", "先看：report-summary.txt", "再看：report-view.md",
  ]
  match view.find_entry("task-profile.md") {
    Some(entry) => lines.push("任务不确定时看：\{entry.file_name}")
    None => ()
  }
  match view.find_entry("run-input-story.md") {
    Some(entry) => lines.push("输入不确定时看：\{entry.file_name}")
    None => ()
  }
  match view.find_entry("output-catalog.md") {
    Some(entry) => lines.push("查字典时看：\{entry.file_name}")
    None => ()
  }
  lines.join("\n") + "\n"
}

///|
/// 根据目录导航生成一份结果自查清单。
/// 这份清单更像“人工验收步骤”，适合打开结果目录后逐条核对。
pub fn render_output_self_checklist(
  view : @domain.OutputCatalogView,
) -> String {
  let lines : Array[String] = [
    "# MoonForge 结果自查清单",
    "",
    "1. 先看 report-summary.txt，确认最终结论是不是你预期的。",
    "2. 再看 report-view.md，确认任务、输入、历史、提醒有没有明显对不上。",
    "3. 如果结论不懂，就去看 decision-explanation.md，把问题分组逐条看清楚。",
    "4. 如果怀疑 task 猜错，就去看 task-profile.md，确认标题和范围。",
    "5. 如果怀疑输入拿错，就去看 run-input-story.md，确认 patch 和材料目录。",
  ]
  if view.find_entry("preflight-advice.md") is Some(_) {
    lines.push("6. 如果结果虽然过了但你心里不踏实，再补看 preflight-advice.md。")
  }
  if view.find_entry("events.jsonl") is Some(_) {
    lines.push("7. 如果你在排查问题来源，最后再翻 events.jsonl 做审计和调试。")
  }
  lines.push("")
  lines.push("完成上面这些后，你通常就能把这次运行讲清楚。")
  lines.join("\n") + "\n"
}
