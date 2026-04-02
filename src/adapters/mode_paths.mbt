///|
/// 根据命令行入参统一收敛运行模式，避免业务层重复判断字符串。
pub fn normalize_mode(mode : String) -> String {
  let trimmed = mode.trim().to_string()
  if trimmed == "ci" {
    "ci"
  } else {
    "local"
  }
}

///|
/// 返回某种运行模式下最近一次输出目录的位置。
pub fn latest_output_dir(repo_root : String, mode : String) -> String {
  @infra.join_path(repo_root, ".moonforge/out/\{normalize_mode(mode)}/latest")
}

///|
/// 返回某次门禁检查的快照归档目录。
pub fn snapshot_dir(repo_root : String, run_id : String) -> String {
  @infra.join_path(repo_root, ".moonforge/runs/\{run_id}")
}

///|
/// 根据材料目录名称生成稳定的运行编号。
pub fn run_id_from_run_dir(run_dir : String) -> String {
  "run-\{@infra.basename(run_dir)}"
}
