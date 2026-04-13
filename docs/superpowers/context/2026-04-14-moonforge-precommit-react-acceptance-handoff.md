# MoonForge Handoff Context

## Session Snapshot

- Date: `2026-04-14`
- Worktree: `/Users/leila/Documents/Playground 3/moonforge_gate/.worktrees/moonforge-core-impl`
- Branch: `codex/moonforge-core-impl`
- Product focus:
  - Expand `MoonForge` itself, not the React app.
  - React homepage repo is only the acceptance fixture.
  - Main growth should stay in `init / task / check / report / replay / pack`.
  - Acceptance-specific code should stay under one quarter of the whole implementation.

## User-Confirmed Product Decisions

1. Primary use case is `pre-commit` style checking on staged changes.
2. The same rule set should also support online recheck through CI / PR diff mode.
3. Acceptance scenarios must be rule-trigger scenarios for common AI coding failures, not page-business stories.
4. The agreed 10 first-phase scenarios are:
   - 单文件合规通过
   - 双文件合规通过
   - 非法后缀拦截
   - 越权文件拦截
   - 受保护路径拦截
   - 改动文件数超限
   - 缺少预览材料需重试
   - 必需校验命令未通过需重试
   - 误提交生成产物或缓存文件拦截
   - 调试残留拦截
5. `README` and `AGENTS.md` must be bilingual.
6. Internal acceptance command should be memorable and short:
   - `moonforge acc pass`
   - `moonforge acc retry`
   - `moonforge acc reject`

## What Was Implemented

### Core rule model expansion

- `RepoRules` now supports:
  - `blocked_extensions`
  - `generated_artifact_paths`
  - `blocked_file_names`
  - `blocked_file_patterns`
  - `content_blocklist_patterns`
- `TaskTemplate` now supports:
  - `required_commands`
- `EffectiveTask` now carries all of the above merged runtime constraints.
- `CheckResult`, `ScopeResultFile`, and `ArtifactResultFile` now expose:
  - generated artifact hits
  - blocked filename / pattern hits
  - invalid artifacts
  - command failures
  - content blocklist hits

### New checker capabilities

- `src/checkers/command_checker.mbt`
  - runs required shell commands in repo cwd
- `src/checkers/content_pattern_checker.mbt`
  - scans added diff lines for debug residue / blocked patterns
- `src/infra/process_runner.mbt`
  - minimal synchronous shell runner using libuv process APIs
- `src/checkers/file_type_checker.mbt`
  - now distinguishes:
    - forbidden extensions
    - blocked filenames
    - blocked path patterns
    - generated artifact paths
- `src/checkers/artifact_checker.mbt`
  - now validates:
    - missing artifacts
    - JSON object shape
    - required JSON fields
    - markdown body presence
- `src/checkers/gate.mbt`
  - now produces `Retryable` on missing / invalid artifacts and command failures
  - now produces `Reject` on generated artifacts, blocked content, blocked patterns, blocked filenames, etc.

### Service-layer wiring

- `src/services/commands.mbt` now:
  - loads new repo rule fields
  - loads `required_commands`
  - loads artifact schema required fields from `.moonforge/artifact-schemas/*.yml`
  - initializes default artifact schemas for:
    - `review-report.json`
    - `test-report.json`
    - `preview-report.json`
  - passes repo root and artifact schema map into `evaluate_gate`
  - writes richer output files

### Internal acceptance package

- `src/services/acceptance_service.mbt`
  - implements internal fixed-case acceptance runner
- New fixed acceptance assets:
  - `examples/acceptance/current.yml`
  - `examples/acceptance/react-homepage-fixture/...`
  - `examples/acceptance/cases/pass/...`
  - `examples/acceptance/cases/retry/...`
  - `examples/acceptance/cases/reject/...`
- `docs/acceptance/matrix.md`
  - rewritten to the 10 pre-commit rule scenarios
- `cmd/main/main.mbt`
  - now exposes `acc pass|retry|reject`

### Docs

- `README.mbt.md` is now bilingual and explains:
  - pre-commit flow
  - CI recheck flow
  - repo config structure
  - acceptance fixture usage
- `AGENTS.md` is now bilingual and reflects the current rule-engine focus.

## Test Status

Verified in this session:

- `moon test`
  - result: `Total tests: 100, passed: 100, failed: 0.`
- `moon run cmd/main -- acc pass`
  - result: `moonforge acc pass => Accept`
- `moon run cmd/main -- acc retry`
  - result: `moonforge acc retry => Retryable`
- `moon run cmd/main -- acc reject`
  - result: `moonforge acc reject => Reject`

Also completed:

- `moon info`
- `moon fmt`

Known warnings still present:

- `tests/unit/moon.pkg`
- `tests/integration/moon.pkg`
- `tests/e2e/moon.pkg`

These currently emit unused-package warnings only. They do not break builds or tests.

## Current Changed Files

Main touched areas:

- `cmd/main/main.mbt`
- `src/domain/*`
- `src/checkers/*`
- `src/infra/process_runner.mbt`
- `src/services/commands.mbt`
- `src/services/acceptance_service.mbt`
- `examples/acceptance/*`
- `docs/acceptance/matrix.md`
- `README.mbt.md`
- `AGENTS.md`
- `tests/unit/*`
- `tests/integration/gate_flow_test.mbt`
- `tests/e2e/*`

Generated interface files also changed after `moon info`:

- `src/checkers/pkg.generated.mbti`
- `src/domain/pkg.generated.mbti`
- `src/infra/pkg.generated.mbti`
- `src/services/pkg.generated.mbti`
- `tests/e2e/pkg.generated.mbti`

## What Is Not Done Yet

1. No commits have been created yet.
   - User wants the work later split into roughly `50` meaningful commits.
2. The large `15000` effective MoonBit LOC target is not yet reached.
   - Current work is a solid rule-engine expansion slice, not the full expansion plan.
3. GitHub CLI / PR recheck is only partially represented by existing `ci` mode.
   - No dedicated `gh` or PR-oriented command layer has been added yet.
4. The broader scenario-pack expansion across more rule families and more init/task/check/report detail is still open.

## Recommended Resume Order

1. Inspect `git status` and keep this worktree as the active implementation branch.
2. Continue expanding `init/task/check` around more concrete AI coding rule families.
3. Add stronger CI / PR recheck orchestration on top of the existing `ci` mode.
4. Start slicing the completed work into meaningful commits instead of one large commit.
5. Keep acceptance code as a minority while pushing most growth into core command/rule modules.

## Useful Resume Commands

```bash
git -C '/Users/leila/Documents/Playground 3/moonforge_gate/.worktrees/moonforge-core-impl' status --short
moon test
moon run cmd/main -- acc pass
moon run cmd/main -- acc retry
moon run cmd/main -- acc reject
```
