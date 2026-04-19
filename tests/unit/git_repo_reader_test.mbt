///|
/// 文件说明：覆盖 git 仓库读取基础设施，确保工具能在用户项目里自动找到仓库根目录、暂存文件和 staged diff。
/// 联动文件：对应 `src/infra/git_repo_reader.mbt`，是 `task` 自动补全和 `check` 自动 staged diff 的输入来源。

///|
/// 为 git 读取测试生成互不干扰的临时仓库目录。
fn unique_git_repo(label : String) -> String {
  @infra.join_path("/tmp", @infra.unique_temp_name("moonforge-git-\{label}"))
}

///|
/// 初始化一个最小 git 仓库并放入一份已暂存的前端文件。
fn seed_git_repo(repo : String) -> Unit raise {
  @infra.ensure_dir(repo)
  ignore(@infra.run_shell_command("git init -q", repo))
  ignore(
    @infra.run_shell_command("git config user.name 'MoonForge Test'", repo),
  )
  ignore(
    @infra.run_shell_command(
      "git config user.email 'moonforge@test.local'", repo,
    ),
  )
  @infra.write_text(
    @infra.join_path(repo, "frontend/src/pages/UserList/index.tsx"),
    "export const userListPage = true\n",
  )
  ignore(
    @infra.run_shell_command(
      "git add frontend/src/pages/UserList/index.tsx", repo,
    ),
  )
}

///|
/// git 读取器应自动返回仓库根目录、暂存文件列表和 staged diff 文本。
test "git repo reader returns root staged files and staged diff" {
  let repo = unique_git_repo("reader")
  seed_git_repo(repo)

  let root = @infra.resolve_git_repo_root(repo)
  let staged_files = @infra.read_staged_files(repo)
  let staged_diff = @infra.read_staged_diff(repo)

  assert_true(root.has_suffix(repo))
  assert_true(staged_files.contains("frontend/src/pages/UserList/index.tsx"))
  assert_true(
    staged_diff.contains("diff --git a/frontend/src/pages/UserList/index.tsx"),
  )
}
