///|
/// 文件说明：校验任务模板的最小语义约束，当前只覆盖文件名与基础数值合法性。
/// 输入：模板文件名与模板对象。
/// 输出：当文件名或关键规则不合法时返回错误码，合法时返回空结果。
/// 作用：在进入门禁合并前，先阻止模板文件本身的结构性错误。

///|
/// 校验模板文件名与模板内容的基础语义。
pub fn validate_template_semantics(
  file_name : String,
  template : @domain.TaskTemplate,
) -> Result[Unit, String] {
  let overlapping_paths = template.allowed_paths.filter(path => {
    template.forbidden_paths.contains(path)
  })
  if file_name != @infra.template_yaml_file_name(template.task_type) {
    Err("CONFIG_SCHEMA_INVALID")
  } else if !overlapping_paths.is_empty() {
    Err("RULE_SEMANTIC_INVALID")
  } else if template.max_changed_files <= 0 {
    Err("RULE_SEMANTIC_INVALID")
  } else {
    Ok(())
  }
}
