///|
/// 文件说明：实现门禁核心判定逻辑，负责把补丁文件、任务约束和材料输入转成最终决策。
/// 联动文件：读取 `src/domain/types.mbt` 中的规则与结果对象，并被 `src/services/commands.mbt` 作为检查主引擎调用。

///|

///|
/// 统一构造违规项，减少重复字段拼装代码。
fn push_violation(
  violations : Array[@domain.Violation],
  code : String,
  file : String?,
  detail : String,
  suggestion : String,
) -> Unit {
  violations.push(@domain.Violation::{ code, file, detail, suggestion })
}

///|
/// 从标准 git diff 文本中提取本次真正触碰的文件列表。
pub fn extract_touched_files(diff_text : String) -> Array[String] {
  @infra.parse_changed_files(diff_text)
}

///|
/// 将仓库规则、模板规则和当前任务合并为一次检查的最终约束。
/// 这里会展开 `target_groups`，并把 repo 级与模板级文件上限收紧成最终值。
pub fn build_effective_task(
  repo_rules : @domain.RepoRules,
  template : @domain.TaskTemplate,
  current_task : @domain.CurrentTask,
) -> @domain.EffectiveTask raise {
  if template.task_type != current_task.task_type {
    raise Failure::Failure(
      "Current task type \{current_task.task_type} does not match template \{template.task_type}",
    )
  }

  let expanded_target_groups = @infra.expand_target_groups(
    repo_rules.path_groups,
    current_task.target_groups,
  )
  let explicit_allowed_paths = @infra.unique_strings(
    expanded_target_groups + current_task.target_paths,
  )
  let invalid_explicit_targets = explicit_allowed_paths.filter(path => {
    !@infra.matches_any(path, template.allowed_paths)
  })
  if !invalid_explicit_targets.is_empty() {
    raise Failure::Failure("TASK_SCOPE_INVALID")
  }
  let allowed_paths = if explicit_allowed_paths.is_empty() {
    template.allowed_paths
  } else {
    explicit_allowed_paths
  }
  let max_changed_files = match repo_rules.max_changed_files {
    Some(limit) => pick_stricter_limit(template.max_changed_files, limit)
    None => template.max_changed_files
  }

  @domain.EffectiveTask::{
    task_type: current_task.task_type,
    title: current_task.title,
    allowed_paths: @infra.unique_strings(allowed_paths),
    forbidden_paths: @infra.unique_strings(
      template.forbidden_paths + repo_rules.protected_paths,
    ),
    approval_required_paths: @infra.unique_strings(
      template.manual_approval_paths + repo_rules.approval_required_paths,
    ),
    allowed_extensions: if template.allowed_extensions.is_empty() {
      repo_rules.default_allowed_extensions
    } else {
      template.allowed_extensions
    },
    blocked_extensions: @infra.unique_strings(repo_rules.blocked_extensions),
    generated_artifact_paths: @infra.unique_strings(
      repo_rules.generated_artifact_paths,
    ),
    blocked_file_names: @infra.unique_strings(repo_rules.blocked_file_names),
    blocked_file_patterns: @infra.unique_strings(
      repo_rules.blocked_file_patterns,
    ),
    content_blocklist_patterns: @infra.unique_strings(
      repo_rules.content_blocklist_patterns,
    ),
    required_artifacts: current_task.merged_required_artifacts(
      template.required_artifacts,
    ),
    required_commands: current_task.merged_required_commands(
      template.required_commands,
    ),
    max_changed_files,
  }
}

///|
/// 取两个文件上限中更严格的那个值，避免合并后放宽门禁。
pub fn pick_stricter_limit(left : Int, right : Int) -> Int {
  if left <= right {
    left
  } else {
    right
  }
}

