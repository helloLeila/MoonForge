///|
/// 文件说明：实现 pack 命令的独立服务层，负责收集检查结果文件并生成压缩包。
/// 联动文件：由 `src/services/commands.mbt` 调用，依赖 `src/infra/run_store.mbt` 读取运行目录。

///|
/// 从给定的文件名列表中识别所有需要打包的结果文件。
/// 入参：`filenames`，文件名数组。
/// 出参：过滤后的结果文件名数组。
pub fn collect_pack_files(filenames : Array[String]) -> Array[String] {
  filenames.filter(fn(name) {
    name.has_suffix(".json") ||
    name.has_suffix(".md") ||
    name.has_suffix(".txt") ||
    name.has_suffix(".jsonl")
  })
}

///|
/// 生成符合规范的打包文件名，格式为 `moonforge-{run_id}.tar.gz`。
/// 入参：`run_id`，运行标识符。
/// 出参：打包文件名字符串。
pub fn generate_pack_filename(run_id : String) -> String {
  "moonforge-\{run_id}.tar.gz"
}

///|
/// 计算打包文件的总大小估算值（字节）。
/// 入参：`file_sizes`，文件大小数组。
/// 出参：总大小的整数值。
pub fn calculate_total_size(file_sizes : Array[Int]) -> Int {
  let mut total = 0
  for size in file_sizes {
    total = total + size
  }
  total
}

///|
/// 统计导出文件里不同类型的文件数量。
/// 入参：`exported_files`，已经加入验收包的相对路径数组。
/// 入参：`prefix`，需要统计的路径前缀。
/// 出参：匹配该前缀的文件数量。
pub fn count_files_with_prefix(
  exported_files : Array[String],
  prefix : String,
) -> Int {
  let mut count = 0
  for file in exported_files {
    if file.has_prefix(prefix) {
      count = count + 1
    }
  }
  count
}

///|
/// 构造验收包清单对象，记录导出模式、运行结论和文件分布。
/// 入参：`mode`，导出时对应的运行模式。
/// 入参：`run_id`，最近一次运行编号。
/// 入参：`decision`，最近一次运行结论。
/// 入参：`context_summary`，最近一次运行的来源摘要。
/// 入参：`exported_files`，已经加入验收包的相对路径数组。
/// 出参：可直接写入 `pack-manifest.json` 的结构化对象。
pub fn build_pack_manifest(
  mode : String,
  run_id : String,
  decision : String,
  context_summary : String,
  exported_files : Array[String],
) -> @domain.PackManifestFile {
  let acceptance_file_count = count_files_with_prefix(exported_files, "acceptance/")
  @domain.PackManifestFile::{
    mode,
    run_id,
    decision,
    context_summary,
    exported_files,
    input_file_count: exported_files.filter(fn(file) {
      file == "repo-rules.yml" || file == "current-task.yml"
    }).length(),
    result_file_count: exported_files.filter(fn(file) {
      !file.has_prefix("acceptance/") &&
      file != "repo-rules.yml" &&
      file != "current-task.yml" &&
      file != "pack-manifest.json" &&
      file != "pack-summary.md"
    }).length(),
    acceptance_file_count,
  }
}

///|
/// 渲染验收包摘要说明，方便人工快速查看包内重点内容。
/// 入参：`manifest`，已经统计好的验收包清单对象。
/// 出参：可直接写入 `pack-summary.md` 的 Markdown 文本。
pub fn render_pack_summary(manifest : @domain.PackManifestFile) -> String {
  [
    "# MoonForge 验收包摘要",
    "",
    "- 模式：\{manifest.mode}",
    "- 运行编号：\{manifest.run_id}",
    "- 结论：\{manifest.decision}",
    "- 来源：\{manifest.context_summary}",
    "- 固定输入文件数：\{manifest.input_file_count}",
    "- 最近运行结果文件数：\{manifest.result_file_count}",
    "- 内置验收夹具文件数：\{manifest.acceptance_file_count}",
    "- 总文件数：\{manifest.exported_files.length()}",
  ].join("\n") +
  "\n"
}

///|
/// 渲染打包成功的终端提示文本。
/// 入参：`archive_path`，生成的压缩包完整路径。
/// 入参：`file_count`，打包的文件数量。
/// 出参：终端可打印的成功提示文本。
pub fn render_pack_success(archive_path : String, file_count : Int) -> String {
  "📦 打包完成：\{archive_path}（包含 \{file_count} 个文件）"
}

///|
/// 渲染打包失败的错误提示文本。
/// 入参：`reason`，失败原因描述。
/// 出参：终端可打印的错误提示文本。
pub fn render_pack_failure(reason : String) -> String {
  "❌ 打包失败：\{reason}"
}
