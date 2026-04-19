///|
/// 文件总说：
/// 这个文件负责把材料目录册写成 YAML，也负责从 YAML 读回结构化对象。
/// 目录册的目的是让 `check` 不必死盯一个目录，而是能按项目习惯去搜索材料。

///|
/// 返回材料目录册文件路径。
pub fn material_catalog_path(repo_root : String) -> String {
  join_path(repo_root, ".moonforge/material-catalog.yml")
}

///|
/// 渲染目录册中的目录定义块。
fn render_directory_blocks(
  directories : Array[@domain.MaterialDirectorySpec],
) -> Array[String] {
  let lines : Array[String] = []
  for directory in directories {
    lines.push("directories.\{directory.name}: \"\{directory.directory}\"")
    lines.push(
      "directory_descriptions.\{directory.name}: \"\{directory.description}\"",
    )
  }
  lines
}

///|
/// 渲染目录册中的别名列表块。
fn render_alias_blocks(aliases : Map[String, Array[String]]) -> Array[String] {
  let blocks : Array[String] = []
  aliases.each((artifact_name, names) => {
    let lines : Array[String] = ["aliases.\{artifact_name}:"]
    for name in names {
      lines.push("  - \"\{name}\"")
    }
    blocks.push(lines.join("\n"))
  })
  blocks
}

///|
/// 渲染材料目录册 YAML。
pub fn render_material_catalog(catalog : @domain.MaterialCatalog) -> String {
  let sections : Array[String] = [
    render_material_list_block(
      "preferred_directory_names",
      catalog.preferred_directory_names,
    ),
  ]
  for line in render_directory_blocks(catalog.directories) {
    sections.push(line)
  }
  for block in render_alias_blocks(catalog.artifact_aliases) {
    sections.push(block)
  }
  sections.join("\n\n") + "\n"
}

///|
/// 读取材料目录册 YAML。
pub fn read_material_catalog(path : String) -> @domain.MaterialCatalog raise {
  let yaml = read_flat_yaml(path)
  let directories_by_name = yaml.get_scalars_with_prefix("directories.")
  let descriptions_by_name = yaml.get_scalars_with_prefix(
    "directory_descriptions.",
  )
  let directories : Array[@domain.MaterialDirectorySpec] = []
  directories_by_name.each((name, directory) => {
    directories.push(@domain.MaterialDirectorySpec::{
      name,
      directory,
      description: descriptions_by_name.get_or_default(name, ""),
    })
  })
  @domain.MaterialCatalog::{
    directories,
    artifact_aliases: yaml.get_lists_with_prefix("aliases."),
    preferred_directory_names: yaml.get_list("preferred_directory_names"),
  }
}

///|
/// 这个文件也需要一个最小列表渲染能力。
fn render_material_list_block(key : String, values : Array[String]) -> String {
  let lines : Array[String] = ["\{key}:"]
  for value in values {
    lines.push("  - \"\{value}\"")
  }
  lines.join("\n")
}
