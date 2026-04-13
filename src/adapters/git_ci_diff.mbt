///|
/// 文件说明：提供 GitHub CI 执行面的差异读取入口，负责校验环境后读取补丁文件。
/// 联动文件：由 `src/services/commands.mbt` 在 `ci` 模式下调用，并依赖 `src/adapters/github_env.mbt`。

///|
/// 在 GitHub Actions 环境中读取 CI 输入补丁，缺失环境上下文时立即终止。
pub fn read_ci_diff(env : Map[String, String], path : String) -> String raise {
  if !is_github_actions_env(env) {
    raise Failure::Failure("CI_CONTEXT_NOT_FOUND")
  }
  @infra.read_text(path)
}
