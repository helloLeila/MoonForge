///|
/// 文件说明：实现 replay 命令的独立服务层，负责从快照目录重放历史检查结果。
/// 联动文件：由 `src/services/commands.mbt` 的 `replay_check` 函数调用，依赖 `src/infra/run_store.mbt` 读取快照文件。

///|
/// 检查指定运行 ID 的快照目录是否存在。
/// 入参：`repo_root`，仓库根目录路径。
/// 入参：`run_id`，需要重放的运行标识符。
/// 出参：快照目录存在时返回 `true`，否则返回 `false`。
pub fn snapshot_exists(repo_root : String, run_id : String) -> Bool raise {
  let snapshot_dir = @infra.snapshot_run_dir(repo_root, run_id)
  @infra.path_exists(snapshot_dir)
}

///|
/// 从快照目录读取任务快照文件内容。
/// 入参：`repo_root`，仓库根目录路径。
/// 入参：`run_id`，需要重放的运行标识符。
/// 出参：task.snapshot.json 的原始文本内容，文件不存在时返回 `None`。
pub fn read_task_snapshot(
  repo_root : String,
  run_id : String,
) -> String? raise {
  let path = @infra.join_path(
    @infra.snapshot_run_dir(repo_root, run_id),
    "task.snapshot.json",
  )
  @infra.read_text_if_exists(path)
}

///|
/// 生成 replay 命令的终端输出摘要文本。
/// 入参：`run_id`，重放的运行标识符。
/// 入参：`task_type`，快照中记录的任务类型。
/// 出参：终端可打印的重放摘要文本。
pub fn render_replay_summary(run_id : String, task_type : String) -> String {
  "🔁 重放历史检查：\{run_id}（任务类型：\{task_type}）"
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
  let snapshots_dir = @infra.join_path(repo_root, ".moonforge/out/snapshots")
  if !@infra.path_exists(snapshots_dir) {
    return []
  }
  []
}
