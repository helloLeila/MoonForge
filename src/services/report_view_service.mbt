///|
/// 文件总说：
/// 这个文件负责把内存里的检查结果整理成“人类真的想看的报告视图”。
/// 它不重新判断规则，只做展示组织。
///
/// 工作顺序很固定：
/// 1. 先讲最终结论
/// 2. 再讲任务和输入
/// 3. 再讲问题为什么发生
/// 4. 最后给下一步建议

///|
/// 构造“任务摘要”分块。
fn build_task_section(
  result : @domain.CheckResult,
) -> @domain.ReportViewSection {
  {
    title: "任务摘要",
    intro: "这块只回答一件事：系统这次到底在检查什么任务。",
    lines: [
      "任务类型：\{result.effective_task.task_type}",
      "任务标题：\{result.effective_task.title}",
      "变更文件数：\{result.checked_files.length()}",
      "材料要求数：\{result.effective_task.required_artifacts.length()}",
      "命令要求数：\{result.effective_task.required_commands.length()}",
    ],
    is_warning: false,
  }
}

///|
/// 构造“输入与范围”分块。
fn build_scope_section(
  result : @domain.CheckResult,
) -> @domain.ReportViewSection {
  let out_of_scope_text = result.out_of_scope_files.join("，")
  let protected_files_text = result.protected_files.join("，")
  let lines : Array[String] = [
    "本次实际触碰文件：\{result.checked_files.length()} 个",
    "允许范围：\{result.effective_task.allowed_paths.length()} 条",
  ]
  if !result.out_of_scope_files.is_empty() {
    lines.push("超范围文件：\{out_of_scope_text}")
  }
  if !result.protected_files.is_empty() {
    lines.push("受保护文件：\{protected_files_text}")
  }
  if result.changed_file_count_exceeded {
    lines.push(
      "文件数超限：\{result.changed_file_count} > \{result.effective_task.max_changed_files}",
    )
  }
  {
    title: "输入与范围",
    intro: "这块解释系统看到了哪些文件，以及这些文件有没有越界。",
    lines,
    is_warning: !result.out_of_scope_files.is_empty() ||
    !result.protected_files.is_empty() ||
    result.changed_file_count_exceeded,
  }
}

///|
/// 构造“材料与命令”分块。
fn build_artifact_section(
  result : @domain.CheckResult,
) -> @domain.ReportViewSection {
  let provided_artifacts_text = result.provided_artifacts.join("，")
  let missing_artifacts_text = result.missing_artifacts.join("，")
  let invalid_artifacts_text = result.invalid_artifacts.join("，")
  let command_failures_text = result.command_failures.join("；")
  let lines : Array[String] = ["已提供材料：\{provided_artifacts_text}"]
  if !result.missing_artifacts.is_empty() {
    lines.push("缺少材料：\{missing_artifacts_text}")
  }
  if !result.invalid_artifacts.is_empty() {
    lines.push("材料无效：\{invalid_artifacts_text}")
  }
  if !result.command_failures.is_empty() {
    lines.push("命令失败：\{command_failures_text}")
  }
  {
    title: "材料与命令",
    intro: "这块回答两件事：材料齐不齐，必须跑的命令有没有通过。",
    lines,
    is_warning: !result.missing_artifacts.is_empty() ||
    !result.invalid_artifacts.is_empty() ||
    !result.command_failures.is_empty(),
  }
}

///|
/// 把解释对象压成报告里的“结论原因”分块。
fn build_explanation_section(
  explanation : @domain.DecisionExplanation,
) -> @domain.ReportViewSection {
  let lines : Array[String] = [explanation.reason_summary]
  for bucket in explanation.buckets {
    lines.push("\{bucket.title}：\{bucket.summary}")
  }
  {
    title: "结论原因",
    intro: explanation.headline,
    lines,
    is_warning: explanation.decision != "Accept",
  }
}

///|
/// 构造“历史提示”分块。
fn build_history_section(history_hint : String) -> @domain.ReportViewSection {
  let lines : Array[String] = []
  if history_hint.trim() != "" {
    lines.push(history_hint)
  }
  {
    title: "历史提示",
    intro: "这块帮助你判断这次是偶发，还是最近一直在重复发生。",
    lines,
    is_warning: false,
  }
}

