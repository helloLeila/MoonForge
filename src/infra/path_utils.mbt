///|
/// 文件说明：提供路径标准化、目录拼接、后缀判断和最小 glob 匹配能力，是门禁范围判定的基础组件。
/// 联动文件：被 `src/checkers/gate.mbt` 用于路径命中判断，也被 `src/services/commands.mbt` 和测试代码复用。

///|

///|
/// 统一路径分隔符和尾部斜杠，保证后续匹配行为稳定。
pub fn normalize_path(path : String) -> String {
  let replaced = path.replace(old="\\", new="/").trim().to_string()
  if replaced == "/" {
    replaced
  } else {
    replaced.trim_end(chars="/").to_string()
  }
}

///|
/// 将路径拆成段数组，供 glob 匹配和目录运算复用。
pub fn split_path(path : String) -> Array[String] {
  let normalized = normalize_path(path)
  if normalized == "" || normalized == "." || normalized == "/" {
    []
  } else {
    normalized
    .split("/")
    .map(segment => segment.trim().to_string())
    .filter(segment => segment != "")
    .collect()
  }
}

///|
/// 以平台无关方式拼接两个路径片段。
pub fn join_path(base : String, child : String) -> String {
  let left = normalize_path(base)
  let right = normalize_path(child)
  if right == "" {
    left
  } else if right.has_prefix("/") {
    right
  } else if left == "" || left == "." {
    right
  } else if left == "/" {
    "/" + right
  } else {
    left + "/" + right
  }
}

///|
/// 提取路径的最后一个文件名或目录名。
pub fn basename(path : String) -> String {
  let parts = split_path(path)
  if parts.is_empty() {
    normalize_path(path)
  } else {
    parts[parts.length() - 1]
  }
}

///|
/// 提取路径的父目录，便于写文件前创建目录。
pub fn dirname(path : String) -> String {
  let normalized = normalize_path(path)
  let absolute = normalized.has_prefix("/")
  let parts = split_path(normalized)
  if parts.length() <= 1 {
    if absolute {
      "/"
    } else {
      "."
    }
  } else {
    let parent : Array[String] = []
    for i in 0..<(parts.length() - 1) {
      parent.push(parts[i])
    }
    let body = parent.join("/")
    if absolute {
      "/" + body
    } else {
      body
    }
  }
}

///|
/// 在保持原顺序的前提下对字符串数组去重。
pub fn unique_strings(values : Array[String]) -> Array[String] {
  let output : Array[String] = []
  for value in values {
    if !output.contains(value) {
      output.push(value)
    }
  }
  output
}

///|
/// 提取文件后缀，未命中时返回空字符串。
pub fn extension_of(path : String) -> String {
  let name = basename(path)
  guard name.contains(".") else { return "" }
  let parts = name.split(".").map(segment => segment.to_string()).collect()
  if parts.length() <= 1 {
    ""
  } else {
    "." + parts[parts.length() - 1]
  }
}

///|
/// 判断文件后缀或显式允许文件名是否命中允许列表。
pub fn has_allowed_extension(path : String, allowed : Array[String]) -> Bool {
  if allowed.is_empty() {
    true
  } else {
    let name = basename(path)
    allowed.contains(name) || allowed.contains(extension_of(path))
  }
}

///|
/// 比较单个路径段是否匹配模式段。
fn match_segment(path_segment : String, pattern_segment : String) -> Bool {
  pattern_segment == "*" || path_segment == pattern_segment
}

///|
/// 递归执行 `*` 和 `**` 规则的段级匹配。
fn match_segments(
  path_segments : Array[String],
  path_index : Int,
  pattern_segments : Array[String],
  pattern_index : Int,
) -> Bool {
  if pattern_index >= pattern_segments.length() {
    return path_index >= path_segments.length()
  }

  let pattern_segment = pattern_segments[pattern_index]
  if pattern_segment == "**" {
    if pattern_index + 1 >= pattern_segments.length() {
      return true
    }
    for next_index in path_index..<(path_segments.length() + 1) {
      if match_segments(
          path_segments,
          next_index,
          pattern_segments,
          pattern_index + 1,
        ) {
        return true
      }
    }
    return false
  }

  if path_index >= path_segments.length() {
    return false
  }

  if !match_segment(path_segments[path_index], pattern_segment) {
    return false
  }

  match_segments(
    path_segments,
    path_index + 1,
    pattern_segments,
    pattern_index + 1,
  )
}

///|
/// 对外暴露的最小 glob 匹配能力。
pub fn match_glob(path : String, pattern : String) -> Bool {
  let normalized_path = normalize_path(path)
  let normalized_pattern = normalize_path(pattern)
  if normalized_pattern == "" {
    normalized_path == ""
  } else {
    match_segments(
      split_path(normalized_path),
      0,
      split_path(normalized_pattern),
      0,
    )
  }
}

///|
/// 判断一个路径是否命中任意一条规则。
pub fn matches_any(path : String, patterns : Array[String]) -> Bool {
  for pattern in patterns {
    if match_glob(path, pattern) {
      return true
    }
  }
  false
}
