///|
/// 文件说明：定义 MoonForge Gate 的 CLI 入口，负责解析命令行参数并把请求分发到服务层。
/// 联动文件：直接调用 `src/services/commands.mbt` 中的命令编排逻辑，并依赖 `src/domain/types.mbt` 中的结果对象完成终端输出。

///|

///|
/// 从 argparse 结果中提取某个单值参数，并在缺失时给出明确错误。
fn option_value(matches : @argparse.Matches, key : String) -> String raise {
  guard matches.values.get(key) is Some(values) else {
    raise Failure::Failure("Missing required option --\{key}")
  }
  guard !values.is_empty() else {
    raise Failure::Failure("Option --\{key} has no value")
  }
  values[0]
}

///|
/// 从解析结果里读取某个参数的第一个值。
/// 这个帮助函数同时兼容 option 和 positional，因为它们最后都会落进 `matches.values`。
fn first_value(matches : @argparse.Matches, key : String) -> String? {
  match matches.values.get(key) {
    Some(values) if !values.is_empty() => Some(values[0])
    _ => None
  }
}

///|
/// 从 argparse 结果中提取某个可选参数。
/// 如果用户没传这个参数，就直接回退到默认值。
fn option_value_or_default(
  matches : @argparse.Matches,
  key : String,
  default_value : String,
) -> String {
  match first_value(matches, key) {
    Some(value) => value
    None => default_value
  }
}

///|
/// task 命令既支持新的位置参数写法，也兼容旧的 `--type` 写法。
/// 优先级上，位置参数优先，因为这是后续文档要主推的新入口。
fn task_type_value(matches : @argparse.Matches) -> String raise {
  match first_value(matches, "task_type") {
    Some(value) => value
    None =>
      match first_value(matches, "type") {
        Some(value) => value
        None =>
          raise Failure::Failure(
            "Missing task type. Use `moonforge task feature-change`.",
          )
      }
  }
}

///|
/// 根据命令名和 `--repo` 参数解析真正要操作的项目根目录。
/// 这样用户在目标项目目录里直接运行时，就不需要每次都手写完整路径。
fn resolve_repo_root(
  command_name : String,
  matches : @argparse.Matches,
) -> String raise {
  let repo_arg = option_value_or_default(matches, "repo", "")
  let allow_non_git = command_name == "init"
  @services.resolve_cli_project_context(repo_arg, allow_non_git~).repo_root
}

