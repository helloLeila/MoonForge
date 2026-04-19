///|
/// 文件总说：
/// 这个文件负责“怎么维护运行历史”。
/// 上一层命令编排只需要关心：
/// - 这次运行结束了
/// - 我要把它记进历史里
/// - 我还想拿最近几次运行做提示
///
/// 具体怎么裁剪、怎么去重、怎么给用户展示，
/// 都放在这里统一处理。

///|
/// 历史最多保留多少条。
/// 这里取一个偏保守的值：
/// - 足够看最近趋势
/// - 又不会把历史文件养得太大
fn history_keep_limit() -> Int {
  50
}

///|
/// 根据一次检查结果构造单条历史记录。
pub fn build_run_history_record(
  result : @domain.CheckResult,
  mode : String,
  context_summary : String,
  created_at_ns : String,
) -> @domain.RunHistoryRecord {
  @domain.RunHistoryRecord::{
    run_id: result.run_id,
    mode,
    decision: result.decision.label(),
    task_type: result.effective_task.task_type,
    title: result.effective_task.title,
    checked_file_count: result.checked_files.length(),
    missing_artifact_count: result.missing_artifacts.length(),
    invalid_artifact_count: result.invalid_artifacts.length(),
    command_failure_count: result.command_failures.length(),
    violation_count: result.violations.length(),
    context_summary,
    next_action: result.decision.next_action(),
    created_at_ns,
  }
}

///|
/// 把一条新记录插到历史最前面，同时去掉旧的同 run_id 记录。
fn prepend_record(
  index : @domain.RunHistoryIndex,
  record : @domain.RunHistoryRecord,
) -> @domain.RunHistoryIndex {
  let records : Array[@domain.RunHistoryRecord] = [record]
  for existing in index.records {
    if !existing.matches_run_id(record.run_id) {
      records.push(existing)
    }
  }
  { records, }
}

///|
/// 把最新运行写回历史文件。
pub fn record_run_history(
  repo_root : String,
  record : @domain.RunHistoryRecord,
) -> @domain.RunHistoryIndex raise {
  let current = @infra.read_run_history_index(repo_root)
  let next = prepend_record(current, record).trimmed(history_keep_limit())
  @infra.write_run_history_index(repo_root, next)
  next
}

///|
/// 读取仓库中的运行历史。
pub fn read_run_history(repo_root : String) -> @domain.RunHistoryIndex raise {
  @infra.read_run_history_index(repo_root)
}

///|
/// 只挑出最近若干条历史摘要行。
pub fn render_recent_history_lines(
  index : @domain.RunHistoryIndex,
  limit : Int,
) -> Array[String] {
  let lines : Array[String] = []
  for record in index.latest_n(limit) {
    lines.push(record.summary_line())
  }
  lines
}

///|
/// 给 report 提供一段很短的历史提示。
/// 这段提示的目的不是列全，而是回答：
/// - 最近是不是稳定
/// - 最近有没有连续失败
pub fn render_history_hint(index : @domain.RunHistoryIndex) -> String {
  if index.is_empty() {
    return "还没有历史运行记录"
  }
  let counts = index.decision_counts()
  let accept_count = counts.get_or_default("Accept", 0)
  let retryable_count = counts.get_or_default("Retryable", 0)
  let reject_count = counts.get_or_default("Reject", 0)
  let approval_count = counts.get_or_default("NeedHumanApproval", 0)
  let latest_line = match index.latest() {
    Some(record) => record.summary_line()
    None => ""
  }
  [
    "最近 \{index.count()} 次",
    "Accept \{accept_count}",
    "Retryable \{retryable_count}",
    "Reject \{reject_count}",
    "NeedHumanApproval \{approval_count}",
    if latest_line == "" {
      ""
    } else {
      "最新：\{latest_line}"
    },
  ]
  .filter(item => item != "")
  .join(" | ")
}

///|
/// 按任务类型筛出最近若干条相关历史。
/// 这样 report 就能回答“这个任务类型最近是不是经常出问题”。
pub fn filter_history_by_task_type(
  index : @domain.RunHistoryIndex,
  task_type : String,
  limit : Int,
) -> Array[@domain.RunHistoryRecord] {
  if limit <= 0 {
    return []
  }
  let matched : Array[@domain.RunHistoryRecord] = []
  for record in index.records {
    if record.task_type == task_type {
      matched.push(record)
      if matched.length() >= limit {
        return matched
      }
    }
  }
  matched
}

///|
/// 给指定任务类型生成一段趋势提示。
pub fn render_task_type_trend_hint(
  index : @domain.RunHistoryIndex,
  task_type : String,
  limit : Int,
) -> String {
  let records = filter_history_by_task_type(index, task_type, limit)
  if records.is_empty() {
    return "历史里还没有 \{task_type} 的运行记录"
  }
  let decision_counts : Map[String, Int] = {}
  for record in records {
    decision_counts[record.decision] = decision_counts.get_or_default(
        record.decision,
        0,
      ) +
      1
  }
  let accept_count = decision_counts.get_or_default("Accept", 0)
  let retryable_count = decision_counts.get_or_default("Retryable", 0)
  let reject_count = decision_counts.get_or_default("Reject", 0)
  [
    "\{task_type} 最近 \{records.length()} 次",
    "Accept \{accept_count}",
    "Retryable \{retryable_count}",
    "Reject \{reject_count}",
  ].join(" | ")
}
