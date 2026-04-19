///|
/// 文件总说：
/// 这个文件检查“task 阶段看到的暂存文件”和“check 阶段 diff 里真正出现的文件”是不是一致。
/// 这类不一致通常说明两种情况：
/// - 用户在生成任务后又改了暂存区
/// - 当前任务文件已经有点过期
///
/// 这里同样不直接改判定，
/// 主要给 report 一个更直白的提醒：你现在看到的任务描述，可能和这次真正检查的输入不完全一致。

///|
/// 一条输入一致性提醒。
pub(all) struct RunConsistencyIssue {
  code : String
  severity : String
  detail : String
  suggestion : String
} derive(Debug)

///|
/// 一次输入一致性检查结果。
pub(all) struct RunConsistencyReview {
  shared_files : Array[String]
  task_only_files : Array[String]
  diff_only_files : Array[String]
  issues : Array[RunConsistencyIssue]
} derive(Debug)

///|
/// 取两个列表的交集。
fn collect_shared_files(
  left : Array[String],
  right : Array[String],
) -> Array[String] {
  let shared : Array[String] = []
  for item in left {
    if right.contains(item) {
      shared.push(item)
    }
  }
  shared
}

///|
/// 取只出现在左边、不出现在右边的条目。
fn collect_left_only_files(
  left : Array[String],
  right : Array[String],
) -> Array[String] {
  let items : Array[String] = []
  for item in left {
    if !right.contains(item) {
      items.push(item)
    }
  }
  items
}

///|
/// 检查 staged 文件列表和 diff 文件列表的一致性。
pub fn review_run_consistency(
  staged_files : Array[String],
  checked_files : Array[String],
) -> RunConsistencyReview {
  let shared_files = collect_shared_files(staged_files, checked_files)
  let task_only_files = collect_left_only_files(staged_files, checked_files)
  let diff_only_files = collect_left_only_files(checked_files, staged_files)
  let issues : Array[RunConsistencyIssue] = []

  if !task_only_files.is_empty() {
    issues.push({
      code: "TASK_STAGED_FILES_OLD",
      severity: "warning",
      detail: "任务文件里还记着 \{task_only_files.length()} 个旧的暂存文件",
      suggestion: "重新运行 moonforge task --type ...，让 current-task.yml 跟上当前暂存区",
    })
  }

  if !diff_only_files.is_empty() {
    issues.push({
      code: "DIFF_HAS_NEW_FILES",
      severity: "warning",
      detail: "本次检查里出现了 \{diff_only_files.length()} 个 task 阶段没有记录的新文件",
      suggestion: "检查是否在 task 之后又新增了改动；必要时重新生成 current-task.yml",
    })
  }

  if staged_files.is_empty() && !checked_files.is_empty() {
    issues.push({
      code: "TASK_MISSING_STAGED_SNAPSHOT",
      severity: "info",
      detail: "当前任务文件没有记录 staged_files，但这次检查确实读到了 diff 文件",
      suggestion: "重新执行一次 task，让任务文件把当前输入记录完整",
    })
  }

  { shared_files, task_only_files, diff_only_files, issues }
}

///|
/// 生成一致性检查摘要。
pub fn RunConsistencyReview::summary(self : RunConsistencyReview) -> String {
  [
    "shared=\{self.shared_files.length()}",
    "task_only=\{self.task_only_files.length()}",
    "diff_only=\{self.diff_only_files.length()}",
    "issues=\{self.issues.length()}",
  ].join(" | ")
}
