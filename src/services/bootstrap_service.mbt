///|
/// 文件总说：
/// 这个文件专门负责“MoonForge 初始化后，项目默认行为应该长什么样”。
/// 它不直接写磁盘，只负责给出一套稳定、可解释的默认值。
///
/// 这样做的好处很简单：
/// - `init` 只管把默认值写出去
/// - `task / check / report` 只管把默认值读回来
/// - 默认值改动时，只需要来这里改一处

///|
/// 返回按任务类型区分的默认标题前缀。
/// 这些前缀会参与 `task <type>` 的自动标题生成。
fn default_title_prefixes() -> Map[String, String] {
  {
    "feature-change": "补充",
    "bug-fix": "修正",
    "api-change": "调整",
    "config-change": "更新",
    "test-addition": "补上",
  }
}

///|
/// 返回 task 阶段默认偏好。
pub fn default_task_defaults() -> @domain.TaskDefaults {
  @domain.TaskDefaults::{
    default_check_mode: "local",
    default_artifact_dir: ".moonforge/artifacts/current",
    default_title_prefixes: default_title_prefixes(),
    note_lines: [
      "如果系统自动生成的标题和范围不准确，请直接修改 current-task.yml",
      "建议优先用路径组描述任务范围，只有补不全时再写显式路径",
    ],
  }
}

///|
/// 返回 check 阶段默认偏好。
pub fn default_check_preferences() -> @domain.CheckPreferences {
  @domain.CheckPreferences::{
    prefer_staged_diff: true,
    auto_prepare_local_run_input: true,
    keep_local_input_snapshot: true,
    artifact_search_dirs: [
      ".moonforge/artifacts/current", ".moonforge/artifacts/latest", ".moonforge/out/local/latest",
    ],
    write_input_summary: true,
  }
}

///|
/// 返回 report 阶段默认偏好。
pub fn default_report_preferences() -> @domain.ReportPreferences {
  @domain.ReportPreferences::{
    show_context: true,
    show_metrics: true,
    show_next_action: true,
    show_history_hint: true,
    show_preflight_hint: true,
  }
}

///|
/// 返回完整 bootstrap 配置。
pub fn default_bootstrap_bundle() -> @domain.BootstrapBundle {
  @domain.BootstrapBundle::{
    task_defaults: default_task_defaults(),
    check_preferences: default_check_preferences(),
    report_preferences: default_report_preferences(),
  }
}
