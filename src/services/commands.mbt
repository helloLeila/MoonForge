///|
/// 文件说明：编排 `init`、`task`、`check`、`report` 四个核心命令，负责规则装配、检查执行和结果写出。
/// 联动文件：向下调用 `src/infra/*`、`src/adapters/mode_paths.mbt` 和 `src/checkers/gate.mbt`，向上被 `cmd/main/main.mbt` 调用。

///|

///|
/// 读取必填标量字段，缺失时立即终止初始化或检查流程。
fn scalar_required(yaml : @infra.FlatYaml, key : String) -> String raise {
  guard yaml.get_scalar(key) is Some(value) else {
    raise Failure::Failure("Missing required field in YAML: \{key}")
  }
  value
}

///|
/// 将 YAML 中的整数字段解析成 Int，并在失败时补充字段名。
fn int_required(yaml : @infra.FlatYaml, key : String) -> Int raise {
  @string.parse_int(scalar_required(yaml, key)) catch {
    err =>
      raise Failure::Failure(
        "Field \{key} is not a valid integer: \{err.to_string()}",
      )
  }
}

///|
/// 将 YAML 中的可选整数字段解析成 `Int?`，缺失时保留 `None`。
fn int_optional(yaml : @infra.FlatYaml, key : String) -> Int? raise {
  match yaml.get_scalar(key) {
    Some(value) =>
      Some(
        @string.parse_int(value) catch {
          err =>
            raise Failure::Failure(
              "Field \{key} is not a valid integer: \{err.to_string()}",
            )
        },
      )
    None => None
  }
}

///|
/// 默认模板种子，用来批量生成 task-types 下的模板文件。
priv struct TemplateSeed {
  name : String
  template : @domain.TaskTemplate
}

///|
/// 返回模板目录的标准路径。
fn task_types_dir(repo_root : String) -> String {
  @infra.join_path(repo_root, ".moonforge/task-types")
}

///|
/// 返回仓库规则文件的标准路径。
fn repo_rules_path(repo_root : String) -> String {
  @infra.join_path(repo_root, ".moonforge/repo-rules.yml")
}

///|
/// 返回当前任务文件的标准路径。
fn current_task_path(repo_root : String) -> String {
  @infra.join_path(repo_root, ".moonforge/current-task.yml")
}

///|
/// 返回某个任务模板文件的完整路径。
fn template_path(repo_root : String, task_type : String) -> String {
  @infra.join_path(task_types_dir(repo_root), "\{task_type}.yml")
}

///|
/// 加载仓库级长期规则。
fn load_repo_rules(repo_root : String) -> @domain.RepoRules raise {
  let yaml = @infra.read_flat_yaml(repo_rules_path(repo_root))
  @domain.RepoRules::{
    protected_paths: yaml.get_list("protected_paths"),
    approval_required_paths: yaml.get_list("approval_required_paths"),
    default_allowed_extensions: yaml.get_list("default_allowed_extensions"),
    path_groups: yaml.get_lists_with_prefix("path_groups."),
    max_changed_files: int_optional(yaml, "max_changed_files"),
  }
}

///|
/// 按任务类型加载对应模板文件。
fn load_template(
  repo_root : String,
  task_type : String,
) -> @domain.TaskTemplate raise {
  let yaml = @infra.read_flat_yaml(template_path(repo_root, task_type))
  @domain.TaskTemplate::{
    task_type: scalar_required(yaml, "task_type"),
    allowed_paths: yaml.get_list("allowed_paths"),
    forbidden_paths: yaml.get_list("forbidden_paths"),
    allowed_extensions: yaml.get_list("allowed_extensions"),
    required_artifacts: yaml.get_list("required_artifacts"),
    max_changed_files: int_required(yaml, "max_changed_files"),
    manual_approval_paths: yaml.get_list("manual_approval_paths"),
  }
}

///|
/// 读取当前正在执行的任务描述。
fn load_current_task(repo_root : String) -> @domain.CurrentTask raise {
  let yaml = @infra.read_flat_yaml(current_task_path(repo_root))
  @domain.CurrentTask::{
    task_type: scalar_required(yaml, "task_type"),
    title: scalar_required(yaml, "title"),
    target_groups: yaml.get_list("target_groups"),
    target_paths: yaml.get_list("target_paths"),
  }
}

