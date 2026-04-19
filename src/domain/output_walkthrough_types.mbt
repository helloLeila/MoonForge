///|
/// 文件总说：
/// 这个文件定义“结果阅读指引”这层结构。
/// 目录导航只告诉你“每个文件是什么”，
/// 但第一次接触 MoonForge 的人还会问：
/// - 那我到底先看哪个？
/// - 什么时候该跳到另一个文件？
///
/// 所以这里再多一层“阅读顺序”模型。

///|
/// 指引里的一个步骤。
pub(all) struct OutputWalkthroughStep {
  title : String
  why_it_matters : String
  action : String
} derive(Debug, ToJson)

///|
/// 一整份阅读指引。
pub(all) struct OutputWalkthroughView {
  headline : String
  steps : Array[OutputWalkthroughStep]
} derive(Debug, ToJson)

///|
/// 指引里是否至少有一个步骤。
pub fn OutputWalkthroughView::has_steps(self : OutputWalkthroughView) -> Bool {
  !self.steps.is_empty()
}

///|
/// 返回步骤数。
pub fn OutputWalkthroughView::count(self : OutputWalkthroughView) -> Int {
  self.steps.length()
}

///|
/// 返回第一步阅读建议。
pub fn OutputWalkthroughView::first_step(
  self : OutputWalkthroughView,
) -> OutputWalkthroughStep? {
  if self.steps.is_empty() {
    None
  } else {
    Some(self.steps[0])
  }
}

///|
/// 返回最后一步阅读建议。
pub fn OutputWalkthroughView::last_step(
  self : OutputWalkthroughView,
) -> OutputWalkthroughStep? {
  if self.steps.is_empty() {
    None
  } else {
    Some(self.steps[self.steps.length() - 1])
  }
}

///|
/// 生成指引摘要。
pub fn OutputWalkthroughView::summary(self : OutputWalkthroughView) -> String {
  ["steps=\{self.steps.length()}", "headline=\{self.headline}"].join(" | ")
}
