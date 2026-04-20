#!/bin/sh
set -eu

# 文件说明：
# 这是给普通用户直接安装 MoonForge 的脚本。
# 用户只需要一条命令：
# curl -fsSL https://raw.githubusercontent.com/helloLeila/MoonForge/main/scripts/install.sh | bash

REPO="${MOONFORGE_GITHUB_REPO:-helloLeila/MoonForge}"
VERSION="${MOONFORGE_VERSION:-latest}"
INSTALL_DIR="${MOONFORGE_INSTALL_DIR:-$HOME/.local/bin}"

normalize_os() {
  case "$(uname -s)" in
    Darwin) printf 'darwin' ;;
    Linux) printf 'linux' ;;
    *) printf 'unsupported' ;;
  esac
}

normalize_arch() {
  case "$(uname -m)" in
    arm64|aarch64) printf 'arm64' ;;
    x86_64|amd64) printf 'x64' ;;
    *) printf 'unsupported' ;;
  esac
}

OS_NAME=$(normalize_os)
ARCH_NAME=$(normalize_arch)

if [ "$OS_NAME" = "unsupported" ] || [ "$ARCH_NAME" = "unsupported" ]; then
  echo "MoonForge install does not support this platform yet."
  echo "MoonForge 安装脚本暂时不支持当前系统或 CPU 架构。"
  exit 1
fi

if [ "$VERSION" = "latest" ]; then
  DOWNLOAD_URL="https://github.com/${REPO}/releases/latest/download/moonforge-${OS_NAME}-${ARCH_NAME}"
else
  case "$VERSION" in
    v*) TAG_NAME="$VERSION" ;;
    *) TAG_NAME="v$VERSION" ;;
  esac
  DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${TAG_NAME}/moonforge-${OS_NAME}-${ARCH_NAME}"
fi

TMP_FILE=$(mktemp)
mkdir -p "$INSTALL_DIR"

echo "Downloading MoonForge from:"
echo "$DOWNLOAD_URL"
curl -fsSL "$DOWNLOAD_URL" -o "$TMP_FILE"
chmod +x "$TMP_FILE"
mv "$TMP_FILE" "$INSTALL_DIR/moonforge"

echo
echo "MoonForge installed to: $INSTALL_DIR/moonforge"
if command -v moonforge >/dev/null 2>&1; then
  echo "moonforge is already in PATH."
else
  echo "If 'moonforge' is not found, add this to your shell profile:"
  echo "export PATH=\"$INSTALL_DIR:\$PATH\""
fi
