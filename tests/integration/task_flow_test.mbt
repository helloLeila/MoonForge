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
/// `init_repo` should create rule files, task templates, and the pre-commit hook scaffold.
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
  let hook_text = @infra.read_text(
    @infra.join_path(repo, ".git/hooks/pre-commit"),
  )
  assert_true(hook_text.contains("moonforge check"))
  assert_true(hook_text.contains(".moonforge/current-task.yml"))
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

///|
/// create_task 应拒绝未知任务类型，并返回稳定错误码。
test "create task rejects unknown task type" {
  let repo = unique_init_dir("unknown-type")
  ignore(@services.init_repo(repo))

  try {
    ignore(
      @services.create_task(
        repo, "unknown-type", "Add grouped filter", "@frontend_pages",
      ),
    )
    panic()
  } catch {
    err => assert_true(err.to_string().contains("TASK_TYPE_UNKNOWN"))
  }
}

///|
/// create_task 应支持仓库中新增的自定义任务模板类型。
test "create task accepts custom task type from repo templates" {
  let repo = unique_init_dir("custom-type")
  let custom_template =
    #|task_type: custom-review
    #|
    #|allowed_paths:
    #|  - "frontend/src/pages/**"
    #|
    #|forbidden_paths:
    #|  - "infra/**"
    #|
    #|allowed_extensions:
    #|  - ".ts"
    #|  - ".tsx"
    #|
    #|required_artifacts:
    #|  - "review.md"
    #|
    #|max_changed_files: 8
    #|
    #|manual_approval_paths:
    #|  - "backend/src/main/java/**/service/high-risk/**"
    #|
  ignore(@services.init_repo(repo))
  @infra.write_text(
    @infra.join_path(repo, ".moonforge/task-types/custom-review.yml"),
    custom_template,
  )
  ignore(
    @services.create_task(
      repo, "custom-review", "Review list page", "@frontend_pages",
    ),
  )
  let content = @infra.read_text(
    @infra.join_path(repo, ".moonforge/current-task.yml"),
  )
  assert_true(content.contains("custom-review"))
}

///|
/// create_task 应拦截模板文件名与模板 task_type 不一致的情况。
test "create task rejects mismatched template task type" {
  let repo = unique_init_dir("mismatched-template-type")
  let invalid_template =
    #|task_type: bug-fix
    #|
    #|allowed_paths:
    #|  - "frontend/src/pages/**"
    #|
    #|forbidden_paths:
    #|  - "infra/**"
    #|
    #|allowed_extensions:
    #|  - ".ts"
    #|
    #|required_artifacts:
    #|  - "test-report.json"
    #|
    #|max_changed_files: 8
    #|
    #|manual_approval_paths:
    #|  - "backend/src/main/java/**/service/high-risk/**"
    #|
  ignore(@services.init_repo(repo))
  @infra.write_text(
    @infra.join_path(repo, ".moonforge/task-types/feature-change.yml"),
    invalid_template,
  )

  try {
    ignore(
      @services.create_task(
        repo, "feature-change", "Add user filter", "frontend/src/pages/**",
      ),
    )
    panic()
  } catch {
    err => assert_true(err.to_string().contains("CONFIG_SCHEMA_INVALID"))
  }
}
