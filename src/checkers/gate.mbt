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
  let touched : Array[String] = []
  for
    line in diff_text.split("\n").map(item => item.trim().to_string()).collect() {
    if line.has_prefix("diff --git a/") {
      let tokens = line.split(" ").map(token => token.to_string()).collect()
      if tokens.length() >= 4 {
        let left = tokens[2]
        if left.has_prefix("a/") {
          touched.push(left[2:left.length()].to_string())
        } else {
          touched.push(left)
        }
      }
    }
  }
  @infra.unique_strings(touched)
}

///|
/// 将仓库规则、模板规则和当前任务合并为一次检查的最终约束。
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

  let allowed_paths = if current_task.target_paths.is_empty() {
    template.allowed_paths
  } else {
    current_task.target_paths
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
    required_artifacts: @infra.unique_strings(template.required_artifacts),
    max_changed_files: template.max_changed_files,
  }
}

///|
/// 执行路径、后缀、材料和审批要求的完整门禁判定。
pub fn evaluate_gate(
  effective_task : @domain.EffectiveTask,
  diff_text : String,
  provided_artifacts : Array[String],
  run_id : String,
) -> @domain.CheckResult {
  let checked_files = extract_touched_files(diff_text)
  let out_of_scope_files : Array[String] = []
  let protected_files : Array[String] = []
  let approval_required_files : Array[String] = []
  let forbidden_extension_files : Array[String] = []
  let violations : Array[@domain.Violation] = []
  let missing_artifacts : Array[String] = []

  let mut hard_failure = false
  let mut needs_human = false

  for file in checked_files {
    if !@infra.matches_any(file, effective_task.allowed_paths) {
      out_of_scope_files.push(file)
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

    if !@infra.has_allowed_extension(file, effective_task.allowed_extensions) {
      forbidden_extension_files.push(file)
      push_violation(
        violations,
        "FORBIDDEN_EXTENSION",
        Some(file),
        "生成了当前模板不允许的文件类型",
        "移除该文件，或调整模板允许后缀后重新执行",
      )
      hard_failure = true
    }
  }

  if checked_files.length() > effective_task.max_changed_files {
    push_violation(
      violations,
      "CHANGED_FILE_COUNT_EXCEEDED",
      None,
      "本次变更文件数 \{checked_files.length()} 超出上限 \{effective_task.max_changed_files}",
      "拆分任务或缩减改动范围后重新检查",
    )
    hard_failure = true
  }

  for artifact in effective_task.required_artifacts {
    if !provided_artifacts.contains(artifact) {
      missing_artifacts.push(artifact)
      push_violation(
        violations,
        "MISSING_ARTIFACT",
        Some(artifact),
        "缺少模板要求的材料文件",
        "补齐 \{artifact} 后重新执行检查",
      )
    }
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
  } else if !missing_artifacts.is_empty() {
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
    missing_artifacts,
    provided_artifacts,
    effective_task,
    changed_file_count: checked_files.length(),
    changed_file_count_exceeded: checked_files.length() >
    effective_task.max_changed_files,
  }
}
