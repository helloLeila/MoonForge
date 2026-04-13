///|
/// 文件说明：集中处理任务允许范围与变更数量的基础检查，供 gate 主链路复用。
/// 联动文件：被 `src/checkers/gate.mbt` 调用，用于识别越界文件、命中的目标路径以及文件数上限。

///|
/// 范围检查结果，保留 gate 复用所需的最小字段。
pub(all) struct ScopeCheckResult {
  out_of_scope_files : Array[String]
  target_paths_hit : Array[String]
  file_count_exceeded : Bool
} derive(Debug)

///|
/// 检查变更文件是否命中允许范围，并判断文件数是否超过上限。
pub fn check_scope(
  task : @domain.EffectiveTask,
  changed_files : Array[String],
) -> ScopeCheckResult {
  let out_of_scope_files : Array[String] = []
  let target_paths_hit : Array[String] = []

  for file in changed_files {
    if @infra.matches_any(file, task.allowed_paths) {
      target_paths_hit.push(file)
    } else {
      out_of_scope_files.push(file)
    }
  }

  ScopeCheckResult::{
    out_of_scope_files,
    target_paths_hit,
    file_count_exceeded: changed_files.length() > task.max_changed_files,
  }
}
