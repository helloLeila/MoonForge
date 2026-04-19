///|
/// 文件总说：
/// 这个文件负责处理 task 命令里最“贴着用户输入”的那一层工作。
/// 主要做三件事：
/// 1. 把命令行里零散的字符串整理成结构化草稿
/// 2. 把 `CurrentTask` 渲染成用户真正会看到的 YAML 文件
/// 3. 提供一些很小但常用的 task 辅助函数，避免上层重复写同样的字符串处理逻辑
///
/// 为什么单独放这里：
/// - `commands.mbt` 更适合做命令编排，不适合堆大量字符串和 YAML 细节
/// - `task_autofill_service.mbt` 更适合做“怎么猜”的逻辑，不适合关心“怎么写文件更好懂”

///|
/// 把一个普通字符串列表渲染成 YAML 列表块。
/// 入参：
/// - `key`：字段名
/// - `values`：要写进列表里的值
/// 出参：
/// - 一段完整的 YAML 文本块
fn render_task_list_block(key : String, values : Array[String]) -> String {
  let lines : Array[String] = ["\{key}:"]
  for value in values {
    lines.push("  - \"\{value}\"")
  }
  lines.join("\n")
}

///|
/// 把布尔值转成更适合 YAML 的 `true / false` 文本。
fn render_bool_scalar(value : Bool) -> String {
  if value {
    "true"
  } else {
    "false"
  }
}

///|
/// 把逗号分隔的命令行输入拆成干净的条目列表。
/// 这一步只做最基础的清洗，不判断它到底是路径组还是显式路径。
pub fn parse_target_values(paths_csv : String) -> Array[String] {
  let values : Array[String] = []
  for raw_item in paths_csv.split(",") {
    let item = raw_item.trim().to_string()
    if item != "" {
      values.push(item)
    }
  }
  values
}

///|
/// 兼容旧调用方式，继续提供“只取显式路径”的简单辅助函数。
/// 规则是：
/// - `@group_name` 这种路径组会被过滤掉
/// - 只有普通路径字符串会被保留下来
pub fn parse_target_paths(paths_csv : String) -> Array[String] {
  let paths : Array[String] = []
  for item in parse_target_values(paths_csv) {
    if !item.has_prefix("@") {
      paths.push(item)
    }
  }
  paths
}

///|
/// 把原始目标字符串整理成更好懂的结构化对象。
/// 入参：命令行里的 `--paths` 原始文本。
/// 出参：每条目标都会被标注成“路径组”还是“显式路径”。
pub fn parse_target_choices(
  paths_csv : String,
) -> Array[@domain.TaskTargetChoice] {
  let choices : Array[@domain.TaskTargetChoice] = []
  for item in parse_target_values(paths_csv) {
    if item.has_prefix("@") {
      let group_name = item[1:item.length()].trim().to_string()
      if group_name != "" {
        choices.push(@domain.TaskTargetChoice::{
          raw_value: item,
          normalized_value: group_name,
          is_group: true,
        })
      }
    } else {
      choices.push(@domain.TaskTargetChoice::{
        raw_value: item,
        normalized_value: item,
        is_group: false,
      })
    }
  }
  choices
}

///|
/// 把结构化目标选择再拆回“路径组数组”和“显式路径数组”。
/// 这样后面的自动补全服务和命令编排层就能直接拿到它们。
pub fn split_target_choices(
  choices : Array[@domain.TaskTargetChoice],
) -> (Array[String], Array[String]) {
  let target_groups : Array[String] = []
  let target_paths : Array[String] = []
  for choice in choices {
    if choice.is_group {
      if !target_groups.contains(choice.normalized_value) {
        target_groups.push(choice.normalized_value)
      }
    } else if !target_paths.contains(choice.normalized_value) {
      target_paths.push(choice.normalized_value)
    }
  }
  (target_groups, target_paths)
}

