# MoonForge Gate

MoonForge Gate is a MoonBit CLI demo for repository admission checks before code enters a shared repository.

Current demo scope:

- `moonforge init`
- `moonforge task`
- `moonforge validate`
- `moonforge check`
- `moonforge report`
- `moonforge replay`
- `moonforge doctor`
- `moonforge pack`

Current MVP flow:

1. `init` initializes `.moonforge` config, repo rules, and built-in task templates.
2. `task` writes `.moonforge/current-task.yml` from a task type plus target paths/groups.
3. `validate` checks repo rules, task templates, and current task before running the gate.
4. `check` reads `patch.diff` plus required artifacts and writes standard outputs under `.moonforge/out/<mode>/latest`.
5. `report`, `replay`, `doctor`, and `pack` support reading, auditing, diagnosing, and exporting the latest run.

Project layout:

- `src/domain`
- `src/infra`
- `src/checkers`
- `src/services`
- `cmd/main`
- `tests/unit`
- `tests/integration`
- `examples`

Useful commands:

```bash
moon build
moon test
moon run cmd/main -- init --repo ./tmp/demo
moon run cmd/main -- task --repo ./tmp/demo --type feature-change --title "Add filter" --paths "source/front/pages/**,source/front/components/**"
moon run cmd/main -- validate --repo ./tmp/demo
moon run cmd/main -- check --repo ./tmp/demo --run ./examples/runs/pass
moon run cmd/main -- report --repo ./tmp/demo
moon run cmd/main -- replay --repo ./tmp/demo --run-id run-pass
moon run cmd/main -- doctor --repo ./tmp/demo
moon run cmd/main -- pack --repo ./tmp/demo
./scripts/run_demo.sh
```
# leila/moonforge_gate
