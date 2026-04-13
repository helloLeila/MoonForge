///|
/// 文件说明：验证领域层的双语结论视图与违规项视图是否对外提供稳定字段。
/// 联动文件：这些测试会直接覆盖 `src/domain/types.mbt` 拆分后的领域类型导出结果。

///|
/// 验证正式结论可以暴露给上层消费的中英文字段，并保持代码名稳定。
test "decision label exposes bilingual fields" {
  let decision = @domain.DecisionView::from_decision(@domain.Reject)
  assert_eq(decision.code, "Reject")
  assert_eq(decision.text_zh, "拒绝放行")
}

///|
/// 验证违规项视图会同时保留编码、中文说明、英文说明与中文处置建议。
test "violation view keeps code and chinese action" {
  let violation = @domain.ViolationView::{
    code: "PATH_OUT_OF_SCOPE",
    text_zh: "超出任务允许范围",
    text_en: "path out of scope",
    action_zh: "缩小改动范围后重试",
  }
  assert_eq(violation.action_zh, "缩小改动范围后重试")
}
