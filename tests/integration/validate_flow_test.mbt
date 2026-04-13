///|
/// 文件说明：覆盖 validate 与 check 命令服务的集成行为，确保校验和检查流程能正确返回结果。
/// 联动文件：直接调用 `src/services/commands.mbt` 的 `validate_repo` 和 `run_check` 函数。

///|

///|
/// 为每条集成测试生成互不干扰的临时仓库目录。
fn unique_validate_dir(label : String) -> String {
  @infra.join_path("tmp", "moonforge-validate-\{label}-\{@uv.hrtime()}")
}

///|
/// validate_repo 应在初始化后的仓库中返回通过结果。
test "validate passes after init" {
  let repo = unique_validate_dir("pass")
  ignore(@services.init_repo(repo))
  ignore(
    @services.create_task(
      repo, "feature-change", "Add filter", "frontend/src/pages/**",
    ),
  )
  let result = @services.validate_repo(repo)
  assert_true(result is Ok(_))
}

///|
/// validate_repo 应在仓库规则文件为空时返回错误。
test "validate fails when repo rules empty" {
  let repo = unique_validate_dir("repo-rules-empty")
  ignore(@services.init_repo(repo))
  ignore(
    @services.create_task(
      repo, "feature-change", "Add filter", "frontend/src/pages/**",
    ),
  )
  @infra.write_text(@infra.join_path(repo, ".moonforge/repo-rules.yml"), "")
  let result = @services.validate_repo(repo)
  assert_true(result is Err(_))
}

///|
/// validate_repo 应在仓库规则文件缺少必填字段时返回错误。
test "validate fails when repo rules missing required field" {
  let repo = unique_validate_dir("repo-rules-missing-field")
  let invalid_rules =
    #|protected_paths:
    #|  - "infra/**"
    #|
    #|approval_required_paths:
    #|  - "backend/src/main/java/**/service/high-risk/**"
    #|
    #|default_allowed_extensions:
    #|  - ".ts"
    #|
  ignore(@services.init_repo(repo))
  ignore(
    @services.create_task(
      repo, "feature-change", "Add filter", "frontend/src/pages/**",
    ),
  )
  @infra.write_text(
    @infra.join_path(repo, ".moonforge/repo-rules.yml"),
    invalid_rules,
  )
  let result = @services.validate_repo(repo)
  assert_true(result is Err(_))
}

///|
/// validate_repo 应在仓库规则 YAML 语法非法时返回错误，而不是放过。
test "validate fails when repo rules yaml invalid" {
  let repo = unique_validate_dir("repo-rules-yaml")
  let invalid_rules =
    #|protected_paths:
    #|  - "infra/**"
    #|
    #|approval_required_paths:
    #|  - "backend/src/main/java/**/service/high-risk/**"
    #|
    #|default_allowed_extensions:
    #|  - ".ts"
    #|
    #|path_groups.frontend_pages:
    #|  - "frontend/src/pages/**"
    #|oops
    #|
  ignore(@services.init_repo(repo))
  ignore(
    @services.create_task(
      repo, "feature-change", "Add filter", "frontend/src/pages/**",
    ),
  )
  @infra.write_text(
    @infra.join_path(repo, ".moonforge/repo-rules.yml"),
    invalid_rules,
  )
  let result = @services.validate_repo(repo)
  assert_true(result is Err(_))
}

///|
/// validate_repo 不应把 init 生成的空白任务样例当作合法任务。
test "validate fails on blank task sample after init" {
  let repo = unique_validate_dir("blank")
  ignore(@services.init_repo(repo))
  let result = @services.validate_repo(repo)
  assert_true(result is Err(_))
}

///|
/// validate_repo 应在缺失当前任务文件时返回错误。
test "validate fails when current task missing" {
  let repo = unique_validate_dir("missing")
  ignore(@services.init_repo(repo))
  @infra.write_text(@infra.join_path(repo, ".moonforge/current-task.yml"), "")
  let result = @services.validate_repo(repo)
  assert_true(result is Err(_))
}

