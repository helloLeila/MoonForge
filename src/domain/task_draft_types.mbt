///|
/// 文件总说：
/// 这个文件负责承接“用户刚把命令打出来时”的最原始输入。
/// 那个时候系统只知道两件事：
/// 1. 用户选了什么 `task_type`
/// 2. 用户有没有额外手填标题和路径
///
/// 为了避免后面的自动补全服务直接面对一堆零散字符串，
/// 这里先把命令行输入整理成几个更好懂的小对象。

///|
/// 一条原始目标选择。
/// 比如用户输入：
/// - `@frontend_pages`
/// - `frontend/src/pages/**`
/// 这两种虽然都是“目标”，但前者是路径组，后者是显式路径，所以要分清楚。
pub(all) struct TaskTargetChoice {
  raw_value : String
  normalized_value : String
  is_group : Bool
} derive(Debug, ToJson)

///|
/// 返回这条目标选择的简短标签，方便日志和测试里直接看。
pub fn TaskTargetChoice::label(self : TaskTargetChoice) -> String {
  if self.is_group {
    "路径组：\{self.normalized_value}"
  } else {
    "显式路径：\{self.normalized_value}"
  }
}

///|
/// 当前任务草稿种子。
/// 这是“命令行刚进来时”那份还没自动补全的任务草稿。
pub(all) struct CurrentTaskDraftSeed {
  task_type : String
  override_title : String
  manual_target_groups : Array[String]
  manual_target_paths : Array[String]
  target_choices : Array[TaskTargetChoice]
} derive(Debug, ToJson)

///|
/// 判断用户有没有手工提供标题。
pub fn CurrentTaskDraftSeed::has_manual_title(
  self : CurrentTaskDraftSeed,
) -> Bool {
  self.override_title.trim() != ""
}

///|
/// 判断用户有没有手工提供范围。
/// 只要手填了路径组或显式路径，都算人工指定了范围。
pub fn CurrentTaskDraftSeed::has_manual_scope(
  self : CurrentTaskDraftSeed,
) -> Bool {
  !self.manual_target_groups.is_empty() || !self.manual_target_paths.is_empty()
}

///|
/// 生成草稿种子的说明文本，方便测试和调试读取。
pub fn CurrentTaskDraftSeed::summary(self : CurrentTaskDraftSeed) -> String {
  let title_mode = if self.has_manual_title() {
    "标题由命令行提供"
  } else {
    "标题等待自动补全"
  }
  let scope_mode = if self.has_manual_scope() {
    "范围由命令行提供"
  } else {
    "范围等待自动补全"
  }
  "\{self.task_type} / \{title_mode} / \{scope_mode}"
}
