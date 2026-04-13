///|
/// 文件说明：解析标准 git patch 文本，提取本次变更真正触碰的文件路径。
/// 联动文件：由 `src/checkers/gate.mbt` 复用，也为本地与 CI 差异适配器后的统一解析入口提供支持。

///|
/// 从标准 git diff 文本中提取去重后的变更文件路径。
pub fn parse_changed_files(diff_text : String) -> Array[String] {
  let touched : Array[String] = []
  for
    line in diff_text.split("\n").map(item => item.trim().to_string()).collect() {
    if line.has_prefix("diff --git a/") {
      let tokens = line.split(" ").map(token => token.to_string()).collect()
      if tokens.length() >= 4 {
        let left = tokens[2]
        if left.has_prefix("a/") {
          touched.push(left[2:left.length()].to_string())
        } else {
          touched.push(left)
        }
      }
    }
  }
  unique_strings(touched)
}
