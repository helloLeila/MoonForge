///|
/// 文件说明：提供本地执行面的差异读取入口，当前从运行目录中的标准补丁文件读取变更文本。
/// 联动文件：由 `src/services/commands.mbt` 在 `local` 模式下调用；后续可替换为真实 staged diff 来源而不改业务层。

///|
/// 从本地运行目录读取标准 patch 文件内容。
pub fn read_local_diff(run_dir : String) -> String raise {
  @infra.read_text(@infra.join_path(run_dir, "patch.diff"))
}