///|
/// 将字符串数组渲染成 YAML 一级列表块。
fn render_list_block(key : String, values : Array[String]) -> String {
  let lines : Array[String] = ["\{key}:"]
  for value in values {
    lines.push("  - \"\{value}\"")
  }
  lines.join("\n")
}

///|
/// 将带公共前缀的命名列表集合渲染成多个 YAML 列表块。
fn render_prefixed_list_blocks(
  prefix : String,
  groups : Map[String, Array[String]],
) -> Array[String] {
  let blocks : Array[String] = []
  groups.each((name, values) => {
    blocks.push(render_list_block("\{prefix}\{name}", values))
  })
  blocks
}

///|
/// 将任务模板对象渲染为模板 YAML。
fn render_task_template(template : @domain.TaskTemplate) -> String {
  [
    "task_type: \{template.task_type}",
    render_list_block("allowed_paths", template.allowed_paths),
    render_list_block("forbidden_paths", template.forbidden_paths),
    render_list_block("allowed_extensions", template.allowed_extensions),
    render_list_block("required_artifacts", template.required_artifacts),
    "max_changed_files: \{template.max_changed_files}",
    render_list_block("manual_approval_paths", template.manual_approval_paths),
  ].join("\n\n") +
  "\n"
}

///|
/// 将仓库规则对象渲染为仓库规则 YAML。
fn render_repo_rules(repo_rules : @domain.RepoRules) -> String {
  let sections : Array[String] = [
    render_list_block("protected_paths", repo_rules.protected_paths),
    render_list_block(
      "approval_required_paths",
      repo_rules.approval_required_paths,
    ),
    render_list_block(
      "default_allowed_extensions",
      repo_rules.default_allowed_extensions,
    ),
  ]
  match repo_rules.max_changed_files {
    Some(limit) => sections.push("max_changed_files: \{limit}")
    None => ()
  }
  for
    block in render_prefixed_list_blocks("path_groups.", repo_rules.path_groups) {
    sections.push(block)
  }
  sections.join("\n\n") + "\n"
}

///|
/// 将当前任务对象渲染为 current-task YAML。
fn render_current_task(task : @domain.CurrentTask) -> String {
  [
    "task_type: \{task.task_type}",
    "title: \"\{task.title}\"",
    render_list_block("target_groups", task.target_groups),
    render_list_block("target_paths", task.target_paths),
  ].join("\n\n") +
  "\n"
}

///|
/// 构造默认仓库规则，作为 `moonforge init` 的初始化内容。
fn default_repo_rules() -> @domain.RepoRules {
  @domain.RepoRules::{
    protected_paths: ["backend/src/main/java/**/security/**", "infra/**"],
    approval_required_paths: ["backend/src/main/java/**/service/high-risk/**"],
    default_allowed_extensions: [
      ".java", ".ts", ".tsx", ".md", ".json", ".yml", ".yaml",
    ],
    path_groups: {
      "frontend_pages": ["frontend/src/pages/**"],
      "frontend_components": ["frontend/src/components/**"],
      "backend_user_module": ["backend/src/main/java/**/user/**"],
      "tests_root": ["tests/**"],
    },
    max_changed_files: None,
  }
}

