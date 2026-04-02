#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEMO_ROOT="$ROOT/tmp/demo-repo"

rm -rf "$DEMO_ROOT"
mkdir -p "$ROOT/tmp"
cp -R "$ROOT/examples/demo-repo-skeleton" "$DEMO_ROOT"

cd "$ROOT"

echo "[1/6] init demo repo"
moon run cmd/main -- init --repo "$DEMO_ROOT"

echo "[2/6] create current task"
moon run cmd/main -- task \
  --repo "$DEMO_ROOT" \
  --type feature-change \
  --title "Add department filter" \
  --paths "frontend/src/pages/**,frontend/src/components/**,backend/src/main/java/com/acme/user/service/**"

echo "[3/6] run pass fixture"
moon run cmd/main -- check --repo "$DEMO_ROOT" --run "$ROOT/examples/runs/pass"

echo "[4/6] run retry fixture"
moon run cmd/main -- check --repo "$DEMO_ROOT" --run "$ROOT/examples/runs/retry"

echo "[5/6] run manual approval fixture"
moon run cmd/main -- check --repo "$DEMO_ROOT" --run "$ROOT/examples/runs/approval"

echo "[6/6] run reject fixture and print latest report"
moon run cmd/main -- check --repo "$DEMO_ROOT" --run "$ROOT/examples/runs/reject" || true
moon run cmd/main -- report --repo "$DEMO_ROOT"
