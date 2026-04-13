///|
/// 文件说明：提供路径组展开能力，把命名组解析成可直接匹配的 glob 列表。
/// 输入：路径组映射与待展开的组名数组。
/// 输出：按输入顺序展开后的唯一 glob 列表；当组名不存在时抛出错误。

///|
/// 将命名路径组展开为具体 glob，并在缺少组名时返回明确错误。
pub fn expand_target_groups(
  groups : Map[String, Array[String]],
  names : Array[String],
) -> Array[String] raise {
  let output : Array[String] = []
  for name in names {
    guard groups.get(name) is Some(paths) else {
      raise Failure::Failure("PATH_GROUP_NOT_FOUND")
    }
    for path in paths {
      output.push(path)
    }
  }
  unique_strings(output)
}