///|
/// 把命令行原始输入整理成任务草稿种子。
/// 这是 task 自动补全真正开始之前的第一步。
pub fn build_current_task_draft_seed(
  task_type : String,
  title : String,
  paths_csv : String,
) -> @domain.CurrentTaskDraftSeed {
  let choices = parse_target_choices(paths_csv)
  let (manual_target_groups, manual_target_paths) = split_target_choices(
    choices,
  )
  @domain.CurrentTaskDraftSeed::{
    task_type,
    override_title: title.trim().to_string(),
    manual_target_groups,
    manual_target_paths,
    target_choices: choices,
  }
}

///|
/// 返回写入 `current-task.yml` 时使用的注释头。
/// 这里故意写得比较白话，就是为了让第一次接触项目的人一眼明白怎么改。
fn current_task_header() -> String {
  let header =
    #|# 当前任务文件说明
    #|# 先总说：
    #|# 1. 这是 MoonForge 正在检查的“这一轮任务”
    #|# 2. 大部分字段可以由 `moonforge task --type ...` 自动补全
    #|# 3. 如果系统猜得不准，你通常只需要改 title、target_groups、target_paths
    #|#
    #|# 再分说：
    #|# - task_type：任务类型
    #|# - title：任务标题
    #|# - target_groups / target_paths：本次任务允许触碰的范围
    #|# - staged_files：系统生成任务时看到的暂存文件
    #|# - required_artifacts / required_commands：这次任务需要补齐的材料和命令
    #|# - need_user_review：系统建议你是否再看一眼这个文件
    #|
  header
}

///|
/// 把完整的 `CurrentTask` 渲染成更厚、更容易读懂的 YAML 文件。
/// 这就是用户在 `.moonforge/current-task.yml` 里真正会看到的内容。
pub fn render_current_task_file(task : @domain.CurrentTask) -> String {
  [
    current_task_header().trim_end(chars="\n").to_string(),
    "task_type: \"\{task.task_type}\"",
    "title: \"\{task.title}\"",
    "title_source: \"\{task.title_source}\"",
    render_task_list_block("target_groups", task.target_groups),
    render_task_list_block("target_paths", task.target_paths),
    "target_path_source: \"\{task.target_path_source}\"",
    render_task_list_block("staged_files", task.staged_files),
    render_task_list_block("required_artifacts", task.required_artifacts),
    render_task_list_block("required_commands", task.required_commands),
    "artifact_dir: \"\{task.artifact_dir}\"",
    "check_mode: \"\{task.check_mode}\"",
    render_task_list_block("auto_inferred_fields", task.auto_inferred_fields),
    render_task_list_block("notes", task.notes),
    "need_user_review: \{render_bool_scalar(task.need_user_review)}",
    "last_auto_fill_ns: \"\{task.last_auto_fill_ns}\"",
  ].join("\n\n") +
  "\n"
}

///|
/// 给内置验收包继续保留一份更简单的 current-task YAML。
/// 这个函数只服务固定夹具导出，不承载真正的运行时注释说明。
pub fn render_current_task_yaml(
  task_type : String,
  title : String,
  target_paths : Array[String],
) -> String {
  let lines : Array[String] = [
    "task_type: \"\{task_type}\"",
    "title: \"\{title}\"",
    "target_paths:",
  ]
  for path in target_paths {
    lines.push("  - \"\{path}\"")
  }
  lines.join("\n") + "\n"
}

///|
/// 验证任务类型是否在已知模板列表中，不在列表中则返回错误码。
/// 入参：`task_type`，需要验证的任务类型标识。
/// 出参：`Result[Unit, String]`，有效时返回 `Ok(())`，无效时返回 `Err("TASK_TYPE_UNKNOWN")`。
pub fn validate_task_type(task_type : String) -> Result[Unit, String] {
  let known : Array[String] = [
    "feature-change", "bug-fix", "api-change", "config-change", "test-addition",
  ]
  if known.contains(task_type) {
    Ok(())
  } else {
    Err("TASK_TYPE_UNKNOWN")
  }
}
