///|
/// 文件说明：封装 GitHub Actions 环境识别与常见 PR 上下文字段读取。
/// File: Wraps GitHub Actions environment detection and common PR context lookups.

///|
/// 返回当前进程可见的环境变量快照，供 CI 适配器读取上下文。
/// Returns the current process environment snapshot for CI adapters.
pub fn current_env() -> Map[String, String] {
  @env.get_env_vars()
}

///|
/// 判断当前环境是否处于 GitHub Actions 中。
/// Returns whether the current environment is GitHub Actions.
pub fn is_github_actions_env(env : Map[String, String]) -> Bool {
  env.contains("GITHUB_ACTIONS")
}

///|
/// 读取 GitHub 事件名称，例如 `pull_request`。
/// Reads the GitHub event name such as `pull_request`.
pub fn github_event_name(env : Map[String, String]) -> String? {
  env.get("GITHUB_EVENT_NAME")
}

///|
/// 读取 PR 或对比分支的 base ref。
/// Reads the base ref for PR or compare-based rechecks.
pub fn github_base_ref(env : Map[String, String]) -> String? {
  env.get("GITHUB_BASE_REF")
}

///|
/// 读取 PR 或对比分支的 head ref。
/// Reads the head ref for PR or compare-based rechecks.
pub fn github_head_ref(env : Map[String, String]) -> String? {
  env.get("GITHUB_HEAD_REF")
}

///|
/// 读取可选的 PR 编号环境变量，缺失时返回 None。
/// Reads an optional PR number environment variable.
pub fn github_pr_number(env : Map[String, String]) -> String? {
  match env.get("GITHUB_PR_NUMBER") {
    Some(value) if value.trim() != "" => Some(value)
    _ => None
  }
}

///|
/// 判断 GitHub 事件是否属于 pull request 流程。
/// Returns whether the GitHub event belongs to a pull-request flow.
pub fn is_pull_request_event(env : Map[String, String]) -> Bool {
  match github_event_name(env) {
    Some("pull_request") => true
    Some("pull_request_target") => true
    _ => false
  }
}
