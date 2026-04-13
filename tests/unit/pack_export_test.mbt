///|
/// 文件说明：覆盖最小验收包导出的主链路，确保固定输入与固定输出文件会被复制到导出目录。
/// 联动文件：对应 `src/services/commands.mbt` 中的 pack 导出实现。

///|
/// 为 pack 导出测试生成独立仓库目录。
fn unique_pack_repo(label : String) -> String {
  @infra.join_path("tmp", "moonforge-pack-\{label}")
}

///|
/// pack_latest 应导出固定输入与固定输出文件。
test "pack latest exports fixed input and output files" {
  let repo = unique_pack_repo("latest")
  let run_dir = @infra.join_path(repo, "fixture-runs/pack")
  let diff =
    #|diff --git a/frontend/src/pages/UserList/index.tsx b/frontend/src/pages/UserList/index.tsx
    #|index 1111111..2222222 100644
    #|--- a/frontend/src/pages/UserList/index.tsx
    #|+++ b/frontend/src/pages/UserList/index.tsx
    #|@@ -1,1 +1,2 @@
    #| export const userListPage = true
    #|+export const packEnabled = true
    #|
  @infra.write_text(
    @infra.join_path(repo, "frontend/src/pages/UserList/index.tsx"),
    "export const userListPage = true\n",
  )
  ignore(@services.init_repo(repo))
  ignore(
    @services.create_task(
      repo,
      "feature-change",
      "Pack filter",
      "frontend/src/pages/**",
    ),
  )
  @infra.write_text(@infra.join_path(run_dir, "patch.diff"), diff)
  @infra.write_text(
    @infra.join_path(run_dir, "test-report.json"),
    "{\n  \"passed\": true\n}\n",
  )
  @infra.write_text(
    @infra.join_path(run_dir, "review-report.json"),
    "{\n  \"status\": \"approved\"\n}\n",
  )
  ignore(@services.run_check(repo, run_dir))

  let message = @services.pack_latest(repo)
  assert_true(message.contains("打包完成"))
  assert_true(
    @infra.path_exists(
      @infra.join_path(repo, ".moonforge/out/local/packs/latest/repo-rules.yml"),
    ),
  )
  assert_true(
    @infra.path_exists(
      @infra.join_path(repo, ".moonforge/out/local/packs/latest/current-task.yml"),
    ),
  )
  assert_true(
    @infra.path_exists(
      @infra.join_path(repo, ".moonforge/out/local/packs/latest/gate-result.json"),
    ),
  )
  assert_true(
    @infra.path_exists(
      @infra.join_path(repo, ".moonforge/out/local/packs/latest/gate-report.md"),
    ),
  )
}
