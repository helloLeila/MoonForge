///|
/// 文件总说：
/// 这个文件定义“把门禁结果翻译成人话”时要用到的结构。
/// 原始 `Violation` 已经够程序判断了，
/// 但对人来说还缺两层组织：
/// 1. 单条问题应该用什么标题和严重级别去讲
/// 2. 多条问题应该按什么主题归并
///
/// 所以这里把解释拆成三层：
/// - `DecisionExplanationItem`：单条问题怎么说
/// - `DecisionExplanationBucket`：同类问题怎么归组
/// - `DecisionExplanation`：整次检查最后怎么总说

///|
/// 单条解释项。
/// 它和原始违规项很像，但会多保存“解释层真正关心”的字段：
/// - 分类桶
/// - 中文标题
/// - 严重级别
pub(all) struct DecisionExplanationItem {
  code : String
  bucket_key : String
  title : String
  severity : String
  file : String?
  detail : String
  suggestion : String
} derive(Debug, ToJson)

///|
/// 把单条解释项压缩成一行。
pub fn DecisionExplanationItem::summary_line(
  self : DecisionExplanationItem,
) -> String {
  match self.file {
    Some(file) => "[\{self.severity}] \{self.title} @ \{file}：\{self.detail}"
    None => "[\{self.severity}] \{self.title}：\{self.detail}"
  }
}

///|
/// 同类解释项的分组。
/// 比如“范围问题”“材料问题”“命令问题”都各自是一组。
pub(all) struct DecisionExplanationBucket {
  bucket_key : String
  title : String
  summary : String
  items : Array[DecisionExplanationItem]
} derive(Debug, ToJson)

///|
/// 返回这个分组中一共有多少条问题。
pub fn DecisionExplanationBucket::count(
  self : DecisionExplanationBucket,
) -> Int {
  self.items.length()
}

///|
/// 判断这个分组是不是高风险分组。
/// 规则很简单：只要里面有一条 severe，就算高风险。
pub fn DecisionExplanationBucket::has_severe_item(
  self : DecisionExplanationBucket,
) -> Bool {
  for item in self.items {
    if item.severity == "severe" {
      return true
    }
  }
  false
}

///|
/// 单次检查的完整解释对象。
pub(all) struct DecisionExplanation {
  decision : String
  headline : String
  reason_summary : String
  next_action : String
  buckets : Array[DecisionExplanationBucket]
  follow_up_steps : Array[String]
} derive(Debug, ToJson)

///|
/// 判断这次解释里是否包含任何问题分组。
pub fn DecisionExplanation::has_buckets(self : DecisionExplanation) -> Bool {
  !self.buckets.is_empty()
}

///|
/// 统计解释里一共有多少条问题项。
pub fn DecisionExplanation::item_count(self : DecisionExplanation) -> Int {
  let mut count = 0
  for bucket in self.buckets {
    count = count + bucket.count()
  }
  count
}

///|
/// 生成整份解释的简短摘要。
pub fn DecisionExplanation::summary(self : DecisionExplanation) -> String {
  [
    "decision=\{self.decision}",
    "buckets=\{self.buckets.length()}",
    "items=\{self.item_count()}",
    "headline=\{self.headline}",
  ].join(" | ")
}
