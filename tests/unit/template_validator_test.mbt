///|
/// 文件说明：覆盖模板语义校验器的基础失败场景，确保模板文件名与任务类型一致性会被检查。
/// 输入：构造一个任务模板对象，并传入不匹配的配置文件名。
/// 输出：当文件名与模板任务类型不一致时，应返回错误。

///|
/// 模板校验器应拒绝文件名与任务类型不匹配的模板文件。
test "template validator rejects file name mismatch" {
  let template = @domain.TaskTemplate::{
    task_type: "bug-fix",
    allowed_paths: ["src/**"],
    forbidden_paths: [],
    allowed_extensions: [".mbt"],
    required_artifacts: ["test-report.json"],
    max_changed_files: 8,
    manual_approval_paths: [],
  }
  let result = @checkers.validate_template_semantics(
    "feature-change.yml", template,
  )
  assert_eq(result, Err("CONFIG_SCHEMA_INVALID"))
}

///|
/// 模板校验器应拒绝非法的改动文件上限，并保留成功路径。
test "template validator rejects nonpositive max changed files" {
  let template = @domain.TaskTemplate::{
    task_type: "feature-change",
    allowed_paths: ["src/**"],
    forbidden_paths: [],
    allowed_extensions: [".mbt"],
    required_artifacts: ["test-report.json"],
    max_changed_files: 0,
    manual_approval_paths: [],
  }
  let result = @checkers.validate_template_semantics(
    "feature-change.yml", template,
  )
  assert_eq(result, Err("RULE_SEMANTIC_INVALID"))
}

///|
/// 模板校验器应接受文件名匹配且规则值有效的模板。
test "template validator accepts valid template" {
  let template = @domain.TaskTemplate::{
    task_type: "feature-change",
    allowed_paths: ["src/**"],
    forbidden_paths: [],
    allowed_extensions: [".mbt"],
    required_artifacts: ["test-report.json"],
    max_changed_files: 8,
    manual_approval_paths: [],
  }
  let result = @checkers.validate_template_semantics(
    "feature-change.yml", template,
  )
  assert_eq(result, Ok(()))
}
