///|
/// 文件说明：集中读取 git 仓库上下文，负责回答“当前项目是谁、暂存了哪些文件、staged diff 是什么”。
/// 联动文件：被 task 自动补全、check 自动 staged diff、项目上下文服务和后续历史索引复用。

///|
/// 执行一条 git 命令，并在失败时把 stderr 拼进错误信息，方便上层直接定位问题。
fn run_git_command(
  repo_root : String,
  command : String,
) -> @domain.ProcessCapture raise {
  let full_command = "git -C \{shell_quote(repo_root)} \{command}"
  let result = run_shell_capture(full_command, ".")
  if result.is_ok() {
    result
  } else {
    let message = result.preferred_message().trim().to_string()
    if message == "" {
      raise Failure::Failure("Git command failed: \{full_command}")
    } else {
      raise Failure::Failure("Git command failed: \{full_command}: \{message}")
    }
  }
}

///|
/// 把多行命令输出整理成去空白、去空行后的数组，便于后续逐行解析。
fn split_non_empty_lines(text : String) -> Array[String] {
  text
  .split("\n")
  .map(line => line.trim().to_string())
  .filter(line => line != "")
  .collect()
}

///|
/// 返回给定目录所在 git 仓库的根目录。
/// 入参：`start_dir`，用户当前目录或工具推断出来的候选目录。
/// 出参：git 根目录的绝对或相对路径文本。
pub fn resolve_git_repo_root(start_dir : String) -> String raise {
  let result = run_git_command(start_dir, "rev-parse --show-toplevel")
  result.stdout.trim().to_string()
}

///|
/// 读取当前 git 分支名称。
/// 入参：`repo_root`，目标仓库根目录。
/// 出参：当前分支名称，例如 `main` 或 `feature/moonforge`。
pub fn read_current_branch(repo_root : String) -> String raise {
  let result = run_git_command(repo_root, "rev-parse --abbrev-ref HEAD")
  result.stdout.trim().to_string()
}

///|
/// 读取暂存区的补丁文本。
/// 入参：`repo_root`，目标仓库根目录。
/// 出参：`git diff --cached` 的完整文本。
pub fn read_staged_diff(repo_root : String) -> String raise {
  let result = run_git_command(repo_root, "diff --cached")
  result.stdout
}

///|
/// 判断某个 git 引用是否已经存在于当前仓库。
/// 这一步主要给 PR 比对场景复用，避免直接假设 `origin/main` 一定存在。
fn git_ref_exists(repo_root : String, git_ref : String) -> Bool {
  let command =
    "git -C \{shell_quote(repo_root)} rev-parse --verify \{shell_quote(git_ref)}"
  let result = run_shell_capture(command, ".") catch {
    _ => return false
  }
  result.is_ok()
}

///|
/// 读取最近一次提交相对于上一个提交的完整补丁。
/// 线上普通 CI 场景没有暂存区时，可以用这份 diff 代表“这次构建新带来的代码变化”。
pub fn read_head_commit_diff(repo_root : String) -> String raise {
  let result = run_git_command(repo_root, "diff --binary HEAD^ HEAD")
  result.stdout
}

///|
/// 读取当前 HEAD 相对于 PR base 的完整补丁。
/// 优先使用 `origin/<base>`，如果本地只有同名分支，就退回到本地分支名。
/// 当远端引用还没拉下来时，会先尝试执行一次 `git fetch origin <base> --depth=1`。
pub fn read_pr_compare_diff(repo_root : String, base_ref : String) -> String raise {
  let trimmed = base_ref.trim().to_string()
  if trimmed == "" {
    raise Failure::Failure("PR base ref is empty")
  }
  let origin_ref = "origin/\{trimmed}"
  if !git_ref_exists(repo_root, origin_ref) {
    let fetch_command =
      "git -C \{shell_quote(repo_root)} fetch --quiet --depth=1 origin \{shell_quote(trimmed)}"
    ignore(run_shell_command(fetch_command, ".") catch { _ => 1 })
  }
  let base_target = if git_ref_exists(repo_root, origin_ref) {
    origin_ref
  } else if git_ref_exists(repo_root, trimmed) {
    trimmed
  } else {
    raise Failure::Failure("PR base ref not found in repository: \{trimmed}")
  }
  let merge_base_result = run_git_command(
    repo_root,
    "merge-base \{shell_quote(base_target)} HEAD",
  )
  let merge_base = merge_base_result.stdout.trim().to_string()
  if merge_base == "" {
    raise Failure::Failure("Failed to resolve merge-base for PR base ref: \{base_target}")
  }
  let diff_result = run_git_command(
    repo_root,
    "diff --binary \{shell_quote(merge_base)} HEAD",
  )
  diff_result.stdout
}

///|
/// 读取已暂存文件列表。
/// 入参：`repo_root`，目标仓库根目录。
/// 出参：按相对路径给出的已暂存文件数组。
pub fn read_staged_files(repo_root : String) -> Array[String] raise {
  let result = run_git_command(
    repo_root, "diff --cached --name-only --diff-filter=ACMR",
  )
  split_non_empty_lines(result.stdout)
}

///|
/// 读取未暂存文件列表。
/// 入参：`repo_root`，目标仓库根目录。
/// 出参：工作区中尚未进入暂存区的文件数组。
pub fn read_unstaged_files(repo_root : String) -> Array[String] raise {
  let result = run_git_command(repo_root, "diff --name-only")
  split_non_empty_lines(result.stdout)
}

///|
/// 读取未跟踪文件列表。
/// 入参：`repo_root`，目标仓库根目录。
/// 出参：还未进入 git 跟踪范围的文件数组。
pub fn read_untracked_files(repo_root : String) -> Array[String] raise {
  let result = run_git_command(
    repo_root, "ls-files --others --exclude-standard",
  )
  split_non_empty_lines(result.stdout)
}

///|
/// 读取 git status porcelain 并解析成结构化数组。
/// 入参：`repo_root`，目标仓库根目录。
/// 出参：每条状态记录都被解析成 `GitStatusEntry`。
pub fn read_status_entries(
  repo_root : String,
) -> Array[@domain.GitStatusEntry] raise {
  let result = run_git_command(repo_root, "status --short --porcelain")
  let entries : Array[@domain.GitStatusEntry] = []
  for line in split_non_empty_lines(result.stdout) {
    entries.push(@domain.GitStatusEntry::from_porcelain_line(line))
  }
  entries
}

///|
/// 读取当前仓库的完整 git 快照，供上层一次性拿到最常用的上下文字段。
/// 入参：`repo_root`，目标仓库根目录。
/// 出参：包含分支、staged 文件、unstaged 文件、untracked 文件和 staged diff 的快照对象。
pub fn read_git_project_snapshot(
  repo_root : String,
) -> @domain.GitProjectSnapshot {
  let branch_name = read_current_branch(repo_root) catch { _ => "" }
  let staged_files = read_staged_files(repo_root) catch { _ => [] }
  let unstaged_files = read_unstaged_files(repo_root) catch { _ => [] }
  let untracked_files = read_untracked_files(repo_root) catch { _ => [] }
  let status_entries = read_status_entries(repo_root) catch { _ => [] }
  let staged_diff = read_staged_diff(repo_root) catch { _ => "" }
  @domain.GitProjectSnapshot::{
    repo_root,
    branch_name,
    staged_files,
    unstaged_files,
    untracked_files,
    status_entries,
    staged_diff,
  }
}
