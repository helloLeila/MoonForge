///|
/// 文件总说：
/// 这个文件负责把门禁结果翻译成“普通人能直接读懂”的解释。
/// 原始结果里已经有 `violations`，但它们还是偏机器视角：
/// - 代码很多
/// - 同类问题散着
/// - 不够像真正的人类报告
///
/// 这里做的事很直接：
/// 1. 先给每条违规项补一个更像标题的说法
/// 2. 再按主题分桶
/// 3. 最后给整次运行产出一个总标题和下一步动作

///|
/// 根据违规码判断它属于哪个解释分组。
fn bucket_key_for_violation(code : String) -> String {
  match code {
    "PATH_OUT_OF_SCOPE" => "scope"
    "PROTECTED_PATH_TOUCHED" => "scope"
    "CHANGED_FILE_COUNT_EXCEEDED" => "scope"
    "BLOCKED_FILE_NAME" => "file_policy"
    "BLOCKED_FILE_PATTERN" => "file_policy"
    "FORBIDDEN_EXTENSION" => "file_policy"
    "GENERATED_ARTIFACT_TOUCHED" => "file_policy"
    "MISSING_ARTIFACT" => "artifacts"
    "ARTIFACT_INVALID" => "artifacts"
    "REQUIRED_COMMAND_FAILED" => "commands"
    "CONTENT_PATTERN_BLOCKED" => "content"
    "MANUAL_APPROVAL_REQUIRED" => "approval"
    _ => "others"
  }
}

///|
/// 给解释分组取一个能直接显示给人的中文标题。
fn bucket_title(bucket_key : String) -> String {
  match bucket_key {
    "scope" => "任务范围与文件边界"
    "file_policy" => "文件类型与仓库规则"
    "artifacts" => "材料与证明文件"
    "commands" => "必需命令执行"
    "content" => "内容黑名单与调试残留"
    "approval" => "人工审批提醒"
    _ => "其他问题"
  }
}

///|
/// 给违规码取一个更短、更像标题的中文名字。
fn violation_title(code : String) -> String {
  match code {
    "PATH_OUT_OF_SCOPE" => "改动超出任务范围"
    "PROTECTED_PATH_TOUCHED" => "触碰了受保护路径"
    "CHANGED_FILE_COUNT_EXCEEDED" => "改动文件数超限"
    "BLOCKED_FILE_NAME" => "命中了禁止文件名"
    "BLOCKED_FILE_PATTERN" => "命中了禁止路径模式"
    "FORBIDDEN_EXTENSION" => "出现了不允许的后缀"
    "GENERATED_ARTIFACT_TOUCHED" => "误提交了生成产物"
    "MISSING_ARTIFACT" => "缺少必需材料"
    "ARTIFACT_INVALID" => "材料结构不合格"
    "REQUIRED_COMMAND_FAILED" => "必需命令没有通过"
    "CONTENT_PATTERN_BLOCKED" => "代码里留了调试残留"
    "MANUAL_APPROVAL_REQUIRED" => "需要人工审批"
    _ => code
  }
}

///|
/// 为解释项打一个简单严重级别。
/// 这里只做三档：
/// - severe：会直接拒绝
/// - retry：补齐后可重试
/// - info：不是硬拒绝，但需要关注
fn severity_for_violation(code : String) -> String {
  match code {
    "PATH_OUT_OF_SCOPE" => "severe"
    "PROTECTED_PATH_TOUCHED" => "severe"
    "CHANGED_FILE_COUNT_EXCEEDED" => "severe"
    "BLOCKED_FILE_NAME" => "severe"
    "BLOCKED_FILE_PATTERN" => "severe"
    "FORBIDDEN_EXTENSION" => "severe"
    "GENERATED_ARTIFACT_TOUCHED" => "severe"
    "CONTENT_PATTERN_BLOCKED" => "severe"
    "MISSING_ARTIFACT" => "retry"
    "ARTIFACT_INVALID" => "retry"
    "REQUIRED_COMMAND_FAILED" => "retry"
    "MANUAL_APPROVAL_REQUIRED" => "info"
    _ => "info"
  }
}

///|
/// 把原始违规项翻译成解释项。
fn build_explanation_item(
  violation : @domain.Violation,
) -> @domain.DecisionExplanationItem {
  let bucket_key = bucket_key_for_violation(violation.code)
  @domain.DecisionExplanationItem::{
    code: violation.code,
    bucket_key,
    title: violation_title(violation.code),
    severity: severity_for_violation(violation.code),
    file: violation.file,
    detail: violation.detail,
    suggestion: violation.suggestion,
  }
}

