///|
/// 最小 YAML 结果对象，只支持标量和一级字符串列表。
pub struct FlatYaml {
  scalars : Map[String, String]
  lists : Map[String, Array[String]]
} derive(Show)

///|
/// 读取某个标量字段，不存在时返回 None。
pub fn FlatYaml::get_scalar(self : FlatYaml, key : String) -> String? {
  self.scalars.get(key)
}

///|
/// 读取某个列表字段，不存在时返回空数组。
pub fn FlatYaml::get_list(self : FlatYaml, key : String) -> Array[String] {
  self.lists.get_or_default(key, [])
}

///|
/// 去掉 YAML 字符串值外围的双引号。
fn unquote(value : String) -> String {
  if value.length() >= 2 && value.has_prefix("\"") && value.has_suffix("\"") {
    value[1:value.length() - 1].to_string()
  } else {
    value
  }
}

///|
/// 解析最小子集 YAML，专门服务本项目的规则与任务文件。
pub fn parse_flat_yaml(text : String) -> FlatYaml raise {
  let scalars : Map[String, String] = {}
  let lists : Map[String, Array[String]] = {}
  let mut current_list_key : String? = None

  for
    raw_line in text
    .split("\n")
    .map(line => line.trim_end(chars="\r").to_string())
    .collect() {
    let trimmed = raw_line.trim().to_string()
    if trimmed == "" || trimmed.has_prefix("#") {
      continue
    }

    let indent = raw_line.length() - raw_line.trim_start(chars=" ").length()
    if indent == 0 {
      if trimmed.has_suffix(":") {
        let key = trimmed.trim_end(chars=":").to_string()
        current_list_key = Some(key)
        lists[key] = []
      } else if trimmed.contains(":") {
        guard trimmed.split_once(":") is Some((key, value)) else {
          raise Failure::Failure("Malformed YAML line: \{trimmed}")
        }
        scalars[key.trim().to_string()] = unquote(value.trim().to_string())
        current_list_key = None
      } else {
        raise Failure::Failure("Unsupported YAML line: \{trimmed}")
      }
      continue
    }

    guard indent >= 2 && trimmed.has_prefix("- ") else {
      raise Failure::Failure(
        "Only flat list YAML is supported, got: \{trimmed}",
      )
    }
    guard current_list_key is Some(key) else {
      raise Failure::Failure("List item appears before a key: \{trimmed}")
    }
    guard trimmed.split_once(" ") is Some((_, raw_value)) else {
      raise Failure::Failure("Malformed list entry: \{trimmed}")
    }
    let next_values = lists.get_or_default(key, [])
    next_values.push(unquote(raw_value.trim().to_string()))
    lists[key] = next_values
  }

  { scalars, lists }
}

///|
/// 从文件读取 YAML 文本并转成最小结构对象。
pub fn read_flat_yaml(path : String) -> FlatYaml raise {
  parse_flat_yaml(read_text(path))
}
