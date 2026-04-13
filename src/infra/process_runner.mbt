///|
/// 文件说明：封装最小同步命令执行能力，主要供提交前规则中的必需校验命令检查复用。
/// 联动文件：由 `src/checkers/command_checker.mbt` 调用，依赖 libuv 的进程能力执行 shell 命令。

///|
/// 在指定工作目录中执行 shell 命令，并返回退出码。
pub fn run_shell_command(command : String, cwd : String) -> Int raise {
  let uv = @uv.Loop::new()
  let mut exit_status = 0
  try {
    let options = @uv.ProcessOptions::new(
      @utf8.encode("/bin/sh"),
      [@utf8.encode("/bin/sh"), @utf8.encode("-lc"), @utf8.encode(command)],
      cwd=@utf8.encode(cwd),
      stdio=[
        @uv.StdioContainer::ignore(),
        @uv.StdioContainer::ignore(),
        @uv.StdioContainer::ignore(),
      ],
      fn(process, status, _) {
        exit_status = status.to_int()
        process.close(() => ())
      },
    )
    ignore(uv.spawn(options))
    uv.run(Default)
    uv.close()
    exit_status
  } catch {
    err => {
      let _ = try? uv.close()
      raise err
    }
  }
}
