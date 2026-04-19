///|
/// 文件说明：定义命令执行结果的领域对象，负责把 shell 命令运行后的关键信息整理成上层容易消费的结构。
/// 联动文件：由 `src/infra/process_runner.mbt` 生产，再被 git 读取器、项目上下文服务和后续自动补全逻辑复用。

///|
/// 一次 shell 命令执行后的完整结果。
/// 这里不仅保存退出码，还保存 stdout 和 stderr，避免上层只能看到“成功/失败”。
pub(all) struct ProcessCapture {
  command : String
  cwd : String
  exit_code : Int
  stdout : String
  stderr : String
} derive(Debug, ToJson)

///|
/// 判断命令是否成功执行。
/// 入参：当前命令执行结果对象。
/// 出参：退出码为 0 时返回 `true`，否则返回 `false`。
pub fn ProcessCapture::is_ok(self : ProcessCapture) -> Bool {
  self.exit_code == 0
}

///|
/// 返回更适合日志展示的单行摘要。
/// 入参：当前命令执行结果对象。
/// 出参：包含命令、目录和退出码的中文摘要。
pub fn ProcessCapture::summary(self : ProcessCapture) -> String {
  "命令：\{self.command}；目录：\{self.cwd}；退出码：\{self.exit_code}"
}

///|
/// 返回标准输出与标准错误中更值得优先展示的那一份文本。
/// 入参：当前命令执行结果对象。
/// 出参：优先返回 stderr，若 stderr 为空则返回 stdout。
pub fn ProcessCapture::preferred_message(self : ProcessCapture) -> String {
  if self.stderr.trim() != "" {
    self.stderr
  } else {
    self.stdout
  }
}
