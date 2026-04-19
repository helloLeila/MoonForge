///|
/// 文件说明：覆盖项目上下文服务的关键行为，确保工具在用户不传 `--repo` 时，也能根据当前目录自动找到目标项目。
/// 联动文件：对应 `src/services/project_context_service.mbt`，会被 CLI 默认当前目录逻辑复用。

///|
/// 为项目上下文测试生成互不干扰的临时仓库目录。
fn unique_context_repo(label : String) -> String {
  @infra.join_path(
    "/tmp",
    @infra.unique_temp_name("moonforge-context-\{label}"),
  )
}

///|
/// 初始化一个最小 git 仓库，供项目上下文解析使用。
fn seed_context_repo(repo : String) -> Unit raise {
  @infra.ensure_dir(repo)
  ignore(@infra.run_shell_command("git init -q", repo))
  @infra.write_text(@infra.join_path(repo, "README.md"), "# demo\n")
  ignore(@infra.run_shell_command("git add README.md", repo))
}

///|
/// 当用户没有传 `--repo`，而当前目录位于 git 仓库子目录时，应自动回到仓库根目录。
test "project context resolves repo root from nested cwd" {
  let repo = unique_context_repo("nested")
  seed_context_repo(repo)
  let nested = @infra.join_path(repo, "frontend/src/pages")
  @infra.ensure_dir(nested)

  let context = @services.resolve_project_context(
    "",
    nested,
    allow_non_git=false,
  )

  assert_true(context.repo_root.has_suffix(@infra.basename(repo)))
  assert_eq(context.request_dir, nested)
  assert_true(context.is_git_repo)
}

///|
/// `init` 场景允许在还没初始化 git 的普通目录里使用当前目录作为项目根目录。
test "project context allows plain directory during init" {
  let repo = unique_context_repo("plain")
  @infra.ensure_dir(repo)

  let context = @services.resolve_project_context("", repo, allow_non_git=true)

  assert_eq(context.repo_root, repo)
  assert_true(!context.is_git_repo)
}
