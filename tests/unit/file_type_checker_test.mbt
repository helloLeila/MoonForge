///|
/// 文件说明：覆盖文件类型检查器的最小行为，确保非法后缀、黑名单文件名和生成产物都能被识别。
/// 联动文件：对应 `src/checkers/file_type_checker.mbt`，并为 `src/checkers/gate.mbt` 的后续复用提供回归保护。

///|
/// 黑名单文件名应优先于后缀规则被识别。
test "file type checker blocks env file name" {
  let result = @checkers.check_file_types(
    [".mbt", ".md", ".json"],
    [".lock"],
    [".env"],
    [],
    [],
    [".env"],
  )

  assert_eq(result.forbidden_extension_files, [])
  assert_eq(result.blocked_file_name_files, [".env"])
  assert_eq(result.generated_artifact_files, [])
}

///|
/// 非法后缀文件应落入 forbidden_extension 列表。
test "file type checker marks forbidden extension" {
  let result = @checkers.check_file_types(
    [".mbt", ".md", ".json"],
    [".lock"],
    [],
    [],
    [],
    ["frontend/src/pages/UserList/index.tsx"],
  )

  assert_eq(result.forbidden_extension_files, [
    "frontend/src/pages/UserList/index.tsx",
  ])
  assert_eq(result.blocked_file_name_files, [])
}

///|
/// 生成产物路径应单独命中 generated_artifact 列表，而不是普通后缀错误。
test "file type checker marks generated artifact path" {
  let result = @checkers.check_file_types(
    [".js", ".jsx"],
    [".map"],
    [],
    [],
    ["dist/**", ".next/**"],
    ["dist/assets/index.js"],
  )

  assert_eq(result.generated_artifact_files, ["dist/assets/index.js"])
  assert_eq(result.forbidden_extension_files, [])
}

///|
/// 黑名单路径模式应在后缀之前被拦截。
test "file type checker marks blocked path pattern" {
  let result = @checkers.check_file_types(
    [".js", ".jsx"],
    [],
    [],
    ["coverage/**"],
    [],
    ["coverage/index.html"],
  )

  assert_eq(result.blocked_file_pattern_files, ["coverage/index.html"])
  assert_eq(result.forbidden_extension_files, [])
}
