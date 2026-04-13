///|
/// 文件说明：实现正式结论构建器，按优先级顺序将各检查器结果合并为唯一门禁结论。
/// 联动文件：被 `src/checkers/gate.mbt` 调用，替代内联的决策分支，确保优先级语义集中维护。

///|
/// 按优先级合并所有检查器标志，生成最终门禁结论视图。
/// 优先级从高到低：Reject（越界或受保护路径）> NeedHumanApproval > Retryable（材料缺失）> Accept。
/// 入参：`has_scope_reject`，是否有文件越界或文件数超限。
/// 入参：`has_protected_path`，是否命中受保护目录。
/// 入参：`has_approval`，是否命中人工审批目录。
/// 入参：`has_missing_artifacts`，是否存在缺失的必需材料。
/// 出参：`DecisionView`，携带结论编码与双语展示字段的视图对象。
pub fn build_decision(
  has_scope_reject~ : Bool,
  has_protected_path~ : Bool,
  has_approval~ : Bool,
  has_missing_artifacts~ : Bool,
) -> @domain.DecisionView {
  let decision = if has_scope_reject || has_protected_path {
    @domain.Reject
  } else if has_approval {
    @domain.NeedHumanApproval
  } else if has_missing_artifacts {
    @domain.Retryable
  } else {
    @domain.Accept
  }
  @domain.DecisionView::from_decision(decision)
}
