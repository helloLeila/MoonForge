///|
/// 文件总说：
/// 这个文件负责把一次运行的输入来源讲清楚。
/// 这对真实用户很重要，因为“check 为什么会得出这个结果”，
/// 很大一部分其实取决于它到底拿到了什么输入。
///
/// 所以这里会明确说：
/// 1. 运行目录在哪里
/// 2. 材料主目录在哪里
/// 3. 系统又额外扫了哪些目录
/// 4. 最后找到了多少材料、还缺多少

///|
/// 生成运行模式对应的人话标签。
fn render_mode_story(mode : String) -> String {
  match mode {
    "pr" => "这次运行属于 PR 复检输入"
    "ci" => "这次运行属于 CI 复检输入"
    _ => "这次运行属于本地暂存区检查输入"
  }
}

///|
/// 统计命中的材料数。
fn found_artifact_count(discovery : @domain.MaterialDiscoveryResult) -> Int {
  let mut count = 0
  for record in discovery.records {
    if record.found() {
      count = count + 1
    }
  }
  count
}

///|
/// 统计仍然缺失的材料数。
fn missing_artifact_count(discovery : @domain.MaterialDiscoveryResult) -> Int {
  let mut count = 0
  for record in discovery.records {
    if !record.found() {
      count = count + 1
    }
  }
  count
}

///|
/// 构造“材料发现记录”说明。
fn build_discovery_lines(
  discovery : @domain.MaterialDiscoveryResult,
) -> Array[String] {
  let lines : Array[String] = []
  for record in discovery.records {
    match (record.matched_path, record.matched_name) {
      (Some(path), Some(name)) =>
        lines.push("\{record.artifact_name} 命中 \{name}，位置在 \{path}")
      (Some(path), None) =>
        lines.push("\{record.artifact_name} 已命中，位置在 \{path}")
      (None, _) =>
        lines.push(
          "\{record.artifact_name} 尚未命中；系统已搜索 \{record.searched_directories.length()} 个目录",
        )
    }
  }
  lines
}

///|
/// 构造运行输入说明主对象。
pub fn build_run_input_story_view(
  mode : String,
  run_dir : String,
  artifact_source_dir : String,
  discovery : @domain.MaterialDiscoveryResult,
) -> @domain.RunInputStoryView {
  let found_count = found_artifact_count(discovery)
  let missing_count = missing_artifact_count(discovery)
  let lines : Array[String] = [
    "运行目录：\{run_dir}",
    "材料主目录：\{artifact_source_dir}",
    "候选搜索目录数：\{discovery.searched_directories.length()}",
    "已命中材料数：\{found_count}",
    "仍缺失材料数：\{missing_count}",
  ]
  for line in build_discovery_lines(discovery) {
    lines.push(line)
  }

  @domain.RunInputStoryView::{
    headline: render_mode_story(mode),
    mode,
    run_dir,
    artifact_source_dir,
    search_directories: discovery.searched_directories,
    discovered_artifact_count: found_count,
    missing_artifact_count: missing_count,
    lines,
  }
}

///|
/// 把输入说明渲染成 Markdown。
pub fn render_run_input_story_markdown(
  view : @domain.RunInputStoryView,
) -> String {
  let lines : Array[String] = [
    "# MoonForge 输入来源说明",
    "",
    "## 总说",
    view.headline,
    "",
    view.summary(),
    "",
    "## 分说",
  ]
  for line in view.lines {
    lines.push("- \{line}")
  }
  lines.join("\n") + "\n"
}
