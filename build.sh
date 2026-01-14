#!/bin/bash
# Claude Code 一键安装工具
# 跨平台构建脚本 (Bash)

set -e

TARGET=${1:-all}

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 创建输出目录
mkdir -p dist

build_windows() {
    echo -e "${CYAN}🔨 构建 Windows 版本...${NC}"
    GOOS=windows GOARCH=amd64 go build -ldflags="-s -w" -o dist/claude-installer-windows-amd64.exe ./cmd/installer
    echo -e "${GREEN}✅ Windows 版本构建完成${NC}"
}

build_linux() {
    echo -e "${CYAN}🔨 构建 Linux 版本...${NC}"
    GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o dist/claude-installer-linux-amd64 ./cmd/installer
    echo -e "${GREEN}✅ Linux 版本构建完成${NC}"
}

build_darwin_amd64() {
    echo -e "${CYAN}🔨 构建 macOS (Intel) 版本...${NC}"
    GOOS=darwin GOARCH=amd64 go build -ldflags="-s -w" -o dist/claude-installer-darwin-amd64 ./cmd/installer
    echo -e "${GREEN}✅ macOS (Intel) 版本构建完成${NC}"
}

build_darwin_arm64() {
    echo -e "${CYAN}🔨 构建 macOS (Apple Silicon) 版本...${NC}"
    GOOS=darwin GOARCH=arm64 go build -ldflags="-s -w" -o dist/claude-installer-darwin-arm64 ./cmd/installer
    echo -e "${GREEN}✅ macOS (Apple Silicon) 版本构建完成${NC}"
}

build_all() {
    echo -e "${YELLOW}🚀 开始构建所有平台版本...${NC}"
    echo ""
    build_windows
    build_linux
    build_darwin_amd64
    build_darwin_arm64
    echo ""
    echo -e "${GREEN}🎉 所有平台构建完成！${NC}"
    echo ""
    echo -e "${YELLOW}输出文件:${NC}"
    ls -lh dist/ | tail -n +2 | awk '{print "  📦 " $9 " (" $5 ")"}'
}

case $TARGET in
    windows)
        build_windows
        ;;
    linux)
        build_linux
        ;;
    darwin)
        build_darwin_amd64
        build_darwin_arm64
        ;;
    darwin-amd64)
        build_darwin_amd64
        ;;
    darwin-arm64)
        build_darwin_arm64
        ;;
    all)
        build_all
        ;;
    clean)
        echo -e "${YELLOW}🧹 清理构建目录...${NC}"
        rm -rf dist/
        echo -e "${GREEN}✅ 清理完成${NC}"
        ;;
    *)
        echo -e "${YELLOW}用法: ./build.sh [target]${NC}"
        echo ""
        echo -e "${CYAN}可用目标:${NC}"
        echo "  all          - 构建所有平台 (默认)"
        echo "  windows      - 仅构建 Windows"
        echo "  linux        - 仅构建 Linux"
        echo "  darwin       - 构建 macOS (Intel + ARM)"
        echo "  darwin-amd64 - 仅构建 macOS Intel"
        echo "  darwin-arm64 - 仅构建 macOS Apple Silicon"
        echo "  clean        - 清理构建目录"
        ;;
esac
