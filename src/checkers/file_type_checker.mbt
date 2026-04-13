///|
/// 文件说明：实现文件类型检查器，识别敏感文件名与非法后缀，供 gate 主链路复用。
/// 联动文件：由 `src/checkers/gate.mbt` 调用，检查结果决定是否触发 FORBIDDEN_EXTENSION 或敏感文件违规。

///|
/// 文件类型检查结果，区分非法后缀、命中黑名单文件名、命中黑名单路径模式与生成产物。
pub(all) struct FileTypeResult {
  forbidden_extension_files : Array[String]
  blocked_file_name_files : Array[String]
  blocked_file_pattern_files : Array[String]
  generated_artifact_files : Array[String]
} derive(Debug)

///|
/// 检查变更文件列表的文件类型合法性，优先识别黑名单文件名、黑名单路径模式与生成产物，再检查后缀约束。
/// 入参：`allowed_extensions`，模板允许的文件后缀列表；`blocked_filenames`，明确禁止的文件名（如 `.env`）。
/// 入参：`changed_files`，本次差异中提取的文件路径列表。
/// 出参：`FileTypeResult`，分别记录非法后缀、黑名单文件名、黑名单路径模式与生成产物文件。
pub fn check_file_types(
  allowed_extensions : Array[String],
  blocked_extensions : Array[String],
  blocked_filenames : Array[String],
  blocked_file_patterns : Array[String],
  generated_artifact_paths : Array[String],
  changed_files : Array[String],
) -> FileTypeResult {
  let forbidden_extension_files : Array[String] = []
  let blocked_file_name_files : Array[String] = []
  let blocked_file_pattern_files : Array[String] = []
  let generated_artifact_files : Array[String] = []
  for file in changed_files {
    let name = @infra.basename(file)
    if blocked_filenames.contains(name) {
      blocked_file_name_files.push(file)
    } else if @infra.matches_any(file, blocked_file_patterns) {
      blocked_file_pattern_files.push(file)
    } else if @infra.matches_any(file, generated_artifact_paths) {
      generated_artifact_files.push(file)
    } else if blocked_extensions.contains(@infra.extension_of(file)) {
      forbidden_extension_files.push(file)
    } else if !@infra.has_allowed_extension(file, allowed_extensions) {
      forbidden_extension_files.push(file)
    }
  }
  FileTypeResult::{
    forbidden_extension_files,
    blocked_file_name_files,
    blocked_file_pattern_files,
    generated_artifact_files,
  }
}