///|
/// 为一个分组生成简短摘要。
fn bucket_summary(
  bucket_key : String,
  items : Array[@domain.DecisionExplanationItem],
) -> String {
  let severe_count = items.filter(item => item.severity == "severe").length()
  let retry_count = items.filter(item => item.severity == "retry").length()
  let info_count = items.filter(item => item.severity == "info").length()
  [
    "\{bucket_title(bucket_key)} 共 \{items.length()} 条",
    if severe_count > 0 {
      "严重 \{severe_count}"
    } else {
      ""
    },
    if retry_count > 0 {
      "重试 \{retry_count}"
    } else {
      ""
    },
    if info_count > 0 {
      "提醒 \{info_count}"
    } else {
      ""
    },
  ]
  .filter(line => line != "")
  .join(" | ")
}

///|
/// 按分组把解释项组织起来。
fn group_explanation_items(
  items : Array[@domain.DecisionExplanationItem],
) -> Array[@domain.DecisionExplanationBucket] {
  let grouped : Map[String, Array[@domain.DecisionExplanationItem]] = {}
  for item in items {
    let current = grouped.get_or_default(item.bucket_key, [])
    current.push(item)
    grouped[item.bucket_key] = current
  }

  let ordered_keys : Array[String] = [
    "scope", "file_policy", "artifacts", "commands", "content", "approval", "others",
  ]
  let buckets : Array[@domain.DecisionExplanationBucket] = []
  for key in ordered_keys {
    match grouped.get(key) {
      Some(bucket_items) =>
        buckets.push(@domain.DecisionExplanationBucket::{
          bucket_key: key,
          title: bucket_title(key),
          summary: bucket_summary(key, bucket_items),
          items: bucket_items,
        })
      None => ()
    }
  }
  buckets
}

///|
/// 根据门禁结论构造解释标题。
fn explanation_headline(result : @domain.CheckResult) -> String {
  match result.decision {
    @domain.Accept => "这次检查可以直接放行"
    @domain.Retryable => "这次检查还差一点，补齐后可以重试"
    @domain.Reject => "这次检查已经触发硬性拦截"
    @domain.NeedHumanApproval => "这次检查需要转人工审批"
  }
}

///|
/// 生成整次检查的原因总说。
fn explanation_reason_summary(result : @domain.CheckResult) -> String {
  if result.violations.is_empty() {
    "系统没有发现需要拦截或补齐的问题。"
  } else {
    [
      "系统一共记录了 \{result.violations.length()} 条问题",
      "涉及 \{result.checked_files.length()} 个变更文件",
      "最终结论是 \{result.decision.label()}",
    ].join("，") +
    "。"
  }
}

///|
/// 根据结论和问题项生成后续动作清单。
fn follow_up_steps(
  result : @domain.CheckResult,
  items : Array[@domain.DecisionExplanationItem],
) -> Array[String] {
  let steps : Array[String] = [result.decision.next_action()]
  let mentioned_codes : Array[String] = []
  for item in items {
    if mentioned_codes.contains(item.code) {
      continue
    }
    mentioned_codes.push(item.code)
    steps.push(item.suggestion)
  }
  steps
}

///|
/// 构造完整的门禁解释对象。
pub fn build_decision_explanation(
  result : @domain.CheckResult,
) -> @domain.DecisionExplanation {
  let items : Array[@domain.DecisionExplanationItem] = []
  for violation in result.violations {
    items.push(build_explanation_item(violation))
  }
  let buckets = group_explanation_items(items)
  @domain.DecisionExplanation::{
    decision: result.decision.label(),
    headline: explanation_headline(result),
    reason_summary: explanation_reason_summary(result),
    next_action: result.decision.next_action(),
    buckets,
    follow_up_steps: follow_up_steps(result, items),
  }
}

///|
/// 把解释对象渲染成 Markdown。
/// 这份 Markdown 适合直接落到 latest 输出目录里供人查看。
pub fn render_decision_explanation_markdown(
  explanation : @domain.DecisionExplanation,
) -> String {
  let lines : Array[String] = [
    "# MoonForge 结论解释",
    "",
    "## 总说",
    explanation.headline,
    "",
    explanation.reason_summary,
    "",
    "## 下一步",
    explanation.next_action,
  ]

  if !explanation.follow_up_steps.is_empty() {
    lines.push("")
    lines.push("## 建议动作")
    for step in explanation.follow_up_steps {
      lines.push("- \{step}")
    }
  }

  if explanation.has_buckets() {
    lines.push("")
    lines.push("## 问题分组")
    for bucket in explanation.buckets {
      lines.push("")
      lines.push("### \{bucket.title}")
      lines.push(bucket.summary)
      for item in bucket.items {
        lines.push("- \{item.summary_line()}")
        lines.push("  建议：\{item.suggestion}")
      }
    }
  }

  lines.join("\n") + "\n"
}