///|
/// validate_repo 应在当前任务缺少 title 时返回错误，而不是抛出异常。
test "validate fails when current task title missing" {
  let repo = unique_validate_dir("missing-title")
  let invalid_task =
    #|task_type: "feature-change"
    #|
    #|target_groups:
    #|  - "frontend_pages"
    #|
    #|target_paths:
    #|  - "frontend/src/pages/**"
    #|
  ignore(@services.init_repo(repo))
  @infra.write_text(
    @infra.join_path(repo, ".moonforge/current-task.yml"),
    invalid_task,
  )
  let result = @services.validate_repo(repo)
  assert_true(result is Err(_))
}

///|
/// validate_repo 应在当前任务使用未知 task_type 时返回错误。
test "validate fails when current task type unknown" {
  let repo = unique_validate_dir("unknown-task-type")
  let invalid_task =
    #|task_type: "unknown-type"
    #|title: "Add filter"
    #|
    #|target_groups:
    #|  - "frontend_pages"
    #|
    #|target_paths:
    #|  - "frontend/src/pages/**"
    #|
  ignore(@services.init_repo(repo))
  @infra.write_text(
    @infra.join_path(repo, ".moonforge/current-task.yml"),
    invalid_task,
  )
  let result = @services.validate_repo(repo)
  match result {
    Err(message) => assert_true(message.contains("TASK_TYPE_UNKNOWN"))
    Ok(_) => panic()
  }
}

///|
/// validate_repo 应接受仓库内新增模板对应的自定义 task_type。
test "validate passes when current task type matches custom template" {
  let repo = unique_validate_dir("custom-task-type")
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
  let custom_task =
    #|task_type: "custom-review"
    #|title: "Review list page"
    #|
    #|target_groups:
    #|  - "frontend_pages"
    #|
    #|target_paths:
    #|  - "frontend/src/pages/**"
    #|
  ignore(@services.init_repo(repo))
  @infra.write_text(
    @infra.join_path(repo, ".moonforge/task-types/custom-review.yml"),
    custom_template,
  )
  @infra.write_text(
    @infra.join_path(repo, ".moonforge/current-task.yml"),
    custom_task,
  )
  let result = @services.validate_repo(repo)
  assert_true(result is Ok(_))
}

///|
/// validate_repo 应在当前任务 YAML 语法非法时返回错误，而不是抛出异常。
test "validate fails when current task yaml invalid" {
  let repo = unique_validate_dir("invalid-task-yaml")
  let invalid_task =
    #|task_type: "feature-change"
    #|title: "Add filter"
    #|target_groups:
    #|  - "frontend_pages"
    #|oops
    #|
  ignore(@services.init_repo(repo))
  @infra.write_text(
    @infra.join_path(repo, ".moonforge/current-task.yml"),
    invalid_task,
  )
  let result = @services.validate_repo(repo)
  assert_true(result is Err(_))
}

///|
/// validate_repo 应拦截手工写入的越界目标路径。
test "validate fails when current task target path is outside template scope" {
  let repo = unique_validate_dir("target-outside-scope")
  let invalid_task =
    #|task_type: "feature-change"
    #|title: "Add filter"
    #|target_groups:
    #|  - "frontend_pages"
    #|
    #|target_paths:
    #|  - "backend/src/main/java/**/security/**"
    #|
  ignore(@services.init_repo(repo))
  @infra.write_text(
    @infra.join_path(repo, ".moonforge/current-task.yml"),
    invalid_task,
  )
  let result = @services.validate_repo(repo)
  assert_true(result is Err(_))
}

