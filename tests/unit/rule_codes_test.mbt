///|
/// 文件说明：验证领域层的双语结论视图与违规项视图是否对外提供稳定字段。
/// 联动文件：这些测试会直接覆盖 `src/domain/rule_codes.mbt` 与 `src/domain/result_types.mbt` 的对外导出结果。

///|
/// 验证正式结论的标签、中文摘要、英文摘要和处置建议都来自同一个映射源。
test "decision view exposes accept branch in bilingual fields" {
  let decision = @domain.DecisionView::from_decision(@domain.Accept)
  assert_eq(decision.code, "Accept")
  assert_eq(decision.text_zh, "允许放行")
  assert_eq(decision.text_en, "accept")
  assert_eq(decision.action_zh, "可进入下一阶段")
  assert_eq(@domain.Accept.label(), "Accept")
  assert_eq(@domain.Accept.summary(), "允许放行")
  assert_eq(@domain.Accept.next_action(), "可进入下一阶段")
}

///|
/// 验证另一条决策分支也会通过同一映射源输出一致结果。
test "decision view exposes retryable branch in bilingual fields" {
  let decision = @domain.DecisionView::from_decision(@domain.Retryable)
  assert_eq(decision.code, "Retryable")
  assert_eq(decision.text_en, "retryable")
  assert_eq(decision.action_zh, "补齐材料后重新执行检查")
  assert_eq(@domain.Retryable.label(), "Retryable")
  assert_eq(@domain.Retryable.summary(), "补齐后重试")
  assert_eq(@domain.Retryable.next_action(), "补齐材料后重新执行检查")
}

///|
/// 验证拒绝放行分支也会通过同一映射源输出一致结果。
test "decision view exposes reject branch in bilingual fields" {
  let decision = @domain.DecisionView::from_decision(@domain.Reject)
  assert_eq(decision.code, "Reject")
  assert_eq(decision.text_zh, "拒绝放行")
  assert_eq(decision.text_en, "reject")
  assert_eq(decision.action_zh, "撤回越界修改或缩小变更范围后重新提交")
  assert_eq(@domain.Reject.label(), "Reject")
  assert_eq(@domain.Reject.summary(), "拒绝放行")
  assert_eq(@domain.Reject.next_action(), "撤回越界修改或缩小变更范围后重新提交")
}

///|
/// 验证需要人工审批分支也会通过同一映射源输出一致结果。
test "decision view exposes human approval branch in bilingual fields" {
  let decision = @domain.DecisionView::from_decision(@domain.NeedHumanApproval)
  assert_eq(decision.code, "NeedHumanApproval")
  assert_eq(decision.text_zh, "需要人工审批")
  assert_eq(decision.text_en, "need human approval")
  assert_eq(decision.action_zh, "转人工审批或拆分高风险修改")
  assert_eq(@domain.NeedHumanApproval.label(), "NeedHumanApproval")
  assert_eq(@domain.NeedHumanApproval.summary(), "需要人工审批")
  assert_eq(
    @domain.NeedHumanApproval.next_action(),
    "转人工审批或拆分高风险修改",
  )
}

///|
/// 验证违规项可以从领域模型转换为对外视图，并保留中文处置建议。
test "violation view converts from violation domain object" {
  let violation = @domain.Violation::{
    code: "PATH_OUT_OF_SCOPE",
    file: Some("frontend/src/pages/Home/index.tsx"),
    detail: "超出任务允许范围",
    suggestion: "缩小改动范围后重试",
  }
  let view = @domain.ViolationView::from_violation(violation)
  assert_eq(view.code, "PATH_OUT_OF_SCOPE")
  assert_eq(view.text_zh, "超出任务允许范围")
  assert_eq(view.text_en, "path out of scope")
  assert_eq(view.action_zh, "缩小改动范围后重试")
}
