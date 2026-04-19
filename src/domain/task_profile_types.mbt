///|
/// 文件总说：
/// 这个文件定义“任务画像”这层模型。
/// 它要回答的不是门禁结论，而是：
/// - 当前任务写得像不像一个完整任务
/// - 自动补全过程留下了哪些痕迹
/// - 这份任务文件到底包含了哪些关键输入

///|
/// 一次任务画像视图。
pub(all) struct TaskProfileView {
  headline : String
  summary : String
  lines : Array[String]
  need_user_review : Bool
} derive(Debug, ToJson)

///|
/// 任务画像是否有内容。
pub fn TaskProfileView::has_content(self : TaskProfileView) -> Bool {
  self.headline.trim() != "" || !self.lines.is_empty()
}

///|
/// 任务画像行数统计。
pub fn TaskProfileView::line_count(self : TaskProfileView) -> Int {
  let headline_count = if self.headline.trim() == "" { 0 } else { 1 }
  let summary_count = if self.summary.trim() == "" { 0 } else { 1 }
  headline_count + summary_count + self.lines.length()
}
