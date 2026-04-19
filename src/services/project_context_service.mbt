///|
/// 文件说明：负责把“用户当前在哪个项目里执行命令”这件事说清楚，统一处理 cwd、`--repo`、git 根目录和 `.moonforge` 路径。
/// 联动文件：后续 `init / task / check / report` 四个主命令都会先经过这里，避免每个命令都自己猜项目根目录。

///|
/// 读取当前 shell 工作目录。
/// 出参：当前进程看到的工作目录绝对路径。
pub fn read_current_working_dir() -> String raise {
  let result = @infra.run_shell_capture("pwd", ".")
  if !result.is_ok() {
    raise Failure::Failure(
      "无法读取当前目录：\{result.preferred_message()}",
    )
  }
  result.stdout.trim().to_string()
}

///|
/// 把命令行里的 `--repo` 参数规范成一个明确目录。
/// 规则很直接：
/// 1. 如果用户没传，就用当前目录
/// 2. 如果用户传的是相对路径，就相对当前目录展开
/// 3. 如果用户传的是绝对路径，就直接使用
pub fn normalize_requested_repo(repo_arg : String, cwd : String) -> String {
  let trimmed = repo_arg.trim().to_string()
  if trimmed == "" {
    @infra.normalize_path(cwd)
  } else if trimmed.has_prefix("/") {
    @infra.normalize_path(trimmed)
  } else {
    @infra.join_path(cwd, trimmed)
  }
}

///|
/// 根据项目根目录生成完整的上下文对象。
/// 入参：`request_dir`，用户实际请求的目录。
/// 入参：`repo_root`，最终判定后的项目根目录。
/// 入参：`is_git_repo`，当前目录是否处在 git 仓库中。
/// 出参：后续主命令可直接复用的结构化上下文。
fn build_project_context(
  request_dir : String,
  repo_root : String,
  is_git_repo : Bool,
) -> @domain.ProjectContext {
  let moonforge_dir = @infra.join_path(repo_root, ".moonforge")
  @domain.ProjectContext::{
    request_dir,
    repo_root,
    is_git_repo,
    moonforge_dir,
    repo_rules_file: @infra.join_path(moonforge_dir, "repo-rules.yml"),
    task_types_dir: @infra.join_path(moonforge_dir, "task-types"),
    current_task_file: @infra.join_path(moonforge_dir, "current-task.yml"),
    artifact_schema_dir: @infra.join_path(moonforge_dir, "artifact-schemas"),
    output_root_dir: @infra.join_path(moonforge_dir, "out"),
    runs_dir: @infra.join_path(moonforge_dir, "runs"),
    hook_file: @infra.join_path(repo_root, ".git/hooks/pre-commit"),
  }
}

///|
/// 根据用户输入和当前目录解析项目上下文。
/// 入参：`repo_arg`，命令行的 `--repo` 参数；允许为空。
/// 入参：`cwd`，当前 shell 工作目录。
/// 入参：`allow_non_git`，是否允许普通目录作为目标项目。
/// 出参：完整的项目上下文对象。
///
/// 这里的规则是：
/// 1. 优先用用户显式传入的目录
/// 2. 没传时就用当前目录
/// 3. 如果目录在 git 仓库里，就自动回到仓库根目录
/// 4. 只有 `init` 这类场景才允许普通目录继续走下去
pub fn resolve_project_context(
  repo_arg : String,
  cwd : String,
  allow_non_git? : Bool = false,
) -> @domain.ProjectContext raise {
  let request_dir = normalize_requested_repo(repo_arg, cwd)
  try {
    let repo_root = @infra.resolve_git_repo_root(request_dir)
    build_project_context(request_dir, repo_root, true)
  } catch {
    err =>
      if allow_non_git {
        build_project_context(request_dir, request_dir, false)
      } else {
        raise Failure::Failure(
          "当前目录不是 git 项目，无法继续：\{request_dir}；原始原因：\{err.to_string()}",
        )
      }
  }
}

///|
/// 这是给 CLI 主命令直接调用的便利入口。
/// 入参：`repo_arg`，命令行里的 `--repo` 参数；允许为空。
/// 入参：`allow_non_git`，例如 `init` 可以允许普通目录。
/// 出参：基于当前 shell 目录自动解析出的项目上下文。
pub fn resolve_cli_project_context(
  repo_arg : String,
  allow_non_git? : Bool = false,
) -> @domain.ProjectContext raise {
  let cwd = read_current_working_dir()
  resolve_project_context(repo_arg, cwd, allow_non_git~)
}

///|
/// 生成项目上下文的终端说明，供诊断或日志输出复用。
/// 入参：项目上下文对象。
/// 出参：便于直接打印的中文摘要。
pub fn render_project_context_summary(
  context : @domain.ProjectContext,
) -> String {
  context.summary()
}
