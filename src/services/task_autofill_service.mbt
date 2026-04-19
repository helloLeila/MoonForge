///|
/// 文件总说：
/// 这个文件负责“根据当前 git 暂存改动，自动把任务大部分内容填好”。
/// 它专门解决用户最烦的那件事：
/// - 不想每次都手打标题
/// - 不想每次都手打路径范围
/// - 但又希望系统填出来的内容不是瞎猜
///
/// 所以这里会按很直白的顺序工作：
/// 1. 先看当前有哪些暂存文件
/// 2. 再看这些文件能不能命中已有路径组
/// 3. 路径组覆盖不了的文件，再单独补到 `target_paths`
/// 4. 然后根据文件名和任务类型，生成一个普通人能看懂的标题
/// 5. 最后把“为什么这么填”也一起记下来
///
/// 这份服务不直接写文件。
/// 它只负责产出一份 `TaskAutoFillPlan`，真正写入 YAML 由 `task_service.mbt` 负责。

///|
/// 判断一个文件是否落在模板允许范围内，同时没有踩到模板禁止范围。
fn file_is_allowed_by_template(
  file : String,
  template : @domain.TaskTemplate,
) -> Bool {
  @infra.matches_any(file, template.allowed_paths) &&
  !@infra.matches_any(file, template.forbidden_paths)
}

///|
/// 判断一个路径组里的所有规则，是否整体都落在模板允许范围内。
/// 这样可以避免系统把明显越界的路径组自动塞进当前任务。
fn group_is_allowed_by_template(
  patterns : Array[String],
  template : @domain.TaskTemplate,
) -> Bool {
  for pattern in patterns {
    if !@infra.matches_any(pattern, template.allowed_paths) {
      return false
    }
    if @infra.matches_any(pattern, template.forbidden_paths) {
      return false
    }
  }
  true
}

///|
/// 从路径中提取一个更像“人话”的主题词，供自动标题复用。
/// 规则尽量简单：
/// - 如果文件名是 `index.*`，优先拿父目录名
/// - 否则直接拿文件名
fn human_subject_from_path(path : String) -> String {
  let file_name = @infra.basename(path)
  if file_name.has_prefix("index.") {
    let parent = @infra.basename(@infra.dirname(path))
    if parent.trim() != "" && parent != "." {
      parent
    } else {
      file_name
    }
  } else {
    file_name
  }
}

///|
/// 生成标题建议。
/// 逻辑优先级：
/// 1. 用户手填标题时，直接沿用
/// 2. 没手填时，根据暂存文件数量和名称自动生成
fn build_title_suggestion(
  seed : @domain.CurrentTaskDraftSeed,
  staged_files : Array[String],
  task_defaults : @domain.TaskDefaults,
) -> @domain.TaskTitleSuggestion {
  if seed.has_manual_title() {
    @domain.TaskTitleSuggestion::{
      title: seed.override_title,
      source: "manual_input",
      based_on_files: staged_files,
      reason: "用户已经在命令行里明确给出了标题，所以系统不再覆盖它",
    }
  } else if staged_files.is_empty() {
    @domain.TaskTitleSuggestion::{
      title: "请补充任务标题",
      source: "fallback_missing_staged_files",
      based_on_files: [],
      reason: "当前没有可参考的暂存文件，系统无法可靠生成标题",
    }
  } else {
    let verb = task_defaults.default_title_prefixes.get_or_default(
      seed.task_type,
      "处理",
    )
    let subject = human_subject_from_path(staged_files[0])
    let generated = if staged_files.length() == 1 {
      "\{verb}\{subject}"
    } else {
      "\{verb}\{subject}等\{staged_files.length()}处改动"
    }
    @domain.TaskTitleSuggestion::{
      title: generated,
      source: "auto_from_staged_files",
      based_on_files: staged_files,
      reason: "系统根据暂存文件的名字和数量，自动生成了一个能直接读懂的标题",
    }
  }
}

