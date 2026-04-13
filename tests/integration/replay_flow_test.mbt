///|
/// 文件说明：覆盖 replay 命令的集成行为，确保历史快照可以通过命令服务读取并输出摘要。
/// 联动文件：直接调用 `src/services/commands.mbt` 的 `run_check` 与 `replay_check`。

///|
/// 为 replay 集成测试生成互不干扰的临时仓库目录。
fn unique_replay_repo(label : String) -> String {
  @infra.join_path("tmp", "moonforge-replay-\{label}-\{@uv.hrtime()}")
}

///|
/// replay_check 应读取已落盘的任务快照并返回运行摘要。
test "replay command reads snapshot after check" {
  let repo = unique_replay_repo("flow")
  let run_dir = @infra.join_path(repo, "fixture-runs/replay")
  let diff =
    #|diff --git a/frontend/src/pages/UserList/index.tsx b/frontend/src/pages/UserList/index.tsx
    #|index 1111111..2222222 100644
    #|--- a/frontend/src/pages/UserList/index.tsx
    #|+++ b/frontend/src/pages/UserList/index.tsx
    #|@@ -1,1 +1,2 @@
    #| export const userListPage = true
    #|+export const replayMode = true
    #|
  @infra.write_text(
    @infra.join_path(repo, "frontend/src/pages/UserList/index.tsx"),
    "export const userListPage = true\n",
  )
  ignore(@services.init_repo(repo))
  ignore(
    @services.create_task(
      repo, "feature-change", "Replay integration", "frontend/src/pages/**",
    ),
  )
  @infra.write_text(@infra.join_path(run_dir, "patch.diff"), diff)
  @infra.write_text(
    @infra.join_path(run_dir, "test-report.json"),
    "{\n  \"passed\": true,\n  \"suite\": \"replay\"\n}\n",
  )
  @infra.write_text(
    @infra.join_path(run_dir, "review-report.json"),
    "{\n  \"reviewer\": \"leila\",\n  \"status\": \"approved\"\n}\n",
  )

  let result = @services.run_check(repo, run_dir)
  let summary = @services.replay_check(repo, result.run_id)

  assert_true(summary.contains(result.run_id))
  assert_true(summary.contains("feature-change"))
  assert_true(summary.contains("Accept"))
  assert_true(summary.contains("变更文件"))
}

///|
/// PR 复检模式落盘后，replay 摘要应保留 base/head 线索和运行结论。
test "replay command keeps pr recheck context" {
  let repo = unique_replay_repo("pr")
  let run_dir = @infra.join_path(repo, "fixture-runs/pr")
  let diff =
    #|diff --git a/frontend/src/pages/UserList/index.tsx b/frontend/src/pages/UserList/index.tsx
    #|index 1111111..2222222 100644
    #|--- a/frontend/src/pages/UserList/index.tsx
    #|+++ b/frontend/src/pages/UserList/index.tsx
    #|@@ -1,1 +1,2 @@
    #| export const userListPage = true
    #|+export const prReplayMode = true
    #|
  @infra.write_text(
    @infra.join_path(repo, "frontend/src/pages/UserList/index.tsx"),
    "export const userListPage = true\n",
  )
  ignore(@services.init_repo(repo))
  ignore(
    @services.create_task(
      repo, "feature-change", "Replay pr integration", "frontend/src/pages/**",
    ),
  )
  @infra.write_text(@infra.join_path(run_dir, "patch.diff"), diff)
  @infra.write_text(
    @infra.join_path(run_dir, "test-report.json"),
    "{\n  \"passed\": true,\n  \"suite\": \"replay-pr\"\n}\n",
  )
  @infra.write_text(
    @infra.join_path(run_dir, "review-report.json"),
    "{\n  \"reviewer\": \"leila\",\n  \"status\": \"approved\"\n}\n",
  )

  @env.set_env_var("GITHUB_ACTIONS", "true")
  @env.set_env_var("GITHUB_EVENT_NAME", "pull_request")
  @env.set_env_var("GITHUB_BASE_REF", "main")
  @env.set_env_var("GITHUB_HEAD_REF", "feature/search")

  let result = @services.run_check(repo, run_dir, mode="pr")
  let summary = @services.replay_check(repo, result.run_id)

  @env.unset_env_var("GITHUB_ACTIONS")
  @env.unset_env_var("GITHUB_EVENT_NAME")
  @env.unset_env_var("GITHUB_BASE_REF")
  @env.unset_env_var("GITHUB_HEAD_REF")

  assert_true(summary.contains(result.run_id))
  assert_true(summary.contains("feature-change"))
  assert_true(summary.contains("Accept"))
  assert_true(summary.contains("main"))
  assert_true(summary.contains("feature/search"))
  assert_true(summary.contains("变更文件"))
}

///|
/// replay 应能列出已经落盘的运行快照编号，便于后续选择回放目标。
test "replay service lists available snapshot ids" {
  let repo = unique_replay_repo("list")
  let run_dir = @infra.join_path(repo, "fixture-runs/list")
  let diff =
    #|diff --git a/frontend/src/pages/UserList/index.tsx b/frontend/src/pages/UserList/index.tsx
    #|index 1111111..2222222 100644
    #|--- a/frontend/src/pages/UserList/index.tsx
    #|+++ b/frontend/src/pages/UserList/index.tsx
    #|@@ -1,1 +1,2 @@
    #| export const userListPage = true
    #|+export const replayListMode = true
    #|
  @infra.write_text(
    @infra.join_path(repo, "frontend/src/pages/UserList/index.tsx"),
    "export const userListPage = true\n",
  )
  ignore(@services.init_repo(repo))
  ignore(
    @services.create_task(
      repo, "feature-change", "Replay list integration", "frontend/src/pages/**",
    ),
  )
  @infra.write_text(@infra.join_path(run_dir, "patch.diff"), diff)
  @infra.write_text(
    @infra.join_path(run_dir, "test-report.json"),
    "{\n  \"passed\": true,\n  \"suite\": \"replay-list\"\n}\n",
  )
  @infra.write_text(
    @infra.join_path(run_dir, "review-report.json"),
    "{\n  \"reviewer\": \"leila\",\n  \"status\": \"approved\"\n}\n",
  )

  let result = @services.run_check(repo, run_dir)
  let snapshots = @services.list_available_snapshots(repo)

  assert_true(snapshots.contains(result.run_id))
}
