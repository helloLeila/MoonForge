///|
/// 文件总说：
/// 这个文件专门放“系统自动补全任务时产生的中间结果”。
/// 之所以单独拆出来，是因为自动补全不是一步到位的，它会先回答几件事：
/// 1. 哪些路径组命中了当前暂存文件
/// 2. 还有哪些文件没有被路径组覆盖，需要单独写进 `target_paths`
/// 3. 任务标题应该怎么起，理由是什么
/// 4. 最终哪些字段是自动补上的，哪些地方还建议人再看一眼
///
/// 把这些中间结果保留下来有两个好处：
/// - 代码更容易读，不会把所有判断都挤进一个大函数
/// - 后面要做报告解释、历史回放时，也能直接复用这些结构

///|
/// 一条路径组命中记录。
/// 它回答的是：“这个路径组为什么会被选中，它到底覆盖了哪些暂存文件”。
pub(all) struct TaskGroupMatch {
  group_name : String
  group_patterns : Array[String]
  matched_files : Array[String]
} derive(Debug, ToJson)

///|
/// 判断一条路径组命中记录是否真的有用。
/// 只要命中了至少一个暂存文件，就说明这个路径组值得写进当前任务。
pub fn TaskGroupMatch::is_useful(self : TaskGroupMatch) -> Bool {
  !self.matched_files.is_empty()
}

///|
/// 生成给人看的简短说明，方便在日志或测试里直接看懂。
pub fn TaskGroupMatch::summary(self : TaskGroupMatch) -> String {
  "\{self.group_name} 覆盖了 \{self.matched_files.length()} 个暂存文件"
}

///|
/// 自动生成标题时的建议结果。
/// 这里会同时保存标题文本、标题来源、理由和参考文件。
pub(all) struct TaskTitleSuggestion {
  title : String
  source : String
  based_on_files : Array[String]
  reason : String
} derive(Debug, ToJson)

///|
/// 返回标题建议是否为空，供上层在写文件前做最后防守。
pub fn TaskTitleSuggestion::is_blank(self : TaskTitleSuggestion) -> Bool {
  self.title.trim() == ""
}

///|
/// 生成一句简短说明，告诉人“这个标题是怎么来的”。
pub fn TaskTitleSuggestion::summary(self : TaskTitleSuggestion) -> String {
  "\{self.title}（来源：\{self.source}）"
}

///|
/// 自动推断出的任务范围建议。
/// 它会同时保存：
/// - 最终要写入的路径组
/// - 最终要写入的显式路径
/// - 哪些暂存文件已经被覆盖
/// - 哪些暂存文件还没被路径组覆盖
/// - 以及每一步为什么这么做
pub(all) struct TaskScopeSuggestion {
  target_groups : Array[String]
  target_paths : Array[String]
  covered_files : Array[String]
  uncovered_files : Array[String]
  group_matches : Array[TaskGroupMatch]
  reason_lines : Array[String]
} derive(Debug, ToJson)

///|
/// 判断这份范围建议是否至少给出了一个有效范围。
pub fn TaskScopeSuggestion::has_scope(self : TaskScopeSuggestion) -> Bool {
  !self.target_groups.is_empty() || !self.target_paths.is_empty()
}

///|
/// 判断系统是否应该建议用户再看一眼当前任务文件。
/// 这里的规则偏保守：
/// - 有未覆盖文件时，建议人工确认
/// - 什么路径组都没命中时，建议人工确认
pub fn TaskScopeSuggestion::needs_manual_review(
  self : TaskScopeSuggestion,
) -> Bool {
  !self.uncovered_files.is_empty() || self.target_groups.is_empty()
}

///|
/// 生成范围建议的中文摘要。
pub fn TaskScopeSuggestion::summary(self : TaskScopeSuggestion) -> String {
  "命中 \{self.target_groups.length()} 个路径组，补了 \{self.target_paths.length()} 条显式路径"
}

///|
/// 一次完整自动补全的总计划。
/// 它相当于“系统在真正写 current-task.yml 之前的草稿总表”。
pub(all) struct TaskAutoFillPlan {
  task_type : String
  title_suggestion : TaskTitleSuggestion
  scope_suggestion : TaskScopeSuggestion
  staged_files : Array[String]
  required_artifacts : Array[String]
  required_commands : Array[String]
  artifact_dir : String
  check_mode : String
  auto_inferred_fields : Array[String]
  notes : Array[String]
  need_user_review : Bool
  last_auto_fill_ns : String
} derive(Debug, ToJson)

///|
/// 把自动补全计划转换成真正要落盘的 `CurrentTask`。
/// 这样上层不需要自己一项一项搬字段，只要说一句“把计划变成任务”即可。
pub fn TaskAutoFillPlan::to_current_task(
  self : TaskAutoFillPlan,
) -> CurrentTask {
  CurrentTask::{
    task_type: self.task_type,
    title: self.title_suggestion.title,
    title_source: self.title_suggestion.source,
    target_groups: self.scope_suggestion.target_groups,
    target_paths: self.scope_suggestion.target_paths,
    target_path_source: if self.scope_suggestion.target_groups.is_empty() {
      "auto_paths_only"
    } else if self.scope_suggestion.target_paths.is_empty() {
      "auto_groups_only"
    } else {
      "auto_groups_and_paths"
    },
    staged_files: self.staged_files,
    required_artifacts: self.required_artifacts,
    required_commands: self.required_commands,
    artifact_dir: self.artifact_dir,
    check_mode: self.check_mode,
    auto_inferred_fields: self.auto_inferred_fields,
    notes: self.notes,
    need_user_review: self.need_user_review,
    last_auto_fill_ns: self.last_auto_fill_ns,
  }
}

///|
/// 生成这次自动补全的简短结论，方便上层打印调试信息。
pub fn TaskAutoFillPlan::summary(self : TaskAutoFillPlan) -> String {
  "\{self.title_suggestion.summary()} / \{self.scope_suggestion.summary()}"
}
