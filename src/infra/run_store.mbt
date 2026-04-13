///|
/// 文件说明：提供门禁运行结果的磁盘持久化能力，负责写出所有结构化结果物到标准目录。

///|
/// 将检查结果的覆盖文件列表写成纯文本，每行一个文件路径。
/// 入参：`path`，目标文件路径。
/// 入参：`files`，已检查的文件路径数组。
pub fn write_checked_files(path : String, files : Array[String]) -> Unit raise {
  write_text(path, files.join("\n") + "\n")
}

///|
/// 将已序列化的事件行数组写入审计日志文件，每行一条 JSON 记录。
/// 入参：`path`，目标文件路径。
/// 入参：`lines`，已序列化为 JSON 字符串的事件行数组。
pub fn write_jsonl(path : String, lines : Array[String]) -> Unit raise {
  write_text(path, lines.join("\n") + "\n")
}

///|
/// 将任意可序列化对象以格式化 JSON 写入文件。
/// 入参：`path`，目标文件路径。
/// 入参：`value`，实现了 ToJson 接口的对象。
pub fn[T : ToJson] write_json_artifact(path : String, value : T) -> Unit raise {
  write_text(path, value.to_json().stringify(indent=2) + "\n")
}

///|
/// 返回当前运行的输出目录路径，格式为 `.moonforge/out/{mode}/latest`。
/// 入参：`repo_root`，仓库根目录路径。
/// 入参：`mode`，运行模式，可为 `"local"`、`"ci"` 或 `"pr"`。
/// 出参：最新运行结果目录路径。
pub fn latest_run_dir(repo_root : String, mode : String) -> String {
  join_path(repo_root, ".moonforge/out/\{mode}/latest")
}

///|
/// 返回指定运行快照的目录路径，格式为 `.moonforge/runs/{run_id}`。
/// 入参：`repo_root`，仓库根目录路径。
/// 入参：`run_id`，本次运行的唯一标识符。
/// 出参：快照目录路径。
pub fn snapshot_run_dir(repo_root : String, run_id : String) -> String {
  join_path(repo_root, ".moonforge/runs/\{run_id}")
}

///|
/// 确保 latest 输出目录存在，并返回其路径。
/// 入参：`repo_root`，仓库根目录路径。
/// 入参：`mode`，运行模式。
/// 出参：已创建的 latest 目录路径。
pub fn ensure_latest_dir(repo_root : String, mode : String) -> String raise {
  let dir = latest_run_dir(repo_root, mode)
  ensure_dir(dir)
  dir
}

///|
/// 读取最近一次运行的 gate-result.json 文件内容。
/// 入参：`repo_root`，仓库根目录路径。
/// 入参：`mode`，运行模式。
/// 出参：JSON 文件的原始文本内容，文件不存在时返回 None。
pub fn read_latest_gate_result(
  repo_root : String,
  mode : String,
) -> String? raise {
  let path = join_path(latest_run_dir(repo_root, mode), "gate-result.json")
  read_text_if_exists(path)
}

///|
/// 读取最近一次运行的 `scope-result.json` 文件内容。
pub fn read_latest_scope_result(
  repo_root : String,
  mode : String,
) -> String? raise {
  let path = join_path(latest_run_dir(repo_root, mode), "scope-result.json")
  read_text_if_exists(path)
}

///|
/// 读取最近一次运行的 `artifact-result.json` 文件内容。
pub fn read_latest_artifact_result(
  repo_root : String,
  mode : String,
) -> String? raise {
  let path = join_path(latest_run_dir(repo_root, mode), "artifact-result.json")
  read_text_if_exists(path)
}

///|
/// 读取最近一次运行的 `run-context.json` 文件内容。
pub fn read_latest_run_context(
  repo_root : String,
  mode : String,
) -> String? raise {
  let path = join_path(latest_run_dir(repo_root, mode), "run-context.json")
  read_text_if_exists(path)
}

///|
/// 读取指定运行快照中的 `gate.snapshot.json`。
pub fn read_snapshot_gate_result(
  repo_root : String,
  run_id : String,
) -> String? raise {
  let path = join_path(snapshot_run_dir(repo_root, run_id), "gate.snapshot.json")
  read_text_if_exists(path)
}

///|
/// 读取指定运行快照中的 `scope.snapshot.json`。
pub fn read_snapshot_scope_result(
  repo_root : String,
  run_id : String,
) -> String? raise {
  let path = join_path(snapshot_run_dir(repo_root, run_id), "scope.snapshot.json")
  read_text_if_exists(path)
}

///|
/// 读取指定运行快照中的 `artifact.snapshot.json`。
pub fn read_snapshot_artifact_result(
  repo_root : String,
  run_id : String,
) -> String? raise {
  let path = join_path(
    snapshot_run_dir(repo_root, run_id),
    "artifact.snapshot.json",
  )
  read_text_if_exists(path)
}

///|
/// 读取指定运行快照中的 `run-context.snapshot.json`。
pub fn read_snapshot_run_context(
  repo_root : String,
  run_id : String,
) -> String? raise {
  let path = join_path(snapshot_run_dir(repo_root, run_id), "run-context.snapshot.json")
  read_text_if_exists(path)
}
