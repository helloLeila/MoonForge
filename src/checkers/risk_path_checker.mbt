///|
/// 文件说明：实现风险路径检查器，将受保护目录与人工审批目录分开识别，供 gate 主链路复用。
/// 联动文件：由 `src/checkers/gate.mbt` 调用，检查结果决定是否触发 Reject 或 NeedHumanApproval 分支。

///|
/// 风险路径检查结果，区分直接拒绝的受保护文件和需要人工审批的高风险文件。
pub(all) struct RiskPathResult {
  protected_files : Array[String]
  approval_files : Array[String]
} derive(Debug)

///|
/// 将变更文件列表与受保护路径和审批路径做匹配，优先识别受保护路径。
/// 入参：`protected_paths`，不允许任何修改的目录；`approval_paths`，修改前需人工审批的目录。
/// 入参：`changed_files`，本次差异中提取的文件路径列表。
/// 出参：`RiskPathResult`，分别记录命中受保护目录和命中审批目录的文件列表。
pub fn check_risk_paths(
  protected_paths : Array[String],
  approval_paths : Array[String],
  changed_files : Array[String],
) -> RiskPathResult {
  let protected_files : Array[String] = []
  let approval_files : Array[String] = []
  for file in changed_files {
    if @infra.matches_any(file, protected_paths) {
      protected_files.push(file)
    } else if @infra.matches_any(file, approval_paths) {
      approval_files.push(file)
    }
  }
  RiskPathResult::{ protected_files, approval_files }
}
