# MoonForge Pre-commit React Acceptance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expand `MoonForge` into a rule-driven pre-commit and PR recheck gate for AI coding workflows, with bilingual docs and a minimal acceptance pack, while keeping acceptance-specific code under one quarter of the total implementation.

**Architecture:** Keep `init / task / check / report / replay / pack / validate / doctor` as the public surface, but move the core logic behind them into scenario-aware rule loading, staged/PR input adapters, trigger-based checks, command validation, artifact schema validation, and richer reporting. Add `acc` only as an internal acceptance harness that reuses the same rule engine with fixed fixture inputs and expected outputs.

**Tech Stack:** MoonBit, git staged diff workflow, JSON/YAML config parsing, existing MoonForge service/checker layers, React fixture acceptance inputs, markdown docs.

---

## File Map

### Existing files expected to change

- `cmd/main/main.mbt`
  - Extend CLI tree with `acc` and shorter acceptance cases.
- `src/domain/types.mbt`
  - Add richer rule, artifact schema, command requirement, and trigger result types.
- `src/domain/result_types.mbt`
  - Extend result payloads for new trigger families and bilingual summaries.
- `src/domain/task_types.mbt`
  - Add scenario-aware task metadata if needed.
- `src/checkers/gate.mbt`
  - Split monolithic checks into trigger-oriented orchestration.
- `src/checkers/artifact_checker.mbt`
  - Add artifact existence and schema validation.
- `src/checkers/file_type_checker.mbt`
  - Support blocked extensions and generated-artifact detection.
- `src/checkers/scope_checker.mbt`
  - Keep path ownership checks focused and reusable.
- `src/checkers/task_validator.mbt`
  - Validate new task template fields.
- `src/checkers/template_validator.mbt`
  - Validate required commands and artifact schema references.
- `src/services/commands.mbt`
  - Wire new config loading, local/PR modes, `acc`, and richer outputs.
- `src/services/check_service.mbt`
  - Render richer summaries.
- `src/services/report_service.mbt`
  - Produce bilingual result summaries with trigger details.
- `src/services/replay_service.mbt`
  - Replay newer snapshot content and acceptance cases.
- `src/services/pack_service.mbt`
  - Export acceptance bundles and richer run artifacts.
- `src/services/doctor_service.mbt`
  - Diagnose missing hook/config/rule assets.
- `src/infra/flat_yaml.mbt`
  - Support additional scalar/list lookups cleanly.
- `src/infra/run_store.mbt`
  - Persist richer snapshots and acceptance outputs.
- `src/infra/report_text.mbt`
  - Centralize bilingual output strings.
- `src/adapters/git_local_diff.mbt`
  - Ensure staged diff/file enumeration is reliable.
- `src/adapters/git_ci_diff.mbt`
  - Support PR diff inputs.
- `src/adapters/mode_paths.mbt`
  - Add acceptance-related output locations if needed.
- `README.mbt.md`
  - Convert to bilingual.
- `AGENTS.md`
  - Convert to bilingual.

### New files expected to be created

- `src/domain/artifact_schema_types.mbt`
  - Types for artifact schema definitions.
- `src/domain/rule_trigger_types.mbt`
  - Types for trigger categories and hit details.
- `src/checkers/generated_artifact_checker.mbt`
  - Detect staged generated files and caches.
- `src/checkers/content_pattern_checker.mbt`
  - Detect debug residue and blocklisted content.
- `src/checkers/command_checker.mbt`
  - Run required commands and normalize results.
- `src/checkers/artifact_schema_checker.mbt`
  - Validate artifact JSON shape against schema rules.
- `src/services/acceptance_service.mbt`
  - Internal acceptance runner for `acc pass|retry|reject`.
- `src/services/pr_check_service.mbt`
  - Shared orchestration for PR-mode checks if separation is cleaner.
- `src/infra/json_shape.mbt`
  - Minimal JSON field/shape inspection helpers.
- `src/infra/git_hook_text.mbt`
  - Generate pre-commit hook content.
- `src/infra/acceptance_store.mbt`
  - Fixture loading and expected-output comparison helpers.
- `.moonforge/artifact-schemas/preview-report.yml`
  - Default preview artifact schema.
- `.moonforge/artifact-schemas/review-report.yml`
  - Default review artifact schema.
- `examples/acceptance/react-homepage-fixture/...`
  - Minimal React homepage fixture files.
- `examples/acceptance/cases/pass/...`
  - Fixed pass case inputs and expected outputs.
- `examples/acceptance/cases/retry/...`
  - Fixed retry case inputs and expected outputs.
