///|
/// 文件总说：
/// 这个文件专门检查任务标题是不是“写了跟没写差不多”。
/// 这类问题对门禁结果不一定有直接影响，
/// 但对团队理解任务非常重要。
///
/// 比如这些标题就很弱：
/// - 修改
/// - 调整
/// - 处理改动
/// - 更新文件
///
/// 看的人根本不知道这次到底改了什么。

///|
/// 一条标题质量提醒。
pub(all) struct TaskDescriptionIssue {
  code : String
  severity : String
  detail : String
  suggestion : String
} derive(Debug)

///|
/// 一次标题质量检查结果。
pub(all) struct TaskDescriptionReview {
  normalized_title : String
  issues : Array[TaskDescriptionIssue]
} derive(Debug)

///|
/// 判断标题是不是明显太泛。
fn title_is_generic(title : String) -> Bool {
  let generic_titles = [
    "修改", "调整", "更新", "处理", "改动", "处理改动", "更新文件",
  ]
  if generic_titles.contains(title) {
    return true
  }
  title.has_suffix("改动") || title.has_suffix("文件")
}

///|
/// 规范化标题文本。
fn normalize_title(title : String) -> String {
  title.trim().to_string()
}

///|
/// 检查当前任务标题质量。
pub fn review_task_description(
  current_task : @domain.CurrentTask,
) -> TaskDescriptionReview {
  let normalized_title = normalize_title(current_task.title)
  let issues : Array[TaskDescriptionIssue] = []

  if normalized_title == "" {
    issues.push({
      code: "TASK_TITLE_EMPTY",
      severity: "warning",
      detail: "当前任务标题还是空的",
      suggestion: "给任务补一个能直接说清楚改动对象的标题",
    })
  } else {
    if normalized_title.length() <= 2 {
      issues.push({
        code: "TASK_TITLE_TOO_SHORT",
        severity: "warning",
        detail: "当前任务标题太短，别人很难看懂你在做什么",
        suggestion: "尽量写到“动作 + 对象”这个粒度，比如“补充用户列表筛选”",
      })
    }

    if title_is_generic(normalized_title) {
      issues.push({
        code: "TASK_TITLE_TOO_GENERIC",
        severity: "info",
        detail: "当前任务标题偏泛，信息量不够",
        suggestion: "把标题改得更具体一点，至少点出改动对象",
      })
    }
  }

  if current_task.need_user_review {
    issues.push({
      code: "TASK_STILL_NEEDS_REVIEW",
      severity: "info",
      detail: "系统之前已经标记这份任务建议人工再看一眼",
      suggestion: "打开 current-task.yml，确认标题和范围是不是准确",
    })
  }

  { normalized_title, issues }
}

///|
/// 生成标题质量检查摘要。
pub fn TaskDescriptionReview::summary(self : TaskDescriptionReview) -> String {
  ["title=\{self.normalized_title}", "issues=\{self.issues.length()}"].join(
    " | ",
  )
}
