///|
/// 文件总说：
/// 这个文件负责把 bootstrap 默认偏好在磁盘上读出来、写进去。
/// 它只关心两件事：
/// 1. 配置文件路径放哪里
/// 2. 结构化对象怎么和 YAML 文本来回转换
///
/// 这样 `init`、`task`、`check`、`report` 都不用自己拼路径和字符串。

///|
/// 返回 bootstrap 配置目录。
pub fn bootstrap_dir(repo_root : String) -> String {
  join_path(repo_root, ".moonforge/bootstrap")
}

///|
/// 返回 task 默认偏好文件路径。
pub fn task_defaults_path(repo_root : String) -> String {
  join_path(bootstrap_dir(repo_root), "task-defaults.yml")
}

///|
/// 返回 check 默认偏好文件路径。
pub fn check_preferences_path(repo_root : String) -> String {
  join_path(bootstrap_dir(repo_root), "check-preferences.yml")
}

///|
/// 返回 report 默认偏好文件路径。
pub fn report_preferences_path(repo_root : String) -> String {
  join_path(bootstrap_dir(repo_root), "report-preferences.yml")
}

///|
/// 将布尔值渲染成 YAML 用的 `true / false`。
fn render_bool(value : Bool) -> String {
  if value {
    "true"
  } else {
    "false"
  }
}

///|
/// 解析 YAML 里的布尔标量。
fn parse_bool(
  yaml : FlatYaml,
  key : String,
  default_value : Bool,
) -> Bool raise {
  match yaml.get_scalar(key) {
    Some(value) =>
      match value.trim().to_string() {
        "true" => true
        "false" => false
        _ => raise Failure::Failure("Field \{key} is not a valid boolean")
      }
    None => default_value
  }
}

///|
/// 渲染字符串列表块。
fn render_bootstrap_list_block(key : String, values : Array[String]) -> String {
  let lines : Array[String] = ["\{key}:"]
  for value in values {
    lines.push("  - \"\{value}\"")
  }
  lines.join("\n")
}

///|
/// 渲染带前缀的标量块。
fn render_prefixed_scalars(
  prefix : String,
  values : Map[String, String],
) -> Array[String] {
  let lines : Array[String] = []
  values.each((key, value) => lines.push("\{prefix}\{key}: \"\{value}\""))
  lines
}

///|
/// 渲染 task 默认偏好 YAML。
pub fn render_task_defaults(task_defaults : @domain.TaskDefaults) -> String {
  let lines : Array[String] = [
    "default_check_mode: \"\{task_defaults.default_check_mode}\"",
    "default_artifact_dir: \"\{task_defaults.default_artifact_dir}\"",
    render_bootstrap_list_block("note_lines", task_defaults.note_lines),
  ]
  for
    line in render_prefixed_scalars(
      "title_prefixes.",
      task_defaults.default_title_prefixes,
    ) {
    lines.push(line)
  }
  lines.join("\n\n") + "\n"
}

///|
/// 读取 task 默认偏好 YAML。
pub fn read_task_defaults(path : String) -> @domain.TaskDefaults raise {
  let yaml = read_flat_yaml(path)
  @domain.TaskDefaults::{
    default_check_mode: yaml.get_scalar("default_check_mode").unwrap_or("local"),
    default_artifact_dir: yaml
    .get_scalar("default_artifact_dir")
    .unwrap_or(".moonforge/artifacts/current"),
    default_title_prefixes: yaml.get_scalars_with_prefix("title_prefixes."),
    note_lines: yaml.get_list("note_lines"),
  }
}

///|
/// 渲染 check 默认偏好 YAML。
pub fn render_check_preferences(
  check_preferences : @domain.CheckPreferences,
) -> String {
  [
    "prefer_staged_diff: \{render_bool(check_preferences.prefer_staged_diff)}",
    "auto_prepare_local_run_input: \{render_bool(check_preferences.auto_prepare_local_run_input)}",
    "keep_local_input_snapshot: \{render_bool(check_preferences.keep_local_input_snapshot)}",
    "write_input_summary: \{render_bool(check_preferences.write_input_summary)}",
    render_bootstrap_list_block(
      "artifact_search_dirs",
      check_preferences.artifact_search_dirs,
    ),
  ].join("\n\n") +
  "\n"
}

///|
/// 读取 check 默认偏好 YAML。
pub fn read_check_preferences(path : String) -> @domain.CheckPreferences raise {
  let yaml = read_flat_yaml(path)
  @domain.CheckPreferences::{
    prefer_staged_diff: parse_bool(yaml, "prefer_staged_diff", true),
    auto_prepare_local_run_input: parse_bool(
      yaml, "auto_prepare_local_run_input", true,
    ),
    keep_local_input_snapshot: parse_bool(
      yaml, "keep_local_input_snapshot", true,
    ),
    artifact_search_dirs: yaml.get_list("artifact_search_dirs"),
    write_input_summary: parse_bool(yaml, "write_input_summary", true),
  }
}

///|
/// 渲染 report 默认偏好 YAML。
pub fn render_report_preferences(
  report_preferences : @domain.ReportPreferences,
) -> String {
  [
    "show_context: \{render_bool(report_preferences.show_context)}",
    "show_metrics: \{render_bool(report_preferences.show_metrics)}",
    "show_next_action: \{render_bool(report_preferences.show_next_action)}",
    "show_history_hint: \{render_bool(report_preferences.show_history_hint)}",
    "show_preflight_hint: \{render_bool(report_preferences.show_preflight_hint)}",
  ].join("\n") +
  "\n"
}

///|
/// 读取 report 默认偏好 YAML。
pub fn read_report_preferences(
  path : String,
) -> @domain.ReportPreferences raise {
  let yaml = read_flat_yaml(path)
  @domain.ReportPreferences::{
    show_context: parse_bool(yaml, "show_context", true),
    show_metrics: parse_bool(yaml, "show_metrics", true),
    show_next_action: parse_bool(yaml, "show_next_action", true),
    show_history_hint: parse_bool(yaml, "show_history_hint", true),
    show_preflight_hint: parse_bool(yaml, "show_preflight_hint", true),
  }
}
