///|
/// 文件总说：
/// 这个文件定义“运行输入说明”这层模型。
/// 它的目的很直接：
/// 让人看到一次运行结果时，不用猜：
/// - patch 是从哪里来的
/// - 材料主目录是哪
/// - 系统又额外去哪些地方找过材料

///|
/// 一次运行输入说明视图。
pub(all) struct RunInputStoryView {
  headline : String
  mode : String
  run_dir : String
  artifact_source_dir : String
  search_directories : Array[String]
  discovered_artifact_count : Int
  missing_artifact_count : Int
  lines : Array[String]
} derive(Debug, ToJson)

///|
/// 这份输入说明是否有内容。
pub fn RunInputStoryView::has_content(self : RunInputStoryView) -> Bool {
  self.headline.trim() != "" || !self.lines.is_empty()
}

///|
/// 生成输入说明的简短摘要。
pub fn RunInputStoryView::summary(self : RunInputStoryView) -> String {
  [
    "mode=\{self.mode}",
    "run_dir=\{self.run_dir}",
    "search_dirs=\{self.search_directories.length()}",
    "found=\{self.discovered_artifact_count}",
    "missing=\{self.missing_artifact_count}",
  ].join(" | ")
}
