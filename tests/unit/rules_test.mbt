///|
/// 文件说明：验证最小规则组件的基础正确性，包括 glob 匹配、YAML 解析和 patch 文件抽取。
/// 联动文件：主要覆盖 `src/infra/path_utils.mbt`、`src/infra/flat_yaml.mbt` 和 `src/checkers/gate.mbt` 中的底层逻辑。

///|

///|
/// 验证最小 glob 实现能够匹配计划书里的典型目录模式。
test "glob matches nested paths with doublestar" {
  assert_true(
    @infra.match_glob(
      "frontend/src/pages/UserList/index.tsx", "frontend/src/pages/**",
    ),
  )
  assert_true(
    @infra.match_glob(
      "backend/src/main/java/com/acme/user/service/UserService.java", "backend/src/main/java/**/service/**",
    ),
  )
  assert_true(
    !@infra.match_glob(
      "backend/src/main/java/com/acme/common/security/AuthFilter.java", "frontend/src/pages/**",
    ),
  )
}

///|
/// 验证最小 YAML 解析器能读取模板中常用的标量和列表字段。
test "flat yaml parser reads scalar and list fields" {
  let yaml_text =
    #|task_type: feature-change
    #|title: "demo"
    #|allowed_paths:
    #|  - "frontend/src/pages/**"
    #|required_artifacts:
    #|  - "test-report.json"
    #|max_changed_files: 8
    #|
  let yaml = @infra.parse_flat_yaml(yaml_text)

  assert_eq(yaml.get_scalar("task_type"), Some("feature-change"))
  assert_eq(yaml.get_scalar("title"), Some("demo"))
  assert_eq(yaml.get_scalar("max_changed_files"), Some("8"))
  assert_eq(yaml.get_list("allowed_paths"), ["frontend/src/pages/**"])
  assert_eq(yaml.get_list("required_artifacts"), ["test-report.json"])
}

///|
/// 验证最小 YAML 解析器能按前缀归并路径组列表字段。
test "flat yaml parser groups prefixed list fields" {
  let yaml_text =
    #|path_groups.frontend_user_pages:
    #|  - "frontend/src/pages/UserList/**"
    #|  - "frontend/src/pages/UserDetail/**"
    #|path_groups.frontend_shared_components:
    #|  - "frontend/src/components/UserCard/**"
    #|
  let yaml = @infra.parse_flat_yaml(yaml_text)

  assert_eq(yaml.get_lists_with_prefix("path_groups."), {
    "frontend_user_pages": [
      "frontend/src/pages/UserList/**", "frontend/src/pages/UserDetail/**",
    ],
    "frontend_shared_components": ["frontend/src/components/UserCard/**"],
  })
}

///|
/// 验证目录扫描能返回顶层文件与子目录名称。
test "list dir returns top-level entries" {
  let dir = @infra.join_path("tmp", "moonforge-list-dir-test")
  @infra.write_text(
    @infra.join_path(dir, "feature-change.yml"),
    "task_type: feature-change\n",
  )
  @infra.write_text(@infra.join_path(dir, "nested/demo.txt"), "demo\n")

  let entries = @infra.list_dir(dir)
  assert_true(entries.contains("feature-change.yml"))
  assert_true(entries.contains("nested"))
}

///|
/// 验证 diff 解析器能从标准 git patch 中提取被修改文件。
test "diff extractor collects touched git files" {
  let diff =
    #|diff --git a/frontend/src/pages/UserList/index.tsx b/frontend/src/pages/UserList/index.tsx
    #|index 1111111..2222222 100644
    #|--- a/frontend/src/pages/UserList/index.tsx
    #|+++ b/frontend/src/pages/UserList/index.tsx
    #|@@ -1,1 +1,2 @@
    #| export const page = true
    #|+export const filter = "department"
    #|,
  assert_eq(@checkers.extract_touched_files(diff), [
    "frontend/src/pages/UserList/index.tsx",
  ])
}
