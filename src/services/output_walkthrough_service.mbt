///|
/// 文件总说：
/// 这个文件负责把一堆输出文件串成“普通人该怎么读”的路径。
/// 它比 `output-catalog` 更进一步：
/// - 目录导航回答“文件分别是什么”
/// - 阅读指引回答“你应该按什么顺序读”
///
/// 这份指引尤其适合两类人：
/// 1. 第一次接触 MoonForge 的使用者
/// 2. 只拿到结果目录、没参与这轮开发的人

///|
/// 方便构造步骤对象的小函数。
fn step(
  title : String,
  why_it_matters : String,
  action : String,
) -> @domain.OutputWalkthroughStep {
  @domain.OutputWalkthroughStep::{ title, why_it_matters, action }
}

///|
/// 根据报告视图生成“为什么应该先看结论摘要”的解释。
fn decision_step_reason(report_view : @domain.ReportView) -> String {
  let section_count = report_view.filled_section_count()
  if report_view.has_warning_sections() {
    "因为这次结果里不只有结论，还有 \{section_count} 个有内容的分块，而且其中包含告警分块，先看摘要最不容易迷路。"
  } else {
    "因为这次结果里虽然有 \{section_count} 个有内容的分块，但整体比较平稳，先看摘要就能很快掌握主线。"
  }
}

///|
/// 根据报告视图生成“读完整报告时要关注什么”的动作说明。
fn report_step_action(report_view : @domain.ReportView) -> String {
  if report_view.has_warning_sections() {
    "读报告时优先留意告警分块，再决定要不要继续钻到 decision-explanation.md。"
  } else {
    "读报告时先按任务、输入、历史这几块顺着看，确认系统对这次任务的理解是不是和你一致。"
  }
}

///|
/// 根据任务画像生成额外说明。
fn task_profile_reason(task_profile : @domain.TaskProfileView) -> String {
  let line_count = task_profile.line_count()
  if task_profile.need_user_review {
    "这份画像一共有 \{line_count} 行关键信息，而且系统明确建议人工再确认一次。"
  } else {
    "这份画像一共有 \{line_count} 行关键信息，足够帮助你确认自动补全的结果。"
  }
}

///|
/// 根据输入来源说明生成额外解释。
fn input_story_reason(run_input_story : @domain.RunInputStoryView) -> String {
  "这次输入说明覆盖了 \{run_input_story.search_directories.length()} 个材料搜索目录，命中 \{run_input_story.discovered_artifact_count} 个材料，缺少 \{run_input_story.missing_artifact_count} 个材料。"
}

///|
/// 根据目录导航生成“为什么要把它当字典”的解释。
fn catalog_reason(output_catalog : @domain.OutputCatalogView) -> String {
  "当前目录导航一共解释了 \{output_catalog.count()} 个输出文件，所以它更像结果目录的说明书。"
}

///|
/// 第一步：先看结论。
fn build_decision_step(
  report_view : @domain.ReportView,
) -> @domain.OutputWalkthroughStep {
  step(
    "先看 report-summary.txt",
    decision_step_reason(report_view),
    "如果这里只看一眼还不够，再继续看 report-view.md。",
  )
}

///|
/// 第二步：看完整报告。
fn build_report_step(
  report_view : @domain.ReportView,
) -> @domain.OutputWalkthroughStep {
  let warning_hint = if report_view.has_warning_sections() {
    "这次报告里有告警分块，说明还有值得重点看的部分。"
  } else {
    "这次报告整体比较平稳，主要是帮助你理解输入和结果。"
  }
  step(
    "再看 report-view.md",
    "这份报告最接近“人类最终解释版”，它会把任务、范围、材料、历史和提醒串起来。 \{warning_hint}",
    report_step_action(report_view),
  )
}

///|
/// 第三步：看结论原因。
fn build_explanation_step() -> @domain.OutputWalkthroughStep {
  step(
    "然后看 decision-explanation.md", "这里会把问题按主题分组，比如范围问题、材料问题、命令问题。",
    "如果你已经知道哪里有问题，但想知道系统为什么这么判断，就看这个文件。",
  )
}

///|
/// 第四步：看任务画像。
fn build_task_profile_step(
  task_profile : @domain.TaskProfileView,
) -> @domain.OutputWalkthroughStep {
  let review_hint = if task_profile.need_user_review {
    "当前任务还建议人工再看一眼。"
  } else {
    "当前任务看起来已经比较稳定。"
  }
  step(
    "如果怀疑 task 猜错了，就看 task-profile.md",
    "这份画像会解释系统到底把 current-task.yml 理解成了什么任务。 \{review_hint} \{task_profile_reason(task_profile)}",
    "当你觉得标题不对、范围不对、材料要求不对时优先看它。",
  )
}

