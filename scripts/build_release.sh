#!/bin/sh
set -eu

# 文件说明：
# 这个脚本负责在本地或 CI 中产出真正要发布的 MoonForge 二进制。
# 它做的事情很少：
# 1. 调 MoonBit 构建 release 二进制
# 2. 按平台生成统一名字
# 3. 顺手输出 sha256，方便发布页校验

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT_DIR=${1:-"$ROOT/dist"}

normalize_os() {
  case "$(uname -s)" in
    Darwin) printf 'darwin' ;;
    Linux) printf 'linux' ;;
    *) printf 'unknown' ;;
  esac
}

normalize_arch() {
  case "$(uname -m)" in
    arm64|aarch64) printf 'arm64' ;;
    x86_64|amd64) printf 'x64' ;;
    *) printf 'unknown' ;;
  esac
}

OS_NAME=${MOONFORGE_RELEASE_OS:-$(normalize_os)}
ARCH_NAME=${MOONFORGE_RELEASE_ARCH:-$(normalize_arch)}
ASSET_NAME="moonforge-${OS_NAME}-${ARCH_NAME}"
BUILD_OUTPUT="$ROOT/_build/native/release/build/cmd/main/main.exe"

mkdir -p "$OUT_DIR"
moon build --target native --release --strip cmd/main
cp "$BUILD_OUTPUT" "$OUT_DIR/$ASSET_NAME"
chmod +x "$OUT_DIR/$ASSET_NAME"
shasum -a 256 "$OUT_DIR/$ASSET_NAME" > "$OUT_DIR/$ASSET_NAME.sha256"

printf '%s\n' "$OUT_DIR/$ASSET_NAME"
