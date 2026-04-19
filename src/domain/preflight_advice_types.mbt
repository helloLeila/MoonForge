///|
/// 文件总说：
/// 这个文件定义“额外提醒”这层输出模型。
/// 这些提醒和最终门禁结论不是一回事：
/// - 结论回答“能不能过”
/// - 提醒回答“虽然可能能过，但还有哪里建议你再看一眼”
///
/// 这样做的目的很明确：
/// 让 `report` 不只是像裁判给结果，
/// 也像老师给你指出哪些地方可能还不够稳。

///|
/// 一条额外提醒。
/// 这里统一保存来源、严重级别、标题、详情和建议动作，
/// 方便来自不同 checker 的提醒都走同一套展示格式。
pub(all) struct PreflightAdviceItem {
  source : String
  severity : String
  title : String
  detail : String
  suggestion : String
} derive(Debug, ToJson)

///|
/// 把一条提醒压成一行摘要。
pub fn PreflightAdviceItem::summary_line(self : PreflightAdviceItem) -> String {
  "[\{self.severity}] \{self.title}：\{self.detail}"
}

///|
/// 一组提醒的汇总。
pub(all) struct PreflightAdviceBundle {
  summary : String
  items : Array[PreflightAdviceItem]
  need_user_review : Bool
} derive(Debug, ToJson)

///|
/// 判断有没有任何提醒项。
pub fn PreflightAdviceBundle::has_items(self : PreflightAdviceBundle) -> Bool {
  !self.items.is_empty()
}

///|
/// 统计高优先级提醒有多少条。
pub fn PreflightAdviceBundle::warning_count(
  self : PreflightAdviceBundle,
) -> Int {
  let mut count = 0
  for item in self.items {
    if item.severity == "warning" || item.severity == "severe" {
      count = count + 1
    }
  }
  count
}

///|
/// 把提醒组装成适合 report 使用的普通文本行。
pub fn PreflightAdviceBundle::report_lines(
  self : PreflightAdviceBundle,
) -> Array[String] {
  let lines : Array[String] = []
  if self.summary.trim() != "" {
    lines.push(self.summary)
  }
  for item in self.items {
    lines.push(item.summary_line())
    lines.push("建议：\{item.suggestion}")
  }
  lines
}