///|
/// 第五步：看输入来源。
fn build_input_story_step(
  run_input_story : @domain.RunInputStoryView,
) -> @domain.OutputWalkthroughStep {
  step(
    "如果怀疑输入拿错了，就看 run-input-story.md",
    "这里会说明 patch 在哪、材料主目录在哪、系统还去哪些目录找过材料。 \{input_story_reason(run_input_story)}",
    "当你想确认“系统到底拿了什么来判定”时看它。",
  )
}

///|
/// 第六步：看额外提醒。
fn build_preflight_step(
  preflight_advice : @domain.PreflightAdviceBundle,
) -> @domain.OutputWalkthroughStep {
  let summary = if preflight_advice.summary.trim() == "" {
    "这一步主要是补充性提醒。"
  } else {
    preflight_advice.summary
  }
  step(
    "如果结果过了但你还不放心，就看 preflight-advice.md",
    "这个文件记录的是不会直接改判定、但很值得你回头再看一眼的点。 \{summary}",
    "当你想把任务写得更清楚、把材料放得更规范时看它。",
  )
}

///|
/// 最后一步：遇到调试场景时看目录导航。
fn build_catalog_step(
  output_catalog : @domain.OutputCatalogView,
) -> @domain.OutputWalkthroughStep {
  step(
    "最后把 output-catalog.md 当字典用",
    "如果你已经知道大概问题在哪，但还不清楚某个文件具体干嘛，目录导航最省事。 \{catalog_reason(output_catalog)}",
    "你可以把它当“输出目录说明书”，随查随用。",
  )
}

///|
/// 在阅读顺序之前，再补一句“看到什么情况时应该停下来处理”。
fn build_stop_rule_lines(
  preflight_advice : @domain.PreflightAdviceBundle,
  report_view : @domain.ReportView,
) -> Array[String] {
  let lines : Array[String] = []
  if report_view.has_warning_sections() {
    lines.push(
      "如果 report-view.md 里已经出现告警分块，就不要只停留在摘要。",
    )
  }
  if preflight_advice.need_user_review {
    lines.push(
      "如果 preflight-advice 里提示需要人工再看一眼，优先回头检查 current-task.yml。",
    )
  }
  if lines.is_empty() {
    lines.push(
      "如果摘要、报告和任务画像三者看起来一致，这次结果通常已经足够清楚。",
    )
  }
  lines
}

///|
/// 构造完整阅读指引。
pub fn build_output_walkthrough_view(
  task_profile : @domain.TaskProfileView,
  run_input_story : @domain.RunInputStoryView,
  report_view : @domain.ReportView,
  preflight_advice : @domain.PreflightAdviceBundle,
  output_catalog : @domain.OutputCatalogView,
) -> @domain.OutputWalkthroughView {
  let stop_rule_lines = build_stop_rule_lines(preflight_advice, report_view)
  let headline_lines : Array[String] = [
    "这份阅读指引告诉第一次接触这次结果的人：应该先看哪个文件、再看哪个文件、每一步是为了解决什么疑问。",
  ]
  for line in stop_rule_lines {
    headline_lines.push(line)
  }
  @domain.OutputWalkthroughView::{
    headline: headline_lines.join(" "),
    steps: [
      build_decision_step(report_view),
      build_report_step(report_view),
      build_explanation_step(),
      build_task_profile_step(task_profile),
      build_input_story_step(run_input_story),
      build_preflight_step(preflight_advice),
      build_catalog_step(output_catalog),
    ],
  }
}

///|
/// 把阅读指引渲染成 Markdown。
pub fn render_output_walkthrough_markdown(
  view : @domain.OutputWalkthroughView,
) -> String {
  let lines : Array[String] = [
    "# MoonForge 结果阅读指引",
    "",
    "## 总说",
    view.headline,
    "",
    view.summary(),
    "",
    "## 推荐阅读顺序",
  ]
  let mut index = 1
  for item in view.steps {
    lines.push("")
    lines.push("\{index}. \{item.title}")
    lines.push("为什么看：\{item.why_it_matters}")
    lines.push("怎么做：\{item.action}")
    index = index + 1
  }
  lines.join("\n") + "\n"
}
