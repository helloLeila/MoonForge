///|
/// 文件说明：定义门禁系统的核心领域对象，包括任务模板、仓库规则、违规项和最终检查结果。
/// 联动文件：被 `src/checkers/gate.mbt` 用于构建判定结果，也被 `src/services/commands.mbt` 用于序列化输出和报告生成。

///|

///|
/// 门禁最终决策类型，对应计划书里的四种正式结论。
pub(all) enum Decision {
  Accept
  Retryable
  Reject
  NeedHumanApproval
} derive(Eq, Show)

///|
/// 返回给机器处理的英文标签，用于 JSON 和命令行摘要。
pub fn Decision::label(self : Decision) -> String {
  match self {
    Accept => "Accept"
    Retryable => "Retryable"
    Reject => "Reject"
    NeedHumanApproval => "NeedHumanApproval"
  }
}

///|
/// 返回给研发人员阅读的中文结论摘要。
pub fn Decision::summary(self : Decision) -> String {
  match self {
    Accept => "允许放行"
    Retryable => "补齐后重试"
    Reject => "拒绝放行"
    NeedHumanApproval => "需要人工审批"
  }
}

///|
/// 根据门禁结论给出下一步处理动作。
pub fn Decision::next_action(self : Decision) -> String {
  match self {
    Accept => "可进入下一阶段"
    Retryable => "补齐材料后重新执行检查"
    Reject => "撤回越界修改或缩小变更范围后重新提交"
    NeedHumanApproval => "转人工审批或拆分高风险修改"
  }
}

///|
/// 仓库级长期规则，负责表达受保护目录和全局允许后缀。
pub(all) struct RepoRules {
  protected_paths : Array[String]
  approval_required_paths : Array[String]
  default_allowed_extensions : Array[String]
} derive(Show)

///|
/// 任务模板规则，负责限定某类任务的默认边界。
pub(all) struct TaskTemplate {
  task_type : String
  allowed_paths : Array[String]
  forbidden_paths : Array[String]
  allowed_extensions : Array[String]
  required_artifacts : Array[String]
  max_changed_files : Int
  manual_approval_paths : Array[String]
} derive(Show)

///|
/// 当前任务文件对应的运行时对象。
pub(all) struct CurrentTask {
  task_type : String
  title : String
  target_paths : Array[String]
} derive(Show, ToJson)

///|
/// 仓库规则、模板规则与当前任务合并后的生效约束。
pub(all) struct EffectiveTask {
  task_type : String
  title : String
  allowed_paths : Array[String]
  forbidden_paths : Array[String]
  approval_required_paths : Array[String]
  allowed_extensions : Array[String]
  required_artifacts : Array[String]
  max_changed_files : Int
} derive(Show, ToJson)

///|
/// 一条结构化违规项，同时保存问题编码和修复建议。
pub(all) struct Violation {
  code : String
  file : String?
  detail : String
  suggestion : String
} derive(Show, ToJson)

///|
/// 一次完整门禁检查的内存结果对象。
pub(all) struct CheckResult {
  run_id : String
  decision : Decision
  violations : Array[Violation]
  checked_files : Array[String]
  out_of_scope_files : Array[String]
  protected_files : Array[String]
  approval_required_files : Array[String]
  forbidden_extension_files : Array[String]
  missing_artifacts : Array[String]
  provided_artifacts : Array[String]
  effective_task : EffectiveTask
  changed_file_count : Int
  changed_file_count_exceeded : Bool
} derive(Show)

///|
/// 变更范围检查结果文件的输出结构。
pub(all) struct ScopeResultFile {
  checked_files : Array[String]
  out_of_scope_files : Array[String]
  protected_files : Array[String]
  approval_required_files : Array[String]
  forbidden_extension_files : Array[String]
  changed_file_count : Int
  max_changed_files : Int
} derive(Show, ToJson)

///|
/// 材料完整性检查结果文件的输出结构。
pub(all) struct ArtifactResultFile {
  required_artifacts : Array[String]
  provided_artifacts : Array[String]
  missing_artifacts : Array[String]
} derive(Show, ToJson)

///|
/// 最终门禁结论文件的输出结构。
pub(all) struct GateResultFile {
  run_id : String
  decision : String
  decision_summary : String
  violations : Array[Violation]
  next_action : String
} derive(Show, ToJson)

///|
/// 事件日志中的单条记录结构。
pub(all) struct EventEntry {
  time_ns : UInt64
  event : String
  detail : String
} derive(Show, ToJson)
