///|
/// 文件总说：
/// 这个文件检查“材料到底是从哪里找到的、找的过程是不是符合项目默认习惯”。
/// 这类提醒对用户很重要，因为很多时候：
/// - 材料不是没有，而是放错目录了
/// - 材料名字不是没有，而是用了别名
/// - 系统虽然找到了材料，但并不是从当前任务主目录里找到的
///
/// 这些问题不一定要立刻拦截，
/// 但很值得在 report 里说清楚。

///|
/// 一条材料策略提醒。
pub(all) struct MaterialPolicyIssue {
  code : String
  severity : String
  detail : String
  suggestion : String
} derive(Debug)

///|
/// 一次材料策略检查结果。
pub(all) struct MaterialPolicyReview {
  found_outside_primary_dir : Array[String]
  alias_matched_artifacts : Array[String]
  missing_artifacts : Array[String]
  issues : Array[MaterialPolicyIssue]
} derive(Debug)

///|
/// 把任务里写的主材料目录规范化成绝对路径。
fn resolve_primary_artifact_dir(
  repo_root : String,
  current_task : @domain.CurrentTask,
) -> String {
  let directory = current_task.artifact_dir.trim().to_string()
  if directory == "" {
    repo_root
  } else if directory.has_prefix("/") {
    @infra.normalize_path(directory)
  } else {
    @infra.join_path(repo_root, directory)
  }
}

///|
/// 检查材料发现结果是否符合主目录优先的习惯。
pub fn review_material_policy(
  repo_root : String,
  current_task : @domain.CurrentTask,
  required_artifacts : Array[String],
  discovery : @domain.MaterialDiscoveryResult,
) -> MaterialPolicyReview {
  let primary_dir = resolve_primary_artifact_dir(repo_root, current_task)
  let found_outside_primary_dir : Array[String] = []
  let alias_matched_artifacts : Array[String] = []
  let missing_artifacts : Array[String] = []
  let issues : Array[MaterialPolicyIssue] = []

  for record in discovery.records {
    match record.matched_path {
      Some(path) =>
        if !path.has_prefix(primary_dir) {
          found_outside_primary_dir.push(record.artifact_name)
        }
      None => missing_artifacts.push(record.artifact_name)
    }

    match record.matched_name {
      Some(name) =>
        if name != record.artifact_name {
          alias_matched_artifacts.push(record.artifact_name)
        }
      None => ()
    }
  }

  if !found_outside_primary_dir.is_empty() {
    issues.push({
      code: "ARTIFACT_FOUND_OUTSIDE_PRIMARY_DIR",
      severity: "info",
      detail: "有 \{found_outside_primary_dir.length()} 个材料不是从当前任务主目录找到的",
      suggestion: "如果希望团队更容易理解，建议把材料收拢到 artifact_dir 指向的目录",
    })
  }

  if !alias_matched_artifacts.is_empty() {
    issues.push({
      code: "ARTIFACT_MATCHED_BY_ALIAS",
      severity: "info",
      detail: "有 \{alias_matched_artifacts.length()} 个材料是通过候选别名命中的",
      suggestion: "如果团队想降低歧义，建议统一使用标准材料文件名",
    })
  }

  if !missing_artifacts.is_empty() {
    issues.push({
      code: "ARTIFACT_STILL_MISSING",
      severity: "warning",
      detail: "仍有 \{missing_artifacts.length()} 个必需材料没有找到",
      suggestion: "把缺失材料补到当前任务主目录，或检查材料目录册配置",
    })
  }

  if required_artifacts.is_empty() && !discovery.records.is_empty() {
    issues.push({
      code: "ARTIFACT_SEARCH_REDUNDANT",
      severity: "info",
      detail: "当前任务理论上不需要材料，但系统仍执行了材料发现",
      suggestion: "检查模板定义，确认 required_artifacts 是否需要收紧",
    })
  }

  {
    found_outside_primary_dir,
    alias_matched_artifacts,
    missing_artifacts,
    issues,
  }
}

///|
/// 生成材料策略检查摘要。
pub fn MaterialPolicyReview::summary(self : MaterialPolicyReview) -> String {
  [
    "outside_primary=\{self.found_outside_primary_dir.length()}",
    "alias=\{self.alias_matched_artifacts.length()}",
    "missing=\{self.missing_artifacts.length()}",
    "issues=\{self.issues.length()}",
  ].join(" | ")
}
