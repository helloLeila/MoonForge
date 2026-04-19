# MoonForge Main Flow 10000 LOC Handoff

## 本轮目标

- 继续保留 `init / task / check / report` 作为主命令
- 让用户在自己的项目里直接使用，不再频繁输入完整路径
- 让 `task --type ...` 自动补全大部分 `current-task.yml`
- 让本地 `check` 默认吃 staged diff
- 把 `src` 下 `.mbt` 有效行数推到 `10000+`
- 强化中文注释，尽量做到“先总说，再分说”

## 当前结果

- `src` 下 `.mbt` 当前总行数：`10006`
- 主链路已经能走：
  - `moonforge init`
  - `moonforge task --type feature-change`
  - `moonforge check`
  - `moonforge report`
- 本轮又补厚了这些核心层：
  - 运行历史：`run_history_*`
  - 结论解释：`decision_explanation_*`
  - 报告视图：`report_view_*`
  - 额外提醒：`preflight_advice_*`
  - 任务画像：`task_profile_*`
  - 输入来源说明：`run_input_story_*`
  - 输出目录导航：`output_catalog_*`
  - 结果阅读指引：`output_walkthrough_*`

## 已验证

- `moon test`
  - `Total tests: 128, passed: 128, failed: 0.`
- `moon run cmd/main -- acc pass`
  - `moonforge acc pass => Accept`
- `moon run cmd/main -- acc retry`
  - `moonforge acc retry => Retryable`
- `moon run cmd/main -- acc reject`
  - `moonforge acc reject => Reject`

## 关键产物变化

这轮 `check` 输出目录里新增了很多“给人看”的文件：

- `decision-explanation.json / .md`
- `report-view.json / .md`
- `preflight-advice.json / .md`
- `task-profile.json / .md`
- `run-input-story.json / .md`
- `output-catalog.json / .md`
- `output-walkthrough.json / .md`
- `output-quickstart.txt`

快照目录里也同步新增了对应的 `snapshot` 文件。

## 还没做完

- 还没有拆成 `20` 次中文 `feat:/fix:` 提交
- 还没有重新整理最近这批提交标题的人味和长短变化
- 还没有推送远端

## 建议的下一步

1. 先按功能层把当前改动拆成 `20` 次提交
2. 再检查一次 `git status`
3. 最后再决定是否推远端或生成 PR 文案
