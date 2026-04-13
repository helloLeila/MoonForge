# MoonForge Pre-commit 验收矩阵 / Acceptance Matrix

## 范围 / Scope

MoonForge 第一阶段验收聚焦 `AI coding -> git add -> pre-commit check` 这条主链路。  
The first acceptance phase focuses on the `AI coding -> git add -> pre-commit check` path.

固定验收入口：
Fixed acceptance entrypoints:

- `moonforge acc pass`
- `moonforge acc retry`
- `moonforge acc reject`

固定配置文件：
Fixed scenario config:

- `examples/acceptance/current.yml`

固定夹具：
Fixed fixture:

- `examples/acceptance/react-homepage-fixture`

## 十个规则场景 / Ten Rule Scenarios

| 场景 | 结果 | 具体触发 | 配置位置 |
| --- | --- | --- | --- |
| 单文件合规通过 | `Accept` | 暂存区只包含 1 个允许文件，后缀合法、材料齐全、必需命令通过 | `current.yml` 中的 `target_paths`、`allowed_extensions`、`required_artifacts`、`required_commands` |
| 双文件合规通过 | `Accept` | 暂存区刚好命中 2 个允许文件，且未超上限 | 同上 |
| 非法后缀拦截 | `Reject` | staged diff 出现 `.map`、`.snap` 等禁止后缀 | `blocked_extensions` |
| 越权文件拦截 | `Reject` | staged diff 触碰当前任务允许范围之外的文件 | `target_paths` + `allowed_paths` |
| 受保护路径拦截 | `Reject` | staged diff 命中 `src/core/**` 等保护路径 | `protected_paths` |
| 改动文件数超限 | `Reject` | staged diff 文件数大于 `max_changed_files` | `max_changed_files` |
| 缺少预览材料需重试 | `Retryable` | 路径合法，但缺 `preview-report.json` | `required_artifacts` |
| 必需校验命令未通过需重试 | `Retryable` | `required_commands` 中任一命令执行失败 | `required_commands` |
| 误提交生成产物或缓存文件拦截 | `Reject` | staged diff 命中 `dist/**`、`build/**`、`.next/**` 等 | `generated_artifact_paths` |
| 调试残留拦截 | `Reject` | 新增行命中 `console.log`、`debugger`、`TODO`、`FIXME` 等 | `content_blocklist_patterns` |

## acc 用例 / acc Cases

| 命令 | 复现场景 | 预期结果 | 固定输入目录 |
| --- | --- | --- | --- |
| `moonforge acc pass` | 单文件合规通过 | `Accept` | `examples/acceptance/cases/pass` |
| `moonforge acc retry` | 缺少预览材料需重试 | `Retryable` | `examples/acceptance/cases/retry` |
| `moonforge acc reject` | 调试残留拦截 | `Reject` | `examples/acceptance/cases/reject` |

## 固定结果物 / Fixed Outputs

每个 acc case 都对比这 3 个结果文件：  
Each acc case compares these three outputs:

- `gate-result.json`
- `checked-files.txt`
- `gate-report.md`

这些 expected 文件位于：
These expected files live under:

- `examples/acceptance/cases/<case>/expected/`
