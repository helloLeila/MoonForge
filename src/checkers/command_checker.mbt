///|
/// 文件说明：执行任务模板要求的必需校验命令，并把失败命令汇总为可重试问题。
/// 联动文件：由 `src/checkers/gate.mbt` 调用，底层依赖 `src/infra/process_runner.mbt`。

///|
/// 必需命令检查结果，只记录失败的命令文本。
pub(all) struct CommandCheckResult {
  failed_commands : Array[String]
} derive(Debug)

///|
/// 依次执行任务模板声明的必需命令，失败命令会被保留下来。
pub fn check_required_commands(
  commands : Array[String],
  cwd : String,
) -> CommandCheckResult raise {
  let failed_commands : Array[String] = []
  for command in commands {
    let trimmed = command.trim().to_string()
    if trimmed == "" {
      continue
    }
    if @infra.run_shell_command(trimmed, cwd) != 0 {
      failed_commands.push(trimmed)
    }
  }
  CommandCheckResult::{ failed_commands, }
}
