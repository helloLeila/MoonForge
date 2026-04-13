///|
/// 文件说明：定义违规项、检查结果以及最终文件输出结构，负责承载门禁执行结果。
/// 联动文件：被 `src/checkers/gate.mbt` 填充，也被 `src/services/commands.mbt` 序列化为报告与文件。

///|
/// 一条结构化违规项，同时保存问题编码、文件位置、问题详情和修复建议。
pub(all) struct Violation {
  code : String
  file : String?
  detail : String
  suggestion : String
} derive(Debug, ToJson)

///|
/// 面向外部展示的违规项视图，同时保留代码、中文说明、英文说明和中文处置建议。
pub(all) struct ViolationView {
  code : String
  text_zh : String
  text_en : String
  action_zh : String
} derive(Debug)

///|
/// 根据领域违规项生成对外展示视图，并把稳定文案集中到一个转换入口。
/// 入参：`violation`，表示门禁引擎产生的一条结构化违规项。
/// 出参：`ViolationView`，用于上层报告与测试读取中英文展示字段。
pub fn ViolationView::from_violation(violation : Violation) -> ViolationView {
  ViolationView::{
    code: violation.code,
    text_zh: violation.detail,
    text_en: violation_code_text_en(violation.code),
    action_zh: violation.suggestion,
  }
}

///|
/// 根据违规码返回对外展示的英文说明，作为转换入口中的唯一英文来源。
/// 入参：`code`，表示结构化违规项的编码。
/// 出参：与编码对应的英文说明，未知编码则原样返回编码本身。
fn violation_code_text_en(code : String) -> String {
  match code {
    "PATH_OUT_OF_SCOPE" => "path out of scope"
    "PROTECTED_PATH_TOUCHED" => "protected path touched"
    "FORBIDDEN_EXTENSION" => "forbidden extension"
    "CHANGED_FILE_COUNT_EXCEEDED" => "changed file count exceeded"
    "MISSING_ARTIFACT" => "missing artifact"
    "MANUAL_APPROVAL_REQUIRED" => "manual approval required"
    _ => code
  }
}

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
} derive(Debug)

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
} derive(Debug, ToJson)

///|
/// 材料完整性检查结果文件的输出结构。
pub(all) struct ArtifactResultFile {
  required_artifacts : Array[String]
  provided_artifacts : Array[String]
  missing_artifacts : Array[String]
} derive(Debug, ToJson)

///|
/// 最终门禁结论文件的输出结构。
pub(all) struct GateResultFile {
  run_id : String
  decision : String
  decision_summary : String
  violations : Array[Violation]
  next_action : String
} derive(Debug, ToJson)

///|
/// 事件日志中的单条记录结构。
pub(all) struct EventEntry {
  time_ns : UInt64
  event : String
  detail : String
} derive(Debug, ToJson)