- `examples/acceptance/cases/reject/...`
  - Fixed reject case inputs and expected outputs.

### Test files expected to change or be added

- `tests/unit/task_validator_test.mbt`
- `tests/unit/template_validator_test.mbt`
- `tests/unit/artifact_checker_test.mbt`
- `tests/unit/file_type_checker_test.mbt`
- `tests/unit/cli_command_test.mbt`
- `tests/unit/doctor_service_test.mbt`
- `tests/integration/gate_flow_test.mbt`
- `tests/integration/validate_flow_test.mbt`
- `tests/integration/replay_flow_test.mbt`
- `tests/integration/pack_flow_test.mbt`
- `tests/e2e/acceptance_docs_test.mbt`
- `tests/e2e/precommit_acceptance_test.mbt`
- `tests/e2e/pr_recheck_acceptance_test.mbt`

## Task 1: Expand Domain Types For Rule-Driven Checks

**Files:**
- Create: `src/domain/artifact_schema_types.mbt`
- Create: `src/domain/rule_trigger_types.mbt`
- Modify: `src/domain/types.mbt`
- Modify: `src/domain/result_types.mbt`
- Modify: `src/domain/moon.pkg`
- Test: `tests/unit/rules_test.mbt`

- [ ] **Step 1: Write failing tests for new domain objects**

Add tests that assert:
- artifact schema objects retain required field lists
- trigger hit objects preserve trigger code, file, and detail
- check results can carry command failures and content-pattern hits

- [ ] **Step 2: Run the focused unit tests to verify failure**

Run: `moon test tests/unit --filter rules`
Expected: fail because new domain types and fields do not exist yet.

- [ ] **Step 3: Add minimal domain types and result fields**

Implement:
- `ArtifactSchema`
- `ArtifactFieldRule`
- `RuleTriggerHit`
- result fields for `command_failures`, `generated_artifact_files`, `content_blocklist_hits`

- [ ] **Step 4: Run the focused unit tests to verify pass**

Run: `moon test tests/unit --filter rules`
Expected: pass.

- [ ] **Step 5: Commit**

Commit message: `feat: add domain types for rule-triggered checks`

## Task 2: Validate New Template And Repo Rule Fields

**Files:**
- Modify: `src/services/commands.mbt`
- Modify: `src/checkers/task_validator.mbt`
- Modify: `src/checkers/template_validator.mbt`
- Modify: `src/checkers/rule_codes_test.mbt`
- Test: `tests/unit/task_validator_test.mbt`
- Test: `tests/unit/template_validator_test.mbt`

- [ ] **Step 1: Write failing tests for new config fields**

Cover:
- `required_commands`
- `blocked_extensions`
- `generated_artifact_paths`
- `blocked_file_patterns`
- `content_blocklist_patterns`
- artifact schema references

- [ ] **Step 2: Run the config validation tests to verify failure**

Run: `moon test tests/unit --filter validator`
Expected: fail because new fields are ignored or treated as invalid.

- [ ] **Step 3: Implement minimal parsing and validation**

Update loaders and validators so:
- repo rules accept new list fields
- task templates accept `required_commands`
- artifact schema references are checked for existence
- invalid empty command definitions fail validation

- [ ] **Step 4: Re-run config validation tests**

Run: `moon test tests/unit --filter validator`
Expected: pass.

- [ ] **Step 5: Commit**

Commit message: `feat: validate extended repo and task rule fields`

## Task 3: Add Artifact Schema Validation

**Files:**
- Create: `src/checkers/artifact_schema_checker.mbt`
- Create: `src/infra/json_shape.mbt`
- Modify: `src/checkers/artifact_checker.mbt`
- Modify: `src/checkers/moon.pkg`
- Modify: `src/infra/moon.pkg`
- Test: `tests/unit/artifact_checker_test.mbt`

- [ ] **Step 1: Write failing tests for artifact schema checks**

Cover:
- missing file
- invalid JSON
- JSON missing required fields
- JSON with valid required fields

- [ ] **Step 2: Run artifact tests to verify failure**

Run: `moon test tests/unit --filter artifact`
Expected: fail because schema-aware validation is absent.

- [ ] **Step 3: Implement minimal schema-aware artifact checking**

Add helpers to:
- read JSON text
- inspect required field presence
- return structured retryable violations

- [ ] **Step 4: Re-run artifact tests**

Run: `moon test tests/unit --filter artifact`
Expected: pass.

- [ ] **Step 5: Commit**

Commit message: `feat: add artifact schema validation`

## Task 4: Add Generated Artifact And Blocked Extension Checks

