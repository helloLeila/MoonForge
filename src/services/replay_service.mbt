///|
/// 文件说明：实现 replay 命令的独立服务层，负责从快照目录重放历史检查结果。

///|
/// 检查指定运行 ID 的快照目录是否存在。
/// 入参：`repo_root`，仓库根目录路径。
/// 入参：`run_id`，需要重放的运行标识符。
/// 出参：快照目录存在时返回 `true`，否则返回 `false`。
pub fn snapshot_exists(repo_root : String, run_id : String) -> Bool raise {
  let snapshot_dir = @adapters.snapshot_dir(repo_root, run_id)
  @infra.path_exists(snapshot_dir)
}

///|
/// 从快照目录读取任务快照文件内容。
/// 入参：`repo_root`，仓库根目录路径。
/// 入参：`run_id`，需要重放的运行标识符。
/// 出参：task.snapshot.json 的原始文本内容，文件不存在时返回 `None`。
pub fn read_task_snapshot(repo_root : String, run_id : String) -> String? raise {
  let path = @infra.join_path(
    @adapters.snapshot_dir(repo_root, run_id),
    "task.snapshot.json",
  )
  @infra.read_text_if_exists(path)
}

///|
/// 从任务快照 JSON 文本里提取任务类型字段，解析失败时回落为 Unknown。
pub fn extract_task_type(snapshot_text : String) -> String {
  if snapshot_text.contains("\"task_type\"") {
    let lines = snapshot_text
      .split("\n")
      .map(line => line.trim().to_string())
      .collect()
    for line in lines {
      if line.has_prefix("\"task_type\"") {
        let parts = line
          .split(":")
          .map(item => item.trim().to_string())
          .collect()
        if parts.length() >= 2 {
          return parts[1]
            .trim_start(chars="\"")
            .trim_end(chars="\",")
            .to_string()
        }
      }
    }
  }
  "Unknown"
}

///|
/// 生成 replay 命令的终端输出摘要文本。
/// 入参：`run_id`，重放的运行标识符。
/// 入参：`task_type`，快照中记录的任务类型。
/// 入参：`context_summary`，运行来源摘要，可能为空。
/// 出参：终端可打印的重放摘要文本。
pub fn render_replay_summary(
  run_id : String,
  task_type : String,
  decision_label : String,
  context_summary : String,
  metrics_summary : String,
) -> String {
  let details : Array[String] = ["任务类型：\{task_type}", "结论：\{decision_label}"]
  if context_summary.trim() != "" {
    details.push("来源：\{context_summary}")
  }
  if metrics_summary.trim() != "" {
    details.push("统计：\{metrics_summary}")
  }
  let detail_text = details.join("，")
  "🔁 重放历史检查：\{run_id}（\{detail_text}）"
}

///|
/// 当指定运行 ID 的快照不存在时，生成错误提示文本。
/// 入参：`run_id`，用户请求重放的运行标识符。
/// 出参：提示快照不存在的中文错误文本。
pub fn render_snapshot_not_found(run_id : String) -> String {
  "❌ 快照不存在：\{run_id}，请检查运行 ID 是否正确。"
}

///|
/// 列出所有可用的快照运行 ID，供用户选择重放目标。
/// 入参：`repo_root`，仓库根目录路径。
/// 出参：快照目录下所有子目录名称的数组，每个名称对应一个运行 ID。
pub fn list_available_snapshots(repo_root : String) -> Array[String] raise {
  let snapshots_dir = @infra.join_path(repo_root, ".moonforge/runs")
  if !@infra.path_exists(snapshots_dir) {
    return []
  }
  @infra.list_dir(snapshots_dir)
}
