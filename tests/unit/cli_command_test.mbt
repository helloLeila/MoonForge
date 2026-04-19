///|
/// 文件说明：覆盖 CLI 子命令分发的最小行为，确保 validate 入口已接通服务层。
/// 联动文件：对应 `src/services/commands.mbt` 的命令分发函数，避免 CLI 入口遗漏。

///|
/// 为 CLI 分发测试生成独立仓库目录。
fn unique_cli_repo(label : String) -> String {
  @infra.join_path("tmp", "moonforge-cli-\{label}")
}

///|
/// 为依赖 git 暂存区的 CLI 测试生成独立目录，避免受当前工作树影响。
fn unique_cli_git_repo(label : String) -> String {
  @infra.join_path("/tmp", @infra.unique_temp_name("moonforge-cli-\{label}"))
}

///|
/// 初始化一个带暂存文件的最小 git 仓库，供 CLI 的 task 自动补全场景复用。
fn seed_cli_git_repo(repo : String) -> Unit raise {
  @infra.ensure_dir(repo)
  ignore(@infra.run_shell_command("git init -q", repo))
  ignore(
    @infra.run_shell_command("git config user.name 'MoonForge CLI Test'", repo),
  )
  ignore(
    @infra.run_shell_command(
      "git config user.email 'moonforge-cli@test.local'", repo,
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
/// validate 子命令应调用配置校验服务并返回通过摘要。
test "cli dispatches validate command" {
  let repo = unique_cli_repo("validate")
  ignore(@services.init_repo(repo))
  ignore(
    @services.create_task(
      repo, "feature-change", "Add filter", "frontend/src/pages/**",
    ),
  )

  let output = @services.dispatch_cli_command("validate", repo)
  assert_true(output.contains("配置校验通过"))
}

///|
/// task 子命令应允许只传任务类型，由服务层自动补齐标题和范围。
test "cli dispatches task command with autofill" {
  let repo = unique_cli_git_repo("task-autofill")
  seed_cli_git_repo(repo)
  ignore(@services.init_repo(repo))

  let output = @services.dispatch_cli_command(
    "task",
    repo,
    task_type="feature-change",
  )
  let content = @infra.read_text(
    @infra.join_path(repo, ".moonforge/current-task.yml"),
  )

  assert_true(output.contains("Wrote current-task.yml"))
  assert_true(content.contains("title_source"))
  assert_true(content.contains("staged_files"))
}

///|
/// check 子命令在本地模式下应支持省略 run 目录，自动读取暂存区。
test "cli dispatches check command with auto local input" {
  let repo = unique_cli_git_repo("check-autofill")
  seed_cli_git_repo(repo)
  ignore(@services.init_repo(repo))
  ignore(
    @services.dispatch_cli_command("task", repo, task_type="feature-change"),
  )
  @infra.write_text(
    @infra.join_path(repo, ".moonforge/artifacts/current/test-report.json"),
    "{\n  \"passed\": true,\n  \"suite\": \"cli\"\n}\n",
  )
  @infra.write_text(
    @infra.join_path(repo, ".moonforge/artifacts/current/review-report.json"),
    "{\n  \"reviewer\": \"cli\",\n  \"status\": \"approved\"\n}\n",
  )

  let output = @services.dispatch_cli_command("check", repo)
  assert_true(output.contains("decision: Accept"))
}

///|
/// replay 子命令应读取已有任务快照并返回重放摘要。
test "cli dispatches replay command" {
  let repo = unique_cli_repo("replay")
  let run_dir = @infra.join_path(repo, "fixture-runs/replay")
  let diff =
    #|diff --git a/frontend/src/pages/UserList/index.tsx b/frontend/src/pages/UserList/index.tsx
    #|index 1111111..2222222 100644
    #|--- a/frontend/src/pages/UserList/index.tsx
    #|+++ b/frontend/src/pages/UserList/index.tsx
    #|@@ -1,1 +1,2 @@
    #| export const userListPage = true
    #|+export const filterEnabled = true
    #|
  @infra.write_text(
    @infra.join_path(repo, "frontend/src/pages/UserList/index.tsx"),
    "export const userListPage = true\n",
  )
  ignore(@services.init_repo(repo))
  ignore(
    @services.create_task(
      repo, "feature-change", "Replay filter", "frontend/src/pages/**",
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
  let result = @services.run_check(repo, run_dir)

  let output = @services.dispatch_cli_command(
    "replay",
    repo,
    run_id=result.run_id,
  )
  assert_true(output.contains(result.run_id))
  assert_true(output.contains("feature-change"))
}

///|
/// doctor 子命令应返回仓库接入状态诊断摘要。
test "cli dispatches doctor command" {
  let repo = unique_cli_repo("doctor")
  ignore(@services.init_repo(repo))
  ignore(
    @services.create_task(
      repo, "feature-change", "Doctor filter", "frontend/src/pages/**",
    ),
  )

  let output = @services.dispatch_cli_command("doctor", repo)
  assert_true(output.contains("配置健康"))
}

///|
/// CLI 错误输出应同时包含中文与英文前缀。
test "cli renders bilingual error message" {
  let output = @services.render_cli_error("Missing required option --repo")
  assert_true(output.contains("错误 / Error"))
  assert_true(output.contains("Missing required option --repo"))
}

///|
/// report 子命令应输出最近一次检查的中文摘要，而不是完整 Markdown。
test "cli dispatches report summary" {
  let repo = unique_cli_repo("report")
  let run_dir = @infra.join_path(repo, "fixture-runs/report")
  let diff =
    #|diff --git a/frontend/src/pages/UserList/index.tsx b/frontend/src/pages/UserList/index.tsx
    #|index 1111111..2222222 100644
    #|--- a/frontend/src/pages/UserList/index.tsx
    #|+++ b/frontend/src/pages/UserList/index.tsx
    #|@@ -1,1 +1,2 @@
    #| export const userListPage = true
    #|+export const summaryEnabled = true
    #|
  @infra.write_text(
    @infra.join_path(repo, "frontend/src/pages/UserList/index.tsx"),
    "export const userListPage = true\n",
  )
  ignore(@services.init_repo(repo))
  ignore(
    @services.create_task(
      repo, "feature-change", "Report filter", "frontend/src/pages/**",
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

  let output = @services.dispatch_cli_command("report", repo)
  assert_true(output.contains("最近一次检查结论"))
}

///|
/// pack 子命令应调用最小验收包导出逻辑并返回成功摘要。
test "cli dispatches pack command" {
  let repo = unique_cli_repo("pack")
  let run_dir = @infra.join_path(repo, "fixture-runs/pack")
  let diff =
    #|diff --git a/frontend/src/pages/UserList/index.tsx b/frontend/src/pages/UserList/index.tsx
    #|index 1111111..2222222 100644
    #|--- a/frontend/src/pages/UserList/index.tsx
    #|+++ b/frontend/src/pages/UserList/index.tsx
    #|@@ -1,1 +1,2 @@
    #| export const userListPage = true
    #|+export const packSummary = true
    #|
  @infra.write_text(
    @infra.join_path(repo, "frontend/src/pages/UserList/index.tsx"),
    "export const userListPage = true\n",
  )
  ignore(@services.init_repo(repo))
  ignore(
    @services.create_task(
      repo, "feature-change", "Pack command", "frontend/src/pages/**",
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

  let output = @services.dispatch_cli_command("pack", repo)
  assert_true(output.contains("打包完成"))
}

///|
/// acc 子命令应调用内部验收 runner，并返回固定 case 的结果摘要。
test "cli dispatches acc command" {
  let output = @services.dispatch_cli_command("acc", "", acceptance_case="pass")
  assert_true(output.contains("Accept"))
  assert_true(output.contains("pass"))
}