///|
/// 构造内置模板集合，覆盖计划书中的五类常见任务。
fn default_templates() -> Array[TemplateSeed] {
  [
    TemplateSeed::{
      name: "feature-change",
      template: @domain.TaskTemplate::{
        task_type: "feature-change",
        allowed_paths: [
          "frontend/src/pages/**", "frontend/src/components/**", "backend/src/main/java/**/controller/**",
          "backend/src/main/java/**/service/**",
        ],
        forbidden_paths: ["backend/src/main/java/**/security/**", "infra/**"],
        allowed_extensions: [".java", ".ts", ".tsx", ".md", ".json"],
        required_artifacts: ["test-report.json", "review-report.json"],
        max_changed_files: 8,
        manual_approval_paths: ["backend/src/main/java/**/service/high-risk/**"],
      },
    },
    TemplateSeed::{
      name: "bug-fix",
      template: @domain.TaskTemplate::{
        task_type: "bug-fix",
        allowed_paths: ["frontend/src/**", "backend/src/main/java/**/user/**"],
        forbidden_paths: ["backend/src/main/java/**/payment/**"],
        allowed_extensions: [".java", ".ts", ".tsx", ".md", ".json"],
        required_artifacts: ["bug-context.md", "test-report.json"],
        max_changed_files: 10,
        manual_approval_paths: ["backend/src/main/java/**/service/high-risk/**"],
      },
    },
    TemplateSeed::{
      name: "api-change",
      template: @domain.TaskTemplate::{
        task_type: "api-change",
        allowed_paths: [
          "backend/src/main/java/**/api/**", "backend/src/main/java/**/dto/**", "frontend/src/api/**",
        ],
        forbidden_paths: ["backend/src/main/java/**/security/**"],
        allowed_extensions: [".java", ".ts", ".tsx", ".md", ".json"],
        required_artifacts: ["api-spec.md", "test-report.json"],
        max_changed_files: 6,
        manual_approval_paths: ["backend/src/main/java/**/service/high-risk/**"],
      },
    },
    TemplateSeed::{
      name: "config-change",
      template: @domain.TaskTemplate::{
        task_type: "config-change",
        allowed_paths: ["config/**", ".env.example"],
        forbidden_paths: [".env", "scripts/**"],
        allowed_extensions: [
          ".json", ".yml", ".yaml", ".md", ".properties", ".env.example",
        ],
        required_artifacts: ["config-impact.md"],
        max_changed_files: 3,
        manual_approval_paths: [],
      },
    },
    TemplateSeed::{
      name: "test-addition",
      template: @domain.TaskTemplate::{
        task_type: "test-addition",
        allowed_paths: [
          "tests/**", "frontend/src/**/__tests__/**", "backend/src/test/**",
        ],
        forbidden_paths: [
          "frontend/src/**/service/**", "backend/src/main/java/**/service/**", "backend/src/main/java/**/controller/**",
        ],
        allowed_extensions: [".java", ".ts", ".tsx", ".json", ".md"],
        required_artifacts: ["test-report.json", "coverage-report.json"],
        max_changed_files: 10,
        manual_approval_paths: [],
      },
    },
  ]
}

///|
/// 解析命令行里的逗号分隔路径列表。
fn split_paths_csv(paths_csv : String) -> Array[String] {
  paths_csv
  .split(",")
  .map(path => path.trim().to_string())
  .filter(path => path != "")
  .collect()
}

///|
/// 扫描一次运行目录中已经存在的材料文件。
fn collect_present_artifacts(
  run_dir : String,
  effective_task : @domain.EffectiveTask,
) -> Array[String] raise {
  let candidates = @infra.unique_strings(effective_task.required_artifacts)
  let present : Array[String] = []
  for candidate in candidates {
    if @infra.path_exists(@infra.join_path(run_dir, candidate)) {
      present.push(candidate)
    }
  }
  present
}

///|
/// 将任意可序列化对象写成格式化 JSON 文件。
fn[T : ToJson] write_json_file(path : String, value : T) -> Unit raise {
  @infra.write_text(path, value.to_json().stringify(indent=2) + "\n")
}

///|
/// 在源文件存在时把文本内容复制到目标文件，供导出最小验收包复用。
fn copy_text_file_if_exists(source : String, target : String) -> Bool raise {
  match @infra.read_text_if_exists(source) {
    Some(content) => {
      @infra.write_text(target, content)
      true
    }
    None => false
  }
}

///|
/// 生成给开发者阅读的 Markdown 门禁报告。
fn render_report_markdown(result : @domain.CheckResult) -> String {
  let lines : Array[String] = [
    "## 最终结论",
    result.decision.label(),
    "",
    "## 结论说明",
    result.decision.summary(),
    "",
    "## 任务摘要",
    "- task_type: \{result.effective_task.task_type}",
    "- title: \{result.effective_task.title}",
    "- changed_files: \{result.changed_file_count}",
    "",
    "## 命中的问题",
  ]

  if result.violations.is_empty() {
    lines.push("- 无")
  } else {
    for violation in result.violations {
      lines.push("- \{violation.code}: \{violation.detail}")
      if violation.file is Some(file) {
        lines.push("  file: \{file}")
      }
      lines.push("  suggestion: \{violation.suggestion}")
    }
  }

  lines.push("")
  lines.push("## 下一步")
  lines.push(result.decision.next_action())
  lines.push("")
  lines.join("\n")
}

///|
/// 生成一次检查的关键事件序列。
fn render_events(result : @domain.CheckResult) -> Array[@domain.EventEntry] {
  [
    @domain.EventEntry::{
      time_ns: @uv.hrtime(),
      event: "rules_loaded",
      detail: result.effective_task.task_type,
    },
    @domain.EventEntry::{
      time_ns: @uv.hrtime(),
      event: "files_checked",
      detail: "\{result.checked_files.length()} files",
    },
    @domain.EventEntry::{
      time_ns: @uv.hrtime(),
      event: "decision_made",
      detail: result.decision.label(),
    },
  ]
}

