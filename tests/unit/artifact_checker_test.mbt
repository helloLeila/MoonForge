///|
/// 文件说明：覆盖材料检查器的最小行为，确保缺失材料和无效 Markdown 都能被识别。
/// 联动文件：对应 `src/checkers/artifact_checker.mbt`，并为 `src/checkers/gate.mbt` 的后续复用提供回归保护。

///|
/// 材料检查器应识别缺失的必需材料文件。
test "artifact checker reports missing file" {
  let result = @checkers.check_artifacts(["test-report.json"], {})
  assert_eq(result.missing_artifacts, ["test-report.json"])
  assert_eq(result.invalid_artifacts, [])
}

///|
/// 提供所有材料时不产生缺失报告。
test "artifact checker passes when all provided" {
  let provided : Map[String, String] = {}
  provided["test-report.json"] = "{\"passed\":true}"
  let result = @checkers.check_artifacts(["test-report.json"], provided)
  assert_eq(result.missing_artifacts, [])
}

///|
/// 只有标题的 Markdown 应被识别为无效材料。
test "artifact checker rejects empty markdown body" {
  let result = @checkers.validate_markdown_artifact("# API\n")
  assert_true(result is Err(_))
}

///|
/// 包含正文段落的 Markdown 应通过校验。
test "artifact checker accepts markdown with body" {
  let result = @checkers.validate_markdown_artifact(
    "# API\n\n正文内容在此。\n",
  )
  assert_true(result is Ok(_))
}