**Files:**
- Create: `src/checkers/generated_artifact_checker.mbt`
- Modify: `src/checkers/file_type_checker.mbt`
- Modify: `src/checkers/gate.mbt`
- Test: `tests/unit/file_type_checker_test.mbt`

- [ ] **Step 1: Write failing tests for blocked extensions and generated outputs**

Cover:
- legal `.jsx/.js`
- blocked `.map`
- generated `dist/**`
- generated `.next/**`
- blocked `.DS_Store`

- [ ] **Step 2: Run file-type tests to verify failure**

Run: `moon test tests/unit --filter file_type`
Expected: fail because these trigger families are not yet checked.

- [ ] **Step 3: Implement minimal generated-artifact detection**

Add checks for:
- blocked extensions
- generated artifact path patterns
- blocked filename patterns

- [ ] **Step 4: Re-run file-type tests**

Run: `moon test tests/unit --filter file_type`
Expected: pass.

- [ ] **Step 5: Commit**

Commit message: `feat: block generated artifacts and forbidden extensions`

## Task 5: Add Content Pattern Blocklist Checks

**Files:**
- Create: `src/checkers/content_pattern_checker.mbt`
- Modify: `src/checkers/gate.mbt`
- Test: `tests/unit/cli_command_test.mbt`
- Test: `tests/unit/rules_test.mbt`

- [ ] **Step 1: Write failing tests for debug residue detection**

Cover staged content containing:
- `console.log`
- `debugger`
- `printf`
- `println`
- `TODO`
- `FIXME`

- [ ] **Step 2: Run focused tests to verify failure**

Run: `moon test tests/unit --filter rules`
Expected: fail because no content-pattern blocklist exists.

- [ ] **Step 3: Implement minimal content-pattern checker**

Return structured reject violations with:
- trigger code
- file path
- matched pattern

- [ ] **Step 4: Re-run focused tests**

Run: `moon test tests/unit --filter rules`
Expected: pass.

- [ ] **Step 5: Commit**

Commit message: `feat: reject staged debug residue patterns`

## Task 6: Add Required Command Execution Checks

**Files:**
- Create: `src/checkers/command_checker.mbt`
- Modify: `src/checkers/gate.mbt`
- Modify: `src/services/check_service.mbt`
- Test: `tests/unit/cli_command_test.mbt`
- Test: `tests/integration/gate_flow_test.mbt`

- [ ] **Step 1: Write failing tests for required command behavior**

Cover:
- no required commands
- command success
- command failure becomes retryable

- [ ] **Step 2: Run command-related tests to verify failure**

Run: `moon test tests/unit --filter cli_command`
Expected: fail because command-driven retries are not supported.

- [ ] **Step 3: Implement minimal command execution adapter**

Normalize:
- command text
- exit code
- stderr/stdout summary
- retryable violation rendering

- [ ] **Step 4: Re-run command tests**

Run: `moon test tests/unit --filter cli_command`
Expected: pass.

- [ ] **Step 5: Commit**

Commit message: `feat: add required command checks`

## Task 7: Refactor Gate Evaluation Into Trigger Families

**Files:**
- Modify: `src/checkers/gate.mbt`
- Modify: `src/domain/result_types.mbt`
- Modify: `src/services/check_service.mbt`
- Test: `tests/unit/scope_checker_test.mbt`
- Test: `tests/integration/gate_flow_test.mbt`

- [ ] **Step 1: Write failing integration tests for the 10 rule scenarios**

Cover:
- pass single file
- pass two files
- forbidden extension
- out-of-scope file
- protected path
- file count exceeded
- missing preview
- command failure
- generated artifact
- debug residue

- [ ] **Step 2: Run integration tests to verify failure**

Run: `moon test tests/integration --filter gate_flow`
Expected: fail because current gate logic only covers the older subset.

- [ ] **Step 3: Implement trigger-oriented orchestration**

Refactor `evaluate_gate` so it:
- collects trigger hits per checker
- merges retryable and reject reasons
- records richer outputs without widening command surface

- [ ] **Step 4: Re-run gate integration tests**

Run: `moon test tests/integration --filter gate_flow`
Expected: pass.

- [ ] **Step 5: Commit**

Commit message: `feat: refactor gate evaluation into trigger families`

## Task 8: Add Pre-commit Hook Scaffolding In init And doctor

**Files:**
- Create: `src/infra/git_hook_text.mbt`
- Modify: `src/services/commands.mbt`
- Modify: `src/services/doctor_service.mbt`
- Test: `tests/unit/doctor_service_test.mbt`
- Test: `tests/integration/task_flow_test.mbt`

