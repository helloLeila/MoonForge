///|
/// 文件说明：覆盖补丁解析与本地/CI 差异适配器的最小行为，确保变更来源通过适配层进入门禁主链路。
/// 联动文件：对应 `src/infra/diff_parser.mbt`、`src/adapters/git_local_diff.mbt`、
/// `src/adapters/git_ci_diff.mbt` 与 `src/adapters/github_env.mbt`。

///|
/// diff 解析器应从标准 git patch 中提取去重后的文件路径。
test "diff parser extracts touched files from git diff" {
  let diff =
    #|diff --git a/src/foo.mbt b/src/foo.mbt
    #|index 111..222 100644
    #|--- a/src/foo.mbt
    #|+++ b/src/foo.mbt
    #|@@ -1,1 +1,1 @@
    #|-old
    #|+new
    #|diff --git a/src/foo.mbt b/src/foo.mbt
    #|index 222..333 100644
    #|--- a/src/foo.mbt
    #|+++ b/src/foo.mbt
    #|@@ -2,1 +2,1 @@
    #|-new
    #|+newer
    #|diff --git a/src/bar.mbt b/src/bar.mbt
    #|index 444..555 100644
    #|--- a/src/bar.mbt
    #|+++ b/src/bar.mbt
    #|@@ -1,1 +1,1 @@
    #|-bar
    #|+baz
  let files = @infra.parse_changed_files(diff)
  assert_eq(files, ["src/foo.mbt", "src/bar.mbt"])
}

///|
/// 本地差异适配器应从运行目录读取标准 patch 文件。
test "local diff adapter reads patch file from run dir" {
  let run_dir = @infra.join_path("tmp", "moonforge-diff-local")
  let diff =
    #|diff --git a/src/foo.mbt b/src/foo.mbt
    #|index 111..222 100644
    #|--- a/src/foo.mbt
    #|+++ b/src/foo.mbt
    #|@@ -1,1 +1,1 @@
    #|-old
    #|+new
  @infra.write_text(@infra.join_path(run_dir, "patch.diff"), diff)
  assert_eq(@adapters.read_local_diff(run_dir), diff)
}

///|
/// GitHub 环境适配器应识别 Actions 环境，并允许 CI 读取补丁文件。
test "ci diff adapter requires github actions env" {
  let run_dir = @infra.join_path("tmp", "moonforge-diff-ci")
  let diff =
    #|diff --git a/src/ci.mbt b/src/ci.mbt
    #|index 111..222 100644
    #|--- a/src/ci.mbt
    #|+++ b/src/ci.mbt
    #|@@ -1,1 +1,1 @@
    #|-old
    #|+new
  let patch_path = @infra.join_path(run_dir, "patch.diff")
  @infra.write_text(patch_path, diff)

  let empty_env : Map[String, String] = {}
  let github_env : Map[String, String] = { "GITHUB_ACTIONS": "true" }

  assert_true(!@adapters.is_github_actions_env(empty_env))
  assert_true(@adapters.is_github_actions_env(github_env))

  try {
    ignore(@adapters.read_ci_diff(empty_env, patch_path))
    panic()
  } catch {
    err => assert_true(err.to_string().contains("CI_CONTEXT_NOT_FOUND"))
  }

  assert_eq(@adapters.read_ci_diff(github_env, patch_path), diff)
}

///|
/// `pr` 模式应写入独立输出目录，并要求存在 pull request 上下文。
/// `pr` mode should write to its own output directory and require pull-request context.
test "pr diff adapter requires pull request metadata" {
  let run_dir = @infra.join_path("tmp", "moonforge-diff-pr")
  let diff =
    #|diff --git a/src/pr.mbt b/src/pr.mbt
    #|index 111..222 100644
    #|--- a/src/pr.mbt
    #|+++ b/src/pr.mbt
    #|@@ -1,1 +1,1 @@
    #|-old
    #|+new
  let patch_path = @infra.join_path(run_dir, "patch.diff")
  @infra.write_text(patch_path, diff)

  let missing_pr_env : Map[String, String] = {
    "GITHUB_ACTIONS": "true",
    "GITHUB_EVENT_NAME": "pull_request",
  }
  let pr_env : Map[String, String] = {
    "GITHUB_ACTIONS": "true",
    "GITHUB_EVENT_NAME": "pull_request",
    "GITHUB_BASE_REF": "main",
    "GITHUB_HEAD_REF": "feature/search",
  }

  assert_eq(@adapters.normalize_mode("pr"), "pr")
  assert_true(@adapters.latest_output_dir("/tmp/demo", "pr").contains("/pr/latest"))

  try {
    ignore(@adapters.read_pr_diff(missing_pr_env, patch_path))
    panic()
  } catch {
    err => assert_true(err.to_string().contains("PR_CONTEXT_NOT_FOUND"))
  }

  assert_eq(@adapters.read_pr_diff(pr_env, patch_path), diff)
}
