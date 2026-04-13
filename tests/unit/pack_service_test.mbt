///|
/// 文件说明：覆盖 pack 命令服务的单元行为，确保打包逻辑能正确收集文件并生成压缩包路径。
/// 联动文件：测试 `src/services/pack_service.mbt` 的公开函数。

///|
/// 应能从运行目录中识别所有需要打包的结果文件。
test "collect_pack_files identifies all result files" {
  let files = @services.collect_pack_files([
    "scope-result.json",
    "artifact-result.json",
    "gate-result.json",
    "gate-report.md",
    "checked-files.txt",
    "events.jsonl",
  ])
  assert_eq(files.length(), 6)
  assert_true(files.contains("scope-result.json"))
  assert_true(files.contains("gate-report.md"))
}

///|
/// 应能生成符合规范的打包文件名，格式为 `moonforge-{run_id}.tar.gz`。
test "generate_pack_filename produces correct format" {
  let filename = @services.generate_pack_filename("check-1744512345678901234")
  assert_eq(filename, "moonforge-check-1744512345678901234.tar.gz")
}

///|
/// 应能渲染打包成功的终端提示文本。
test "render_pack_success shows archive path" {
  let message = @services.render_pack_success(
    "/tmp/moonforge-check-123.tar.gz",
    6,
  )
  assert_true(message.contains("moonforge-check-123.tar.gz"))
  assert_true(message.contains("6"))
}

///|
/// 应能渲染打包失败的错误提示文本。
test "render_pack_failure shows error reason" {
  let message = @services.render_pack_failure("文件不存在")
  assert_true(message.contains("打包失败"))
  assert_true(message.contains("文件不存在"))
}
