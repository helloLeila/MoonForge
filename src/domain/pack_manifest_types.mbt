///|
/// 文件说明：定义验收包导出时使用的清单结构，便于记录当前包里包含哪些结果文件和固定夹具。

///|
/// `pack-manifest.json` 的结构化内容。
pub(all) struct PackManifestFile {
  mode : String
  run_id : String
  decision : String
  context_summary : String
  exported_files : Array[String]
  input_file_count : Int
  result_file_count : Int
  acceptance_file_count : Int
} derive(Debug, ToJson)
