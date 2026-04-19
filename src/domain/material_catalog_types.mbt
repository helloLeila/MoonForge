///|
/// 文件总说：
/// 这个文件定义“材料应该去哪找、怎么找、找到了要怎么记录”这套模型。
/// 这块的目标很明确：
/// - 让用户少输路径
/// - 让 check 能按项目默认习惯去搜索材料
/// - 让 report 能解释“系统到底从哪里找到材料”

///|
/// 一条材料目录定义。
/// 它表示系统可以去某个目录里找材料，并带上这个目录的中文说明。
pub(all) struct MaterialDirectorySpec {
  name : String
  directory : String
  description : String
} derive(Debug, ToJson)

///|
/// 目录定义摘要。
pub fn MaterialDirectorySpec::summary(self : MaterialDirectorySpec) -> String {
  "\{self.name} -> \{self.directory}"
}

///|
/// 项目级材料目录目录册。
/// 里面同时记录：
/// - 候选材料目录
/// - 每种材料的别名文件名
/// - 默认优先顺序
pub(all) struct MaterialCatalog {
  directories : Array[MaterialDirectorySpec]
  artifact_aliases : Map[String, Array[String]]
  preferred_directory_names : Array[String]
} derive(Debug, ToJson)

///|
/// 判断目录册里是否至少定义了一个候选目录。
pub fn MaterialCatalog::has_directories(self : MaterialCatalog) -> Bool {
  !self.directories.is_empty()
}

///|
/// 读取某种材料的候选文件名列表。
/// 如果没有单独定义别名，就退回到材料自己的文件名。
pub fn MaterialCatalog::candidate_names_for(
  self : MaterialCatalog,
  artifact_name : String,
) -> Array[String] {
  match self.artifact_aliases.get(artifact_name) {
    Some(names) => if names.is_empty() { [artifact_name] } else { names }
    None => [artifact_name]
  }
}

///|
/// 一条材料发现记录。
/// 这里会记录系统到底试了哪些目录、最后是在哪个位置命中的。
pub(all) struct MaterialDiscoveryRecord {
  artifact_name : String
  searched_directories : Array[String]
  matched_path : String?
  matched_name : String?
  note : String
} derive(Debug, ToJson)

///|
/// 判断这条发现记录是否真的命中了材料。
pub fn MaterialDiscoveryRecord::found(self : MaterialDiscoveryRecord) -> Bool {
  self.matched_path is Some(_)
}

///|
/// 一次完整的材料发现结果。
/// 上层真正关心的通常有两部分：
/// - `provided_artifacts`：最后可直接交给 gate 的材料内容
/// - `records`：为什么找到或没找到
pub(all) struct MaterialDiscoveryResult {
  provided_artifacts : Map[String, String]
  records : Array[MaterialDiscoveryRecord]
  searched_directories : Array[String]
} derive(Debug, ToJson)

///|
/// 返回已命中材料数量。
pub fn MaterialDiscoveryResult::found_count(
  self : MaterialDiscoveryResult,
) -> Int {
  self.provided_artifacts.length()
}

///|
/// 生成材料发现摘要。
pub fn MaterialDiscoveryResult::summary(
  self : MaterialDiscoveryResult,
) -> String {
  "directories=\{self.searched_directories.length()} / found=\{self.found_count()} / records=\{self.records.length()}"
}
