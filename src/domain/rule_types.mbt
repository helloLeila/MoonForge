///|
/// 文件说明：定义仓库级规则与任务模板规则，负责表达长期约束和任务默认边界。
/// 联动文件：被 `src/services/commands.mbt` 读取并渲染为配置文件，也被 `src/checkers/gate.mbt` 用于合并约束。

///|
/// 仓库级长期规则，负责表达受保护目录、生成物黑名单、内容黑名单与仓库级默认边界。
pub(all) struct RepoRules {
  protected_paths : Array[String]
  approval_required_paths : Array[String]
  blocked_extensions : Array[String]
  generated_artifact_paths : Array[String]
  blocked_file_names : Array[String]
  blocked_file_patterns : Array[String]
  content_blocklist_patterns : Array[String]
  default_allowed_extensions : Array[String]
  path_groups : Map[String, Array[String]]
  max_changed_files : Int?
} derive(Debug)

///|
/// 任务模板规则，负责限定某类任务的默认边界。
pub(all) struct TaskTemplate {
  task_type : String
  allowed_paths : Array[String]
  forbidden_paths : Array[String]
  allowed_extensions : Array[String]
  required_artifacts : Array[String]
  required_commands : Array[String]
  max_changed_files : Int
  manual_approval_paths : Array[String]
} derive(Debug)