- [ ] **Step 1: Write failing tests for hook generation and diagnosis**

Cover:
- init writes hook scaffold text
- doctor reports missing hook
- doctor reports present hook

- [ ] **Step 2: Run doctor tests to verify failure**

Run: `moon test tests/unit --filter doctor_service`
Expected: fail because hook support is missing or not diagnosed.

- [ ] **Step 3: Implement minimal hook scaffold generation**

Generate a pre-commit snippet that:
- invokes `moonforge check`
- exits non-zero on retry/reject
- is idempotent when re-running init

- [ ] **Step 4: Re-run doctor tests**

Run: `moon test tests/unit --filter doctor_service`
Expected: pass.

- [ ] **Step 5: Commit**

Commit message: `feat: scaffold and diagnose pre-commit hooks`

## Task 9: Add PR Recheck Mode

**Files:**
- Modify: `src/adapters/git_ci_diff.mbt`
- Modify: `src/services/commands.mbt`
- Create: `src/services/pr_check_service.mbt`
- Test: `tests/integration/replay_flow_test.mbt`
- Test: `tests/e2e/pr_recheck_acceptance_test.mbt`

- [ ] **Step 1: Write failing tests for PR diff mode**

Cover:
- mode `pr` or `ci` loading PR diff input
- output path separation for local vs PR results

- [ ] **Step 2: Run PR-mode tests to verify failure**

Run: `moon test tests/e2e --filter pr_recheck`
Expected: fail because PR-mode orchestration is incomplete.

- [ ] **Step 3: Implement minimal PR-mode orchestration**

Reuse the same trigger engine with a different diff adapter and output location.

- [ ] **Step 4: Re-run PR-mode tests**

Run: `moon test tests/e2e --filter pr_recheck`
Expected: pass.

- [ ] **Step 5: Commit**

Commit message: `feat: add PR recheck mode`

## Task 10: Strengthen report And Bilingual Output Helpers

**Files:**
- Modify: `src/infra/report_text.mbt`
- Modify: `src/services/report_service.mbt`
- Modify: `src/services/check_service.mbt`
- Test: `tests/integration/validate_flow_test.mbt`
- Test: `tests/e2e/acceptance_docs_test.mbt`

- [ ] **Step 1: Write failing tests for bilingual summaries**

Cover:
- bilingual decision label output
- rule trigger summary text
- repair suggestion rendering

- [ ] **Step 2: Run reporting tests to verify failure**

Run: `moon test tests/integration --filter validate_flow`
Expected: fail because reporting lacks the richer bilingual text contract.

- [ ] **Step 3: Implement minimal bilingual report text helpers**

Centralize:
- decision labels
- trigger descriptions
- repair hints

- [ ] **Step 4: Re-run reporting tests**

Run: `moon test tests/integration --filter validate_flow`
Expected: pass.

- [ ] **Step 5: Commit**

Commit message: `feat: improve bilingual gate reporting`

## Task 11: Strengthen replay And pack For Acceptance Artifacts

**Files:**
- Modify: `src/services/replay_service.mbt`
- Modify: `src/services/pack_service.mbt`
- Modify: `src/infra/run_store.mbt`
- Create: `src/infra/acceptance_store.mbt`
- Test: `tests/integration/replay_flow_test.mbt`
- Test: `tests/integration/pack_flow_test.mbt`

- [ ] **Step 1: Write failing tests for richer snapshot replay and pack exports**

Cover:
- replay sees richer run assets
- pack includes expected files and summaries
- acceptance bundle exports expected outputs

- [ ] **Step 2: Run replay/pack tests to verify failure**

Run: `moon test tests/integration --filter replay_flow`
Run: `moon test tests/integration --filter pack_flow`
Expected: fail because current snapshot and pack logic is too thin.

- [ ] **Step 3: Implement minimal richer replay/pack storage**

Persist and export:
- trigger hit summaries
- acceptance comparison outputs
- bundle-friendly metadata

- [ ] **Step 4: Re-run replay/pack tests**

Run: `moon test tests/integration --filter replay_flow`
Run: `moon test tests/integration --filter pack_flow`
Expected: pass.

- [ ] **Step 5: Commit**

Commit message: `feat: enrich replay and acceptance pack exports`

## Task 12: Add Internal acc Acceptance Runner

**Files:**
- Create: `src/services/acceptance_service.mbt`
- Modify: `cmd/main/main.mbt`
- Modify: `src/services/commands.mbt`
- Test: `tests/e2e/precommit_acceptance_test.mbt`

- [ ] **Step 1: Write failing tests for `acc pass|retry|reject`**