///|
/// 构造“上下文摘要”分块。
fn build_context_section(context_summary : String) -> @domain.ReportViewSection {
  let lines : Array[String] = []
  if context_summary.trim() != "" {
    lines.push(context_summary)
  }
  {
    title: "运行来源",
    intro: "这块说明这次检查来自本地、CI，还是 PR 复检。",
    lines,
    is_warning: false,
  }
}

///|
/// 把额外提醒整理成一个分块。
pub fn build_advisory_section(
  advisory_lines : Array[String],
) -> @domain.ReportViewSection {
  {
    title: "额外提醒",
    intro: "这块不一定影响最终结论，但会提示你哪里值得再看一眼。",
    lines: advisory_lines,
    is_warning: !advisory_lines.is_empty(),
  }
}

///|
/// 生成报告视图主对象。
pub fn build_report_view(
  result : @domain.CheckResult,
  mode : String,
  context_summary : String,
  explanation : @domain.DecisionExplanation,
  history_hint : String,
  advisory_lines : Array[String],
) -> @domain.ReportView {
  let sections : Array[@domain.ReportViewSection] = [
    build_task_section(result),
    build_context_section(context_summary),
    build_scope_section(result),
    build_artifact_section(result),
    build_explanation_section(explanation),
    build_advisory_section(advisory_lines),
    build_history_section(history_hint),
  ]
  @domain.ReportView::{
    mode,
    decision: result.decision.label(),
    headline: explanation.headline,
    short_summary: "最近一次检查结论（\{mode} 模式）：\{result.decision.label()}",
    sections,
    next_steps: explanation.follow_up_steps,
    history_hint,
  }
}

///|
/// 把报告视图渲染成 Markdown。
pub fn render_report_view_markdown(view : @domain.ReportView) -> String {
  let lines : Array[String] = [
    "# MoonForge 报告视图",
    "",
    "## 总说",
    view.headline,
    "",
    view.short_summary,
  ]

  for section in view.sections {
    if !section.has_content() {
      continue
    }
    lines.push("")
    lines.push("## \{section.title}")
    if section.intro.trim() != "" {
      lines.push(section.intro)
    }
    for line in section.lines {
      lines.push("- \{line}")
    }
  }

  if !view.next_steps.is_empty() {
    lines.push("")
    lines.push("## 下一步建议")
    for step in view.next_steps {
      lines.push("- \{step}")
    }
  }

  lines.join("\n") + "\n"
}

///|
/// 从一行 `"前缀：内容"` 文本里提取后半段。
fn suffix_after_prefix(line : String, prefix : String) -> String? {
  if line.has_prefix(prefix) {
    Some(line[prefix.length():line.length()].to_string())
  } else {
    None
  }
}

///|
/// 统计中文顿号或逗号列表里有多少项。
fn count_list_items(text : String) -> Int {
  let trimmed = text.trim().to_string()
  if trimmed == "" {
    0
  } else {
    trimmed.split("，").collect().length()
  }
}

///|
/// 把报告视图渲染成终端短摘要。
pub fn render_report_terminal_summary(view : @domain.ReportView) -> String {
  let lines : Array[String] = [view.short_summary]
  for section in view.sections {
    if !section.has_content() {
      continue
    }
    if section.title == "运行来源" || section.title == "历史提示" {
      if !section.lines.is_empty() {
        lines.push("\{section.title}：\{section.lines[0]}")
      }
    } else if section.title == "任务摘要" {
      for line in section.lines {
        match suffix_after_prefix(line, "变更文件数：") {
          Some(value) => lines.push("变更文件：\{value}")
          None => ()
        }
      }
    } else if section.title == "材料与命令" {
      for line in section.lines {
        match suffix_after_prefix(line, "缺少材料：") {
          Some(value) => lines.push("缺失材料：\{count_list_items(value)}")
          None => ()
        }
        match suffix_after_prefix(line, "命令失败：") {
          Some(value) => lines.push("命令失败：\{count_list_items(value)}")
          None => ()
        }
      }
    }
  }
  if !view.next_steps.is_empty() {
    lines.push("下一步：\{view.next_steps[0]}")
  }
  lines.join("\n")
}
