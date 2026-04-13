///|
/// 文件说明：扫描补丁新增内容中的调试残留与临时标记，供提交前门禁规则直接复用。
/// 联动文件：由 `src/checkers/gate.mbt` 调用，规则模式来自 `repo-rules.yml` 的 `content_blocklist_patterns`。

///|
/// 从补丁新增内容中提取命中内容黑名单的文件列表。
pub fn find_blocklisted_files(
  diff_text : String,
  patterns : Array[String],
) -> Array[String] {
  let hits : Array[String] = []
  let mut current_file = ""
  for raw_line in diff_text.split("\n").map(item => item.to_string()).collect() {
    if raw_line.has_prefix("+++ b/") {
      current_file = raw_line[6:raw_line.length()].to_string()
      continue
    }
    if !raw_line.has_prefix("+") || raw_line.has_prefix("+++") {
      continue
    }
    for pattern in patterns {
      if pattern.trim() != "" &&
        current_file != "" &&
        raw_line.contains(pattern) &&
        !hits.contains(current_file) {
        hits.push(current_file)
      }
    }
  }
  hits
}
