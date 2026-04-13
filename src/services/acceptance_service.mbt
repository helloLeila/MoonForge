///|
/// 文件说明：实现内部 acc 验收入口，负责复现固定 React 首页夹具上的 pass / retry / reject 三类结果。
/// 联动文件：复用 `src/services/commands.mbt` 的 init/create_task/run_check 主链路，并读取 `examples/acceptance/*` 固定样例。

///|
/// acc 当前场景包的最小配置对象。
priv struct AcceptanceConfig {
  fixture_root : String
  fixture_files : Array[String]
  task_type : String
  title : String
  target_paths : Array[String]
  protected_paths : Array[String]
  approval_required_paths : Array[String]
  blocked_extensions : Array[String]
  generated_artifact_paths : Array[String]
  blocked_file_names : Array[String]
  blocked_file_patterns : Array[String]
  content_blocklist_patterns : Array[String]
  allowed_paths : Array[String]
  forbidden_paths : Array[String]
  allowed_extensions : Array[String]
  required_artifacts : Array[String]
  required_commands : Array[String]
  max_changed_files : Int
}

///|
/// 返回 acceptance 配置文件路径。
fn acceptance_config_path() -> String {
  "examples/acceptance/current.yml"
}

///|
/// 返回 acceptance case 目录路径。
fn acceptance_case_dir(case_name : String) -> String {
  @infra.join_path("examples/acceptance/cases", case_name)
}

///|
/// 返回 acceptance case 的 expected 输出目录。
fn acceptance_expected_dir(case_name : String) -> String {
  @infra.join_path(acceptance_case_dir(case_name), "expected")
}

///|
/// 返回 acceptance 运行时临时仓库路径。
fn unique_acceptance_repo(case_name : String) -> String {
  @infra.join_path("tmp", "moonforge-acc-\{case_name}-\{@uv.hrtime()}")
}

///|
/// acceptance 运行仓库中的 repo-rules 路径。
fn acceptance_repo_rules_path(repo_root : String) -> String {
  @infra.join_path(repo_root, ".moonforge/repo-rules.yml")
}

///|
/// acceptance 运行仓库中的 task template 路径。
fn acceptance_template_path(repo_root : String, task_type : String) -> String {
  @infra.join_path(repo_root, ".moonforge/task-types/\{task_type}.yml")
}

///|
/// 将字符串数组渲染成 YAML 一级列表块。
fn render_acceptance_list_block(key : String, values : Array[String]) -> String {
  let lines : Array[String] = ["\{key}:"]
  for value in values {
    lines.push("  - \"\{value}\"")
  }
  lines.join("\n")
}

///|
/// 从固定 acceptance 配置中加载当前场景包定义。
fn load_acceptance_config() -> AcceptanceConfig raise {
  let yaml = @infra.read_flat_yaml(acceptance_config_path())
  AcceptanceConfig::{
    fixture_root: scalar_required(yaml, "fixture_root"),
    fixture_files: yaml.get_list("fixture_files"),
    task_type: scalar_required(yaml, "task_type"),
    title: scalar_required(yaml, "title"),
    target_paths: yaml.get_list("target_paths"),
    protected_paths: yaml.get_list("protected_paths"),
    approval_required_paths: yaml.get_list("approval_required_paths"),
    blocked_extensions: yaml.get_list("blocked_extensions"),
    generated_artifact_paths: yaml.get_list("generated_artifact_paths"),
    blocked_file_names: yaml.get_list("blocked_file_names"),
    blocked_file_patterns: yaml.get_list("blocked_file_patterns"),
    content_blocklist_patterns: yaml.get_list("content_blocklist_patterns"),
    allowed_paths: yaml.get_list("allowed_paths"),
    forbidden_paths: yaml.get_list("forbidden_paths"),
    allowed_extensions: yaml.get_list("allowed_extensions"),
    required_artifacts: yaml.get_list("required_artifacts"),
    required_commands: yaml.get_list("required_commands"),
    max_changed_files: int_required(yaml, "max_changed_files"),
  }
}