///|
/// 将事件数组转成逐行 JSON 的审计日志文本。
fn events_to_jsonl(events : Array[@domain.EventEntry]) -> String {
  events.map(event => event.to_json().stringify()).join("\n") + "\n"
}

///|
/// 将一次检查结果写入 local/ci 输出目录和运行快照目录。
fn write_outputs(
  repo_root : String,
  mode : String,
  result : @domain.CheckResult,
) -> Unit raise {
  let latest_dir = @adapters.latest_output_dir(repo_root, mode)
  @infra.ensure_dir(latest_dir)

  let scope = @domain.ScopeResultFile::{
    checked_files: result.checked_files,
    out_of_scope_files: result.out_of_scope_files,
    protected_files: result.protected_files,
    approval_required_files: result.approval_required_files,
    forbidden_extension_files: result.forbidden_extension_files,
    changed_file_count: result.changed_file_count,
    max_changed_files: result.effective_task.max_changed_files,
  }
  let artifacts = @domain.ArtifactResultFile::{
    required_artifacts: result.effective_task.required_artifacts,
    provided_artifacts: result.provided_artifacts,
    missing_artifacts: result.missing_artifacts,
  }
  let gate = @domain.GateResultFile::{
    run_id: result.run_id,
    decision: result.decision.label(),
    decision_summary: result.decision.summary(),
    violations: result.violations,
    next_action: result.decision.next_action(),
  }

  write_json_file(@infra.join_path(latest_dir, "scope-result.json"), scope)
  write_json_file(
    @infra.join_path(latest_dir, "artifact-result.json"),
    artifacts,
  )
  write_json_file(@infra.join_path(latest_dir, "gate-result.json"), gate)
  @infra.write_text(
    @infra.join_path(latest_dir, "gate-report.md"),
    render_report_markdown(result),
  )
  @infra.write_text(
    @infra.join_path(latest_dir, "checked-files.txt"),
    result.checked_files.join("\n") + "\n",
  )
  @infra.write_text(
    @infra.join_path(latest_dir, "events.jsonl"),
    events_to_jsonl(render_events(result)),
  )

  let snapshot_dir = @adapters.snapshot_dir(repo_root, result.run_id)
  @infra.ensure_dir(snapshot_dir)
  write_json_file(
    @infra.join_path(snapshot_dir, "task.snapshot.json"),
    result.effective_task,
  )
}

///|
/// 初始化仓库内的 `.moonforge` 配置目录和默认模板。
pub fn init_repo(repo_root : String) -> String raise {
  let moonforge_dir = @infra.join_path(repo_root, ".moonforge")
  @infra.ensure_dir(task_types_dir(repo_root))
  @infra.write_text(
    repo_rules_path(repo_root),
    render_repo_rules(default_repo_rules()),
  )
  for seed in default_templates() {
    @infra.write_text(
      template_path(repo_root, seed.name),
      render_task_template(seed.template),
    )
  }
  @infra.write_text(
    current_task_path(repo_root),
    render_current_task(@domain.CurrentTask::{
      task_type: "feature-change",
      title: "replace-me",
      target_groups: [],
      target_paths: ["frontend/src/pages/**"],
    }),
  )
  "Initialized MoonForge Gate config in \{moonforge_dir}"
}

///|
/// 根据用户选择的模板与目标路径生成当前任务文件。
pub fn create_task(
  repo_root : String,
  task_type : String,
  title : String,
  paths_csv : String,
) -> @domain.CurrentTask raise {
  let template = load_template(repo_root, task_type)
  let target_paths = split_paths_csv(paths_csv)
  if title.trim() == "" {
    raise Failure::Failure("Task title cannot be empty")
  }
  if target_paths.is_empty() {
    raise Failure::Failure("At least one target path is required")
  }

  for target_path in target_paths {
    if !@infra.matches_any(target_path, template.allowed_paths) {
      raise Failure::Failure(
        "Target path \{target_path} is outside template allowed paths for \{task_type}",
      )
    }
    if @infra.matches_any(target_path, template.forbidden_paths) {
      raise Failure::Failure(
        "Target path \{target_path} conflicts with forbidden paths for \{task_type}",
      )
    }
  }

  let task = @domain.CurrentTask::{
    task_type,
    title,
    target_groups: [],
    target_paths,
  }
  @infra.write_text(current_task_path(repo_root), render_current_task(task))
  task
}

