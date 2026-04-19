///|
/// 文件总说：
/// 这个文件负责“把项目里可能放材料的几个地方都找一遍”。
/// 最终目标只有一个：用户别为了跑一次 check 还得每次告诉工具材料路径。
///
/// 工作顺序很简单：
/// 1. 先读项目默认材料目录册
/// 2. 再结合当前任务文件里的 `artifact_dir`
/// 3. 把候选目录按优先顺序排好
/// 4. 对每个必需材料依次搜索候选文件名
/// 5. 返回找到的内容和搜索说明

///|
/// 返回默认材料目录册。
/// 这份目录册会在仓库还没有写出 `material-catalog.yml` 时作为兜底。
pub fn default_material_catalog() -> @domain.MaterialCatalog {
  @domain.MaterialCatalog::{
    directories: [
      @domain.MaterialDirectorySpec::{
        name: "current",
        directory: ".moonforge/artifacts/current",
        description: "当前任务正在写入的材料目录",
      },
      @domain.MaterialDirectorySpec::{
        name: "latest",
        directory: ".moonforge/artifacts/latest",
        description: "最近一次人工整理出来的材料目录",
      },
      @domain.MaterialDirectorySpec::{
        name: "latest_output",
        directory: ".moonforge/out/local/latest",
        description: "最近一次本地检查结果目录",
      },
    ],
    artifact_aliases: {
      "review-report.json": ["review-report.json", "review-report.md"],
      "test-report.json": ["test-report.json", "test-report.md"],
      "preview-report.json": ["preview-report.json", "preview-report.md"],
      "coverage-report.json": ["coverage-report.json", "coverage-summary.json"],
    },
    preferred_directory_names: ["current", "latest", "latest_output"],
  }
}

///|
/// 读取项目材料目录册；文件不存在时回退到默认目录册。
pub fn load_material_catalog(
  repo_root : String,
) -> @domain.MaterialCatalog raise {
  let path = @infra.material_catalog_path(repo_root)
  if @infra.path_exists(path) {
    @infra.read_material_catalog(path)
  } else {
    default_material_catalog()
  }
}

///|
/// 把目录定义转成真正的目录路径。
/// 相对路径默认相对仓库根目录展开。
fn resolve_directory_path(repo_root : String, directory : String) -> String {
  let trimmed = directory.trim().to_string()
  if trimmed == "" {
    repo_root
  } else if trimmed.has_prefix("/") {
    @infra.normalize_path(trimmed)
  } else {
    @infra.join_path(repo_root, trimmed)
  }
}

///|
/// 计算材料搜索目录的最终顺序。
/// 顺序来源有三层：
/// 1. 当前任务明确写的 `artifact_dir`
/// 2. 目录册里声明的 preferred 目录
/// 3. 目录册里其余未被 preferred 覆盖的目录
pub fn resolve_search_directories(
  repo_root : String,
  current_task : @domain.CurrentTask,
  catalog : @domain.MaterialCatalog,
) -> Array[String] {
  let directories : Array[String] = []
  let task_dir = current_task.artifact_dir.trim().to_string()
  if task_dir != "" {
    directories.push(resolve_directory_path(repo_root, task_dir))
  }

  for preferred_name in catalog.preferred_directory_names {
    for directory in catalog.directories {
      if directory.name == preferred_name {
        let resolved = resolve_directory_path(repo_root, directory.directory)
        if !directories.contains(resolved) {
          directories.push(resolved)
        }
      }
    }
  }

  for directory in catalog.directories {
    let resolved = resolve_directory_path(repo_root, directory.directory)
    if !directories.contains(resolved) {
      directories.push(resolved)
    }
  }

  directories
}

///|
/// 在一个目录列表里为单个材料搜索候选文件。
fn discover_single_artifact(
  search_directories : Array[String],
  artifact_name : String,
  candidate_names : Array[String],
) -> @domain.MaterialDiscoveryRecord raise {
  for directory in search_directories {
    for candidate_name in candidate_names {
      let candidate_path = @infra.join_path(directory, candidate_name)
      if @infra.path_exists(candidate_path) {
        return @domain.MaterialDiscoveryRecord::{
          artifact_name,
          searched_directories: search_directories,
          matched_path: Some(candidate_path),
          matched_name: Some(candidate_name),
          note: "系统在候选目录里找到了材料文件",
        }
      }
    }
  }
  @domain.MaterialDiscoveryRecord::{
    artifact_name,
    searched_directories: search_directories,
    matched_path: None,
    matched_name: None,
    note: "系统已经搜索完候选目录，但没有找到材料文件",
  }
}

///|
/// 对所有必需材料执行一次搜索。
/// 找到的材料会直接读成内容，方便后面交给 gate 使用。
pub fn discover_required_artifacts(
  repo_root : String,
  current_task : @domain.CurrentTask,
  required_artifacts : Array[String],
) -> @domain.MaterialDiscoveryResult raise {
  let catalog = load_material_catalog(repo_root)
  let search_directories = resolve_search_directories(
    repo_root, current_task, catalog,
  )
  let records : Array[@domain.MaterialDiscoveryRecord] = []
  let provided_artifacts : Map[String, String] = {}

  for artifact_name in required_artifacts {
    let record = discover_single_artifact(
      search_directories,
      artifact_name,
      catalog.candidate_names_for(artifact_name),
    )
    records.push(record)
    match record.matched_path {
      Some(path) =>
        match @infra.read_text_if_exists(path) {
          Some(content) => provided_artifacts[artifact_name] = content
          None => ()
        }
      None => ()
    }
  }

  @domain.MaterialDiscoveryResult::{
    provided_artifacts,
    records,
    searched_directories: search_directories,
  }
}
