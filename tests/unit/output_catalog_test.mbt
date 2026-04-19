///|
/// 文件总说：
/// 这个文件验证输出目录导航和阅读指引能产出最基本的说明文本。
test "output catalog quickstart mentions core files" {
  let catalog = @services.build_output_catalog_view("local")
  let quickstart = @services.render_output_catalog_quickstart(catalog)

  assert_true(catalog.has_entries())
  assert_true(quickstart.contains("report-summary.txt"))
  assert_true(quickstart.contains("report-view.md"))
}

///|
test "output walkthrough builds ordered reading steps" {
  let task_profile = @domain.TaskProfileView::{
    headline: "task profile",
    summary: "summary",
    lines: ["line"],
    need_user_review: true,
  }
  let run_input_story = @domain.RunInputStoryView::{
    headline: "input story",
    mode: "local",
    run_dir: "/tmp/run",
    artifact_source_dir: "/tmp/artifacts",
    search_directories: ["/tmp/artifacts"],
    discovered_artifact_count: 1,
    missing_artifact_count: 0,
    lines: ["line"],
  }
  let report_view = @domain.ReportView::{
    mode: "local",
    decision: "Retryable",
    headline: "headline",
    short_summary: "summary",
    sections: [
      @domain.ReportViewSection::{
        title: "结论原因",
        intro: "intro",
        lines: ["line"],
        is_warning: true,
      },
    ],
    next_steps: ["补齐材料"],
    history_hint: "history",
  }
  let preflight = @domain.PreflightAdviceBundle::{
    summary: "warning",
    items: [
      @domain.PreflightAdviceItem::{
        source: "task_description_checker",
        severity: "warning",
        title: "任务标题质量提醒",
        detail: "标题太泛",
        suggestion: "改具体一点",
      },
    ],
    need_user_review: true,
  }
  let catalog = @services.build_output_catalog_view("local")
  let walkthrough = @services.build_output_walkthrough_view(
    task_profile, run_input_story, report_view, preflight, catalog,
  )

  assert_true(walkthrough.has_steps())
  assert_true(walkthrough.first_step() is Some(_))
}
