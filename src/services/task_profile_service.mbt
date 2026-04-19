///|
/// 文件总说：
/// 这个文件负责把 `current-task` 和 `effective-task` 整理成“任务画像”。
/// 它的作用很朴素：
/// 用户很多时候知道自己跑了 `task`，
/// 但不知道系统最后到底把这次任务理解成了什么样子。
///
/// 所以这里会把任务拆成几块去讲：
/// 1. 标题怎么来的
/// 2. 范围怎么来的
/// 3. 材料和命令要求是什么
/// 4. 为什么系统建议你再看一眼，或者为什么它觉得可以直接用

///|
/// 给标题来源取一个更白话的说法。
fn render_title_source(source : String) -> String {
  match source {
    "manual_input" => "命令行手工输入"
    "auto_from_staged_files" => "根据暂存文件自动生成"
    "fallback_missing_staged_files" =>
      "因为缺少暂存文件，只能给出兜底标题"
    _ => source
  }
}

///|
/// 给路径来源取一个更白话的说法。
fn render_path_source(source : String) -> String {
  match source {
    "manual_input" => "命令行手工输入"
    "auto_groups_only" => "系统主要依赖路径组自动补全"
    "auto_groups_and_paths" =>
      "系统混合使用路径组和显式路径自动补全"
    "manual_or_unknown" => "来源未细分"
    _ => source
  }
}

///|
/// 构造标题相关说明。
fn build_title_lines(current_task : @domain.CurrentTask) -> Array[String] {
  [
    "标题：\{current_task.title}",
    "标题来源：\{render_title_source(current_task.title_source)}",
  ]
}

///|
/// 构造范围相关说明。
fn build_scope_lines(
  current_task : @domain.CurrentTask,
  effective_task : @domain.EffectiveTask,
  checked_files : Array[String],
) -> Array[String] {
  [
    "target_groups 数量：\{current_task.target_groups.length()}",
    "target_paths 数量：\{current_task.target_paths.length()}",
    "范围来源：\{render_path_source(current_task.target_path_source)}",
    "展开后允许路径数：\{effective_task.allowed_paths.length()}",
    "task 阶段记录的 staged_files 数：\{current_task.staged_files.length()}",
    "check 阶段实际检查文件数：\{checked_files.length()}",
  ]
}

///|
/// 构造材料和命令要求说明。
fn build_requirement_lines(
  current_task : @domain.CurrentTask,
  effective_task : @domain.EffectiveTask,
) -> Array[String] {
  [
    "当前任务材料数：\{current_task.required_artifacts.length()}",
    "最终生效材料数：\{effective_task.required_artifacts.length()}",
    "当前任务命令数：\{current_task.required_commands.length()}",
    "最终生效命令数：\{effective_task.required_commands.length()}",
    "材料主目录：\{current_task.artifact_dir}",
    "检查模式：\{current_task.check_mode}",
  ]
}

///|
/// 构造自动补全痕迹说明。
fn build_autofill_lines(current_task : @domain.CurrentTask) -> Array[String] {
  let auto_inferred_text = current_task.auto_inferred_fields.join("，")
  let lines : Array[String] = [
    "自动补全字段数：\{current_task.auto_inferred_fields.length()}",
  ]
  if !current_task.auto_inferred_fields.is_empty() {
    lines.push("自动补全字段：\{auto_inferred_text}")
  }
  if !current_task.notes.is_empty() {
    lines.push("任务备注数：\{current_task.notes.length()}")
    for note in current_task.notes {
      lines.push("备注：\{note}")
    }
  }
  lines
}

///|
/// 构造任务画像主对象。
pub fn build_task_profile_view(
  current_task : @domain.CurrentTask,
  effective_task : @domain.EffectiveTask,
  checked_files : Array[String],
) -> @domain.TaskProfileView {
  let lines : Array[String] = []
  for line in build_title_lines(current_task) {
    lines.push(line)
  }
  for line in build_scope_lines(current_task, effective_task, checked_files) {
    lines.push(line)
  }
  for line in build_requirement_lines(current_task, effective_task) {
    lines.push(line)
  }
  for line in build_autofill_lines(current_task) {
    lines.push(line)
  }

  @domain.TaskProfileView::{
    headline: "这份任务画像描述的是：系统最终把当前任务理解成什么样。",
    summary: "task_type=\{current_task.task_type} | title=\{current_task.title} | need_review=\{current_task.need_user_review}",
    lines,
    need_user_review: current_task.need_user_review,
  }
}

///|
/// 把任务画像渲染成 Markdown。
pub fn render_task_profile_markdown(view : @domain.TaskProfileView) -> String {
  let lines : Array[String] = [
    "# MoonForge 任务画像",
    "",
    "## 总说",
    view.headline,
    "",
    view.summary,
    "",
    "## 分说",
  ]
  for line in view.lines {
    lines.push("- \{line}")
  }
  lines.join("\n") + "\n"
}
