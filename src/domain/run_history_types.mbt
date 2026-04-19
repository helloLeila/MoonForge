///|
/// 文件总说：
/// 这个文件定义“运行历史”这层模型。
/// 它专门解决一个很实际的问题：
/// 用户不只想看这一次是 `Accept` 还是 `Reject`，
/// 还想知道最近几次检查是不是一直失败、失败点是不是同一类、这次是不是刚修好。
///
/// 所以这里把历史拆成两层：
/// 1. `RunHistoryRecord` 表示单次运行
/// 2. `RunHistoryIndex` 表示一组按时间倒序管理的运行记录
///
/// 这样 `report`、`replay`、`pack` 都能共享同一套历史视图。

///|
/// 一条运行历史记录。
/// 这里保留的字段都是“看历史时最常用”的东西，
/// 目标不是完整复制快照文件，而是让人快速理解这次运行发生了什么。
pub(all) struct RunHistoryRecord {
  run_id : String
  mode : String
  decision : String
  task_type : String
  title : String
  checked_file_count : Int
  missing_artifact_count : Int
  invalid_artifact_count : Int
  command_failure_count : Int
  violation_count : Int
  context_summary : String
  next_action : String
  created_at_ns : String
} derive(Debug, ToJson)

///|
/// 判断这条历史记录是否就是指定的运行编号。
pub fn RunHistoryRecord::matches_run_id(
  self : RunHistoryRecord,
  run_id : String,
) -> Bool {
  self.run_id == run_id
}

///|
/// 判断这次运行是不是“有问题的运行”。
/// 这里故意用很白话的规则：
/// - 只要不是 Accept，就算需要关注
pub fn RunHistoryRecord::needs_attention(self : RunHistoryRecord) -> Bool {
  self.decision != "Accept"
}

///|
/// 把单条历史记录压缩成一行摘要。
/// 这个摘要适合直接放到 report 的“最近几次运行”块里。
pub fn RunHistoryRecord::summary_line(self : RunHistoryRecord) -> String {
  let parts : Array[String] = [
    "\{self.run_id}",
    "\{self.mode}",
    "\{self.decision}",
    "\{self.task_type}",
    "文件 \{self.checked_file_count}",
  ]
  if self.missing_artifact_count > 0 {
    parts.push("缺料 \{self.missing_artifact_count}")
  }
  if self.invalid_artifact_count > 0 {
    parts.push("材料无效 \{self.invalid_artifact_count}")
  }
  if self.command_failure_count > 0 {
    parts.push("命令失败 \{self.command_failure_count}")
  }
  if self.violation_count > 0 {
    parts.push("违规 \{self.violation_count}")
  }
  parts.join(" | ")
}

///|
/// 一组运行历史记录。
/// 约定：
/// - `records[0]` 永远代表最近一次
/// - 越往后越旧
pub(all) struct RunHistoryIndex {
  records : Array[RunHistoryRecord]
} derive(Debug, ToJson)

///|
/// 判断历史索引里有没有记录。
pub fn RunHistoryIndex::is_empty(self : RunHistoryIndex) -> Bool {
  self.records.is_empty()
}

///|
/// 返回历史记录总数。
pub fn RunHistoryIndex::count(self : RunHistoryIndex) -> Int {
  self.records.length()
}

///|
/// 读取最近一次历史记录。
pub fn RunHistoryIndex::latest(self : RunHistoryIndex) -> RunHistoryRecord? {
  if self.records.is_empty() {
    None
  } else {
    Some(self.records[0])
  }
}

///|
/// 在历史索引里按运行编号查找记录。
pub fn RunHistoryIndex::find_by_run_id(
  self : RunHistoryIndex,
  run_id : String,
) -> RunHistoryRecord? {
  for record in self.records {
    if record.matches_run_id(run_id) {
      return Some(record)
    }
  }
  None
}

///|
/// 返回最近 N 条记录。
/// 如果历史数量不足，就直接返回全部。
pub fn RunHistoryIndex::latest_n(
  self : RunHistoryIndex,
  limit : Int,
) -> Array[RunHistoryRecord] {
  if limit <= 0 {
    return []
  }
  let selected : Array[RunHistoryRecord] = []
  let max_count = if self.records.length() < limit {
    self.records.length()
  } else {
    limit
  }
  for i in 0..<max_count {
    selected.push(self.records[i])
  }
  selected
}

///|
/// 统计历史里各类结论出现了多少次。
/// 这样上层就能很快知道：
/// - 最近是不是连续 Reject
/// - Retryable 是否很多
pub fn RunHistoryIndex::decision_counts(
  self : RunHistoryIndex,
) -> Map[String, Int] {
  let counts : Map[String, Int] = {}
  for record in self.records {
    let current = counts.get_or_default(record.decision, 0)
    counts[record.decision] = current + 1
  }
  counts
}

///|
/// 返回历史里需要关注的记录数量。
pub fn RunHistoryIndex::attention_count(self : RunHistoryIndex) -> Int {
  let mut count = 0
  for record in self.records {
    if record.needs_attention() {
      count = count + 1
    }
  }
  count
}

///|
/// 只保留最近的若干条历史记录。
/// 这个函数主要给写入历史索引时做裁剪，避免历史文件无限长大。
pub fn RunHistoryIndex::trimmed(
  self : RunHistoryIndex,
  keep : Int,
) -> RunHistoryIndex {
  if keep <= 0 {
    return { records: [] }
  }
  let trimmed : Array[RunHistoryRecord] = []
  let max_count = if self.records.length() < keep {
    self.records.length()
  } else {
    keep
  }
  for i in 0..<max_count {
    trimmed.push(self.records[i])
  }
  { records: trimmed }
}

///|
/// 判断历史里是否已经包含指定运行编号。
pub fn RunHistoryIndex::contains_run_id(
  self : RunHistoryIndex,
  run_id : String,
) -> Bool {
  self.find_by_run_id(run_id) is Some(_)
}

///|
/// 生成历史索引的简短摘要。
/// 这段摘要适合放到调试信息或日志里。
pub fn RunHistoryIndex::summary(self : RunHistoryIndex) -> String {
  let counts = self.decision_counts()
  let accept_count = counts.get_or_default("Accept", 0)
  let retryable_count = counts.get_or_default("Retryable", 0)
  let reject_count = counts.get_or_default("Reject", 0)
  let approval_count = counts.get_or_default("NeedHumanApproval", 0)
  [
    "records=\{self.count()}",
    "attention=\{self.attention_count()}",
    "accept=\{accept_count}",
    "retryable=\{retryable_count}",
    "reject=\{reject_count}",
    "approval=\{approval_count}",
  ].join(" | ")
}
