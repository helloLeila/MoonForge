# MoonForge Follow-up Handoff

## Session Snapshot

- 日期：`2026-04-14`
- 工作树：`/Users/leila/Documents/Playground 3/moonforge_gate/.worktrees/moonforge-core-impl`
- 分支：`feature0413`
- 当前定位：
  - 继续扩展 `MoonForge` 核心，不扩 acceptance fixture 自身业务
  - 重点补厚 `check / report / replay / pack / doctor`
  - 本轮仍保持“增量增强”，没有重构主命令结构

## 本轮新增内容

### 1. PR 复检上下文打通

- 新增 `src/domain/run_context_types.mbt`
  - 定义 `RunContextFile`
- 新增 `src/services/run_context_service.mbt`
  - 负责解析 `run-context.json`
  - 负责渲染本地 / CI / PR 来源摘要
- 扩展 `src/adapters/*`
  - `mode_paths.mbt` 支持 `pr`
  - `github_env.mbt` 提供 `event/base/head/pr_number` 读取
  - `git_ci_diff.mbt` 支持 PR diff 环境校验
- `run_check` 现在会把运行上下文写到：
  - latest: `run-context.json`
  - snapshot: `run-context.snapshot.json`

### 2. report / replay 摘要变厚

- 新增 `src/services/result_metrics_service.mbt`
  - 解析 `scope-result.json`
  - 解析 `artifact-result.json`
  - 汇总变更文件数、缺失材料数、无效材料数、命令失败数
- `src/services/report_service.mbt`
  - `report_summary` 现在会带来源摘要和结果统计
- `src/services/replay_service.mbt`
  - `replay_check` 现在会带任务类型、结论、来源、结果统计
- `write_outputs` 现在额外落盘：
  - `scope.snapshot.json`
  - `artifact.snapshot.json`
  - `gate.snapshot.json`

### 3. pack 增加结构化清单

- 新增 `src/domain/pack_manifest_types.mbt`
  - 定义 `PackManifestFile`
- `src/services/pack_service.mbt`
  - 增加导出文件统计
  - 增加 `build_pack_manifest`
  - 增加 `render_pack_summary`
- `pack_latest` 现在会额外导出：
  - `pack-manifest.json`
  - `pack-summary.md`

### 4. doctor 不再只看 hook 文件是否存在

- `src/infra/git_hook_text.mbt`
  - 新增 `pre_commit_hook_required_markers`
- `src/services/doctor_service.mbt`
  - `diagnose_pre_commit_hook` 现在会检查关键命令和 current-task 校验片段
- `doctor_repo` 现在会读取 hook 内容再诊断

### 5. 文档和命令帮助同步

- `README.mbt.md`
  - 补充 `pr` 模式说明
  - 补充 `pack` 输出内容
  - 补充 pre-commit hook 接入说明
- `cmd/main/main.mbt`
  - CLI 帮助中的模式说明更新为 `local / ci / pr`

## 本轮验证结果

已重新执行：

- `moon info`
  - 结果：通过，仅保留既有 `unused_package` 警告
- `moon test`
  - 结果：`Total tests: 108, passed: 108, failed: 0.`
- `moon run cmd/main -- acc pass`
  - 结果：`moonforge acc pass => Accept`
- `moon run cmd/main -- acc retry`
  - 结果：`moonforge acc retry => Retryable`
- `moon run cmd/main -- acc reject`
  - 结果：`moonforge acc reject => Reject`

## 关键变更文件

- `src/adapters/git_ci_diff.mbt`
- `src/adapters/github_env.mbt`
- `src/adapters/mode_paths.mbt`
- `src/domain/run_context_types.mbt`
- `src/domain/pack_manifest_types.mbt`
- `src/infra/run_store.mbt`
- `src/infra/git_hook_text.mbt`
- `src/services/run_context_service.mbt`
- `src/services/result_metrics_service.mbt`
- `src/services/report_service.mbt`
- `src/services/replay_service.mbt`
- `src/services/pack_service.mbt`
- `src/services/doctor_service.mbt`
- `src/services/commands.mbt`
- `tests/integration/gate_flow_test.mbt`
- `tests/integration/replay_flow_test.mbt`
- `tests/integration/pack_flow_test.mbt`
- `tests/integration/task_flow_test.mbt`
- `tests/unit/diff_parser_test.mbt`
- `tests/unit/doctor_service_test.mbt`
- `tests/unit/pack_export_test.mbt`

## 当前已知状态

- 工作树在本文件写入时仍处于待提交状态，准备拆成 `10` 次中文提交
- 注释已按“中文具体说明”为主继续补充到本轮新增函数
- `tests/*/moon.pkg` 的 `unused_package` 仍是既有警告，不影响测试通过

## 下次继续建议

1. 继续增加 `task` 侧的可读输出，例如 current-task 中文摘要文件
2. 把 `report / replay / pack` 的统计维度继续扩到违规数和材料清单
3. 视项目书要求补强单独的 PR/GitHub 演示入口，而不只停留在 `--mode pr`
4. 继续往 `init / task / check / report / replay / pack` 主链路加核心代码，避免增长主要落在 acceptance

## 恢复命令

```bash
git -C '/Users/leila/Documents/Playground 3/moonforge_gate/.worktrees/moonforge-core-impl' status --short
moon info
moon test
moon run cmd/main -- acc pass
moon run cmd/main -- acc retry
moon run cmd/main -- acc reject
```
