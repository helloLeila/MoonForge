///|
/// 文件说明：覆盖材料检查器的最小行为，确保缺失材料、JSON 字段缺失和 Markdown 无正文都能被识别。
/// 联动文件：对应 `src/checkers/artifact_checker.mbt`，并为 `src/checkers/gate.mbt` 的后续复用提供回归保护。

///|
/// 材料检查器应识别缺失的必需材料文件。
test "artifact checker reports missing file" {
  let result = @checkers.check_artifacts(["test-report.json"], {}, {})
  assert_eq(result.missing_artifacts, ["test-report.json"])
  assert_eq(result.invalid_artifacts, [])
}

///|
/// 提供所有材料且命中 schema 必填字段时不产生缺失或无效报告。
test "artifact checker passes when json fields satisfied" {
  let provided : Map[String, String] = {}
  let required_fields : Map[String, Array[String]] = {}
  provided["test-report.json"] = "{\"passed\":true,\"suite\":\"demo\"}"
  required_fields["test-report.json"] = ["passed", "suite"]
  let result = @checkers.check_artifacts(
    ["test-report.json"],
    provided,
    required_fields,
  )
  assert_eq(result.missing_artifacts, [])
  assert_eq(result.invalid_artifacts, [])
}

///|
/// JSON 材料缺少必填字段时应进入 invalid_artifacts。
test "artifact checker rejects json missing required field" {
  let provided : Map[String, String] = {}
  let required_fields : Map[String, Array[String]] = {}
  provided["preview-report.json"] = "{\"section\":\"hero\"}"
  required_fields["preview-report.json"] = ["section", "status", "summary"]
  let result = @checkers.check_artifacts(
    ["preview-report.json"],
    provided,
    required_fields,
  )
  assert_eq(result.missing_artifacts, [])
  assert_eq(result.invalid_artifacts, ["preview-report.json"])
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
