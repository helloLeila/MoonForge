///|
/// 文件说明：定义当前任务与生效任务对象，负责承载检查时的任务输入和合并后约束。
/// 联动文件：由 `src/services/commands.mbt` 装配输入，并由 `src/checkers/gate.mbt` 作为判定上下文使用。

///|
/// 当前任务文件对应的运行时对象。
pub(all) struct CurrentTask {
  task_type : String
  title : String
  target_paths : Array[String]
} derive(Debug, ToJson)

///|
/// 仓库规则、模板规则与当前任务合并后的生效约束。
pub(all) struct EffectiveTask {
  task_type : String
  title : String
  allowed_paths : Array[String]
  forbidden_paths : Array[String]
  approval_required_paths : Array[String]
  allowed_extensions : Array[String]
  required_artifacts : Array[String]
  max_changed_files : Int
} derive(Debug, ToJson)
