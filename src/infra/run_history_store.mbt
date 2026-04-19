///|
/// 文件总说：
/// 这个文件负责把运行历史写到磁盘，再从磁盘读回来。
/// 这里故意没有走复杂数据库，也没有走完整 JSON 反序列化，
/// 而是选择一种很朴素的分块文本格式：
/// - 每次运行是一块
/// - 块和块之间用 `---` 隔开
/// - 块内部还是简单的 `key: value`
///
/// 这么做有两个好处：
/// 1. 人能直接打开历史文件看懂
/// 2. 解析逻辑足够稳定，MoonBit 里也容易维护

///|
/// 返回运行历史目录。
pub fn run_history_dir(repo_root : String) -> String {
  join_path(repo_root, ".moonforge/history")
}

///|
/// 返回运行历史索引文件路径。
pub fn run_history_index_path(repo_root : String) -> String {
  join_path(run_history_dir(repo_root), "run-history.log")
}

///|
/// 把任意字符串压缩成适合单行保存的文本。
/// 这里不追求复杂转义，只做一件对用户最有帮助的事：
/// 把换行替换成 ` / `，让历史文件保持一行一义。
fn sanitize_inline_text(text : String) -> String {
  text
  .split("\n")
  .map(line => line.trim().to_string())
  .collect()
  .filter(line => line != "")
  .join(" / ")
}

///|
/// 从最小 YAML 里读取必填标量。
fn required_scalar(yaml : FlatYaml, key : String) -> String raise {
  match yaml.get_scalar(key) {
    Some(value) => value
    None => raise Failure::Failure("Run history record missing field: \{key}")
  }
}

///|
/// 从最小 YAML 里读取整数字段。
fn required_int(yaml : FlatYaml, key : String) -> Int raise {
  @string.parse_int(required_scalar(yaml, key)) catch {
    err =>
      raise Failure::Failure(
        "Run history field \{key} is not a valid integer: \{err.to_string()}",
      )
  }
}

///|
/// 把一条历史记录渲染成一块可读文本。
pub fn render_run_history_record(record : @domain.RunHistoryRecord) -> String {
  [
    "run_id: \"\{sanitize_inline_text(record.run_id)}\"",
    "mode: \"\{sanitize_inline_text(record.mode)}\"",
    "decision: \"\{sanitize_inline_text(record.decision)}\"",
    "task_type: \"\{sanitize_inline_text(record.task_type)}\"",
    "title: \"\{sanitize_inline_text(record.title)}\"",
    "checked_file_count: \{record.checked_file_count}",
    "missing_artifact_count: \{record.missing_artifact_count}",
    "invalid_artifact_count: \{record.invalid_artifact_count}",
    "command_failure_count: \{record.command_failure_count}",
    "violation_count: \{record.violation_count}",
    "context_summary: \"\{sanitize_inline_text(record.context_summary)}\"",
    "next_action: \"\{sanitize_inline_text(record.next_action)}\"",
    "created_at_ns: \"\{sanitize_inline_text(record.created_at_ns)}\"",
  ].join("\n") +
  "\n"
}

///|
/// 从一块文本解析出一条历史记录。
pub fn parse_run_history_record(
  text : String,
) -> @domain.RunHistoryRecord raise {
  let yaml = parse_flat_yaml(text)
  @domain.RunHistoryRecord::{
    run_id: required_scalar(yaml, "run_id"),
    mode: required_scalar(yaml, "mode"),
    decision: required_scalar(yaml, "decision"),
    task_type: required_scalar(yaml, "task_type"),
    title: required_scalar(yaml, "title"),
    checked_file_count: required_int(yaml, "checked_file_count"),
    missing_artifact_count: required_int(yaml, "missing_artifact_count"),
    invalid_artifact_count: required_int(yaml, "invalid_artifact_count"),
    command_failure_count: required_int(yaml, "command_failure_count"),
    violation_count: required_int(yaml, "violation_count"),
    context_summary: required_scalar(yaml, "context_summary"),
    next_action: required_scalar(yaml, "next_action"),
    created_at_ns: required_scalar(yaml, "created_at_ns"),
  }
}

///|
/// 把整份历史索引渲染成磁盘文本。
pub fn render_run_history_index(index : @domain.RunHistoryIndex) -> String {
  let blocks : Array[String] = [
    "# MoonForge 运行历史", "# 先总说：这个文件按时间倒序记录最近几次门禁运行",
    "# 再分说：每一块是一条运行记录，块与块之间用 --- 分隔",
    "",
  ]
  for record in index.records {
    blocks.push(
      render_run_history_record(record).trim_end(chars="\n").to_string(),
    )
    blocks.push("---")
  }
  if !index.records.is_empty() {
    ignore(blocks.pop())
  }
  blocks.join("\n") + "\n"
}

///|
/// 从磁盘文本解析整份历史索引。
pub fn parse_run_history_index(text : String) -> @domain.RunHistoryIndex raise {
  let records : Array[@domain.RunHistoryRecord] = []
  let sections = text.split("\n---\n").map(item => item.to_string()).collect()
  for section in sections {
    let trimmed = section.trim().to_string()
    if trimmed == "" {
      continue
    }
    let useful_lines : Array[String] = []
    for line in trimmed.split("\n").map(item => item.to_string()).collect() {
      let normalized = line.trim_end(chars="\r").to_string()
      if normalized.trim().to_string().has_prefix("#") {
        continue
      }
      useful_lines.push(normalized)
    }
    let useful_text = useful_lines.join("\n").trim().to_string()
    if useful_text != "" {
      records.push(parse_run_history_record(useful_text))
    }
  }
  { records, }
}

///|
/// 把历史索引写入标准文件位置。
pub fn write_run_history_index(
  repo_root : String,
  index : @domain.RunHistoryIndex,
) -> Unit raise {
  ensure_dir(run_history_dir(repo_root))
  write_text(run_history_index_path(repo_root), render_run_history_index(index))
}

///|
/// 读取历史索引；文件不存在时返回空索引。
pub fn read_run_history_index(
  repo_root : String,
) -> @domain.RunHistoryIndex raise {
  let path = run_history_index_path(repo_root)
  match read_text_if_exists(path) {
    Some(text) => parse_run_history_index(text)
    None => { records: [] }
  }
}
