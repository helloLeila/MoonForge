///|
/// 文件说明：覆盖范围检查器的最小行为，确保越界文件和规模超限能在独立检查器层被识别。
/// 联动文件：对应 `src/checkers/scope_checker.mbt`，并为 `src/checkers/gate.mbt` 后续复用提供回归保护。

///|
/// 范围检查器应识别超出允许范围的文件。
test "scope checker rejects out of scope files" {
  let task = @domain.EffectiveTask::{
    task_type: "feature-change",
    title: "Add filter",
    allowed_paths: ["frontend/src/pages/**"],
    forbidden_paths: [],
    approval_required_paths: [],
    allowed_extensions: [".tsx"],
    required_artifacts: [],
    max_changed_files: 8,
  }
  let result = @checkers.check_scope(task, ["backend/src/main/java/App.java"])
  assert_eq(result.out_of_scope_files, ["backend/src/main/java/App.java"])
  assert_eq(result.target_paths_hit, [])
  assert_true(!result.file_count_exceeded)
}

///|
/// 范围检查器应标记命中的目标路径，并识别文件数超限。
test "scope checker tracks in-scope files and file count limit" {
  let task = @domain.EffectiveTask::{
    task_type: "feature-change",
    title: "Add filter",
    allowed_paths: ["frontend/src/pages/**", "frontend/src/components/**"],
    forbidden_paths: [],
    approval_required_paths: [],
    allowed_extensions: [".tsx"],
    required_artifacts: [],
    max_changed_files: 1,
  }
  let result = @checkers.check_scope(task, [
    "frontend/src/pages/UserList/index.tsx",
    "frontend/src/components/UserCard.tsx",
  ])

  assert_eq(result.out_of_scope_files, [])
  assert_eq(result.target_paths_hit, [
    "frontend/src/pages/UserList/index.tsx",
    "frontend/src/components/UserCard.tsx",
  ])
  assert_true(result.file_count_exceeded)
}
