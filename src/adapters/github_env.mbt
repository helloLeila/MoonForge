///|
/// 文件说明：封装 GitHub Actions 环境识别，隔离 CI 执行面对环境变量的读取方式。
/// 联动文件：由 `src/adapters/git_ci_diff.mbt` 和 `src/services/commands.mbt` 调用。

///|
/// 返回当前进程可见的环境变量快照，供 CI 适配器读取上下文。
pub fn current_env() -> Map[String, String] {
  @env.get_env_vars()
}

///|
/// 判断当前环境是否处于 GitHub Actions 中。
pub fn is_github_actions_env(env : Map[String, String]) -> Bool {
  env.contains("GITHUB_ACTIONS")
}