///|
/// 为每个路径组生成命中记录。
/// 这里不直接决定“用不用这个路径组”，只是先把证据收集出来。
fn collect_group_matches(
  repo_rules : @domain.RepoRules,
  template : @domain.TaskTemplate,
  staged_files : Array[String],
) -> Array[@domain.TaskGroupMatch] {
  let matches : Array[@domain.TaskGroupMatch] = []
  repo_rules.path_groups.each((group_name, group_patterns) => {
    if !group_is_allowed_by_template(group_patterns, template) {
      ()
    } else {
      let matched_files : Array[String] = []
      for staged_file in staged_files {
        if @infra.matches_any(staged_file, group_patterns) {
          matched_files.push(staged_file)
        }
      }
      let group_match = @domain.TaskGroupMatch::{
        group_name,
        group_patterns,
        matched_files,
      }
      if group_match.is_useful() {
        matches.push(group_match)
      }
    }
  })
  matches
}

///|
/// 把一组文件压缩成更容易读的 `target_paths`。
/// 简单规则：
/// - 同一目录下只有 1 个文件时，保留文件路径
/// - 同一目录下有多个文件时，压缩成 `目录/**`
fn collapse_files_into_target_paths(
  files : Array[String],
  template : @domain.TaskTemplate,
) -> Array[String] {
  let target_paths : Array[String] = []
  let visited_dirs : Array[String] = []
  let used_files : Array[String] = []

  for file in files {
    let dir = @infra.dirname(file)
    if visited_dirs.contains(dir) {
      continue
    }
    let same_dir_files : Array[String] = []
    for item in files {
      if @infra.dirname(item) == dir {
        same_dir_files.push(item)
      }
    }
    if same_dir_files.length() >= 2 {
      let directory_pattern = if dir == "." || dir == "" {
        file
      } else {
        "\{dir}/**"
      }
      if directory_pattern == file ||
        file_is_allowed_by_template(directory_pattern, template) {
        target_paths.push(directory_pattern)
        visited_dirs.push(dir)
        for same_dir_file in same_dir_files {
          used_files.push(same_dir_file)
        }
        continue
      }
    }
  }

  for file in files {
    if !used_files.contains(file) && !target_paths.contains(file) {
      target_paths.push(file)
    }
  }
  target_paths
}

///|
/// 生成范围建议。
/// 它会把“手工指定的范围”和“系统自动推断的范围”合在一起考虑。
fn build_scope_suggestion(
  seed : @domain.CurrentTaskDraftSeed,
  repo_rules : @domain.RepoRules,
  template : @domain.TaskTemplate,
  staged_files : Array[String],
) -> @domain.TaskScopeSuggestion raise {
  if seed.has_manual_scope() {
    let covered_files : Array[String] = []
    let expanded_manual_groups = @infra.expand_target_groups(
      repo_rules.path_groups,
      seed.manual_target_groups,
    )
    for file in staged_files {
      if @infra.matches_any(file, seed.manual_target_paths) ||
        @infra.matches_any(file, expanded_manual_groups) {
        covered_files.push(file)
      }
    }
    let uncovered_files : Array[String] = []
    for file in staged_files {
      if !covered_files.contains(file) {
        uncovered_files.push(file)
      }
    }
    @domain.TaskScopeSuggestion::{
      target_groups: seed.manual_target_groups,
      target_paths: seed.manual_target_paths,
      covered_files,
      uncovered_files,
      group_matches: [],
      reason_lines: [
        "用户已经手工指定了任务范围，所以系统直接沿用这些范围",
        "系统仍然保留了暂存文件列表，方便后续报告解释",
      ],
    }
  } else {
    let group_matches = collect_group_matches(
      repo_rules, template, staged_files,
    )
    let target_groups : Array[String] = []
    let covered_files : Array[String] = []
    for group_match in group_matches {
      target_groups.push(group_match.group_name)
      for file in group_match.matched_files {
        if !covered_files.contains(file) {
          covered_files.push(file)
        }
      }
    }
    let uncovered_files : Array[String] = []
    for file in staged_files {
      if !covered_files.contains(file) {
        uncovered_files.push(file)
      }
    }
    let target_paths = collapse_files_into_target_paths(
      uncovered_files, template,
    )

    let reason_lines : Array[String] = [
      "系统先尝试用仓库里已经定义好的路径组去覆盖暂存文件",
      "路径组没有覆盖到的文件，会被单独写进 target_paths，避免范围丢失",
    ]
    if !target_groups.is_empty() {
      reason_lines.push(
        "本次一共命中了 \{target_groups.length()} 个路径组",
      )
    }
    if !target_paths.is_empty() {
      reason_lines.push(
        "还有 \{target_paths.length()} 条路径需要单独保留",
      )
    }

    @domain.TaskScopeSuggestion::{
      target_groups,
      target_paths,
      covered_files,
      uncovered_files,
      group_matches,
      reason_lines,
    }
  }
}