///|
/// validate_repo 应在当前任务引用的模板语义非法时返回错误。
test "validate fails when active template semantics invalid" {
  let repo = unique_validate_dir("template")
  let invalid_template =
    #|task_type: feature-change
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
    #|max_changed_files: 0
    #|
    #|manual_approval_paths:
    #|  - "backend/src/main/java/**/service/high-risk/**"
    #|
  ignore(@services.init_repo(repo))
  ignore(
    @services.create_task(
      repo, "feature-change", "Add filter", "frontend/src/pages/**",
    ),
  )
  @infra.write_text(
    @infra.join_path(repo, ".moonforge/task-types/feature-change.yml"),
    invalid_template,
  )
  let result = @services.validate_repo(repo)
  assert_true(result is Err(_))
}

///|
/// validate_repo 应在活动模板的允许路径与禁止路径冲突时返回错误。
test "validate fails when active template paths overlap" {
  let repo = unique_validate_dir("template-overlap")
  let invalid_template =
    #|task_type: feature-change
    #|
    #|allowed_paths:
    #|  - "frontend/src/pages/**"
    #|  - "infra/**"
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
  ignore(
    @services.create_task(
      repo, "feature-change", "Add filter", "frontend/src/pages/**",
    ),
  )
  @infra.write_text(
    @infra.join_path(repo, ".moonforge/task-types/feature-change.yml"),
    invalid_template,
  )
  let result = @services.validate_repo(repo)
  assert_true(result is Err(_))
}

///|
/// validate_repo 应在当前任务引用的模板 YAML 非法时返回错误，而不是抛出异常。
test "validate fails when active template yaml invalid" {
  let repo = unique_validate_dir("template-yaml")
  let invalid_template =
    #|task_type: feature-change
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
    #|max_changed_files: nope
    #|
    #|manual_approval_paths:
    #|  - "backend/src/main/java/**/service/high-risk/**"
    #|
  ignore(@services.init_repo(repo))
  ignore(
    @services.create_task(
      repo, "feature-change", "Add filter", "frontend/src/pages/**",
    ),
  )
  @infra.write_text(
    @infra.join_path(repo, ".moonforge/task-types/feature-change.yml"),
    invalid_template,
  )
  let result = @services.validate_repo(repo)
  assert_true(result is Err(_))
}

///|
/// validate_repo 应在非活动模板语义非法时同样返回错误。
test "validate fails when inactive template semantics invalid" {
  let repo = unique_validate_dir("inactive-template")
  let invalid_template =
    #|task_type: bug-fix
    #|
    #|allowed_paths:
    #|  - "frontend/src/**"
    #|
    #|forbidden_paths:
    #|  - "backend/src/main/java/**/payment/**"
    #|
    #|allowed_extensions:
    #|  - ".ts"
    #|
    #|required_artifacts:
    #|  - "bug-context.md"
    #|
    #|max_changed_files: 0
    #|
    #|manual_approval_paths:
    #|  - "backend/src/main/java/**/service/high-risk/**"
    #|
  ignore(@services.init_repo(repo))
  ignore(
    @services.create_task(
      repo, "feature-change", "Add filter", "frontend/src/pages/**",
    ),
  )
  @infra.write_text(
    @infra.join_path(repo, ".moonforge/task-types/bug-fix.yml"),
    invalid_template,
  )
  let result = @services.validate_repo(repo)
  assert_true(result is Err(_))
}

///|
/// validate_repo 应校验 task-types 目录下额外新增的模板文件。
test "validate fails when custom template semantics invalid" {
  let repo = unique_validate_dir("custom-template")
  let invalid_template =
    #|task_type: custom-review
    #|
    #|allowed_paths:
    #|  - "frontend/src/pages/**"
    #|
    #|forbidden_paths:
    #|  - "frontend/src/pages/**"
    #|
    #|allowed_extensions:
    #|  - ".ts"
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
  ignore(
    @services.create_task(
      repo, "feature-change", "Add filter", "frontend/src/pages/**",
    ),
  )
  @infra.write_text(
    @infra.join_path(repo, ".moonforge/task-types/custom-review.yml"),
    invalid_template,
  )
  let result = @services.validate_repo(repo)
  assert_true(result is Err(_))
}