///|
/// 校验仓库配置文件的完整性与合法性，返回校验结果。
pub fn validate_repo(repo_root : String) -> Result[String, String] raise {
  let errors : Array[String] = []
  let repo_rules_file = repo_rules_path(repo_root)
  if !@infra.path_exists(repo_rules_file) {
    errors.push("仓库规则文件不存在：\{repo_rules_file}")
  }
  let current_task_file = current_task_path(repo_root)
  if !@infra.path_exists(current_task_file) {
    errors.push("当前任务文件不存在：\{current_task_file}")
  } else {
    let task_text = @infra.read_text(current_task_file)
    if task_text.trim() == "" {
      errors.push("当前任务文件为空")
    } else if !task_text.contains("task_type") {
      errors.push("当前任务文件缺少 task_type 字段")
    }
  }
  if errors.is_empty() {
    Ok("配置校验通过")
  } else {
    Err(errors.join("; "))
  }
}

///|
/// 执行一次完整门禁检查并落盘输出结果。
pub fn run_check(
  repo_root : String,
  run_dir : String,
  mode? : String = "local",
) -> @domain.CheckResult raise {
  let actual_mode = @adapters.normalize_mode(mode)
  let repo_rules = load_repo_rules(repo_root)
  let current_task = load_current_task(repo_root)
  let template = load_template(repo_root, current_task.task_type)
  let effective_task = @checkers.build_effective_task(
    repo_rules, template, current_task,
  )
  let diff_text = if actual_mode == "ci" {
    @adapters.read_ci_diff(
      @adapters.current_env(),
      @infra.join_path(run_dir, "patch.diff"),
    )
  } else {
    @adapters.read_local_diff(run_dir)
  }
  let provided_artifacts = collect_present_artifacts(run_dir, effective_task)
  let run_id = @adapters.run_id_from_run_dir(run_dir)
  let result = @checkers.evaluate_gate(
    effective_task, diff_text, provided_artifacts, run_id,
  )
  write_outputs(repo_root, actual_mode, result)
  result
}

///|
/// 读取指定模式下最近一次生成的门禁报告。
pub fn report_latest(
  repo_root : String,
  mode? : String = "local",
) -> String raise {
  let actual_mode = @adapters.normalize_mode(mode)
  @infra.read_text(
    @infra.join_path(
      @adapters.latest_output_dir(repo_root, actual_mode),
      "gate-report.md",
    ),
  )
}

///|
/// 读取最近一次检查结果，并渲染终端友好的中文摘要。
pub fn report_summary(
  repo_root : String,
  mode? : String = "local",
) -> String raise {
  let actual_mode = @adapters.normalize_mode(mode)
  match @infra.read_latest_gate_result(repo_root, actual_mode) {
    Some(json_text) =>
      render_report_summary(extract_decision_label(json_text), actual_mode)
    None => render_no_result_message(actual_mode)
  }
}

///|
/// 读取指定运行编号的任务快照，并返回 replay 命令摘要。
pub fn replay_check(repo_root : String, run_id : String) -> String raise {
  if !snapshot_exists(repo_root, run_id) {
    return render_snapshot_not_found(run_id)
  }
  match read_task_snapshot(repo_root, run_id) {
    Some(snapshot_text) =>
      render_replay_summary(run_id, extract_task_type(snapshot_text))
    None => render_snapshot_not_found(run_id)
  }
}