///|
/// 为自动补全结果生成说明文字。
/// 这些文字会直接写进 `current-task.yml`，给用户解释“系统刚刚做了什么”。
fn build_plan_notes(
  seed : @domain.CurrentTaskDraftSeed,
  title_suggestion : @domain.TaskTitleSuggestion,
  scope_suggestion : @domain.TaskScopeSuggestion,
  staged_files : Array[String],
) -> Array[String] {
  let notes : Array[String] = [
    "系统在生成任务时看到了 \{staged_files.length()} 个暂存文件",
    title_suggestion.reason,
  ]
  for reason in scope_suggestion.reason_lines {
    notes.push(reason)
  }
  if seed.has_manual_title() {
    notes.push("当前标题来自命令行输入")
  }
  if seed.has_manual_scope() {
    notes.push("当前范围来自命令行输入")
  }
  if scope_suggestion.needs_manual_review() {
    notes.push(
      "建议打开 current-task.yml 再看一眼，确认系统推断的范围是否准确",
    )
  }
  notes
}

///|
/// 生成“哪些字段是自动补上的”这份名单。
/// 这个字段会直接写进 current-task，让人一眼看出系统碰了哪些地方。
fn build_auto_inferred_fields(
  seed : @domain.CurrentTaskDraftSeed,
) -> Array[String] {
  let fields : Array[String] = [
    "required_artifacts", "required_commands", "staged_files", "artifact_dir", "check_mode",
  ]
  if !seed.has_manual_title() {
    fields.push("title")
  }
  if !seed.has_manual_scope() {
    fields.push("target_groups")
    fields.push("target_paths")
  }
  fields
}

///|
/// 这是对外暴露的主入口：根据模板、仓库规则和 git 快照生成自动补全计划。
/// 入参：
/// - `seed`：命令行刚进来的原始任务草稿
/// - `repo_rules`：仓库级路径组和长期规则
/// - `template`：当前任务类型对应的模板
/// - `snapshot`：当前 git 暂存快照
/// - `timestamp_ns`：这次自动补全发生的时间戳
pub fn build_task_autofill_plan(
  seed : @domain.CurrentTaskDraftSeed,
  repo_rules : @domain.RepoRules,
  template : @domain.TaskTemplate,
  snapshot : @domain.GitProjectSnapshot,
  timestamp_ns : String,
  task_defaults? : @domain.TaskDefaults = default_task_defaults(),
) -> @domain.TaskAutoFillPlan raise {
  let allowed_staged_files : Array[String] = []
  for file in snapshot.staged_files {
    if file_is_allowed_by_template(file, template) {
      allowed_staged_files.push(file)
    }
  }
  let title_suggestion = build_title_suggestion(
    seed, allowed_staged_files, task_defaults,
  )
  let scope_suggestion = build_scope_suggestion(
    seed, repo_rules, template, allowed_staged_files,
  )
  let notes = build_plan_notes(
    seed, title_suggestion, scope_suggestion, allowed_staged_files,
  )

  @domain.TaskAutoFillPlan::{
    task_type: seed.task_type,
    title_suggestion,
    scope_suggestion,
    staged_files: allowed_staged_files,
    required_artifacts: @infra.unique_strings(template.required_artifacts),
    required_commands: @infra.unique_strings(template.required_commands),
    artifact_dir: task_defaults.default_artifact_dir,
    check_mode: task_defaults.default_check_mode,
    auto_inferred_fields: build_auto_inferred_fields(seed),
    notes: notes + task_defaults.note_lines,
    need_user_review: scope_suggestion.needs_manual_review(),
    last_auto_fill_ns: timestamp_ns,
  }
}
