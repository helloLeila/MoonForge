///|
/// 文件总说：
/// 这个文件验证运行历史的最小行为：
/// - 能写入
/// - 能读回
/// - 最近记录应该排在最前面
fn sample_history_record(run_id : String) -> @domain.RunHistoryRecord {
  @domain.RunHistoryRecord::{
    run_id,
    mode: "local",
    decision: "Accept",
    task_type: "feature-change",
    title: "补充UserList",
    checked_file_count: 2,
    missing_artifact_count: 0,
    invalid_artifact_count: 0,
    command_failure_count: 0,
    violation_count: 0,
    context_summary: "本地暂存区检查",
    next_action: "可进入下一阶段",
    created_at_ns: run_id,
  }
}

///|
test "run history store keeps latest record first" {
  let repo_root = @infra.join_path(
    "/tmp",
    @infra.unique_temp_name("moonforge-run-history"),
  )
  ignore(@services.record_run_history(repo_root, sample_history_record("r1")))
  let index = @services.record_run_history(
    repo_root,
    sample_history_record("r2"),
  )

  assert_eq(index.count(), 2)
  assert_true(index.latest() is Some(_))
  match index.latest() {
    Some(record) => assert_eq(record.run_id, "r2")
    None => panic()
  }
}
