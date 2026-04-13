///|
/// 文件说明：覆盖风险路径检查器的最小行为，确保受保护目录与人工审批目录被分开识别。
/// 联动文件：对应 `src/checkers/risk_path_checker.mbt`，并为 `src/checkers/gate.mbt` 的后续复用提供回归保护。

///|
/// 受保护路径应直接落入 reject 分支。
test "risk checker marks protected path as reject" {
  let result = @checkers.check_risk_paths(
    ["backend/src/main/java/**/security/**"],
    ["backend/src/main/java/**/service/high-risk/**"],
    ["backend/src/main/java/com/acme/common/security/AuthFilter.java"],
  )

  assert_eq(result.protected_files, [
    "backend/src/main/java/com/acme/common/security/AuthFilter.java",
  ])
  assert_eq(result.approval_files, [])
}

///|
/// 非受保护但命中高风险目录的文件应进入人工审批列表。
test "risk checker keeps approval paths separate" {
  let result = @checkers.check_risk_paths(
    ["backend/src/main/java/**/security/**"],
    ["backend/src/main/java/**/service/high-risk/**"],
    [
      "backend/src/main/java/com/acme/user/service/high-risk/UserAuditService.java",
    ],
  )

  assert_eq(result.protected_files, [])
  assert_eq(result.approval_files, [
    "backend/src/main/java/com/acme/user/service/high-risk/UserAuditService.java",
  ])
}
