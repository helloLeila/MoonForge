///|
/// 文件说明：实现 init 命令的独立服务层，负责生成仓库规则模板和默认任务类型模板。
/// 联动文件：由 `src/services/commands.mbt` 的 `init_repo` 函数在初始化流程中调用，输出到 `.moonforge/` 目录。

///|
/// 返回 feature-change 任务类型的默认注释说明文本，用于帮助开发者理解字段含义。
pub fn feature_change_template_header() -> String {
  "# 功能变更任务模板\n# 修改此文件来定制功能变更门禁规则\n"
}

///|
/// 返回 bug-fix 任务类型的默认注释说明文本。
pub fn bug_fix_template_header() -> String {
  "# 缺陷修复任务模板\n# 修改此文件来定制缺陷修复门禁规则\n"
}

///|
/// 返回 api-change 任务类型的默认注释说明文本。
pub fn api_change_template_header() -> String {
  "# 接口变更任务模板\n# 修改此文件来定制接口变更门禁规则\n"
}

///|
/// 返回 config-change 任务类型的默认注释说明文本。
pub fn config_change_template_header() -> String {
  "# 配置变更任务模板\n# 修改此文件来定制配置变更门禁规则\n"
}

///|
/// 返回 test-addition 任务类型的默认注释说明文本。
pub fn test_addition_template_header() -> String {
  "# 测试补充任务模板\n# 修改此文件来定制测试补充门禁规则\n"
}

///|
/// 返回五类任务模板的名称列表，与 init_repo 中生成的文件名保持一致。
pub fn all_task_type_names() -> Array[String] {
  ["feature-change", "bug-fix", "api-change", "config-change", "test-addition"]
}

///|
/// 生成仓库级规则文件的默认文本说明，用于告知开发者各字段含义。
pub fn repo_rules_header() -> String {
  "# MoonForge 仓库规则配置文件\n# 修改此文件来定制仓库级别的门禁规则\n"
}

///|
/// 生成空白当前任务文件的初始化模板文本，引导开发者填写。
pub fn blank_current_task_template() -> String {
  "# 请填写当前任务信息\ntask_type: \"\"\ntitle: \"\"\ntarget_paths:\n  - \"\"\n"
}