///|
/// 定义 CLI 命令树，是所有命令入口的统一描述。
fn cli() -> @argparse.Command {
  @argparse.Command(
    "moonforge",
    about="MoonForge Gate demo CLI built with MoonBit",
    version="0.1.0",
    arg_required_else_help=true,
    subcommand_required=true,
    subcommands=[
      @argparse.Command(
        "init",
        about="Initialize .moonforge config in current repo by default",
        options=[
          @argparse.OptionArg(
            "repo",
            about="Target repo root, default is current directory",
            required=false,
          ),
        ],
      ),
      @argparse.Command(
        "task",
        about="Create current-task.yml and auto-fill most fields from staged files",
        arg_required_else_help=true,
        positionals=[
          @argparse.PositionArg("task_type", about="Task type name"),
        ],
        options=[
          @argparse.OptionArg(
            "repo",
            about="Target repo root, default is current directory",
            required=false,
          ),
          @argparse.OptionArg(
            "type",
            about="Deprecated task type option, use positional task type instead",
            required=false,
          ),
          @argparse.OptionArg(
            "title",
            about="Optional manual task title",
            required=false,
          ),
          @argparse.OptionArg(
            "paths",
            about="Optional comma separated paths or @group names",
            required=false,
          ),
        ],
      ),
      @argparse.Command(
        "check",
        about="Run the gate check, auto-detecting local, CI, or PR mode by default",
        options=[
          @argparse.OptionArg(
            "repo",
            about="Target repo root, default is current directory",
            required=false,
          ),
          @argparse.OptionArg(
            "run",
            about="Optional run input directory, local mode can auto-generate it",
            required=false,
          ),
          @argparse.OptionArg(
            "mode",
            about="Optional mode override: auto, local, ci, or pr",
            required=false,
          ),
        ],
      ),
      @argparse.Command(
        "report",
        about="Print the latest generated gate report",
        options=[
          @argparse.OptionArg(
            "repo",
            about="Target repo root, default is current directory",
            required=false,
          ),
          @argparse.OptionArg(
            "mode",
            about="Optional mode override: auto, local, ci, or pr",
            required=false,
          ),
        ],
      ),
      @argparse.Command(
        "validate",
        about="Validate .moonforge config files in a target repo",
        options=[
          @argparse.OptionArg(
            "repo",
            about="Target repo root, default is current directory",
            required=false,
          ),
        ],
      ),
      @argparse.Command(
        "replay",
        about="Replay a historical gate run from snapshot files",
        options=[
          @argparse.OptionArg(
            "repo",
            about="Target repo root, default is current directory",
            required=false,
          ),
          @argparse.OptionArg(
            "run-id",
            about="Historical run id",
            required=true,
          ),
        ],
      ),
      @argparse.Command(
        "doctor",
        about="Diagnose repository onboarding status and config health",
        options=[
          @argparse.OptionArg(
            "repo",
            about="Target repo root, default is current directory",
            required=false,
          ),
        ],
      ),
      @argparse.Command(
        "pack",
        about="Export the latest run outputs plus the built-in acceptance package",
        options=[
          @argparse.OptionArg(
            "repo",
            about="Target repo root, default is current directory",
            required=false,
          ),
          @argparse.OptionArg(
            "mode",
            about="Optional mode override: auto, local, ci, or pr",
            required=false,
          ),
        ],
      ),
      @argparse.Command(
        "acc",
        about="Run internal acceptance cases",
        arg_required_else_help=true,
        subcommand_required=true,
        subcommands=[
          @argparse.Command("pass", about="Run the fixed pass acceptance case"),
          @argparse.Command(
            "retry",
            about="Run the fixed retry acceptance case",
          ),
          @argparse.Command(
            "reject",
            about="Run the fixed reject acceptance case",
          ),
        ],
      ),
    ],
  )
}

///|
fn main {
  try {
    let matches = cli().parse()
    guard matches.subcommand is Some((name, child)) else {
      println(cli().render_help())
      return
    }

    match name {
      "init" => {
        let repo_root = resolve_repo_root(name, child)
        println(@services.dispatch_cli_command(name, repo_root))
      }
      "task" => {
        let repo_root = resolve_repo_root(name, child)
        println(
          @services.dispatch_cli_command(
            name,
            repo_root,
            task_type=task_type_value(child),
            title=option_value_or_default(child, "title", ""),
            paths=option_value_or_default(child, "paths", ""),
          ),
        )
      }
      "check" => {
        let repo_root = resolve_repo_root(name, child)
        println(
          @services.dispatch_cli_command(
            name,
            repo_root,
            run=option_value_or_default(child, "run", ""),
            mode=option_value_or_default(child, "mode", "auto"),
          ),
        )
      }
      "report" => {
        let repo_root = resolve_repo_root(name, child)
        println(
          @services.dispatch_cli_command(
            name,
            repo_root,
            mode=option_value_or_default(child, "mode", "auto"),
          ),
        )
      }
      "validate" => {
        let repo_root = resolve_repo_root(name, child)
        println(@services.dispatch_cli_command(name, repo_root))
      }
      "replay" => {
        let repo_root = resolve_repo_root(name, child)
        println(
          @services.dispatch_cli_command(
            name,
            repo_root,
            run_id=option_value(child, "run-id"),
          ),
        )
      }
      "doctor" => {
        let repo_root = resolve_repo_root(name, child)
        println(@services.dispatch_cli_command(name, repo_root))
      }
      "pack" => {
        let repo_root = resolve_repo_root(name, child)
        println(
          @services.dispatch_cli_command(
            name,
            repo_root,
            mode=option_value_or_default(child, "mode", "auto"),
          ),
        )
      }
      "acc" => {
        guard child.subcommand is Some((acc_case, _)) else {
          raise Failure::Failure("Missing acceptance case")
        }
        println(
          @services.dispatch_cli_command(name, "", acceptance_case=acc_case),
        )
      }
      _ => raise Failure::Failure("Unsupported subcommand: \{name}")
    }
  } catch {
    err => {
      println(@services.render_cli_error(err.to_string()))
      panic()
    }
  }
}
