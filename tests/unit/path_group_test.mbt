///|
/// 文件说明：覆盖路径组展开与任务上限合并的基础行为，先用红测锁定缺失能力。
/// 输入：路径组映射与候选组名称，或两个任务上限值。
/// 输出：展开后的具体 glob 列表，或更严格的文件上限。

///|
/// 路径组展开应返回命中的具体 glob，并保持原始顺序。
test "path group expansion returns concrete globs" {
  let groups : Map[String, Array[String]] = {
    "frontend_user_pages": ["frontend/src/pages/UserList/**"],
  }
  let expanded = @infra.expand_target_groups(groups, ["frontend_user_pages"])
  assert_eq(expanded, ["frontend/src/pages/UserList/**"])
}

///|
/// 有效任务合并应保留更严格的文件数上限。
test "effective task merge keeps stricter max file count" {
  let task_limit = @checkers.pick_stricter_limit(8, 3)
  assert_eq(task_limit, 3)
}
