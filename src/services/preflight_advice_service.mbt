///|
/// 文件总说：
/// 这个文件把多个“提醒类 checker”的结果合成一份统一的提醒包。
/// 它的定位不是替代 gate，而是补足 gate 没有回答的那部分问题：
/// - 任务写得清不清楚
/// - task 和 check 的输入有没有轻微错位
/// - 材料虽然找到了，但放得是不是够规范
///
/// 这些问题很多时候不该直接拦截，
/// 但如果不说，用户又很容易踩第二次。

///|
/// 把任务聚焦提醒转成统一提醒项。
fn append_task_focus_items(
  items : Array[@domain.PreflightAdviceItem],
  review : @checkers.TaskFocusReview,
) -> Unit {
  for issue in review.issues {
    items.push(@domain.PreflightAdviceItem::{
      source: "task_focus_checker",
      severity: issue.severity,
      title: "任务范围聚焦度提醒",
      detail: issue.detail,
      suggestion: issue.suggestion,
    })
  }
}

///|
/// 把输入一致性提醒转成统一提醒项。
fn append_run_consistency_items(
  items : Array[@domain.PreflightAdviceItem],
  review : @checkers.RunConsistencyReview,
) -> Unit {
  for issue in review.issues {
    items.push(@domain.PreflightAdviceItem::{
      source: "run_consistency_checker",
      severity: issue.severity,
      title: "任务输入一致性提醒",
      detail: issue.detail,
      suggestion: issue.suggestion,
    })
  }
}

///|
/// 把材料策略提醒转成统一提醒项。
fn append_material_policy_items(
  items : Array[@domain.PreflightAdviceItem],
  review : @checkers.MaterialPolicyReview,
) -> Unit {
  for issue in review.issues {
    items.push(@domain.PreflightAdviceItem::{
      source: "material_policy_checker",
      severity: issue.severity,
      title: "材料目录与命名提醒",
      detail: issue.detail,
      suggestion: issue.suggestion,
    })
  }
}

///|
/// 把标题质量提醒转成统一提醒项。
fn append_task_description_items(
  items : Array[@domain.PreflightAdviceItem],
  review : @checkers.TaskDescriptionReview,
) -> Unit {
  for issue in review.issues {
    items.push(@domain.PreflightAdviceItem::{
      source: "task_description_checker",
      severity: issue.severity,
      title: "任务标题质量提醒",
      detail: issue.detail,
      suggestion: issue.suggestion,
    })
  }
}

///|
/// 根据提醒项生成一句总说。
fn build_bundle_summary(items : Array[@domain.PreflightAdviceItem]) -> String {
  if items.is_empty() {
    return "额外提醒：系统没有发现需要你再确认的点。"
  }

  let warning_count = items
    .filter(item => item.severity == "warning" || item.severity == "severe")
    .length()
  let info_count = items.filter(item => item.severity == "info").length()
  [
    "额外提醒一共 \{items.length()} 条",
    if warning_count > 0 {
      "高优先级 \{warning_count}"
    } else {
      ""
    },
    if info_count > 0 {
      "信息提示 \{info_count}"
    } else {
      ""
    },
  ]
  .filter(line => line != "")
  .join(" | ")
}

///|
/// 判断提醒包是否建议用户再回头看 current-task.yml。
fn bundle_needs_user_review(items : Array[@domain.PreflightAdviceItem]) -> Bool {
  for item in items {
    if item.severity == "warning" || item.severity == "severe" {
      return true
    }
  }
  false
}

///|
/// 构造完整的提醒包。
pub fn build_preflight_advice_bundle(
  repo_root : String,
  current_task : @domain.CurrentTask,
  effective_task : @domain.EffectiveTask,
  checked_files : Array[String],
  discovery : @domain.MaterialDiscoveryResult,
) -> @domain.PreflightAdviceBundle {
  let task_focus_review = @checkers.review_task_focus(
    effective_task, checked_files,
  )
  let run_consistency_review = @checkers.review_run_consistency(
    current_task.staged_files,
    checked_files,
  )
  let material_policy_review = @checkers.review_material_policy(
    repo_root,
    current_task,
    effective_task.required_artifacts,
    discovery,
  )
  let task_description_review = @checkers.review_task_description(current_task)

  let items : Array[@domain.PreflightAdviceItem] = []
  append_task_focus_items(items, task_focus_review)
  append_run_consistency_items(items, run_consistency_review)
  append_material_policy_items(items, material_policy_review)
  append_task_description_items(items, task_description_review)

  @domain.PreflightAdviceBundle::{
    summary: build_bundle_summary(items),
    items,
    need_user_review: bundle_needs_user_review(items),
  }
}

///|
/// 把提醒包渲染成 Markdown。
pub fn render_preflight_advice_markdown(
  bundle : @domain.PreflightAdviceBundle,
) -> String {
  let lines : Array[String] = [
    "# MoonForge 额外提醒",
    "",
    "## 总说",
    bundle.summary,
  ]

  if bundle.items.is_empty() {
    lines.push("")
    lines.push("当前没有额外提醒。")
    return lines.join("\n") + "\n"
  }

  lines.push("")
  lines.push("## 分说")
  for item in bundle.items {
    lines.push("")
    lines.push("### \{item.title}")
    lines.push("- 来源：\{item.source}")
    lines.push("- 严重级别：\{item.severity}")
    lines.push("- 详情：\{item.detail}")
    lines.push("- 建议：\{item.suggestion}")
  }
  lines.join("\n") + "\n"
}
