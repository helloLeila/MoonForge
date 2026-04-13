///|
/// 文件说明：覆盖 pack 命令的集成行为，确保最小验收包可从最近一次检查结果导出。
/// 联动文件：直接调用 `src/services/commands.mbt` 的 `run_check` 与 `pack_latest`。

///|
/// 为 pack 集成测试生成互不干扰的临时仓库目录。
fn unique_pack_repo(label : String) -> String {
  @infra.join_path("tmp", "moonforge-pack-flow-\{label}-\{@uv.hrtime()}")
}

///|
/// pack_latest 应导出最近一次检查的固定文件集合。
test "pack command exports latest acceptance files" {
  let repo = unique_pack_repo("flow")
  let run_dir = @infra.join_path(repo, "fixture-runs/pack")
  let diff =
    #|diff --git a/frontend/src/pages/UserList/index.tsx b/frontend/src/pages/UserList/index.tsx
    #|index 1111111..2222222 100644
    #|--- a/frontend/src/pages/UserList/index.tsx
    #|+++ b/frontend/src/pages/UserList/index.tsx
    #|@@ -1,1 +1,2 @@
    #| export const userListPage = true
    #|+export const packMode = true
    #|
  @infra.write_text(
    @infra.join_path(repo, "frontend/src/pages/UserList/index.tsx"),
    "export const userListPage = true\n",
  )
  ignore(@services.init_repo(repo))
  ignore(
    @services.create_task(
      repo, "feature-change", "Pack integration", "frontend/src/pages/**",
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
      @infra.join_path(
        repo, ".moonforge/out/local/packs/latest/gate-result.json",
      ),
    ),
  )
  assert_true(
    @infra.path_exists(
      @infra.join_path(repo, ".moonforge/out/local/packs/latest/events.jsonl"),
    ),
  )
}
