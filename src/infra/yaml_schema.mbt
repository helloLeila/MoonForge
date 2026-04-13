///|
/// 文件说明：提供与 YAML 配置文件名相关的最小辅助函数，避免校验器重复拼接字符串。
/// 输入：任务类型字符串。
/// 输出：对应模板配置文件的标准文件名。
/// 作用：只负责把任务类型映射成 `task-type.yml` 形式，不承担任何解析或校验职责。

///|
/// 返回模板 YAML 的标准文件名。
pub fn template_yaml_file_name(task_type : String) -> String {
  "\{task_type}.yml"
}
