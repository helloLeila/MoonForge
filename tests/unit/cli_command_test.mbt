///|
/// 文件说明：覆盖 CLI 子命令分发的最小行为，确保 validate 入口已接通服务层。
/// 联动文件：对应 `src/services/commands.mbt` 的命令分发函数，避免 CLI 入口遗漏。

///|
/// 为 CLI 分发测试生成独立仓库目录。
fn unique_cli_repo(label : String) -> String {
  @infra.join_path("tmp", "moonforge-cli-\{label}")
}

///|
/// validate 子命令应调用配置校验服务并返回通过摘要。
test "cli dispatches validate command" {
  let repo = unique_cli_repo("validate")
  ignore(@services.init_repo(repo))
  ignore(
    @services.create_task(
      repo,
      "feature-change",
      "Add filter",
      "frontend/src/pages/**",
    ),
  )

  let output = @services.dispatch_cli_command("validate", repo)
  assert_true(output.contains("配置校验通过"))
}
