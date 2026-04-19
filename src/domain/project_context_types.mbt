///|
/// 文件说明：定义“用户当前正在操作哪个项目”的上下文对象，负责把仓库根目录、配置目录、输出目录和 hook 位置集中起来。
/// 联动文件：由 `src/services/project_context_service.mbt` 生成，再被 `init / task / check / report` 四个主命令复用。

///|
/// 一次命令执行时解析出的项目上下文。
/// 这个对象的目标很简单：后续服务不再自己拼路径，而是统一从这里拿。
pub(all) struct ProjectContext {
  request_dir : String
  repo_root : String
  is_git_repo : Bool
  moonforge_dir : String
  repo_rules_file : String
  task_types_dir : String
  current_task_file : String
  artifact_schema_dir : String
  output_root_dir : String
  runs_dir : String
  hook_file : String
} derive(Debug, ToJson)

///|
/// 返回当前上下文对应的“最近一次结果目录”。
/// 入参：项目上下文对象。
/// 入参：`mode`，运行模式，例如 `local`、`ci`、`pr`。
/// 出参：`.moonforge/out/<mode>/latest` 的完整路径。
pub fn ProjectContext::latest_output_dir(
  self : ProjectContext,
  mode : String,
) -> String {
  self.output_root_dir + "/" + mode + "/latest"
}

///|
/// 返回当前上下文对应的一段中文摘要，便于日志或诊断直接输出。
/// 入参：项目上下文对象。
/// 出参：包含请求目录、仓库根目录和 git 状态的中文文本。
pub fn ProjectContext::summary(self : ProjectContext) -> String {
  let git_state = if self.is_git_repo { "git 仓库" } else { "普通目录" }
  "请求目录：\{self.request_dir}；项目根目录：\{self.repo_root}；类型：\{git_state}"
}
