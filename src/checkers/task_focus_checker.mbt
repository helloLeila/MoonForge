///|
/// 文件总说：
/// 这个文件专门检查“任务范围和实际改动是不是一回事”。
/// 这类问题很常见：
/// - 任务写得太宽，像是把半个项目都包进去了
/// - 任务写得太窄，结果实际改动有一部分没覆盖到
/// - 任务目标虽然合法，但读起来过于笼统
///
/// 这里不直接决定放行或拒绝，
/// 主要是给 report 多一层“范围是否讲清楚”的提醒。

///|
/// 一条任务聚焦提醒。
pub(all) struct TaskFocusIssue {
  code : String
  severity : String
  detail : String
  suggestion : String
} derive(Debug)

///|
/// 一次任务聚焦检查的结果。
pub(all) struct TaskFocusReview {
  matched_files : Array[String]
  uncovered_files : Array[String]
  broad_patterns : Array[String]
  issues : Array[TaskFocusIssue]
} derive(Debug)

///|
/// 判断一个允许路径是不是“特别宽”的模式。
fn pattern_is_broad(pattern : String) -> Bool {
  pattern == "**" ||
  pattern == "*" ||
  pattern.has_suffix("/**") ||
  pattern.has_suffix("/*")
}

///|
/// 统计哪些实际改动文件已经被任务范围覆盖到。
fn collect_matched_files(
  allowed_paths : Array[String],
  checked_files : Array[String],
) -> Array[String] {
  let matched : Array[String] = []
  for file in checked_files {
    if @infra.matches_any(file, allowed_paths) {
      matched.push(file)
    }
  }
  matched
}

///|
/// 挑出哪些实际改动文件还没有被任务范围解释清楚。
fn collect_uncovered_files(
  matched_files : Array[String],
  checked_files : Array[String],
) -> Array[String] {
  let uncovered : Array[String] = []
  for file in checked_files {
    if !matched_files.contains(file) {
      uncovered.push(file)
    }
  }
  uncovered
}

///|
/// 列出那些过于宽泛的允许路径。
fn collect_broad_patterns(allowed_paths : Array[String]) -> Array[String] {
  let broad : Array[String] = []
  for pattern in allowed_paths {
    if pattern_is_broad(pattern) {
      broad.push(pattern)
    }
  }
  broad
}

///|
/// 生成任务聚焦检查结果。
pub fn review_task_focus(
  effective_task : @domain.EffectiveTask,
  checked_files : Array[String],
) -> TaskFocusReview {
  let matched_files = collect_matched_files(
    effective_task.allowed_paths,
    checked_files,
  )
  let uncovered_files = collect_uncovered_files(matched_files, checked_files)
  let broad_patterns = collect_broad_patterns(effective_task.allowed_paths)
  let issues : Array[TaskFocusIssue] = []

  if effective_task.allowed_paths.is_empty() {
    issues.push({
      code: "TASK_SCOPE_EMPTY",
      severity: "warning",
      detail: "当前任务没有显式的允许范围，解释性会很弱",
      suggestion: "补充更明确的 target_groups 或 target_paths",
    })
  }

  if !uncovered_files.is_empty() {
    issues.push({
      code: "TASK_SCOPE_COVERAGE_WEAK",
      severity: "warning",
      detail: "有 \{uncovered_files.length()} 个实际改动文件没有被任务范围很好地解释",
      suggestion: "回头检查 current-task.yml，确认任务范围有没有写全",
    })
  }

  if !broad_patterns.is_empty() {
    issues.push({
      code: "TASK_SCOPE_TOO_BROAD",
      severity: "info",
      detail: "当前任务里有 \{broad_patterns.length()} 条范围写得比较宽",
      suggestion: "如果条件允许，尽量把范围缩到更具体的目录或文件",
    })
  }

  { matched_files, uncovered_files, broad_patterns, issues }
}

///|
/// 把任务聚焦结果压成一段摘要。
pub fn TaskFocusReview::summary(self : TaskFocusReview) -> String {
  [
    "matched=\{self.matched_files.length()}",
    "uncovered=\{self.uncovered_files.length()}",
    "broad=\{self.broad_patterns.length()}",
    "issues=\{self.issues.length()}",
  ].join(" | ")
}
