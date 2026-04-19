///|
/// 文件总说：
/// 这个文件定义“输出目录导航”要用到的结构。
/// 它要解决的问题很实际：
/// 结果目录里的文件越来越多，
/// 如果没有一份说明，新接手的人根本不知道应该先看哪个。
///
/// 所以这里提供两层结构：
/// 1. `OutputCatalogEntry`：单个文件是干什么的
/// 2. `OutputCatalogView`：整份输出目录应该怎么读

///|
/// 一条输出文件说明。
pub(all) struct OutputCatalogEntry {
  file_name : String
  title : String
  purpose : String
  when_to_read : String
} derive(Debug, ToJson)

///|
/// 输出文件说明的一行摘要。
pub fn OutputCatalogEntry::summary_line(self : OutputCatalogEntry) -> String {
  "\{self.file_name} -> \{self.title}"
}

///|
/// 整份输出目录导航视图。
pub(all) struct OutputCatalogView {
  headline : String
  mode : String
  entries : Array[OutputCatalogEntry]
} derive(Debug, ToJson)

///|
/// 判断导航里是否至少有一个条目。
pub fn OutputCatalogView::has_entries(self : OutputCatalogView) -> Bool {
  !self.entries.is_empty()
}

///|
/// 返回导航条目数。
pub fn OutputCatalogView::count(self : OutputCatalogView) -> Int {
  self.entries.length()
}

///|
/// 按文件名查找目录条目。
pub fn OutputCatalogView::find_entry(
  self : OutputCatalogView,
  file_name : String,
) -> OutputCatalogEntry? {
  for entry in self.entries {
    if entry.file_name == file_name {
      return Some(entry)
    }
  }
  None
}

///|
/// 返回所有条目的标题列表。
pub fn OutputCatalogView::titles(self : OutputCatalogView) -> Array[String] {
  let titles : Array[String] = []
  for entry in self.entries {
    titles.push(entry.title)
  }
  titles
}

///|
/// 生成导航摘要。
pub fn OutputCatalogView::summary(self : OutputCatalogView) -> String {
  [
    "mode=\{self.mode}",
    "entries=\{self.entries.length()}",
    "headline=\{self.headline}",
  ].join(" | ")
}
