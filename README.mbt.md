# MoonForge Gate

MoonForge Gate is a MoonBit CLI demo for repository admission checks before code enters a shared repository.

Current demo scope:

- `moonforge init`
- `moonforge task`
- `moonforge check`
- `moonforge report`

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
moon run cmd/main -- task --repo ./tmp/demo --type feature-change --title "Add filter" --paths "frontend/src/pages/**,frontend/src/components/**,backend/src/main/java/com/acme/user/service/**"
moon run cmd/main -- check --repo ./tmp/demo --run ./examples/runs/pass
moon run cmd/main -- report --repo ./tmp/demo
./scripts/run_demo.sh
```
# leila/moonforge_gate
