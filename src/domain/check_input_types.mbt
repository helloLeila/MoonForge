///|
/// 文件总说：
/// 这个文件定义“本地 check 真正拿到的输入长什么样”。
/// 之所以要单独建模，是因为用户执行 `moonforge check` 时，系统会在内部补出很多东西：
/// - patch.diff 放在哪里
/// - 材料目录从哪里找
/// - 这次本地输入一共看到了哪些暂存文件
/// - 系统到底自动准备了什么
///
/// 这些信息如果只散落在服务层变量里，后面想做报告、回放和调试都不方便。

///|
/// 一次本地检查最终使用的输入描述。
/// 它既描述 patch 输入，也描述材料目录和辅助说明文件。
pub(all) struct LocalCheckInput {
  run_dir : String
  patch_path : String
  artifact_source_dir : String
  staged_files : Array[String]
  notes : Array[String]
} derive(Debug, ToJson)

///|
/// 根据本地输入目录生成稳定的运行编号。
pub fn LocalCheckInput::run_id(self : LocalCheckInput) -> String {
  let normalized = self.run_dir.trim_end(chars="/").to_string()
  let parts = normalized.split("/").map(part => part.to_string()).collect()
  if parts.is_empty() {
    "run-local-input"
  } else {
    "run-\{parts[parts.length() - 1]}"
  }
}

///|
/// 给日志和测试使用的简短摘要。
pub fn LocalCheckInput::summary(self : LocalCheckInput) -> String {
  "run_dir=\{self.run_dir} / staged_files=\{self.staged_files.length()} / artifact_dir=\{self.artifact_source_dir}"
}
