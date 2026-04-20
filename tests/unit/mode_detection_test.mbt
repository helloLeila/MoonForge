///|
/// 文件说明：覆盖运行模式自动识别的最小行为，确保本地、CI、PR 三种路径能按环境自动分流。
/// 联动文件：对应 `src/adapters/mode_paths.mbt` 的 `resolve_mode`。

///|
/// 未显式指定模式且不在 GitHub Actions 中时，应回退到本地模式。
test "resolve mode falls back to local outside github actions" {
  let mode = @adapters.resolve_mode("auto", {})
  assert_eq(mode, "local")
}

///|
/// 在 GitHub Actions 中且不是 PR 事件时，应自动识别成 CI 模式。
test "resolve mode infers ci inside github actions" {
  let mode = @adapters.resolve_mode("auto", {
    "GITHUB_ACTIONS": "true",
    "GITHUB_EVENT_NAME": "push",
  })
  assert_eq(mode, "ci")
}

///|
/// 在 GitHub Actions PR 事件中且 base/head 完整时，应自动识别成 PR 模式。
test "resolve mode infers pr for github pull request event" {
  let mode = @adapters.resolve_mode("auto", {
    "GITHUB_ACTIONS": "true",
    "GITHUB_EVENT_NAME": "pull_request",
    "GITHUB_BASE_REF": "main",
    "GITHUB_HEAD_REF": "feature/demo",
  })
  assert_eq(mode, "pr")
}

///|
/// 显式指定模式时，应优先使用显式输入，而不是环境自动推断结果。
test "resolve mode respects explicit override" {
  let mode = @adapters.resolve_mode("local", {
    "GITHUB_ACTIONS": "true",
    "GITHUB_EVENT_NAME": "pull_request",
    "GITHUB_BASE_REF": "main",
    "GITHUB_HEAD_REF": "feature/demo",
  })
  assert_eq(mode, "local")
}
