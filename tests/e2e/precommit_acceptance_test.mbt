///|
/// 文件说明：覆盖内部 acc 验收入口，确保固定 case 能复现 pass / retry / reject 三种结论。
/// 联动文件：对应 `src/services/acceptance_service.mbt` 与 `cmd/main/main.mbt` 的 acc 子命令。

///|
/// acc pass 应复现实验夹具中的放行结论。
test "acc pass returns accept summary" {
  let output = @services.run_acceptance_case("pass")
  assert_true(output.contains("Accept"))
  assert_true(output.contains("pass"))
}

///|
/// acc retry 应复现实验夹具中的补齐后重试结论。
test "acc retry returns retryable summary" {
  let output = @services.run_acceptance_case("retry")
  assert_true(output.contains("Retryable"))
  assert_true(output.contains("retry"))
}

///|
/// acc reject 应复现实验夹具中的拒绝结论。
test "acc reject returns reject summary" {
  let output = @services.run_acceptance_case("reject")
  assert_true(output.contains("Reject"))
  assert_true(output.contains("reject"))
}
