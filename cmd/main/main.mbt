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
    ],
  )
}

///|
/// CLI 主函数，负责解析参数并分发到具体服务层命令。
fn main {
  try {
    let matches = cli().parse()
    guard matches.subcommand is Some((name, child)) else {
      println(cli().render_help())
      return
    }

    match name {
      "init" => println(@services.init_repo(option_value(child, "repo")))
      "task" => {
        let task = @services.create_task(
          option_value(child, "repo"),
          option_value(child, "type"),
          option_value(child, "title"),
          option_value(child, "paths"),
        )
        println("Wrote current-task.yml for \{task.task_type}: \{task.title}")
      }
      "check" => {
        let result = @services.run_check(
          option_value(child, "repo"),
          option_value(child, "run"),
          mode=option_value(child, "mode"),
        )
        println(@services.summarize_result(result))
      }
      "report" =>
        println(
          @services.report_latest(
            option_value(child, "repo"),
            mode=option_value(child, "mode"),
          ),
        )
      _ => raise Failure::Failure("Unsupported subcommand: \{name}")
    }
  } catch {
    err => {
      println(err.to_string())
      panic()
    }
  }
}
