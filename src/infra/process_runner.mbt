///|
/// 文件说明：封装最小同步命令执行能力，主要供提交前规则中的必需校验命令检查复用。
/// 联动文件：由 `src/checkers/command_checker.mbt` 调用，依赖 libuv 的进程能力执行 shell 命令。

///|
/// 对 shell 参数做最小单引号转义，避免路径中出现空格或特殊字符时命令拼接错误。
pub fn shell_quote(value : String) -> String {
  "'" + value.replace(old="'", new="'\"'\"'") + "'"
}

///|
/// 在指定工作目录中执行 shell 命令，并把 stdout、stderr 和退出码全部保留下来。
/// 这里通过临时文件承接输出，避免上层只能得到一个退出码。
pub fn run_shell_capture(
  command : String,
  cwd : String,
) -> @domain.ProcessCapture raise {
  let stdout_path = join_path(
    "/tmp",
    unique_temp_name("moonforge-stdout") + ".log",
  )
  let stderr_path = join_path(
    "/tmp",
    unique_temp_name("moonforge-stderr") + ".log",
  )
  let wrapped_command = "{ \{command}; } > \{shell_quote(stdout_path)} 2> \{shell_quote(stderr_path)}"
  let exit_code = run_shell_command(wrapped_command, cwd)
  let stdout = match read_text_if_exists(stdout_path) {
    Some(content) => content
    None => ""
  }
  let stderr = match read_text_if_exists(stderr_path) {
    Some(content) => content
    None => ""
  }
  remove_file_if_exists(stdout_path)
  remove_file_if_exists(stderr_path)
  @domain.ProcessCapture::{ command, cwd, exit_code, stdout, stderr }
}

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
