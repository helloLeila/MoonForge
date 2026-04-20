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
/// 读取可选标量字段，缺失时返回调用方给定的默认值。
fn scalar_optional(
  yaml : @infra.FlatYaml,
  key : String,
  default_value : String,
) -> String {
  match yaml.get_scalar(key) {
    Some(value) => value
    None => default_value
  }
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
/// 将 YAML 中的可选布尔字段解析成 `Bool?`。
/// 这里只接受最直接的 `true / false` 两种写法，避免含糊值混进来。
fn bool_optional(yaml : @infra.FlatYaml, key : String) -> Bool? raise {
  match yaml.get_scalar(key) {
    Some(value) =>
      match value.trim().to_string() {
        "true" => Some(true)
        "false" => Some(false)
        _ =>
          raise Failure::Failure(
            "Field \{key} is not a valid boolean: \{value}",
          )
      }
    None => None
  }
}

///|
/// 去掉字符串列表里的空白项，避免 `- ""` 这种占位值混进运行时对象。
fn cleaned_list(values : Array[String]) -> Array[String] {
  let cleaned : Array[String] = []
  for raw_item in values {
    let item = raw_item.trim().to_string()
    if item != "" {
      cleaned.push(item)
    }
  }
  cleaned
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
/// 返回材料 schema 目录的标准路径。
fn artifact_schemas_dir(repo_root : String) -> String {
  @infra.join_path(repo_root, ".moonforge/artifact-schemas")
}

///|
/// 返回 bootstrap 配置目录的标准路径。
fn bootstrap_dir(repo_root : String) -> String {
  @infra.bootstrap_dir(repo_root)
}

///|
/// 返回材料目录册文件的标准路径。
fn material_catalog_path(repo_root : String) -> String {
  @infra.material_catalog_path(repo_root)
}

///|
/// 将材料文件名映射成 schema 文件名，例如 `preview-report.json -> preview-report.yml`。
fn artifact_schema_file_name(artifact_name : String) -> String {
  let name = @infra.basename(artifact_name)
  let parts = name.split(".").map(segment => segment.to_string()).collect()
  if parts.length() <= 1 {
    "\{name}.yml"
  } else {
    let stem_parts : Array[String] = []
    for i in 0..<(parts.length() - 1) {
      stem_parts.push(parts[i])
    }
    let stem = stem_parts.join(".")
    "\{stem}.yml"
  }
}

///|
/// 返回单个材料 schema 文件的完整路径。
fn artifact_schema_path(repo_root : String, artifact_name : String) -> String {
  @infra.join_path(
    artifact_schemas_dir(repo_root),
    artifact_schema_file_name(artifact_name),
  )
}

///|
/// 加载仓库级长期规则。
fn load_repo_rules(repo_root : String) -> @domain.RepoRules raise {
  let yaml = @infra.read_flat_yaml(repo_rules_path(repo_root))
  @domain.RepoRules::{
    protected_paths: yaml.get_list("protected_paths"),
    approval_required_paths: yaml.get_list("approval_required_paths"),
    blocked_extensions: yaml.get_list("blocked_extensions"),
    generated_artifact_paths: yaml.get_list("generated_artifact_paths"),
    blocked_file_names: yaml.get_list("blocked_file_names"),
    blocked_file_patterns: yaml.get_list("blocked_file_patterns"),
    content_blocklist_patterns: yaml.get_list("content_blocklist_patterns"),
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
    required_commands: yaml.get_list("required_commands"),
    max_changed_files: int_required(yaml, "max_changed_files"),
    manual_approval_paths: yaml.get_list("manual_approval_paths"),
  }
}

///|
/// 校验仓库中的任务模板是否都满足基础语义与可解析性。
fn collect_repo_template_names(repo_root : String) -> Array[String] raise {
  let template_names : Array[String] = []
  for seed in default_templates() {
    template_names.push(seed.name)
  }
  for file_name in @infra.list_dir(task_types_dir(repo_root)) {
    if file_name.has_suffix(".yml") {
      let task_type = file_name[0:file_name.length() - 4].to_string()
      if !template_names.contains(task_type) {
        template_names.push(task_type)
      }
    }
  }
  template_names
}

///|
/// 根据仓库中的 task-types 目录判断任务类型是否合法。
fn validate_task_type_in_repo(
  repo_root : String,
  task_type : String,
) -> Result[Unit, String] raise {
  if collect_repo_template_names(repo_root).contains(task_type) {
    Ok(())
  } else {
    Err("TASK_TYPE_UNKNOWN")
  }
}

///|
/// 校验仓库中的任务模板是否都满足基础语义与可解析性。
fn validate_all_templates(repo_root : String, errors : Array[String]) -> Unit {
  let template_names : Array[String] = []
  try {
    for template_name in collect_repo_template_names(repo_root) {
      template_names.push(template_name)
    }
  } catch {
    err => errors.push("任务模板目录非法：\{err.to_string()}")
  }

  for template_name in template_names {
    try {
      let template = load_template(repo_root, template_name)
      match
        @checkers.validate_template_semantics(
          @infra.template_yaml_file_name(template_name),
          template,
        ) {
        Ok(_) => ()
        Err(code) =>
          errors.push("任务模板文件非法：\{template_name}: \{code}")
      }
    } catch {
      err =>
        errors.push(
          "任务模板文件非法：\{template_name}: \{err.to_string()}",
        )
    }
  }
}

///|
/// 读取当前正在执行的任务描述。
fn load_current_task(repo_root : String) -> @domain.CurrentTask raise {
  let yaml = @infra.read_flat_yaml(current_task_path(repo_root))
  @domain.CurrentTask::{
    task_type: scalar_required(yaml, "task_type"),
    title: scalar_required(yaml, "title"),
    title_source: scalar_optional(yaml, "title_source", "manual_or_unknown"),
    target_groups: cleaned_list(yaml.get_list("target_groups")),
    target_paths: cleaned_list(yaml.get_list("target_paths")),
    target_path_source: scalar_optional(
      yaml, "target_path_source", "manual_or_unknown",
    ),
    staged_files: cleaned_list(yaml.get_list("staged_files")),
    required_artifacts: cleaned_list(yaml.get_list("required_artifacts")),
    required_commands: cleaned_list(yaml.get_list("required_commands")),
    artifact_dir: scalar_optional(
      yaml, "artifact_dir", ".moonforge/artifacts/current",
    ),
    check_mode: scalar_optional(yaml, "check_mode", "local"),
    auto_inferred_fields: cleaned_list(yaml.get_list("auto_inferred_fields")),
    notes: cleaned_list(yaml.get_list("notes")),
    need_user_review: match bool_optional(yaml, "need_user_review") {
      Some(value) => value
      None => false
    },
    last_auto_fill_ns: scalar_optional(yaml, "last_auto_fill_ns", ""),
  }
}

///|
/// 加载材料 schema 中的必填字段定义；未提供 schema 时使用空规则。
fn load_artifact_required_fields(
  repo_root : String,
  artifact_names : Array[String],
) -> Map[String, Array[String]] raise {
  let field_map : Map[String, Array[String]] = {}
  for artifact_name in @infra.unique_strings(artifact_names) {
    let schema_path = artifact_schema_path(repo_root, artifact_name)
    if !@infra.path_exists(schema_path) {
      continue
    }
    let yaml = @infra.read_flat_yaml(schema_path)
    let required_fields : Array[String] = []
    for field in yaml.get_list("required_fields") {
      let trimmed = field.trim().to_string()
      if trimmed != "" {
        required_fields.push(trimmed)
      }
    }
    field_map[artifact_name] = required_fields
  }
  field_map
}

///|
/// 读取 task 默认偏好；文件不存在时回退到内置默认值。
fn load_task_defaults(repo_root : String) -> @domain.TaskDefaults raise {
  let path = @infra.task_defaults_path(repo_root)
  if @infra.path_exists(path) {
    @infra.read_task_defaults(path)
  } else {
    default_task_defaults()
  }
}

///|
/// 读取 check 默认偏好；文件不存在时回退到内置默认值。
fn load_check_preferences(repo_root : String) -> @domain.CheckPreferences raise {
  let path = @infra.check_preferences_path(repo_root)
  if @infra.path_exists(path) {
    @infra.read_check_preferences(path)
  } else {
    default_check_preferences()
  }
}

///|
/// 读取 report 默认偏好；文件不存在时回退到内置默认值。
fn load_report_preferences(
  repo_root : String,
) -> @domain.ReportPreferences raise {
  let path = @infra.report_preferences_path(repo_root)
  if @infra.path_exists(path) {
    @infra.read_report_preferences(path)
  } else {
    default_report_preferences()
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
    render_list_block("required_commands", template.required_commands),
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
    render_list_block("blocked_extensions", repo_rules.blocked_extensions),
    render_list_block(
      "generated_artifact_paths",
      repo_rules.generated_artifact_paths,
    ),
    render_list_block("blocked_file_names", repo_rules.blocked_file_names),
    render_list_block("blocked_file_patterns", repo_rules.blocked_file_patterns),
    render_list_block(
      "content_blocklist_patterns",
      repo_rules.content_blocklist_patterns,
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
  render_current_task_file(task)
}

///|
/// 构造默认仓库规则，作为 `moonforge init` 的初始化内容。
fn default_repo_rules() -> @domain.RepoRules {
  @domain.RepoRules::{
    protected_paths: ["backend/src/main/java/**/security/**", "infra/**"],
    approval_required_paths: ["backend/src/main/java/**/service/high-risk/**"],
    blocked_extensions: [".map", ".snap", ".lock"],
    generated_artifact_paths: [
      "dist/**", "build/**", "coverage/**", ".next/**", ".cache/**",
    ],
    blocked_file_names: [".env", ".DS_Store"],
    blocked_file_patterns: [],
    content_blocklist_patterns: [
      "console.log", "debugger", "printf", "println", "TODO", "FIXME",
    ],
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
        required_commands: [],
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
        required_commands: [],
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
        required_commands: [],
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
        required_commands: [],
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
        required_commands: [],
        max_changed_files: 10,
        manual_approval_paths: [],
      },
    },
  ]
}

///|
/// 校验任务范围是否真的落在模板允许范围内。
/// 不管范围是用户手填的，还是系统自动推断的，都必须过这一步。
fn ensure_task_scope_allowed(
  repo_rules : @domain.RepoRules,
  template : @domain.TaskTemplate,
  target_groups : Array[String],
  target_paths : Array[String],
) -> Unit raise {
  let expanded_target_groups = @infra.expand_target_groups(
    repo_rules.path_groups,
    target_groups,
  )
  for
    target_path in @infra.unique_strings(expanded_target_groups + target_paths) {
    if !@infra.matches_any(target_path, template.allowed_paths) {
      raise Failure::Failure(
        "Target path \{target_path} is outside template allowed paths for \{template.task_type}",
      )
    }
    if @infra.matches_any(target_path, template.forbidden_paths) {
      raise Failure::Failure(
        "Target path \{target_path} conflicts with forbidden paths for \{template.task_type}",
      )
    }
  }
}

///|
/// 扫描一次运行目录中已经存在的材料文件。
fn collect_present_artifacts(
  run_dir : String,
  required_artifacts : Array[String],
) -> Map[String, String] raise {
  @checkers.collect_artifacts(
    run_dir,
    @infra.unique_strings(required_artifacts),
  )
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
/// 在没有显式 `--run` 目录时，为 CI / PR 模式自动生成输入目录。
/// 这一步和本地模式的 staged 输入类似，只是补丁来源不再是暂存区，而是当前仓库历史。
fn prepare_hosted_check_input(
  repo_root : String,
  current_task : @domain.CurrentTask,
  mode : String,
  env : Map[String, String],
) -> (String, String) raise {
  let run_dir = @infra.join_path(
    repo_root,
    ".moonforge/runs/\{mode}-auto-\{@uv.hrtime()}/input",
  )
  let patch_path = @infra.join_path(run_dir, "patch.diff")
  let artifact_source_dir = resolve_artifact_source_dir(repo_root, current_task)
  let diff_text = if mode == "pr" {
    guard @adapters.github_base_ref(env) is Some(base_ref) else {
      raise Failure::Failure("PR_CONTEXT_NOT_FOUND")
    }
    @infra.read_pr_compare_diff(repo_root, base_ref)
  } else {
    @infra.read_head_commit_diff(repo_root)
  }
  let summary_lines = [
    "# 在线检查输入说明",
    "",
    "## 先总说",
    "这次 `moonforge check` 没有手工提供 --run，所以系统根据当前仓库历史自动生成了输入目录。",
    "",
    "## 再分说",
    "- mode: \{mode}",
    "- patch_path: \{patch_path}",
    "- artifact_source_dir: \{artifact_source_dir}",
  ]
  @infra.ensure_dir(run_dir)
  @infra.ensure_dir(artifact_source_dir)
  @infra.write_text(patch_path, diff_text)
  @infra.write_text(
    @infra.join_path(run_dir, "input-summary.md"),
    summary_lines.join("\n") + "\n",
  )
  (run_dir, artifact_source_dir)
}

///|
/// 返回内置最小验收包需要附带的固定文件清单。
fn built_in_acceptance_pack_files() -> Array[(String, String)] {
  [
    ("docs/acceptance/matrix.md", "acceptance/matrix.md"),
    ("examples/acceptance/current.yml", "acceptance/current.yml"),
    (
      "examples/acceptance/react-homepage-fixture/src/components/WorkLinks.jsx",
      "acceptance/react-homepage-fixture/src/components/WorkLinks.jsx",
    ),
    (
      "examples/acceptance/react-homepage-fixture/src/core/request.js", "acceptance/react-homepage-fixture/src/core/request.js",
    ),
    (
      "examples/acceptance/react-homepage-fixture/src/data/siteContent.js", "acceptance/react-homepage-fixture/src/data/siteContent.js",
    ),
    (
      "examples/acceptance/cases/pass/patch.diff", "acceptance/cases/pass/patch.diff",
    ),
    (
      "examples/acceptance/cases/pass/preview-report.json", "acceptance/cases/pass/preview-report.json",
    ),
    (
      "examples/acceptance/cases/pass/expected/checked-files.txt", "acceptance/cases/pass/expected/checked-files.txt",
    ),
    (
      "examples/acceptance/cases/pass/expected/gate-result.json", "acceptance/cases/pass/expected/gate-result.json",
    ),
    (
      "examples/acceptance/cases/pass/expected/gate-report.md", "acceptance/cases/pass/expected/gate-report.md",
    ),
    (
      "examples/acceptance/cases/retry/patch.diff", "acceptance/cases/retry/patch.diff",
    ),
    (
      "examples/acceptance/cases/retry/expected/checked-files.txt", "acceptance/cases/retry/expected/checked-files.txt",
    ),
    (
      "examples/acceptance/cases/retry/expected/gate-result.json", "acceptance/cases/retry/expected/gate-result.json",
    ),
    (
      "examples/acceptance/cases/retry/expected/gate-report.md", "acceptance/cases/retry/expected/gate-report.md",
    ),
    (
      "examples/acceptance/cases/reject/patch.diff", "acceptance/cases/reject/patch.diff",
    ),
    (
      "examples/acceptance/cases/reject/preview-report.json", "acceptance/cases/reject/preview-report.json",
    ),
    (
      "examples/acceptance/cases/reject/expected/checked-files.txt", "acceptance/cases/reject/expected/checked-files.txt",
    ),
    (
      "examples/acceptance/cases/reject/expected/gate-result.json", "acceptance/cases/reject/expected/gate-result.json",
    ),
    (
      "examples/acceptance/cases/reject/expected/gate-report.md", "acceptance/cases/reject/expected/gate-report.md",
    ),
  ]
}

///|
/// 将 acceptance 固定配置渲染为可直接查看的 `.moonforge` 文件并写入验收包。
fn export_built_in_acceptance_configs(pack_dir : String) -> Array[String] raise {
  let config = load_acceptance_config()
  let exported : Array[String] = []

  let repo_rules_target = @infra.join_path(
    pack_dir, "acceptance/.moonforge/repo-rules.yml",
  )
  @infra.write_text(repo_rules_target, render_acceptance_repo_rules(config))
  exported.push("acceptance/.moonforge/repo-rules.yml")

  let template_target = @infra.join_path(
    pack_dir,
    "acceptance/.moonforge/task-types/\{config.task_type}.yml",
  )
  @infra.write_text(template_target, render_acceptance_template(config))
  exported.push("acceptance/.moonforge/task-types/\{config.task_type}.yml")

  let current_task_target = @infra.join_path(
    pack_dir, "acceptance/.moonforge/current-task.yml",
  )
  @infra.write_text(
    current_task_target,
    render_current_task_yaml(
      config.task_type,
      config.title,
      config.target_paths,
    ),
  )
  exported.push("acceptance/.moonforge/current-task.yml")

  exported
}

///|
/// 根据执行模式和环境变量构建一次运行的上下文描述。
fn build_run_context(
  mode : String,
  run_dir : String,
  env : Map[String, String],
) -> @domain.RunContextFile {
  let actual_mode = @adapters.normalize_mode(mode)
  let source_kind = match actual_mode {
    "pr" => "pr_recheck"
    "ci" => "ci_recheck"
    _ => "local_staged"
  }
  let environment = if actual_mode == "local" {
    "local_shell"
  } else {
    "github_actions"
  }
  @domain.RunContextFile::{
    mode: actual_mode,
    source_kind,
    environment,
    event_name: @adapters.github_event_name(env),
    base_ref: @adapters.github_base_ref(env),
    head_ref: @adapters.github_head_ref(env),
    pr_number: @adapters.github_pr_number(env),
    diff_path: @infra.join_path(run_dir, "patch.diff"),
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
  run_context : @domain.RunContextFile,
  preflight_advice : @domain.PreflightAdviceBundle,
  task_profile : @domain.TaskProfileView,
  run_input_story : @domain.RunInputStoryView,
) -> Unit raise {
  let latest_dir = @adapters.latest_output_dir(repo_root, mode)
  @infra.ensure_dir(latest_dir)
  let run_context_json = run_context.to_json().stringify(indent=2) + "\n"
  let context_summary = render_run_context_summary(run_context_json)
  let explanation = build_decision_explanation(result)
  let history_index = record_run_history(
    repo_root,
    build_run_history_record(result, mode, context_summary, "\{@uv.hrtime()}"),
  )
  let history_hint = render_history_hint(history_index)
  let report_view = build_report_view(
    result,
    mode,
    context_summary,
    explanation,
    history_hint,
    preflight_advice.report_lines(),
  )
  let output_catalog = build_output_catalog_view(mode)
  let output_walkthrough = build_output_walkthrough_view(
    task_profile, run_input_story, report_view, preflight_advice, output_catalog,
  )
  let snapshot_card = render_run_snapshot_card(
    result, context_summary, history_hint,
  )

  let scope = @domain.ScopeResultFile::{
    checked_files: result.checked_files,
    out_of_scope_files: result.out_of_scope_files,
    protected_files: result.protected_files,
    approval_required_files: result.approval_required_files,
    forbidden_extension_files: result.forbidden_extension_files,
    blocked_file_name_files: result.blocked_file_name_files,
    blocked_file_pattern_files: result.blocked_file_pattern_files,
    generated_artifact_files: result.generated_artifact_files,
    changed_file_count: result.changed_file_count,
    max_changed_files: result.effective_task.max_changed_files,
  }
  let artifacts = @domain.ArtifactResultFile::{
    required_artifacts: result.effective_task.required_artifacts,
    provided_artifacts: result.provided_artifacts,
    missing_artifacts: result.missing_artifacts,
    invalid_artifacts: result.invalid_artifacts,
    command_failures: result.command_failures,
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
  write_json_file(@infra.join_path(latest_dir, "run-context.json"), run_context)
  write_json_file(
    @infra.join_path(latest_dir, "decision-explanation.json"),
    explanation,
  )
  write_json_file(@infra.join_path(latest_dir, "report-view.json"), report_view)
  write_json_file(
    @infra.join_path(latest_dir, "preflight-advice.json"),
    preflight_advice,
  )
  write_json_file(
    @infra.join_path(latest_dir, "task-profile.json"),
    task_profile,
  )
  write_json_file(
    @infra.join_path(latest_dir, "run-input-story.json"),
    run_input_story,
  )
  write_json_file(
    @infra.join_path(latest_dir, "output-catalog.json"),
    output_catalog,
  )
  write_json_file(
    @infra.join_path(latest_dir, "output-walkthrough.json"),
    output_walkthrough,
  )
  @infra.write_text(
    @infra.join_path(latest_dir, "gate-report.md"),
    render_report_markdown(result),
  )
  @infra.write_text(
    @infra.join_path(latest_dir, "decision-explanation.md"),
    render_decision_explanation_markdown(explanation),
  )
  @infra.write_text(
    @infra.join_path(latest_dir, "report-view.md"),
    render_report_view_markdown(report_view),
  )
  @infra.write_text(
    @infra.join_path(latest_dir, "report-summary.txt"),
    render_report_terminal_summary(report_view) + "\n",
  )
  @infra.write_text(
    @infra.join_path(latest_dir, "run-snapshot.md"),
    snapshot_card,
  )
  @infra.write_text(
    @infra.join_path(latest_dir, "preflight-advice.md"),
    render_preflight_advice_markdown(preflight_advice),
  )
  @infra.write_text(
    @infra.join_path(latest_dir, "task-profile.md"),
    render_task_profile_markdown(task_profile),
  )
  @infra.write_text(
    @infra.join_path(latest_dir, "run-input-story.md"),
    render_run_input_story_markdown(run_input_story),
  )
  @infra.write_text(
    @infra.join_path(latest_dir, "output-catalog.md"),
    render_output_catalog_markdown(output_catalog),
  )
  @infra.write_text(
    @infra.join_path(latest_dir, "output-walkthrough.md"),
    render_output_walkthrough_markdown(output_walkthrough),
  )
  @infra.write_text(
    @infra.join_path(latest_dir, "output-quickstart.txt"),
    render_output_catalog_quickstart(output_catalog),
  )
  @infra.write_text(
    @infra.join_path(latest_dir, "output-self-checklist.md"),
    render_output_self_checklist(output_catalog),
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
  write_json_file(
    @infra.join_path(snapshot_dir, "run-context.snapshot.json"),
    run_context,
  )
  write_json_file(@infra.join_path(snapshot_dir, "scope.snapshot.json"), scope)
  write_json_file(
    @infra.join_path(snapshot_dir, "artifact.snapshot.json"),
    artifacts,
  )
  write_json_file(@infra.join_path(snapshot_dir, "gate.snapshot.json"), gate)
  write_json_file(
    @infra.join_path(snapshot_dir, "decision-explanation.snapshot.json"),
    explanation,
  )
  write_json_file(
    @infra.join_path(snapshot_dir, "report-view.snapshot.json"),
    report_view,
  )
  write_json_file(
    @infra.join_path(snapshot_dir, "preflight-advice.snapshot.json"),
    preflight_advice,
  )
  write_json_file(
    @infra.join_path(snapshot_dir, "task-profile.snapshot.json"),
    task_profile,
  )
  write_json_file(
    @infra.join_path(snapshot_dir, "run-input-story.snapshot.json"),
    run_input_story,
  )
  write_json_file(
    @infra.join_path(snapshot_dir, "output-catalog.snapshot.json"),
    output_catalog,
  )
  write_json_file(
    @infra.join_path(snapshot_dir, "output-walkthrough.snapshot.json"),
    output_walkthrough,
  )
  @infra.write_text(
    @infra.join_path(snapshot_dir, "decision-explanation.snapshot.md"),
    render_decision_explanation_markdown(explanation),
  )
  @infra.write_text(
    @infra.join_path(snapshot_dir, "report-view.snapshot.md"),
    render_report_view_markdown(report_view),
  )
  @infra.write_text(
    @infra.join_path(snapshot_dir, "run-snapshot.snapshot.md"),
    snapshot_card,
  )
  @infra.write_text(
    @infra.join_path(snapshot_dir, "preflight-advice.snapshot.md"),
    render_preflight_advice_markdown(preflight_advice),
  )
  @infra.write_text(
    @infra.join_path(snapshot_dir, "task-profile.snapshot.md"),
    render_task_profile_markdown(task_profile),
  )
  @infra.write_text(
    @infra.join_path(snapshot_dir, "run-input-story.snapshot.md"),
    render_run_input_story_markdown(run_input_story),
  )
  @infra.write_text(
    @infra.join_path(snapshot_dir, "output-catalog.snapshot.md"),
    render_output_catalog_markdown(output_catalog),
  )
  @infra.write_text(
    @infra.join_path(snapshot_dir, "output-walkthrough.snapshot.md"),
    render_output_walkthrough_markdown(output_walkthrough),
  )
  @infra.write_text(
    @infra.join_path(snapshot_dir, "output-quickstart.snapshot.txt"),
    render_output_catalog_quickstart(output_catalog),
  )
  @infra.write_text(
    @infra.join_path(snapshot_dir, "output-self-checklist.snapshot.md"),
    render_output_self_checklist(output_catalog),
  )
}

///|
/// 初始化仓库内的 `.moonforge` 配置目录和默认模板。
pub fn init_repo(repo_root : String) -> String raise {
  let moonforge_dir = @infra.join_path(repo_root, ".moonforge")
  let default_artifact_dir = @infra.join_path(
    repo_root, ".moonforge/artifacts/current",
  )
  let bootstrap = default_bootstrap_bundle()
  let material_catalog = default_material_catalog()
  let review_schema =
    #|artifact_name: review-report.json
    #|
    #|required_fields:
    #|  - "reviewer"
    #|  - "status"
    #|
    #|optional_fields:
    #|
    #|allowed_values:
    #|
  let test_schema =
    #|artifact_name: test-report.json
    #|
    #|required_fields:
    #|  - "passed"
    #|  - "suite"
    #|
    #|optional_fields:
    #|
    #|allowed_values:
    #|
  let preview_schema =
    #|artifact_name: preview-report.json
    #|
    #|required_fields:
    #|  - "section"
    #|  - "status"
    #|  - "summary"
    #|
    #|optional_fields:
    #|
    #|allowed_values:
    #|
  @infra.ensure_dir(task_types_dir(repo_root))
  @infra.ensure_dir(artifact_schemas_dir(repo_root))
  @infra.ensure_dir(bootstrap_dir(repo_root))
  @infra.ensure_dir(default_artifact_dir)
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
    artifact_schema_path(repo_root, "review-report.json"),
    review_schema,
  )
  @infra.write_text(
    artifact_schema_path(repo_root, "test-report.json"),
    test_schema,
  )
  @infra.write_text(
    artifact_schema_path(repo_root, "preview-report.json"),
    preview_schema,
  )
  @infra.write_text(
    @infra.task_defaults_path(repo_root),
    @infra.render_task_defaults(bootstrap.task_defaults),
  )
  @infra.write_text(
    @infra.check_preferences_path(repo_root),
    @infra.render_check_preferences(bootstrap.check_preferences),
  )
  @infra.write_text(
    @infra.report_preferences_path(repo_root),
    @infra.render_report_preferences(bootstrap.report_preferences),
  )
  @infra.write_text(
    material_catalog_path(repo_root),
    @infra.render_material_catalog(material_catalog),
  )
  @infra.write_text(current_task_path(repo_root), blank_current_task_template())
  @infra.write_text(
    @infra.join_path(repo_root, ".git/hooks/pre-commit"),
    @infra.render_pre_commit_hook(),
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
  let repo_rules = load_repo_rules(repo_root)
  match validate_task_type_in_repo(repo_root, task_type) {
    Ok(_) => ()
    Err(code) => raise Failure::Failure(code)
  }
  let template = load_template(repo_root, task_type)
  match
    @checkers.validate_template_semantics(
      @infra.template_yaml_file_name(task_type),
      template,
    ) {
    Ok(_) => ()
    Err(code) => raise Failure::Failure(code)
  }
  let seed = build_current_task_draft_seed(task_type, title, paths_csv)
  let task_defaults = load_task_defaults(repo_root)
  let snapshot = @infra.read_git_project_snapshot(repo_root)
  if snapshot.staged_files.is_empty() &&
    !seed.has_manual_title() &&
    !seed.has_manual_scope() {
    raise Failure::Failure(
      "当前仓库没有可用的 git 暂存信息，请先 git add 文件，或手工补齐标题和路径",
    )
  }
  let plan = build_task_autofill_plan(
    seed,
    repo_rules,
    template,
    snapshot,
    "\{@uv.hrtime()}",
    task_defaults~,
  )
  let task = plan.to_current_task()
  if !seed.has_manual_scope() && !task.has_targets() {
    raise Failure::Failure(
      "当前暂存区没有命中模板允许范围的文件，无法自动补全任务范围",
    )
  }
  ensure_task_scope_allowed(
    repo_rules,
    template,
    task.target_groups,
    task.target_paths,
  )
  match @checkers.validate_current_task(task) {
    Ok(_) => ()
    Err(code) => raise Failure::Failure(code)
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
  } else {
    let repo_rules_text = @infra.read_text(repo_rules_file)
    match validate_repo_rules_text(repo_rules_text) {
      Err(code) => errors.push("仓库规则文件非法：\{code}")
      Ok(_) =>
        match
          validate_required_fields(repo_rules_text, [
            "protected_paths", "approval_required_paths", "default_allowed_extensions",
            "path_groups",
          ]) {
          Err(field) => errors.push("仓库规则文件缺少字段：\{field}")
          Ok(_) =>
            try {
              ignore(load_repo_rules(repo_root))
              validate_all_templates(repo_root, errors)
            } catch {
              err =>
                errors.push("仓库规则文件非法：\{err.to_string()}")
            }
        }
    }
  }
  let current_task_file = current_task_path(repo_root)
  if !@infra.path_exists(current_task_file) {
    errors.push("当前任务文件不存在：\{current_task_file}")
  } else {
    let task_text = @infra.read_text(current_task_file)
    match validate_current_task_text(task_text) {
      Err(code) => errors.push("当前任务文件非法：\{code}")
      Ok(_) =>
        try {
          let current_task = load_current_task(repo_root)
          match @checkers.validate_current_task(current_task) {
            Ok(_) => ()
            Err(code) => errors.push("当前任务文件非法：\{code}")
          }
          if errors.is_empty() {
            match
              validate_task_type_in_repo(repo_root, current_task.task_type) {
              Ok(_) => ()
              Err(code) => errors.push("当前任务文件非法：\{code}")
            }
          }
          if errors.is_empty() {
            try {
              let repo_rules = load_repo_rules(repo_root)
              let template = load_template(repo_root, current_task.task_type)
              if errors.is_empty() {
                ignore(
                  @checkers.build_effective_task(
                    repo_rules, template, current_task,
                  ),
                ) catch {
                  err =>
                    errors.push("当前任务文件非法：\{err.to_string()}")
                }
              }
            } catch {
              err =>
                errors.push("任务模板文件非法：\{err.to_string()}")
            }
          }
        } catch {
          err => errors.push("当前任务文件非法：\{err.to_string()}")
        }
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
  let env = @adapters.current_env()
  let repo_rules = load_repo_rules(repo_root)
  let current_task = load_current_task(repo_root)
  let actual_mode = @adapters.resolve_mode(
    mode,
    env,
    fallback_mode=current_task.check_mode,
  )
  let template = load_template(repo_root, current_task.task_type)
  let check_preferences = load_check_preferences(repo_root)
  let effective_task = @checkers.build_effective_task(
    repo_rules, template, current_task,
  )
  let auto_input = if run_dir.trim() == "" {
    if actual_mode == "local" {
      if check_preferences.auto_prepare_local_run_input {
        let input = prepare_local_check_input(
          repo_root,
          current_task,
          @infra.read_git_project_snapshot(repo_root),
        )
        Some((input.run_dir, input.artifact_source_dir))
      } else {
        raise Failure::Failure("当前仓库要求显式提供 --run 目录")
      }
    } else {
      Some(prepare_hosted_check_input(repo_root, current_task, actual_mode, env))
    }
  } else {
    None
  }
  let effective_run_dir = match auto_input {
    Some((generated_run_dir, _)) => generated_run_dir
    None => run_dir
  }
  let artifact_source_dir = match auto_input {
    Some((_, generated_artifact_dir)) => generated_artifact_dir
    None => effective_run_dir
  }
  let diff_path = @infra.join_path(effective_run_dir, "patch.diff")
  let diff_text = if actual_mode == "pr" {
    @adapters.read_pr_diff(env, diff_path)
  } else if actual_mode == "ci" {
    @adapters.read_ci_diff(env, diff_path)
  } else {
    @adapters.read_local_diff(effective_run_dir)
  }
  let discovered_artifacts = discover_required_artifacts(
    repo_root,
    current_task,
    effective_task.required_artifacts,
  )
  let provided_artifacts = if discovered_artifacts.provided_artifacts.is_empty() {
    collect_present_artifacts(
      artifact_source_dir,
      effective_task.required_artifacts,
    )
  } else {
    discovered_artifacts.provided_artifacts
  }
  let artifact_required_fields = load_artifact_required_fields(
    repo_root,
    effective_task.required_artifacts,
  )
  let run_id = @adapters.run_id_from_run_dir(effective_run_dir)
  let result = @checkers.evaluate_gate(
    effective_task, diff_text, provided_artifacts, artifact_required_fields, repo_root,
    run_id,
  )
  let run_context = build_run_context(actual_mode, effective_run_dir, env)
  let preflight_advice = build_preflight_advice_bundle(
    repo_root,
    current_task,
    effective_task,
    result.checked_files,
    discovered_artifacts,
  )
  let task_profile = build_task_profile_view(
    current_task,
    effective_task,
    result.checked_files,
  )
  let run_input_story = build_run_input_story_view(
    actual_mode, effective_run_dir, artifact_source_dir, discovered_artifacts,
  )
  write_outputs(
    repo_root, actual_mode, result, run_context, preflight_advice, task_profile,
    run_input_story,
  )
  result
}

///|
/// 读取指定模式下最近一次生成的门禁报告。
pub fn report_latest(
  repo_root : String,
  mode? : String = "local",
) -> String raise {
  let actual_mode = @adapters.resolve_mode(mode, @adapters.current_env())
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
  let report_preferences = load_report_preferences(repo_root)
  let env = @adapters.current_env()
  let actual_mode = @adapters.resolve_mode(mode, env)
  let summary_path = @infra.join_path(
    @adapters.latest_output_dir(repo_root, actual_mode),
    "report-summary.txt",
  )
  if @infra.path_exists(summary_path) {
    let summary_text = @infra.read_text(summary_path).trim().to_string()
    if summary_text != "" {
      return summary_text
    }
  }
  match @infra.read_latest_gate_result(repo_root, actual_mode) {
    Some(json_text) => {
      let context_summary = if report_preferences.show_context {
        match @infra.read_latest_run_context(repo_root, actual_mode) {
          Some(context_text) => render_run_context_summary(context_text)
          None => ""
        }
      } else {
        ""
      }
      let metrics_summary = if report_preferences.show_metrics {
        render_result_metrics_summary(
          @infra.read_latest_scope_result(repo_root, actual_mode),
          @infra.read_latest_artifact_result(repo_root, actual_mode),
        )
      } else {
        ""
      }
      render_report_summary(
        extract_decision_label(json_text),
        actual_mode,
        context_summary,
        metrics_summary,
      )
    }
    None => render_no_result_message(actual_mode)
  }
}

///|
/// 读取指定运行编号的任务快照，并返回 replay 命令摘要。
pub fn replay_check(repo_root : String, run_id : String) -> String raise {
  if !snapshot_exists(repo_root, run_id) {
    return render_snapshot_not_found(run_id)
  }
  let history_hint = render_history_hint(read_run_history(repo_root))
  match read_task_snapshot(repo_root, run_id) {
    Some(snapshot_text) => {
      let context_summary = match
        @infra.read_snapshot_run_context(repo_root, run_id) {
        Some(context_text) => render_run_context_summary(context_text)
        None => ""
      }
      let decision_label = match
        @infra.read_snapshot_gate_result(repo_root, run_id) {
        Some(gate_text) => extract_decision_label(gate_text)
        None => "Unknown"
      }
      let metrics_summary = render_result_metrics_summary(
        @infra.read_snapshot_scope_result(repo_root, run_id),
        @infra.read_snapshot_artifact_result(repo_root, run_id),
      )
      let summary = render_replay_summary(
        run_id,
        extract_task_type(snapshot_text),
        decision_label,
        context_summary,
        metrics_summary,
      )
      if history_hint.trim() == "" {
        summary
      } else {
        "\{summary}\n历史：\{history_hint}"
      }
    }
    None => render_snapshot_not_found(run_id)
  }
}

///|
/// 诊断仓库接入状态，汇总缺失文件、空文件、缺少字段和 YAML 语法问题。
pub fn doctor_repo(repo_root : String) -> String raise {
  let repo_rules_file = repo_rules_path(repo_root)
  let current_task_file = current_task_path(repo_root)
  let pre_commit_hook = @infra.join_path(repo_root, ".git/hooks/pre-commit")
  let issues = diagnose_missing_files([
    (repo_rules_file, @infra.path_exists(repo_rules_file)),
    (current_task_file, @infra.path_exists(current_task_file)),
  ])
  let hook_content = match @infra.read_text_if_exists(pre_commit_hook) {
    Some(content) => content
    None => ""
  }
  for
    issue in diagnose_pre_commit_hook(
      pre_commit_hook,
      @infra.path_exists(pre_commit_hook),
      content=hook_content,
    ) {
    issues.push(issue)
  }

  if @infra.path_exists(repo_rules_file) {
    let repo_rules_text = @infra.read_text(repo_rules_file)
    for issue in diagnose_empty_files([(repo_rules_file, repo_rules_text)]) {
      issues.push(issue)
    }
    for
      issue in diagnose_required_fields(repo_rules_text, [
        "protected_paths", "approval_required_paths", "default_allowed_extensions",
        "path_groups",
      ]) {
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
    for
      issue in diagnose_required_fields(current_task_text, [
        "task_type", "title", "target_paths",
      ]) {
      issues.push(issue)
    }
    for issue in diagnose_yaml_syntax(current_task_text) {
      issues.push(issue)
    }
  }

  render_doctor_report(issues)
}

///|
/// 导出最近一次检查结果与内置 acceptance 夹具组成的最小验收包。
pub fn pack_latest(
  repo_root : String,
  mode? : String = "local",
) -> String raise {
  let actual_mode = @adapters.resolve_mode(mode, @adapters.current_env())
  let latest_dir = @adapters.latest_output_dir(repo_root, actual_mode)
  if !@infra.path_exists(latest_dir) {
    return render_pack_failure("未找到最近一次检查结果")
  }

  let pack_dir = @infra.join_path(
    repo_root,
    ".moonforge/out/\{actual_mode}/packs/latest",
  )
  let copied_files : Array[String] = []

  let fixed_inputs = [
    (repo_rules_path(repo_root), @infra.join_path(pack_dir, "repo-rules.yml")),
    (
      current_task_path(repo_root),
      @infra.join_path(pack_dir, "current-task.yml"),
    ),
  ]
  for item in fixed_inputs {
    let (source, target) = item
    if copy_text_file_if_exists(source, target) {
      copied_files.push(@infra.basename(target))
    }
  }

  let fixed_outputs = collect_pack_files([
    "gate-result.json", "gate-report.md", "scope-result.json", "artifact-result.json",
    "checked-files.txt", "events.jsonl", "run-context.json", "decision-explanation.json",
    "decision-explanation.md", "report-view.json", "report-view.md", "preflight-advice.json",
    "preflight-advice.md", "task-profile.json", "task-profile.md", "run-input-story.json",
    "run-input-story.md", "output-catalog.json", "output-catalog.md", "output-walkthrough.json",
    "output-walkthrough.md", "output-quickstart.txt", "output-self-checklist.md",
    "report-summary.txt", "run-snapshot.md",
  ])
  for name in fixed_outputs {
    if copy_text_file_if_exists(
        @infra.join_path(latest_dir, name),
        @infra.join_path(pack_dir, name),
      ) {
      copied_files.push(name)
    }
  }

  for item in built_in_acceptance_pack_files() {
    let (source, target) = item
    if copy_text_file_if_exists(source, @infra.join_path(pack_dir, target)) {
      copied_files.push(target)
    }
  }

  if copy_text_file_if_exists(
      @infra.run_history_index_path(repo_root),
      @infra.join_path(pack_dir, "run-history.log"),
    ) {
    copied_files.push("run-history.log")
  }

  for target in export_built_in_acceptance_configs(pack_dir) {
    copied_files.push(target)
  }

  let manifest_files = copied_files + ["pack-manifest.json", "pack-summary.md"]
  let gate_text = match
    @infra.read_text_if_exists(@infra.join_path(latest_dir, "gate-result.json")) {
    Some(content) => content
    None => ""
  }
  let run_context_text = match
    @infra.read_text_if_exists(@infra.join_path(latest_dir, "run-context.json")) {
    Some(content) => content
    None => ""
  }
  let manifest = build_pack_manifest(
    actual_mode,
    match extract_json_string_field(gate_text, "run_id") {
      Some(run_id) => run_id
      None => "unknown"
    },
    extract_decision_label(gate_text),
    if run_context_text.trim() == "" {
      "未记录来源"
    } else {
      render_run_context_summary(run_context_text)
    },
    manifest_files,
  )
  write_json_file(@infra.join_path(pack_dir, "pack-manifest.json"), manifest)
  @infra.write_text(
    @infra.join_path(pack_dir, "pack-summary.md"),
    render_pack_summary(manifest),
  )
  copied_files.push("pack-manifest.json")
  copied_files.push("pack-summary.md")

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
  acceptance_case? : String = "",
) -> String raise {
  match command_name {
    "init" => init_repo(repo_root)
    "task" => {
      let task = create_task(repo_root, task_type, title, paths)
      "Wrote current-task.yml for \{task.task_type}: \{task.title}"
    }
    "check" => {
      let result = run_check(repo_root, run, mode~)
      summarize_result(result)
    }
    "report" => report_summary(repo_root, mode~)
    "validate" =>
      match validate_repo(repo_root) {
        Ok(message) => message
        Err(message) => raise Failure::Failure(message)
      }
    "replay" => replay_check(repo_root, run_id)
    "doctor" => doctor_repo(repo_root)
    "pack" => pack_latest(repo_root, mode~)
    "acc" => run_acceptance_case(acceptance_case)
    _ => raise Failure::Failure("Unsupported subcommand: \{command_name}")
  }
}

///|
/// 将 CLI 异常统一渲染为中英双语提示，便于终端直接阅读。
pub fn render_cli_error(error_text : String) -> String {
  "错误 / Error: \{error_text}"
}
