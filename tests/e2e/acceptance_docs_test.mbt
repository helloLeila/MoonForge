///|
/// 文件说明：校验验收矩阵与固定样例目录的最小文档闭环，确保 10 个 pre-commit 场景和 acc 用例都有落地。
/// 联动文件：直接读取 `docs/acceptance/matrix.md` 与 `examples/acceptance/*` 下的固定样例。

///|
/// 验收矩阵应明确列出 10 个研发侧常见的 AI coding 规则场景。
test "acceptance matrix covers ten precommit scenarios" {
  let matrix = @infra.read_text("docs/acceptance/matrix.md")
  let scenario_names = [
    "单文件合规通过", "双文件合规通过", "非法后缀拦截", "越权文件拦截",
    "受保护路径拦截", "改动文件数超限", "缺少预览材料需重试",
    "必需校验命令未通过需重试", "误提交生成产物或缓存文件拦截",
    "调试残留拦截",
  ]
  for name in scenario_names {
    assert_true(matrix.contains(name))
  }
  assert_true(matrix.contains("moonforge acc pass"))
  assert_true(matrix.contains("moonforge acc retry"))
  assert_true(matrix.contains("moonforge acc reject"))
}

///|
/// 固定验收样例目录应至少提供 pass/retry/reject 三类输入与期望输出。
test "acceptance fixture pack covers pass retry reject cases" {
  let required_paths = [
    "examples/acceptance/current.yml", "examples/acceptance/react-homepage-fixture/src/components/WorkLinks.jsx",
    "examples/acceptance/react-homepage-fixture/src/data/siteContent.js", "examples/acceptance/cases/pass/patch.diff",
    "examples/acceptance/cases/pass/preview-report.json", "examples/acceptance/cases/pass/expected/gate-result.json",
    "examples/acceptance/cases/retry/patch.diff", "examples/acceptance/cases/retry/expected/gate-result.json",
    "examples/acceptance/cases/reject/patch.diff", "examples/acceptance/cases/reject/preview-report.json",
    "examples/acceptance/cases/reject/expected/gate-result.json",
  ]
  for path in required_paths {
    assert_true(@infra.path_exists(path))
  }
}
