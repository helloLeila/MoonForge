///|
/// 文件说明：定义 git 工作区读取时使用的结构化对象，负责把 staged、unstaged、untracked 等状态说清楚。
/// 联动文件：由 `src/infra/git_repo_reader.mbt` 生成，再被 task 自动补全、check 自动输入和项目上下文服务复用。

///|
/// 一条 git status porcelain 记录的结构化表示。
/// `staged_code` 对应第一列，`unstaged_code` 对应第二列。
pub(all) struct GitStatusEntry {
  staged_code : String
  unstaged_code : String
  path : String
  previous_path : String?
  is_staged : Bool
  is_unstaged : Bool
  is_untracked : Bool
} derive(Debug, ToJson)

///|
/// 把 git porcelain 中的一条原始记录解析成结构化对象。
/// 入参：一行类似 `"A  src/app.ts"` 或 `"R  old.ts -> new.ts"` 的文本。
/// 出参：解析后的 `GitStatusEntry`，若格式不合法则抛错。
pub fn GitStatusEntry::from_porcelain_line(
  line : String,
) -> GitStatusEntry raise {
  if line.length() < 3 {
    raise Failure::Failure("Invalid git status line: \{line}")
  }

  let staged_code = line[0:1].to_string()
  let unstaged_code = line[1:2].to_string()
  let payload = line[3:line.length()].trim().to_string()

  if payload.contains(" -> ") {
    let parts = payload
      .split(" -> ")
      .map(item => item.trim().to_string())
      .collect()
    if parts.length() != 2 {
      raise Failure::Failure("Invalid renamed git status line: \{line}")
    }
    GitStatusEntry::{
      staged_code,
      unstaged_code,
      path: parts[1],
      previous_path: Some(parts[0]),
      is_staged: staged_code != " " && staged_code != "?",
      is_unstaged: unstaged_code != " ",
      is_untracked: staged_code == "?" || unstaged_code == "?",
    }
  } else {
    GitStatusEntry::{
      staged_code,
      unstaged_code,
      path: payload,
      previous_path: None,
      is_staged: staged_code != " " && staged_code != "?",
      is_unstaged: unstaged_code != " ",
      is_untracked: staged_code == "?" || unstaged_code == "?",
    }
  }
}

///|
/// 返回更适合给人看的状态标签。
/// 入参：一条 git 状态记录。
/// 出参：例如“已暂存”“未暂存”“未跟踪”的中文标签。
pub fn GitStatusEntry::label(self : GitStatusEntry) -> String {
  if self.is_untracked {
    "未跟踪"
  } else if self.is_staged && self.is_unstaged {
    "已暂存且有未暂存改动"
  } else if self.is_staged {
    "已暂存"
  } else if self.is_unstaged {
    "未暂存"
  } else {
    "无状态"
  }
}

///|
/// 一次读取当前 git 工作区时得到的完整快照。
pub(all) struct GitProjectSnapshot {
  repo_root : String
  branch_name : String
  staged_files : Array[String]
  unstaged_files : Array[String]
  untracked_files : Array[String]
  status_entries : Array[GitStatusEntry]
  staged_diff : String
} derive(Debug, ToJson)

///|
/// 判断当前仓库是否存在至少一个已暂存文件。
/// 入参：git 项目快照。
/// 出参：已暂存文件非空时返回 `true`。
pub fn GitProjectSnapshot::has_staged_changes(
  self : GitProjectSnapshot,
) -> Bool {
  !self.staged_files.is_empty()
}

///|
/// 生成适合终端显示的简短快照摘要。
/// 入参：git 项目快照。
/// 出参：分支、已暂存文件数、未暂存文件数和未跟踪文件数的中文文本。
pub fn GitProjectSnapshot::summary(self : GitProjectSnapshot) -> String {
  "分支：\{self.branch_name}；已暂存：\{self.staged_files.length()}；未暂存：\{self.unstaged_files.length()}；未跟踪：\{self.untracked_files.length()}"
}
