///|
/// 文件说明：实现 pack 命令的独立服务层，负责收集检查结果文件并生成压缩包。
/// 联动文件：由 `src/services/commands.mbt` 调用，依赖 `src/infra/run_store.mbt` 读取运行目录。

///|
/// 从给定的文件名列表中识别所有需要打包的结果文件。
/// 入参：`filenames`，文件名数组。
/// 出参：过滤后的结果文件名数组。
pub fn collect_pack_files(filenames : Array[String]) -> Array[String] {
  filenames.filter(fn(name) {
    name.has_suffix(".json") || name.has_suffix(".md") || name.has_suffix(".txt") ||
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
