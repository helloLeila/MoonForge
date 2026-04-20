///|
/// 文件说明：封装本地模式、CI 模式与 PR 模式下的输出目录、快照目录和运行编号规则，隔离运行环境差异。
/// File: Encapsulates output directories, snapshot directories, and run-id rules
/// for local, CI, and PR modes.

///|

///|
/// 根据命令行入参统一收敛运行模式，避免业务层重复判断字符串。
/// Normalizes the CLI mode so service code does not repeat string branching.
pub fn normalize_mode(mode : String) -> String {
  let trimmed = mode.trim().to_string()
  if trimmed == "pr" {
    "pr"
  } else if trimmed == "ci" {
    "ci"
  } else {
    "local"
  }
}

///|
/// 根据显式参数和当前环境推断真正要使用的运行模式。
/// 规则顺序很简单：
/// 1. 用户明确传了 `ci` / `pr` / `local` 时，直接尊重用户输入
/// 2. 用户没传或传了 `auto` 时，如果在 GitHub Actions 里，自动判断是 `ci` 还是 `pr`
/// 3. 其余情况回退到调用方给的默认模式，默认再回退到 `local`
pub fn resolve_mode(
  requested_mode : String,
  env : Map[String, String],
  fallback_mode? : String = "local",
) -> String {
  let trimmed = requested_mode.trim().to_string()
  if trimmed != "" && trimmed != "auto" {
    return normalize_mode(trimmed)
  }
  if is_github_actions_env(env) {
    let has_base_ref = match github_base_ref(env) {
      Some(value) => value.trim() != ""
      None => false
    }
    let has_head_ref = match github_head_ref(env) {
      Some(value) => value.trim() != ""
      None => false
    }
    if is_pull_request_event(env) && has_base_ref && has_head_ref {
      "pr"
    } else {
      "ci"
    }
  } else {
    normalize_mode(fallback_mode)
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
