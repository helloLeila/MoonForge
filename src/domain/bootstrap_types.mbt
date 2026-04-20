///|
/// 文件总说：
/// 这个文件定义 MoonForge 初始化后写入仓库的“默认偏好配置”。
/// 这些配置不是一次任务的临时输入，而是项目长期保留的默认行为。
///
/// 这里拆成三组，是为了让人一眼看出职责：
/// 1. `TaskDefaults` 负责 task 阶段默认怎么补全
/// 2. `CheckPreferences` 负责 check 阶段默认怎么找输入、找材料、落文件
/// 3. `ReportPreferences` 负责 report 阶段默认怎么展示
///
/// 这样以后就算继续扩字段，也不会所有配置都挤进一个大对象里。

///|
/// task 命令默认偏好。
/// 这组配置主要影响 `moonforge task <type>` 自动填什么、怎么填。
pub(all) struct TaskDefaults {
  default_check_mode : String
  default_artifact_dir : String
  default_title_prefixes : Map[String, String]
  note_lines : Array[String]
} derive(Debug, ToJson)

///|
/// 生成 task 默认偏好的简短摘要。
pub fn TaskDefaults::summary(self : TaskDefaults) -> String {
  "check_mode=\{self.default_check_mode} / artifact_dir=\{self.default_artifact_dir} / title_prefixes=\{self.default_title_prefixes.length()}"
}

///|
/// check 命令默认偏好。
/// 这组配置主要影响本地模式如何自动生成输入、到哪些目录找材料。
pub(all) struct CheckPreferences {
  prefer_staged_diff : Bool
  auto_prepare_local_run_input : Bool
  keep_local_input_snapshot : Bool
  artifact_search_dirs : Array[String]
  write_input_summary : Bool
} derive(Debug, ToJson)

///|
/// 生成 check 默认偏好的简短摘要。
pub fn CheckPreferences::summary(self : CheckPreferences) -> String {
  "search_dirs=\{self.artifact_search_dirs.length()} / auto_run_input=\{self.auto_prepare_local_run_input}"
}

///|
/// report 命令默认偏好。
/// 这组配置不影响门禁判定本身，主要影响 report 输出时带哪些块。
pub(all) struct ReportPreferences {
  show_context : Bool
  show_metrics : Bool
  show_next_action : Bool
  show_history_hint : Bool
  show_preflight_hint : Bool
} derive(Debug, ToJson)

///|
/// 生成 report 默认偏好的简短摘要。
pub fn ReportPreferences::summary(self : ReportPreferences) -> String {
  "context=\{self.show_context} / metrics=\{self.show_metrics} / next_action=\{self.show_next_action}"
}

///|
/// 三组默认偏好的聚合对象。
/// init 阶段会一次性把它拆成多个配置文件写进 `.moonforge/bootstrap/`。
pub(all) struct BootstrapBundle {
  task_defaults : TaskDefaults
  check_preferences : CheckPreferences
  report_preferences : ReportPreferences
} derive(Debug, ToJson)

///|
/// 生成整套 bootstrap 配置的摘要。
pub fn BootstrapBundle::summary(self : BootstrapBundle) -> String {
  [
    "task: \{self.task_defaults.summary()}",
    "check: \{self.check_preferences.summary()}",
    "report: \{self.report_preferences.summary()}",
  ].join(" | ")
}