Cover:
- pass case reuses real check pipeline and compares expected outputs
- retry case fails with retryable result
- reject case fails with reject result

- [ ] **Step 2: Run acceptance runner tests to verify failure**

Run: `moon test tests/e2e --filter precommit_acceptance`
Expected: fail because `acc` does not exist yet.

- [ ] **Step 3: Implement minimal acceptance runner**

It must:
- load fixed case configuration
- stage fixed fixture inputs
- run the shared check pipeline
- compare actual outputs against expected outputs

- [ ] **Step 4: Re-run acceptance runner tests**

Run: `moon test tests/e2e --filter precommit_acceptance`
Expected: pass.

- [ ] **Step 5: Commit**

Commit message: `feat: add internal acceptance runner`

## Task 13: Add React Fixture And Acceptance Cases

**Files:**
- Create: `examples/acceptance/react-homepage-fixture/...`
- Create: `examples/acceptance/cases/pass/...`
- Create: `examples/acceptance/cases/retry/...`
- Create: `examples/acceptance/cases/reject/...`
- Test: `tests/e2e/acceptance_docs_test.mbt`

- [ ] **Step 1: Write failing fixture/acceptance documentation tests**

Cover:
- fixture tree exists
- pass/retry/reject cases exist
- each case has patch and expected outputs

- [ ] **Step 2: Run fixture tests to verify failure**

Run: `moon test tests/e2e --filter acceptance_docs`
Expected: fail because the fixture layout is incomplete.

- [ ] **Step 3: Add minimal React fixture and three case bundles**

Populate:
- legal pass case
- retry case with missing preview artifact
- reject case with forbidden path or debug residue

- [ ] **Step 4: Re-run fixture tests**

Run: `moon test tests/e2e --filter acceptance_docs`
Expected: pass.

- [ ] **Step 5: Commit**

Commit message: `feat: add React homepage acceptance fixtures`

## Task 14: Convert README And AGENTS To Bilingual Guidance

**Files:**
- Modify: `README.mbt.md`
- Modify: `AGENTS.md`
- Test: `tests/e2e/acceptance_docs_test.mbt`

- [ ] **Step 1: Write failing doc tests for bilingual structure**

Cover:
- README includes Chinese and English product summary
- README documents pre-commit and PR usage
- AGENTS describes MoonBit project and new acceptance mode bilingually

- [ ] **Step 2: Run doc tests to verify failure**

Run: `moon test tests/e2e --filter acceptance_docs`
Expected: fail because docs are not yet bilingual or complete.

- [ ] **Step 3: Update docs minimally but completely**

Document:
- product scope
- pre-commit usage
- PR recheck usage
- `acc` internal acceptance usage
- config file layout

- [ ] **Step 4: Re-run doc tests**

Run: `moon test tests/e2e --filter acceptance_docs`
Expected: pass.

- [ ] **Step 5: Commit**

Commit message: `docs: add bilingual project guidance`

## Task 15: Final Verification And Commit Slicing

**Files:**
- Modify: any touched implementation files as needed
- Test: `tests/unit/...`
- Test: `tests/integration/...`
- Test: `tests/e2e/...`

- [ ] **Step 1: Run unit suite**

Run: `moon test tests/unit`
Expected: pass.

- [ ] **Step 2: Run integration suite**

Run: `moon test tests/integration`
Expected: pass.

- [ ] **Step 3: Run e2e suite**

Run: `moon test tests/e2e`
Expected: pass.

- [ ] **Step 4: Run formatting and interface generation**

Run: `moon info`
Run: `moon fmt`
Expected: success and only expected `.mbti` changes.

- [ ] **Step 5: Slice remaining work into frequent commits**

Ensure the implementation history is broken into many small, meaningful commits and that acceptance-specific commits remain a minority.

- [ ] **Step 6: Commit**

Commit message: `chore: verify MoonForge pre-commit acceptance expansion`

## Self-Review

### Spec coverage

This plan covers:
- pre-commit local checks
- GitHub PR recheck mode
- ten concrete rule scenarios
- richer init/task/check/report/replay/pack/validate/doctor behavior
- internal acceptance runner
- React fixture acceptance pack
- bilingual docs

Potential follow-on work not included here:
- restoring `NeedHumanApproval`
- multi-repo control planes
- semantic code review

### Placeholder scan

The plan avoids `TODO`, `TBD`, and “implement later” placeholders. Each task has explicit files, targeted tests, run commands, and commit intent.

### Type consistency

New type families are isolated as:
- artifact schema types
- trigger hit types
- richer check result fields

Later tasks refer back to those same concepts without renaming them.
