///|
/// 文件总说：
/// 这个文件负责把“用户只输入了 `moonforge check`”这件事补成真正可执行的输入。
/// 本地模式下，系统会自动做这些事：
/// 1. 读取当前 git 暂存区补丁
/// 2. 生成一次标准运行目录
/// 3. 写入 `patch.diff`
/// 4. 记录 `staged-files.txt` 和输入说明
/// 5. 计算默认材料目录
///
/// 这样用户就不用再手工准备 `--run /某个目录`，而是直接让工具自己把输入整理好。

///|
/// 把材料目录路径规范成可直接使用的绝对或仓库内路径。
/// 如果用户在 `current-task.yml` 里写的是相对路径，就默认相对仓库根目录展开。
pub fn resolve_artifact_source_dir(
  repo_root : String,
  current_task : @domain.CurrentTask,
) -> String {
  let configured = current_task.artifact_dir.trim().to_string()
  if configured == "" {
    @infra.join_path(repo_root, ".moonforge/artifacts/current")
  } else if configured.has_prefix("/") {
    @infra.normalize_path(configured)
  } else {
    @infra.join_path(repo_root, configured)
  }
}

///|
/// 生成本地输入目录里的说明文档。
/// 这份文档就是给人看的，所以写得尽量直白。
fn render_local_input_summary(input : @domain.LocalCheckInput) -> String {
  let lines : Array[String] = [
    "# 本地检查输入说明",
    "",
    "## 先总说",
    "这次 `moonforge check` 没有手工提供 --run，所以系统自动根据暂存区生成了输入目录。",
    "",
    "## 再分说",
    "- patch_path: \{input.patch_path}",
    "- artifact_source_dir: \{input.artifact_source_dir}",
    "- staged_files: \{input.staged_files.length()}",
    "",
    "## 看到的暂存文件",
  ]
  if input.staged_files.is_empty() {
    lines.push("- 无")
  } else {
    for file in input.staged_files {
      lines.push("- \{file}")
    }
  }
  if !input.notes.is_empty() {
    lines.push("")
    lines.push("## 系统说明")
    for note in input.notes {
      lines.push("- \{note}")
    }
  }
  lines.join("\n") + "\n"
}

///|
/// 准备本地检查输入。
/// 入参：
/// - `repo_root`：当前项目根目录
/// - `current_task`：当前任务文件
/// - `snapshot`：当前 git 快照
///
/// 主要步骤：
/// 1. 检查暂存区是否为空
/// 2. 创建 `.moonforge/runs/local-staged-时间戳/input`
/// 3. 写入 patch、暂存文件清单和说明文档
/// 4. 计算并创建默认材料目录
pub fn prepare_local_check_input(
  repo_root : String,
  current_task : @domain.CurrentTask,
  snapshot : @domain.GitProjectSnapshot,
) -> @domain.LocalCheckInput raise {
  if snapshot.staged_files.is_empty() || snapshot.staged_diff.trim() == "" {
    raise Failure::Failure(
      "当前暂存区为空，无法自动生成本地检查输入",
    )
  }

  let run_dir = @infra.join_path(
    repo_root,
    ".moonforge/runs/local-staged-\{@uv.hrtime()}/input",
  )
  let patch_path = @infra.join_path(run_dir, "patch.diff")
  let artifact_source_dir = resolve_artifact_source_dir(repo_root, current_task)
  @infra.ensure_dir(run_dir)
  @infra.ensure_dir(artifact_source_dir)
  @infra.write_text(patch_path, snapshot.staged_diff)
  @infra.write_text(
    @infra.join_path(run_dir, "staged-files.txt"),
    snapshot.staged_files.join("\n") + "\n",
  )

  let input = @domain.LocalCheckInput::{
    run_dir,
    patch_path,
    artifact_source_dir,
    staged_files: snapshot.staged_files,
    notes: [
      "系统直接使用了当前 git 暂存区生成 patch.diff", "如果材料缺失，请把材料文件放进 artifact_source_dir 再重新执行 check",
    ],
  }
  @infra.write_text(
    @infra.join_path(run_dir, "input-summary.md"),
    render_local_input_summary(input),
  )
  input
}
