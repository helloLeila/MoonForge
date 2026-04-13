///|
/// 文件说明：覆盖文件类型检查器的最小行为，确保敏感文件名与非法后缀都能被识别。
/// 联动文件：对应 `src/checkers/file_type_checker.mbt`，并为 `src/checkers/gate.mbt` 的后续复用提供回归保护。

///|
/// 敏感文件名应优先于后缀规则被识别。
test "file type checker blocks env file" {
  let result = @checkers.check_file_types(
    [".mbt", ".md", ".json"],
    [".env"],
    [".env"],
  )

  assert_eq(result.forbidden_extension_files, [])
  assert_eq(result.sensitive_files, [".env"])
}

///|
/// 非敏感但后缀不在允许列表中的文件应落入非法后缀列表。
test "file type checker marks forbidden extension" {
  let result = @checkers.check_file_types(
    [".mbt", ".md", ".json"],
    [".env"],
    ["frontend/src/pages/UserList/index.tsx"],
  )

  assert_eq(result.forbidden_extension_files, [
    "frontend/src/pages/UserList/index.tsx",
  ])
  assert_eq(result.sensitive_files, [])
}
