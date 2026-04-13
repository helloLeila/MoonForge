///|
/// 文件说明：定义门禁决策码、双语结论视图以及与决策码相关的文本映射。
/// 联动文件：被 `src/services/commands.mbt` 和 `src/checkers/gate.mbt` 间接消费，用于输出最终结论与摘要。

///|
/// 门禁最终决策类型，对应计划书里的四种正式结论。
pub(all) enum Decision {
  Accept
  Retryable
  Reject
  NeedHumanApproval
} derive(Eq, Debug)

///|
/// 面向外部展示的决策视图，同时保留稳定代码名和中英文描述。
pub(all) struct DecisionView {
  code : String
  text_zh : String
  text_en : String
} derive(Debug)

///|
/// 根据内部决策枚举生成对外展示的双语视图。
/// 入参：`decision`，表示门禁引擎算出的正式结论。
/// 出参：`DecisionView`，用于上层命令、测试或报告层读取稳定字段。
pub fn DecisionView::from_decision(decision : Decision) -> DecisionView {
  match decision {
    Accept => { code: "Accept", text_zh: "允许放行", text_en: "accept" }
    Retryable => {
      code: "Retryable", text_zh: "补齐后重试", text_en: "retryable"
    }
    Reject => { code: "Reject", text_zh: "拒绝放行", text_en: "reject" }
    NeedHumanApproval => {
      code: "NeedHumanApproval", text_zh: "需要人工审批", text_en: "need human approval"
    }
  }
}

///|
/// 返回给机器处理的英文标签，用于 JSON 和命令行摘要。
/// 入参：当前决策枚举值。
/// 出参：稳定的英文代码字符串。
pub fn Decision::label(self : Decision) -> String {
  DecisionView::from_decision(self).code
}

///|
/// 返回给研发人员阅读的中文结论摘要。
/// 入参：当前决策枚举值。
/// 出参：对应的中文结论字符串。
pub fn Decision::summary(self : Decision) -> String {
  DecisionView::from_decision(self).text_zh
}

///|
/// 根据门禁结论给出下一步处理动作。
/// 入参：当前决策枚举值。
/// 出参：对应的中文处置建议字符串。
pub fn Decision::next_action(self : Decision) -> String {
  match self {
    Accept => "可进入下一阶段"
    Retryable => "补齐材料后重新执行检查"
    Reject => "撤回越界修改或缩小变更范围后重新提交"
    NeedHumanApproval => "转人工审批或拆分高风险修改"
  }
}
