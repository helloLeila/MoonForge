///|
/// 文件说明：实现材料存在性与有效性检查器，负责识别缺失材料文件和格式不合要求的材料内容。
/// 联动文件：由 `src/checkers/gate.mbt` 调用，检查结果决定是否触发 MISSING_ARTIFACT 违规或 Retryable 分支。

///|
/// 材料检查结果，分别记录缺失的材料文件和格式无效的材料文件。
pub(all) struct ArtifactCheckResult {
  missing_artifacts : Array[String]
  invalid_artifacts : Array[String]
} derive(Debug)

///|
/// 校验 JSON 材料是否具备对象外形与必填字段。
/// 入参：`text`，JSON 材料的原始文本。
/// 入参：`required_fields`，当前材料必须具备的字段名列表。
/// 出参：`Result[Unit, String]`，符合最小结构时返回 `Ok(())`，否则返回 `Err("ARTIFACT_INVALID")`。
pub fn validate_json_artifact(
  text : String,
  required_fields : Array[String],
) -> Result[Unit, String] {
  let trimmed = text.trim().to_string()
  if !trimmed.has_prefix("{") || !trimmed.has_suffix("}") {
    return Err("ARTIFACT_INVALID")
  }
  for field in required_fields {
    if !trimmed.contains("\"\{field}\"") {
      return Err("ARTIFACT_INVALID")
    }
  }
  Ok(())
}

///|
/// 检查所有必需材料是否在提供的材料映射中存在。
/// 入参：`required_artifacts`，模板要求必须提供的材料文件名列表。
/// 入参：`provided_artifacts`，以文件名为键、文件内容为值的材料映射表。
/// 入参：`artifact_required_fields`，按材料名给出的必填字段规则。
/// 出参：`ArtifactCheckResult`，记录缺失和无效的材料文件列表。
pub fn check_artifacts(
  required_artifacts : Array[String],
  provided_artifacts : Map[String, String],
  artifact_required_fields : Map[String, Array[String]],
) -> ArtifactCheckResult {
  let missing_artifacts : Array[String] = []
  let invalid_artifacts : Array[String] = []
  for artifact in required_artifacts {
    if !provided_artifacts.contains(artifact) {
      missing_artifacts.push(artifact)
      continue
    }
    let content = provided_artifacts.get_or_default(artifact, "")
    let required_fields = artifact_required_fields.get_or_default(artifact, [])
    let validation_result = if !required_fields.is_empty() {
      validate_json_artifact(content, required_fields)
    } else if artifact.has_suffix(".md") {
      validate_markdown_artifact(content)
    } else {
      Ok(())
    }
    if validation_result is Err(_) {
      invalid_artifacts.push(artifact)
    }
  }
  ArtifactCheckResult::{ missing_artifacts, invalid_artifacts }
}

///|
/// 校验 Markdown 材料是否包含标题之外的正文内容。
/// 只有标题行的 Markdown 文件被视为空白，返回错误；包含正文段落的文件才通过校验。
/// 入参：`text`，Markdown 材料的原始文本内容。
/// 出参：`Result[Unit, String]`，通过时返回 `Ok(())`，无正文时返回 `Err("ARTIFACT_INVALID")`。
pub fn validate_markdown_artifact(text : String) -> Result[Unit, String] {
  let lines = text
    .split("\n")
    .map(item => item.trim().to_string())
    .filter(item => item != "")
    .collect()
  let body_lines = lines.filter(line => !line.has_prefix("#"))
  if body_lines.length() == 0 {
    Err("ARTIFACT_INVALID")
  } else {
    Ok(())
  }
}

///|
/// 从运行目录中收集已存在的材料文件，以文件名为键、内容为值返回映射表。
/// 入参：`run_dir`，本次检查的运行目录路径。
/// 入参：`artifact_names`，需要收集的材料文件名列表。
/// 出参：`Map[String, String]`，键为文件名，值为读到的内容；不存在的文件不会出现在映射中。
pub fn collect_artifacts(
  run_dir : String,
  artifact_names : Array[String],
) -> Map[String, String] raise {
  let result : Map[String, String] = {}
  for name in artifact_names {
    let path = @infra.join_path(run_dir, name)
    if @infra.path_exists(path) {
      match @infra.read_text_if_exists(path) {
        Some(content) => result[name] = content
        None => ()
      }
    }
  }
  result
}
