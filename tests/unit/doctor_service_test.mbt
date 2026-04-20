///|
/// 文件说明：覆盖 doctor 命令服务的单元行为，确保诊断逻辑能正确检测配置问题并生成诊断报告。
/// 联动文件：测试 `src/services/doctor_service.mbt` 的公开函数。

///|
/// 应能检测缺失的必需配置文件。
test "diagnose_missing_files detects absent config" {
  let issues = @services.diagnose_missing_files([
    ("/path/to/repo-rules.yml", false),
    ("/path/to/current-task.yml", true),
  ])
  assert_eq(issues.length(), 1)
  assert_true(issues[0].contains("repo-rules.yml"))
}

///|
/// 应能检测空的配置文件。
test "diagnose_empty_files detects zero-length config" {
  let issues = @services.diagnose_empty_files([
    ("/path/to/repo-rules.yml", "protected_paths:\n  - \"backend/**\"\n"),
    ("/path/to/current-task.yml", ""),
  ])
  assert_eq(issues.length(), 1)
  assert_true(issues[0].contains("current-task.yml"))
}

///|
/// 应能检测缺少必需字段的配置文件。
test "diagnose_required_fields detects missing keys" {
  let issues = @services.diagnose_required_fields(
    "task_type: feature-change\ntitle: Add filter\n",
    ["task_type", "title", "target_paths"],
  )
  assert_eq(issues.length(), 1)
  assert_true(issues[0].contains("target_paths"))
}

///|
/// 应能渲染完整的诊断报告，包含所有问题项。
test "render_doctor_report shows all issues" {
  let report = @services.render_doctor_report([
    "缺失文件：repo-rules.yml", "空文件：current-task.yml", "缺少字段：target_paths",
  ])
  assert_true(report.contains("repo-rules.yml"))
  assert_true(report.contains("current-task.yml"))
  assert_true(report.contains("target_paths"))
}

///|
/// 应能渲染健康通过的诊断报告。
test "render_doctor_report shows healthy when no issues" {
  let report = @services.render_doctor_report([])
  assert_true(report.contains("配置健康"))
}

///|
/// 应能报告 pre-commit hook 缺失，避免仓库只初始化规则却没有接通提交前门禁。
test "diagnose_pre_commit_hook reports missing hook" {
  let issues = @services.diagnose_pre_commit_hook(
    "/repo/.git/hooks/pre-commit", false,
  )
  assert_eq(issues.length(), 1)
  assert_true(issues[0].contains("pre-commit"))
}

///|
/// 已存在且内容正确的 pre-commit hook 时不应重复上报问题。
test "diagnose_pre_commit_hook accepts present hook" {
  let issues = @services.diagnose_pre_commit_hook(
    "/repo/.git/hooks/pre-commit",
    true,
    content="#!/bin/sh\nif [ ! -f .moonforge/current-task.yml ]; then\n  exit 1\nfi\nif command -v moonforge >/dev/null 2>&1; then\n  MOONFORGE_BIN=$(command -v moonforge)\nfi\noutput=$($MOONFORGE_BIN check --repo . 2>&1 || true)\nprintf '%s\\n' \"$output\"\n",
  )
  assert_true(issues.is_empty())
}

///|
/// hook 文件存在但缺少 MoonForge 命令时，doctor 应明确提示脚本内容不完整。
test "diagnose_pre_commit_hook reports incomplete hook content" {
  let issues = @services.diagnose_pre_commit_hook(
    "/repo/.git/hooks/pre-commit",
    true,
    content="#!/bin/sh\necho only\n",
  )
  assert_eq(issues.length(), 1)
  assert_true(issues[0].contains("检查命令"))
}