///|
/// 执行路径、后缀、材料和审批要求的完整门禁判定。
pub fn evaluate_gate(
  effective_task : @domain.EffectiveTask,
  diff_text : String,
  provided_artifacts : Map[String, String],
  artifact_required_fields : Map[String, Array[String]],
  repo_root : String,
  run_id : String,
) -> @domain.CheckResult raise {
  let checked_files = extract_touched_files(diff_text)
  let scope_result = check_scope(effective_task, checked_files)
  let out_of_scope_files = scope_result.out_of_scope_files
  let protected_files : Array[String] = []
  let approval_required_files : Array[String] = []
  let file_type_result = check_file_types(
    effective_task.allowed_extensions,
    effective_task.blocked_extensions,
    effective_task.blocked_file_names,
    effective_task.blocked_file_patterns,
    effective_task.generated_artifact_paths,
    checked_files,
  )
  let forbidden_extension_files = file_type_result.forbidden_extension_files
  let blocked_file_name_files = file_type_result.blocked_file_name_files
  let blocked_file_pattern_files = file_type_result.blocked_file_pattern_files
  let generated_artifact_files = file_type_result.generated_artifact_files
  let violations : Array[@domain.Violation] = []
  let artifact_result = check_artifacts(
    effective_task.required_artifacts,
    provided_artifacts,
    artifact_required_fields,
  )
  let missing_artifacts = artifact_result.missing_artifacts
  let invalid_artifacts = artifact_result.invalid_artifacts
  let content_blocklist_hits = find_blocklisted_files(
    diff_text,
    effective_task.content_blocklist_patterns,
  )
  let command_result = check_required_commands(
    effective_task.required_commands,
    repo_root,
  )
  let command_failures = command_result.failed_commands
  let provided_artifact_names : Array[String] = []
  for artifact in effective_task.required_artifacts {
    if provided_artifacts.contains(artifact) {
      provided_artifact_names.push(artifact)
    }
  }

  let mut hard_failure = false
  let mut needs_human = false

  for file in checked_files {
    if out_of_scope_files.contains(file) {
      push_violation(
        violations,
        "PATH_OUT_OF_SCOPE",
        Some(file),
        "文件不在本次任务允许范围内",
        "缩小变更范围，或在 task 阶段重新定义目标路径",
      )
      hard_failure = true
    }

    if @infra.matches_any(file, effective_task.forbidden_paths) {
      protected_files.push(file)
      push_violation(
        violations,
        "PROTECTED_PATH_TOUCHED",
        Some(file),
        "触碰了受保护目录或显式禁止目录",
        "撤回该文件修改，或拆分为单独审批任务",
      )
      hard_failure = true
    }

    if @infra.matches_any(file, effective_task.approval_required_paths) {
      approval_required_files.push(file)
      needs_human = true
    }
  }

  for file in forbidden_extension_files {
    push_violation(
      violations,
      "FORBIDDEN_EXTENSION",
      Some(file),
      "生成了当前模板不允许的文件类型",
      "移除该文件，或调整模板允许后缀后重新执行",
    )
    hard_failure = true
  }

  for file in blocked_file_name_files {
    push_violation(
      violations,
      "BLOCKED_FILE_NAME",
      Some(file),
      "命中了仓库级禁止提交的文件名",
      "撤回该文件，或调整仓库规则后重新执行检查",
    )
    hard_failure = true
  }

  for file in blocked_file_pattern_files {
    push_violation(
      violations,
      "BLOCKED_FILE_PATTERN",
      Some(file),
      "命中了仓库级禁止提交的文件路径模式",
      "撤回该文件，或调整仓库规则后重新执行检查",
    )
    hard_failure = true
  }

  for file in generated_artifact_files {
    push_violation(
      violations,
      "GENERATED_ARTIFACT_TOUCHED",
      Some(file),
      "误提交了生成产物、缓存或覆盖率结果",
      "从暂存区移除该文件后重新执行检查",
    )
    hard_failure = true
  }

  if scope_result.file_count_exceeded {
    push_violation(
      violations,
      "CHANGED_FILE_COUNT_EXCEEDED",
      None,
      "本次变更文件数 \{checked_files.length()} 超出上限 \{effective_task.max_changed_files}",
      "拆分任务或缩减改动范围后重新检查",
    )
    hard_failure = true
  }

  for artifact in missing_artifacts {
    push_violation(
      violations,
      "MISSING_ARTIFACT",
      Some(artifact),
      "缺少模板要求的材料文件",
      "补齐 \{artifact} 后重新执行检查",
    )
  }

  for artifact in invalid_artifacts {
    push_violation(
      violations,
      "ARTIFACT_INVALID",
      Some(artifact),
      "材料文件存在，但格式或字段不满足要求",
      "修复 \{artifact} 的结构后重新执行检查",
    )
  }

  for command in command_failures {
    push_violation(
      violations,
      "REQUIRED_COMMAND_FAILED",
      None,
      "必需校验命令执行失败：\{command}",
      "修复命令失败原因后重新执行检查",
    )
  }

  for file in content_blocklist_hits {
    push_violation(
      violations,
      "CONTENT_PATTERN_BLOCKED",
      Some(file),
      "命中了调试残留或临时标记黑名单",
      "移除调试输出或临时标记后重新执行检查",
    )
    hard_failure = true
  }

  if needs_human {
    push_violation(
      violations,
      "MANUAL_APPROVAL_REQUIRED",
      None,
      "本次变更触碰到需要人工审批的路径",
      "转人工审批，或拆分高风险路径后重新提交",
    )
  }

  let decision = if hard_failure {
    @domain.Reject
  } else if needs_human {
    @domain.NeedHumanApproval
  } else if !missing_artifacts.is_empty() ||
    !invalid_artifacts.is_empty() ||
    !command_failures.is_empty() {
    @domain.Retryable
  } else {
    @domain.Accept
  }

  @domain.CheckResult::{
    run_id,
    decision,
    violations,
    checked_files,
    out_of_scope_files,
    protected_files,
    approval_required_files,
    forbidden_extension_files,
    blocked_file_name_files,
    blocked_file_pattern_files,
    generated_artifact_files,
    missing_artifacts,
    invalid_artifacts,
    provided_artifacts: provided_artifact_names,
    command_failures,
    content_blocklist_hits,
    effective_task,
    changed_file_count: checked_files.length(),
    changed_file_count_exceeded: scope_result.file_count_exceeded,
  }
}
