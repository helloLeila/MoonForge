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
