///|
/// 文件说明：集中生成 Git hook 的固定脚本文本，避免在服务层内拼接多行 shell。

///|
/// 返回 pre-commit hook 必须包含的关键片段，供 doctor 诊断时复用。
pub fn pre_commit_hook_required_markers() -> Array[String] {
  ["moonforge check", ".moonforge/current-task.yml"]
}

///|
/// 返回 MoonForge 的 pre-commit hook 脚本文本。
pub fn render_pre_commit_hook() -> String {
  let script =
    #|#!/bin/sh
    #|set -eu
    #|
    #|# MoonForge pre-commit hook
    #|# 月之锻造提交前门禁钩子
    #|
    #|if [ ! -f .moonforge/current-task.yml ]; then
    #|  echo "MoonForge: missing .moonforge/current-task.yml"
    #|  echo "MoonForge：缺少 .moonforge/current-task.yml"
    #|  exit 1
    #|fi
    #|
    #|mkdir -p .moonforge/fixture-runs/pre-commit
    #|git diff --cached > .moonforge/fixture-runs/pre-commit/patch.diff
    #|output=$(moonforge check --repo . --run .moonforge/fixture-runs/pre-commit 2>&1 || true)
    #|printf '%s\n' "$output"
    #|
    #|case "$output" in
    #|  *"decision: Accept"*)
    #|    exit 0
    #|    ;;
    #|  *)
    #|    exit 1
    #|    ;;
    #|esac
  script
}
