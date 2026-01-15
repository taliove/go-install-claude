#!/bin/bash
# 测试 01: 从 GitHub Release 下载最新版本
# 验证能够正确下载并执行二进制文件

set -e

echo "=== Test: Download Latest Release from GitHub ==="

# 配置
GITHUB_REPO="${GITHUB_REPO:-taliove/go-install-claude}"
GITHUB_API="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"
BINARY_NAME="claude-installer"
INSTALL_DIR="${HOME}"

# 构建 API 请求头 (支持可选的 GitHub Token)
CURL_OPTS=(-sL --fail)
if [ -n "$GITHUB_TOKEN" ]; then
    CURL_OPTS+=(-H "Authorization: token ${GITHUB_TOKEN}")
    echo "  Using GitHub Token for API requests"
fi

echo "  Repository: ${GITHUB_REPO}"
echo "  API URL: ${GITHUB_API}"

# 获取最新 Release 信息
echo ""
echo "Fetching latest release info..."
RELEASE_INFO=$(curl "${CURL_OPTS[@]}" "$GITHUB_API")

if [ -z "$RELEASE_INFO" ]; then
    echo "ERROR: Failed to fetch release info from GitHub API"
    exit 1
fi

# 解析版本号
VERSION=$(echo "$RELEASE_INFO" | jq -r '.tag_name')
if [ "$VERSION" == "null" ] || [ -z "$VERSION" ]; then
    echo "ERROR: Could not parse version from release info"
    echo "Response: $RELEASE_INFO"
    exit 1
fi
echo "  Latest version: ${VERSION}"

# 解析发布时间
PUBLISHED_AT=$(echo "$RELEASE_INFO" | jq -r '.published_at')
echo "  Published: ${PUBLISHED_AT}"

# 查找 Linux amd64 二进制文件
echo ""
echo "Finding Linux amd64 binary..."
DOWNLOAD_URL=$(echo "$RELEASE_INFO" | jq -r '.assets[] | select(.name | contains("linux") and contains("amd64")) | .browser_download_url' | head -1)

if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" == "null" ]; then
    echo "ERROR: Could not find Linux amd64 binary in release assets"
    echo "Available assets:"
    echo "$RELEASE_INFO" | jq -r '.assets[].name'
    exit 1
fi

ASSET_NAME=$(echo "$RELEASE_INFO" | jq -r '.assets[] | select(.name | contains("linux") and contains("amd64")) | .name' | head -1)
echo "  Asset: ${ASSET_NAME}"
echo "  URL: ${DOWNLOAD_URL}"

# 下载二进制文件
echo ""
echo "Downloading binary..."
BINARY_PATH="${INSTALL_DIR}/${BINARY_NAME}"
curl -sL --fail -o "$BINARY_PATH" "$DOWNLOAD_URL"

if [ ! -f "$BINARY_PATH" ]; then
    echo "ERROR: Download failed - file not found"
    exit 1
fi

# 检查文件大小
FILE_SIZE=$(stat -c%s "$BINARY_PATH" 2>/dev/null || stat -f%z "$BINARY_PATH" 2>/dev/null)
echo "  Downloaded: ${FILE_SIZE} bytes"

if [ "$FILE_SIZE" -lt 1000 ]; then
    echo "ERROR: Downloaded file is too small, possibly corrupted"
    exit 1
fi

# 设置可执行权限
chmod +x "$BINARY_PATH"
echo "  Made executable: ${BINARY_PATH}"

# 验证可执行
echo ""
echo "Verifying binary..."
if ! "$BINARY_PATH" --version; then
    echo "ERROR: Binary failed to execute"
    exit 1
fi

# 导出路径供后续测试使用
export CLAUDE_INSTALLER_PATH="$BINARY_PATH"
echo ""
echo "SUCCESS: Binary downloaded and verified"
echo "  Path: ${BINARY_PATH}"
echo "  Version: ${VERSION}"