///|
/// 诊断仓库接入状态，汇总缺失文件、空文件、缺少字段和 YAML 语法问题。
pub fn doctor_repo(repo_root : String) -> String raise {
  let repo_rules_file = repo_rules_path(repo_root)
  let current_task_file = current_task_path(repo_root)
  let issues = diagnose_missing_files([
    (repo_rules_file, @infra.path_exists(repo_rules_file)),
    (current_task_file, @infra.path_exists(current_task_file)),
  ])

  if @infra.path_exists(repo_rules_file) {
    let repo_rules_text = @infra.read_text(repo_rules_file)
    for issue in diagnose_empty_files([(repo_rules_file, repo_rules_text)]) {
      issues.push(issue)
    }
    for issue in diagnose_required_fields(
      repo_rules_text,
      [
        "protected_paths",
        "approval_required_paths",
        "default_allowed_extensions",
        "path_groups",
      ],
    ) {
      issues.push(issue)
    }
    for issue in diagnose_yaml_syntax(repo_rules_text) {
      issues.push(issue)
    }
  }

  if @infra.path_exists(current_task_file) {
    let current_task_text = @infra.read_text(current_task_file)
    for issue in diagnose_empty_files([(current_task_file, current_task_text)]) {
      issues.push(issue)
    }
    for issue in diagnose_required_fields(
      current_task_text,
      ["task_type", "title", "target_paths"],
    ) {
      issues.push(issue)
    }
    for issue in diagnose_yaml_syntax(current_task_text) {
      issues.push(issue)
    }
  }

  render_doctor_report(issues)
}

///|
/// 导出最近一次检查的最小验收包，复制固定输入与固定输出文件到标准目录。
pub fn pack_latest(
  repo_root : String,
  mode? : String = "local",
) -> String raise {
  let actual_mode = @adapters.normalize_mode(mode)
  let latest_dir = @adapters.latest_output_dir(repo_root, actual_mode)
  if !@infra.path_exists(latest_dir) {
    return render_pack_failure("未找到最近一次检查结果")
  }

  let pack_dir = @infra.join_path(repo_root, ".moonforge/out/\{actual_mode}/packs/latest")
  let copied_files : Array[String] = []

  let fixed_inputs = [
    (repo_rules_path(repo_root), @infra.join_path(pack_dir, "repo-rules.yml")),
    (current_task_path(repo_root), @infra.join_path(pack_dir, "current-task.yml")),
  ]
  for item in fixed_inputs {
    let (source, target) = item
    if copy_text_file_if_exists(source, target) {
      copied_files.push(@infra.basename(target))
    }
  }

  let fixed_outputs = collect_pack_files([
    "gate-result.json",
    "gate-report.md",
    "scope-result.json",
    "artifact-result.json",
    "checked-files.txt",
    "events.jsonl",
  ])
  for name in fixed_outputs {
    if copy_text_file_if_exists(
        @infra.join_path(latest_dir, name),
        @infra.join_path(pack_dir, name),
      ) {
      copied_files.push(name)
    }
  }

  if copied_files.is_empty() {
    render_pack_failure("未找到可导出的结果文件")
  } else {
    render_pack_success(pack_dir, copied_files.length())
  }
}

///|
/// 将检查结果压缩为终端展示用的摘要文本。
pub fn summarize_result(result : @domain.CheckResult) -> String {
  let lines : Array[String] = [
    "MoonForge Gate Demo",
    "run_id: \{result.run_id}",
    "decision: \{result.decision.label()}",
    "decision_summary: \{result.decision.summary()}",
    "checked_files: \{result.checked_files.length()}",
  ]

  if !result.violations.is_empty() {
    lines.push("violations:")
    for violation in result.violations {
      if violation.file is Some(file) {
        lines.push("- \{violation.code}: \{file}")
      } else {
        lines.push("- \{violation.code}: \{violation.detail}")
      }
    }
  }

  lines.join("\n")
}

///|
/// 统一分发 CLI 子命令到服务层实现，保证入口逻辑集中且可测试。
pub fn dispatch_cli_command(
  command_name : String,
  repo_root : String,
  task_type? : String = "",
  title? : String = "",
  paths? : String = "",
  run? : String = "",
  run_id? : String = "",
  mode? : String = "local",
) -> String raise {
  match command_name {
    "init" => init_repo(repo_root)
    "task" => {
      let task = create_task(repo_root, task_type, title, paths)
      "Wrote current-task.yml for \{task.task_type}: \{task.title}"
    }
    "check" => {
      let result = run_check(repo_root, run, mode=mode)
      summarize_result(result)
    }
    "report" => report_summary(repo_root, mode=mode)
    "validate" => match validate_repo(repo_root) {
      Ok(message) => message
      Err(message) => raise Failure::Failure(message)
    }
    "replay" => replay_check(repo_root, run_id)
    "doctor" => doctor_repo(repo_root)
    _ => raise Failure::Failure("Unsupported subcommand: \{command_name}")
  }
}

///|
/// 将 CLI 异常统一渲染为中英双语提示，便于终端直接阅读。
pub fn render_cli_error(error_text : String) -> String {
  "错误 / Error: \{error_text}"
}
