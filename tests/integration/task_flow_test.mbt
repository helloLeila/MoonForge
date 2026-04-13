///|
/// 文件说明：覆盖 init 与 task 命令服务的集成行为，确保初始化后目录结构和模板文件均正确创建。
/// 联动文件：直接调用 `src/services/commands.mbt` 的 `init_repo` 和 `create_task` 函数。

///|

///|
/// 为每条集成测试生成互不干扰的临时仓库目录。
fn unique_init_dir(label : String) -> String {
  @infra.join_path("tmp", "moonforge-init-\{label}-\{@uv.hrtime()}")
}

///|
/// init_repo 应在指定目录创建仓库规则文件和五类任务模板文件。
test "init creates repo rules and five templates" {
  let repo = unique_init_dir("init")
  ignore(@services.init_repo(repo))
  assert_true(
    @infra.path_exists(@infra.join_path(repo, ".moonforge/repo-rules.yml")),
  )
  assert_true(
    @infra.path_exists(
      @infra.join_path(repo, ".moonforge/task-types/feature-change.yml"),
    ),
  )
  assert_true(
    @infra.path_exists(
      @infra.join_path(repo, ".moonforge/task-types/bug-fix.yml"),
    ),
  )
  assert_true(
    @infra.path_exists(
      @infra.join_path(repo, ".moonforge/task-types/api-change.yml"),
    ),
  )
  assert_true(
    @infra.path_exists(
      @infra.join_path(repo, ".moonforge/task-types/config-change.yml"),
    ),
  )
  assert_true(
    @infra.path_exists(
      @infra.join_path(repo, ".moonforge/task-types/test-addition.yml"),
    ),
  )
  let current_task = @infra.read_text(
    @infra.join_path(repo, ".moonforge/current-task.yml"),
  )
  assert_true(current_task.contains("task_type: \"\""))
  assert_true(current_task.contains("target_groups"))
  assert_true(current_task.contains("target_paths"))
}

///|
/// create_task 应在初始化后创建一个包含 task_type 和 title 的当前任务文件。
test "create task writes current task file" {
  let repo = unique_init_dir("task")
  ignore(@services.init_repo(repo))
  ignore(
    @services.create_task(
      repo, "feature-change", "Add user filter", "frontend/src/pages/**",
    ),
  )
  assert_true(
    @infra.path_exists(@infra.join_path(repo, ".moonforge/current-task.yml")),
  )
  let content = @infra.read_text(
    @infra.join_path(repo, ".moonforge/current-task.yml"),
  )
  assert_true(content.contains("feature-change"))
}

///|
/// create_task 应支持基于路径组快速生成当前任务文件。
test "create task writes target groups when group selected" {
  let repo = unique_init_dir("task-group")
  ignore(@services.init_repo(repo))
  ignore(
    @services.create_task(
      repo, "feature-change", "Add grouped filter", "@frontend_pages",
    ),
  )
  let content = @infra.read_text(
    @infra.join_path(repo, ".moonforge/current-task.yml"),
  )
  assert_true(content.contains("target_groups"))
  assert_true(content.contains("frontend_pages"))
}
