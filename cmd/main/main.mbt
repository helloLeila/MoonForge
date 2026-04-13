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
        about="Initialize .moonforge config in a target repo",
        options=[
          @argparse.OptionArg("repo", about="Target repo root", required=true),
        ],
      ),
      @argparse.Command(
        "task",
        about="Create current-task.yml from a named template",
        options=[
          @argparse.OptionArg("repo", about="Target repo root", required=true),
          @argparse.OptionArg("type", about="Task type name", required=true),
          @argparse.OptionArg("title", about="Task title", required=true),
          @argparse.OptionArg(
            "paths",
            about="Comma separated target paths",
            required=true,
          ),
        ],
      ),
      @argparse.Command(
        "check",
        about="Run the gate check with a diff + artifact directory",
        options=[
          @argparse.OptionArg("repo", about="Target repo root", required=true),
          @argparse.OptionArg("run", about="Run input directory", required=true),
          @argparse.OptionArg("mode", about="Execution mode: local or ci", default_values=[
            "local",
          ]),
        ],
      ),
      @argparse.Command(
        "report",
        about="Print the latest generated gate report",
        options=[
          @argparse.OptionArg("repo", about="Target repo root", required=true),
          @argparse.OptionArg("mode", about="Execution mode: local or ci", default_values=[
            "local",
          ]),
        ],
      ),
      @argparse.Command(
        "validate",
        about="Validate .moonforge config files in a target repo",
        options=[
          @argparse.OptionArg("repo", about="Target repo root", required=true),
        ],
      ),
      @argparse.Command(
        "replay",
        about="Replay a historical gate run from snapshot files",
        options=[
          @argparse.OptionArg("repo", about="Target repo root", required=true),
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
          @argparse.OptionArg("repo", about="Target repo root", required=true),
        ],
      ),
      @argparse.Command(
        "pack",
        about="Export the latest minimal acceptance package",
        options=[
          @argparse.OptionArg("repo", about="Target repo root", required=true),
          @argparse.OptionArg("mode", about="Execution mode: local or ci", default_values=[
            "local",
          ]),
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
      "init" =>
        println(
          @services.dispatch_cli_command(name, option_value(child, "repo")),
        )
      "task" =>
        println(
          @services.dispatch_cli_command(
            name,
            option_value(child, "repo"),
            task_type=option_value(child, "type"),
            title=option_value(child, "title"),
            paths=option_value(child, "paths"),
          ),
        )
      "check" =>
        println(
          @services.dispatch_cli_command(
            name,
            option_value(child, "repo"),
            run=option_value(child, "run"),
            mode=option_value(child, "mode"),
          ),
        )
      "report" =>
        println(
          @services.dispatch_cli_command(
            name,
            option_value(child, "repo"),
            mode=option_value(child, "mode"),
          ),
        )
      "validate" =>
        println(
          @services.dispatch_cli_command(name, option_value(child, "repo")),
        )
      "replay" =>
        println(
          @services.dispatch_cli_command(
            name,
            option_value(child, "repo"),
            run_id=option_value(child, "run-id"),
          ),
        )
      "doctor" =>
        println(
          @services.dispatch_cli_command(name, option_value(child, "repo")),
        )
      "pack" =>
        println(
          @services.dispatch_cli_command(
            name,
            option_value(child, "repo"),
            mode=option_value(child, "mode"),
          ),
        )
      _ => raise Failure::Failure("Unsupported subcommand: \{name}")
    }
  } catch {
    err => {
      println(@services.render_cli_error(err.to_string()))
      panic()
    }
  }
}
