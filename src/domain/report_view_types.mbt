///|
/// 文件总说：
/// 这个文件定义 report 命令真正展示给人的视图模型。
/// 目的很简单：
/// - 命令编排层不要自己拼很多字符串
/// - report、replay、pack 想复用同一份摘要时有统一结构
///
/// 所以这里把报告拆成：
/// 1. `ReportViewSection`：一块一块的信息
/// 2. `ReportView`：完整的一次报告

///|
/// 报告中的一个分块。
pub(all) struct ReportViewSection {
  title : String
  intro : String
  lines : Array[String]
  is_warning : Bool
} derive(Debug, ToJson)

///|
/// 这个分块有没有真正的内容。
pub fn ReportViewSection::has_content(self : ReportViewSection) -> Bool {
  self.intro.trim() != "" || !self.lines.is_empty()
}

///|
/// 返回分块里的总行数。
pub fn ReportViewSection::line_count(self : ReportViewSection) -> Int {
  let intro_count = if self.intro.trim() == "" { 0 } else { 1 }
  intro_count + self.lines.length()
}

///|
/// 一次完整报告。
pub(all) struct ReportView {
  mode : String
  decision : String
  headline : String
  short_summary : String
  sections : Array[ReportViewSection]
  next_steps : Array[String]
  history_hint : String
} derive(Debug, ToJson)

///|
/// 报告里是否存在告警分块。
pub fn ReportView::has_warning_sections(self : ReportView) -> Bool {
  for section in self.sections {
    if section.is_warning {
      return true
    }
  }
  false
}

///|
/// 统计报告有多少个真正有内容的分块。
pub fn ReportView::filled_section_count(self : ReportView) -> Int {
  let mut count = 0
  for section in self.sections {
    if section.has_content() {
      count = count + 1
    }
  }
  count
}

///|
/// 生成一段简短摘要，供调试或日志使用。
pub fn ReportView::summary(self : ReportView) -> String {
  [
    "mode=\{self.mode}",
    "decision=\{self.decision}",
    "sections=\{self.filled_section_count()}",
    "warning=\{self.has_warning_sections()}",
  ].join(" | ")
}
