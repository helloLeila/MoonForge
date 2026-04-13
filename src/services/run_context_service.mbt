///|
/// 文件说明：负责解析 `run-context.json` 并生成终端可读的复检上下文摘要。

///|
/// 从简单 JSON 文本中提取一个字符串字段，缺失时返回 None。
pub fn extract_json_string_field(
  json_text : String,
  field_name : String,
) -> String? {
  let prefix = "\"\{field_name}\""
  let lines = json_text.split("\n").map(line => line.trim().to_string()).collect()
  for line in lines {
    if line.has_prefix(prefix) {
      let parts = line.split(":").map(part => part.trim().to_string()).collect()
      if parts.length() >= 2 {
        let value = parts[1]
          .trim_start(chars="\"")
          .trim_end(chars="\",")
          .to_string()
        if value == "null" || value == "" {
          return None
        }
        return Some(value)
      }
    }
  }
  None
}

///|
/// 根据模式渲染对外展示的复检来源标签。
pub fn render_mode_label(mode : String) -> String {
  match mode {
    "pr" => "PR 复检"
    "ci" => "CI 复检"
    _ => "本地暂存区检查"
  }
}

///|
/// 将 base/head 或 PR 号整理成简洁的线路摘要。
pub fn render_route_summary(
  base_ref : String?,
  head_ref : String?,
  pr_number : String?,
) -> String {
  match (base_ref, head_ref, pr_number) {
    (Some(base), Some(head), Some(pr)) => "#\{pr} \{base} -> \{head}"
    (Some(base), Some(head), None) => "\{base} -> \{head}"
    (None, None, Some(pr)) => "#\{pr}"
    _ => ""
  }
}

///|
/// 从 `run-context.json` 文本生成来源摘要，供 report/replay 复用。
pub fn render_run_context_summary(json_text : String) -> String {
  let mode = match extract_json_string_field(json_text, "mode") {
    Some(value) => value
    None => "local"
  }
  let route = render_route_summary(
    extract_json_string_field(json_text, "base_ref"),
    extract_json_string_field(json_text, "head_ref"),
    extract_json_string_field(json_text, "pr_number"),
  )
  let label = render_mode_label(mode)
  if route == "" {
    label
  } else {
    "\{label}: \{route}"
  }
}
