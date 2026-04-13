///|
/// 文件说明：覆盖结论构建器的最小行为，确保优先级顺序和结论映射均正确。
/// 联动文件：对应 `src/checkers/decision_builder.mbt`，并为 gate 主链路提供回归保护。

///|
/// Reject 应优先于 Retryable。
test "decision builder prefers reject over retryable" {
  let result = @checkers.build_decision(
    has_scope_reject=true,
    has_protected_path=false,
    has_approval=false,
    has_missing_artifacts=true,
  )
  assert_eq(result.code, "Reject")
}

///|
/// 所有条件均无时应返回 Accept。
test "decision builder returns accept when no violations" {
  let result = @checkers.build_decision(
    has_scope_reject=false,
    has_protected_path=false,
    has_approval=false,
    has_missing_artifacts=false,
  )
  assert_eq(result.code, "Accept")
}

///|
/// 仅有人工审批需求时应返回 NeedHumanApproval。
test "decision builder returns approval when only approval needed" {
  let result = @checkers.build_decision(
    has_scope_reject=false,
    has_protected_path=false,
    has_approval=true,
    has_missing_artifacts=false,
  )
  assert_eq(result.code, "NeedHumanApproval")
}

///|
/// 仅有材料缺失时应返回 Retryable。
test "decision builder returns retryable when artifacts missing" {
  let result = @checkers.build_decision(
    has_scope_reject=false,
    has_protected_path=false,
    has_approval=false,
    has_missing_artifacts=true,
  )
  assert_eq(result.code, "Retryable")
}
