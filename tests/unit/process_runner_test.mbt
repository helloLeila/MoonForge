///|
/// 文件说明：覆盖进程执行基础设施的关键行为，确保 shell 命令不仅能拿到退出码，还能拿到标准输出和标准错误。
/// 联动文件：对应 `src/infra/process_runner.mbt`，后续 git 上下文、自动补全、自动检查都会依赖这层。

///|
/// `run_shell_capture` 应保留 stdout、stderr 和退出码，避免上层只能拿到一个整数。
test "process runner captures stdout stderr and exit code" {
  let result = @infra.run_shell_capture(
    "printf 'hello'; printf 'world' >&2; exit 7", ".",
  )

  assert_eq(result.exit_code, 7)
  assert_eq(result.stdout, "hello")
  assert_eq(result.stderr, "world")
}
