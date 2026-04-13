///|
/// 文件说明：提供 GitHub CI 与 PR 复检执行面的差异读取入口，负责校验环境后读取补丁文件。

///|
/// 在 GitHub Actions 环境中读取 CI 输入补丁，缺失环境上下文时立即终止。
pub fn read_ci_diff(env : Map[String, String], path : String) -> String raise {
  if !is_github_actions_env(env) {
    raise Failure::Failure("CI_CONTEXT_NOT_FOUND")
  }
  @infra.read_text(path)
}

///|
/// 在 GitHub pull request 环境中读取 PR diff，并要求 base/head 线索完整。
pub fn read_pr_diff(env : Map[String, String], path : String) -> String raise {
  if !is_github_actions_env(env) {
    raise Failure::Failure("CI_CONTEXT_NOT_FOUND")
  }
  if !is_pull_request_event(env) {
    raise Failure::Failure("PR_CONTEXT_NOT_FOUND")
  }
  guard github_base_ref(env) is Some(_) else {
    raise Failure::Failure("PR_CONTEXT_NOT_FOUND")
  }
  guard github_head_ref(env) is Some(_) else {
    raise Failure::Failure("PR_CONTEXT_NOT_FOUND")
  }
  @infra.read_text(path)
}
