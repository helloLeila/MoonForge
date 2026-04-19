# MoonForge Main Flow Simplification Design

## 背景

当前 `MoonForge` 已经具备基础门禁能力，但真实使用方式仍然偏开发态：

- 需要频繁传 `--repo`
- 本地 `check` 仍依赖手工准备 `--run`
- `task` 需要手工输入较多信息
- 用户不容易在“自己的项目里直接上手”

本轮设计目标是：在不放弃项目书既定主线的前提下，把主命令压缩成对真实用户更自然的 4 步。

## 已确认用户决策

1. 保留项目书主命令：
   - `init`
   - `task`
   - `check`
   - `report`
2. 不新增一套需要用户重新记忆的新命令体系。
3. 用户在自己的项目里直接使用，而不是回到 `MoonForge` 源码仓库里执行。
4. 命令输入越少越好，复杂内容尽量写入配置文件。
5. `task` 只要求用户至少提供 `--type`，其余内容由工具自动补全或落入配置文件。
6. 代码要“中学生一眼就知道怎么回事”：
   - 文件先总说
   - 函数再分说
   - 注释详细、直接、少黑话
7. `src` 有效代码总量必须扩充到 `10000+`。

## 最终用户目标体验

用户在自己的项目里应主要这样使用：

```bash
cd my-project
moonforge init
moonforge task --type feature-change
moonforge check
moonforge report
```

### `init`

- 默认当前目录为目标项目
- 自动生成完整 `.moonforge/`
- 自动写入默认模板、默认运行配置、默认报告配置
- 自动安装并诊断 `pre-commit`

### `task --type ...`

- 用户只输入任务类型
- 工具自动读取当前 git 改动
- 自动补全：
  - 标题
  - 目标路径
  - 目标路径组
  - 材料要求
  - 默认检查偏好
- 输出到 `.moonforge/current-task.yml`

### `check`

- 默认当前目录
- 本地模式默认直接读取 staged diff
- 自动准备运行目录
- 自动收集材料目录
- 自动写入 latest 输出和历史快照

### `report`

- 默认当前目录
- 直接显示最近一次结论
- 同时解释：
  - 为什么过
  - 为什么不过
  - 下一步该怎么改

## 配置设计

### 长期配置

- `.moonforge/repo-rules.yml`
  - 仓库长期规则
- `.moonforge/task-types/*.yml`
  - 各任务类型默认边界
- `.moonforge/artifact-schemas/*.yml`
  - 材料结构约束

### 当前任务配置

- `.moonforge/current-task.yml`
  - 当前任务唯一主配置
  - 由 `moonforge task --type ...` 自动补全大部分字段
  - 用户只在必要时轻微修改

### 输出目录

- `.moonforge/out/<mode>/latest`
  - 最近一次结果
- `.moonforge/runs/<run-id>`
  - 历史快照

## `current-task.yml` 扩充方向

在现有 `task_type / title / target_groups / target_paths` 基础上，增加更适合自动补全和解释的字段：

- `title_source`
- `target_path_source`
- `staged_files`
- `auto_inferred`
- `required_artifacts`
- `required_commands`
- `artifact_dir`
- `check_mode`
- `need_user_review`
- `notes`
- `last_auto_fill_ns`

这样用户能一眼看懂：

- 哪些内容是系统自动推断的
- 哪些内容需要自己确认
- 这次检查到底基于哪些文件和材料

## 代码扩充分配

为了让 `src` 超过 `10000` 行，增长主要放在 6 块核心区域：

1. 当前目录与 git 上下文识别
2. `task` 自动补全与任务推断
3. `check` 本地 staged 输入编排
4. 运行历史、索引与 latest 管理
5. `report` 的解释、历史和可读输出
6. 更多规则族与规则解释链路

## 结构原则

- 不靠 acceptance 夹具堆行数
- 不靠 README 或测试堆行数
- 主要增长在：
  - `src/services`
  - `src/infra`
  - `src/checkers`
  - `src/domain`

## 可读性原则

所有新增文件遵循：

1. 文件开头先写“这个文件总共负责什么”
2. 每个函数前面先写“这个函数总体作用”
3. 再写输入、输出、关键步骤
4. 多用简单直白中文，不堆抽象术语

## 本轮实现范围

本轮优先做：

1. `--repo` 默认当前目录
2. `task --type` 自动补全 `current-task.yml`
3. `check` 本地自动 staged diff
4. `report` 默认当前目录并展示更完整摘要
5. 配套历史、任务推断、材料发现和报告解释基础设施
6. 按上述主线扩厚 `src`

暂不优先：

- 新增一套替代主命令的新 CLI
- 把增长主要放在 acceptance 资产
- 做大量前端或非核心展示层
