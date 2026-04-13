///|
/// 文件说明：定义一次门禁运行的来源上下文，记录本地暂存区、CI 复检或 PR 复检的输入线索。

///|
/// 持久化到 `run-context.json` 的运行上下文结构。
pub(all) struct RunContextFile {
  mode : String
  source_kind : String
  environment : String
  event_name : String?
  base_ref : String?
  head_ref : String?
  pr_number : String?
  diff_path : String
} derive(Debug, ToJson)
