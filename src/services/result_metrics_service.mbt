///|
/// 文件说明：解析 scope 与 artifact 结果文件中的关键计数，供 report、replay、pack 等命令复用。

///|
/// 从简单 JSON 文本中提取一个整数字段，解析失败时返回 `None`。
pub fn extract_json_int_field(json_text : String, field_name : String) -> Int? {
  let prefix = "\"\{field_name}\""
  let lines = json_text
    .split("\n")
    .map(line => line.trim().to_string())
    .collect()
  for line in lines {
    if line.has_prefix(prefix) {
      let parts = line.split(":").map(part => part.trim().to_string()).collect()
      if parts.length() >= 2 {
        let value = parts[1].trim_end(chars=",").to_string()
        if value == "null" || value == "" {
          return None
        }
        return Some(@string.parse_int(value) catch { _ => return None })
      }
    }
  }
  None
}

///|
/// 统计指定 JSON 数组字段里包含多少项，字段不存在时返回 `0`。
pub fn extract_json_array_length(
  json_text : String,
  field_name : String,
) -> Int {
  let prefix = "\"\{field_name}\""
  let lines = json_text
    .split("\n")
    .map(line => line.trim().to_string())
    .collect()
  let mut inside_target = false
  let mut item_count = 0
  for line in lines {
    if !inside_target && line.has_prefix(prefix) {
      if line.contains("[]") {
        return 0
      }
      inside_target = true
    } else if inside_target {
      if line == "]" || line == "]," {
        return item_count
      }
      if line.has_prefix("\"") || line.has_prefix("{") {
        item_count = item_count + 1
      }
    }
  }
  item_count
}

///|
/// 把 scope 与 artifact 结果中的关键计数组装成终端可读摘要。
pub fn render_result_metrics_summary(
  scope_json : String?,
  artifact_json : String?,
) -> String {
  let parts : Array[String] = []

  match scope_json {
    Some(scope_text) =>
      match extract_json_int_field(scope_text, "changed_file_count") {
        Some(count) => parts.push("变更文件：\{count}")
        None => ()
      }
    None => ()
  }

  match artifact_json {
    Some(artifact_text) => {
      let missing_count = extract_json_array_length(
        artifact_text, "missing_artifacts",
      )
      let invalid_count = extract_json_array_length(
        artifact_text, "invalid_artifacts",
      )
      let command_failure_count = extract_json_array_length(
        artifact_text, "command_failures",
      )
      parts.push("缺失材料：\{missing_count}")
      parts.push("无效材料：\{invalid_count}")
      parts.push("命令失败：\{command_failure_count}")
    }
    None => ()
  }

  parts.join("，")
}
