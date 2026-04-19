///|
/// 文件总说：
/// 这个文件专门定义“当前任务长什么样”和“检查时真正生效的任务长什么样”。
/// 你可以把它理解成两层：
/// 1. `CurrentTask` 是用户眼前那份 `.moonforge/current-task.yml`
/// 2. `EffectiveTask` 是系统把仓库规则、任务模板、当前任务揉在一起之后得到的最终检查范围
///
/// 为什么要分两层：
/// - 用户看到的任务文件需要尽量好懂，能看出哪些内容是自动推断出来的
/// - 系统真正检查时又需要一份已经合并好的结果，避免每个检查器都重复算一遍
///
/// 联动关系：
/// - `src/services/task_autofill_service.mbt` 负责把 git 暂存改动自动补进 `CurrentTask`
/// - `src/services/commands.mbt` 负责读写 `.moonforge/current-task.yml`
/// - `src/checkers/gate.mbt` 负责把 `CurrentTask` 合并成 `EffectiveTask`

///|
/// 当前任务文件对应的运行时对象。
/// 这个对象既保留“真正会参与检查的字段”，也保留“系统是怎么猜出来的说明字段”。
///
/// 关键字段怎么理解：
/// - `task_type`：这次任务属于哪一类，比如功能变更、缺陷修复
/// - `title`：这次任务的人类可读标题
/// - `title_source`：标题是用户手填的，还是系统根据暂存文件猜的
/// - `target_groups`：命中的路径组名字，后续会被展开成具体 glob
/// - `target_paths`：这次任务明确锁定的路径或文件
/// - `staged_files`：系统在生成任务时看到的暂存文件
/// - `required_artifacts / required_commands`：这次任务要求补齐的材料和命令
/// - `artifact_dir`：默认去哪里找材料
/// - `check_mode`：这次任务准备按本地、CI 还是 PR 方式检查
/// - `auto_inferred_fields`：哪些字段是系统自动补上的
/// - `notes`：给人的解释说明
/// - `need_user_review`：系统是否建议你打开文件再看一眼
pub(all) struct CurrentTask {
  task_type : String
  title : String
  title_source : String
  target_groups : Array[String]
  target_paths : Array[String]
  target_path_source : String
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
/// 判断当前任务是否至少圈定了一个检查范围。
/// 出参：
/// - `true` 表示 `target_groups` 或 `target_paths` 至少有一个非空
/// - `false` 表示系统还不知道这次任务到底要检查哪里
pub fn CurrentTask::has_targets(self : CurrentTask) -> Bool {
  !self.target_groups.is_empty() || !self.target_paths.is_empty()
}

///|
/// 把模板里的必需材料和当前任务里额外声明的必需材料合并起来。
/// 这样做的原因很简单：
/// - 模板能给出“这类任务通常需要什么”
/// - 当前任务还能再补一层“这一次额外还要什么”
pub fn CurrentTask::merged_required_artifacts(
  self : CurrentTask,
  template_required_artifacts : Array[String],
) -> Array[String] {
  let merged : Array[String] = []
  for artifact in template_required_artifacts + self.required_artifacts {
    let trimmed = artifact.trim().to_string()
    if trimmed != "" && !merged.contains(trimmed) {
      merged.push(trimmed)
    }
  }
  merged
}

///|
/// 把模板里的必需命令和当前任务里额外声明的必需命令合并起来。
/// 作用和材料字段一样，都是“模板给基础，本次任务再做补充”。
pub fn CurrentTask::merged_required_commands(
  self : CurrentTask,
  template_required_commands : Array[String],
) -> Array[String] {
  let merged : Array[String] = []
  for command in template_required_commands + self.required_commands {
    let trimmed = command.trim().to_string()
    if trimmed != "" && !merged.contains(trimmed) {
      merged.push(trimmed)
    }
  }
  merged
}

///|
/// 生成一段很短的任务摘要，方便调试输出或测试里快速看懂对象内容。
pub fn CurrentTask::summary(self : CurrentTask) -> String {
  let scope_label = if self.has_targets() {
    "\{self.target_groups.length()} 个路径组，\{self.target_paths.length()} 条显式路径"
  } else {
    "还没有任务范围"
  }
  let review_label = if self.need_user_review {
    "建议人工复核"
  } else {
    "系统判断可直接使用"
  }
  "\{self.task_type} / \{self.title} / \{scope_label} / \{review_label}"
}

///|
/// 仓库规则、模板规则与当前任务合并后的生效约束。
/// 这个对象只保留真正会影响检查结果的字段。
///
/// 例如：
/// - `target_groups` 在这里已经不见了，因为它们会先被展开成具体路径
/// - `title_source`、`notes` 这类解释性字段也不会进入这里，因为它们不影响判定
/// - `max_changed_files` 表示合并后最终采用的更严格文件上限
pub(all) struct EffectiveTask {
  task_type : String
  title : String
  allowed_paths : Array[String]
  forbidden_paths : Array[String]
  approval_required_paths : Array[String]
  allowed_extensions : Array[String]
  blocked_extensions : Array[String]
  generated_artifact_paths : Array[String]
  blocked_file_names : Array[String]
  blocked_file_patterns : Array[String]
  content_blocklist_patterns : Array[String]
  required_artifacts : Array[String]
  required_commands : Array[String]
  max_changed_files : Int
} derive(Debug, ToJson)
