///|
/// 文件总说：
/// 这个文件验证真正贴近用户的新路径：
/// - 在 git 项目里先 `init`
/// - 再 `task --type ...`
/// - 最后直接 `check`
/// 不再手工准备 `--run` 目录。

///|
/// 为本地自动输入集成测试生成独立 git 仓库目录。
fn unique_local_check_repo(label : String) -> String {
  @infra.join_path("/tmp", @infra.unique_temp_name("moonforge-check-\{label}"))
}

///|
/// 初始化一个带暂存文件的最小 git 仓库。
fn seed_local_check_repo(repo_root : String) -> Unit raise {
  @infra.ensure_dir(repo_root)
  ignore(@infra.run_shell_command("git init -q", repo_root))
  ignore(
    @infra.run_shell_command(
      "git config user.name 'MoonForge Local Check'", repo_root,
    ),
  )
  ignore(
    @infra.run_shell_command(
      "git config user.email 'moonforge-local-check@test.local'", repo_root,
    ),
  )
  @infra.write_text(
    @infra.join_path(repo_root, "frontend/src/pages/UserList/index.tsx"),
    "export const userListPage = true\n",
  )
  ignore(
    @infra.run_shell_command(
      "git add frontend/src/pages/UserList/index.tsx", repo_root,
    ),
  )
}

///|
/// 本地 check 不给 run 目录时，应自动从暂存区生成输入并完成检查。
test "local check auto builds run input from staged diff" {
  let repo_root = unique_local_check_repo("auto")
  seed_local_check_repo(repo_root)
  ignore(@services.init_repo(repo_root))
  ignore(@services.create_task(repo_root, "feature-change", "", ""))
  @infra.write_text(
    @infra.join_path(repo_root, ".moonforge/artifacts/current/test-report.json"),
    "{\n  \"passed\": true,\n  \"suite\": \"demo\"\n}\n",
  )
  @infra.write_text(
    @infra.join_path(
      repo_root, ".moonforge/artifacts/current/review-report.json",
    ),
    "{\n  \"reviewer\": \"leila\",\n  \"status\": \"approved\"\n}\n",
  )

  let result = @services.run_check(repo_root, "")
  assert_true(result.decision == @domain.Accept)
  assert_true(
    @infra.path_exists(
      @infra.join_path(
        repo_root, ".moonforge/out/local/latest/gate-result.json",
      ),
    ),
  )

  let run_entries = @infra.list_dir(
    @infra.join_path(repo_root, ".moonforge/runs"),
  )
  assert_true(run_entries.any(fn(entry) { entry.contains("local-staged-") }))
}