///|
/// 渲染 acceptance 场景用的 repo-rules.yml。
fn render_acceptance_repo_rules(config : AcceptanceConfig) -> String {
  let sections : Array[String] = [
    render_acceptance_list_block("protected_paths", config.protected_paths),
    render_acceptance_list_block(
      "approval_required_paths",
      config.approval_required_paths,
    ),
    render_acceptance_list_block(
      "blocked_extensions",
      config.blocked_extensions,
    ),
    render_acceptance_list_block(
      "generated_artifact_paths",
      config.generated_artifact_paths,
    ),
    render_acceptance_list_block(
      "blocked_file_names",
      config.blocked_file_names,
    ),
    render_acceptance_list_block(
      "blocked_file_patterns",
      config.blocked_file_patterns,
    ),
    render_acceptance_list_block(
      "content_blocklist_patterns",
      config.content_blocklist_patterns,
    ),
    render_acceptance_list_block(
      "default_allowed_extensions",
      config.allowed_extensions,
    ),
    "max_changed_files: \{config.max_changed_files}",
  ]
  sections.join("\n\n") + "\n"
}

///|
/// 渲染 acceptance 场景用的任务模板。
fn render_acceptance_template(config : AcceptanceConfig) -> String {
  [
    "task_type: \{config.task_type}",
    render_acceptance_list_block("allowed_paths", config.allowed_paths),
    render_acceptance_list_block("forbidden_paths", config.forbidden_paths),
    render_acceptance_list_block(
      "allowed_extensions",
      config.allowed_extensions,
    ),
    render_acceptance_list_block(
      "required_artifacts",
      config.required_artifacts,
    ),
    render_acceptance_list_block("required_commands", config.required_commands),
    "max_changed_files: \{config.max_changed_files}",
    render_acceptance_list_block("manual_approval_paths", []),
  ].join("\n\n") +
  "\n"
}

///|
/// 将固定 fixture 文件复制到临时验收仓库。
fn copy_acceptance_fixture(
  repo_root : String,
  config : AcceptanceConfig,
) -> Unit raise {
  for relative_path in config.fixture_files {
    let source = @infra.join_path(config.fixture_root, relative_path)
    @infra.write_text(
      @infra.join_path(repo_root, relative_path),
      @infra.read_text(source),
    )
  }
}

///|
/// 将固定 case 输入复制到本次运行目录。
fn copy_acceptance_case_inputs(
  run_dir : String,
  case_name : String,
) -> Unit raise {
  for
    file_name in [
      "patch.diff", "preview-report.json", "review-report.json", "test-report.json",
    ] {
    let source = @infra.join_path(acceptance_case_dir(case_name), file_name)
    match @infra.read_text_if_exists(source) {
      Some(content) =>
        @infra.write_text(@infra.join_path(run_dir, file_name), content)
      None => ()
    }
  }
}

///|
/// 对比固定 case 的期望输出和实际输出，返回所有不一致文件名。
fn compare_acceptance_outputs(
  repo_root : String,
  case_name : String,
) -> Array[String] raise {
  let actual_dir = @infra.join_path(repo_root, ".moonforge/out/local/latest")
  let expected_dir = acceptance_expected_dir(case_name)
  let mismatches : Array[String] = []
  for file_name in ["gate-result.json", "checked-files.txt", "gate-report.md"] {
    let actual = @infra.read_text(@infra.join_path(actual_dir, file_name))
    let expected = @infra.read_text(@infra.join_path(expected_dir, file_name))
    if actual != expected {
      mismatches.push(file_name)
    }
  }
  mismatches
}

///|
/// 运行固定 acceptance case，并验证输出与仓库中的 expected 文件完全一致。
pub fn run_acceptance_case(case_name : String) -> String raise {
  if !["pass", "retry", "reject"].contains(case_name) {
    raise Failure::Failure("Unsupported acceptance case: \{case_name}")
  }

  let config = load_acceptance_config()
  let repo_root = unique_acceptance_repo(case_name)
  let run_dir = @infra.join_path(repo_root, "fixture-runs/\{case_name}")

  copy_acceptance_fixture(repo_root, config)
  ignore(init_repo(repo_root))
  @infra.write_text(
    acceptance_repo_rules_path(repo_root),
    render_acceptance_repo_rules(config),
  )
  @infra.write_text(
    acceptance_template_path(repo_root, config.task_type),
    render_acceptance_template(config),
  )
  ignore(
    create_task(
      repo_root,
      config.task_type,
      config.title,
      config.target_paths.join(","),
    ),
  )
  copy_acceptance_case_inputs(run_dir, case_name)

  let result = run_check(repo_root, run_dir)
  let mismatches = compare_acceptance_outputs(repo_root, case_name)
  if !mismatches.is_empty() {
    let mismatch_text = mismatches.join(", ")
    raise Failure::Failure(
      "Acceptance case \{case_name} output mismatch: \{mismatch_text}",
    )
  }

  "moonforge acc \{case_name} => \{result.decision.label()}"
}
