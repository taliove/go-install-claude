#!/bin/bash
# Claude Code 一键安装脚本
# 使用方法: curl -fsSL https://raw.githubusercontent.com/taliove/go-install-claude/main/install.sh | bash
#
# 或者带参数:
# curl -fsSL https://raw.githubusercontent.com/taliove/go-install-claude/main/install.sh | bash -s -- --version v1.0.0

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# 配置
REPO="taliove/go-install-claude"
BINARY_NAME="claude-installer"
INSTALL_DIR="${HOME}/.local/bin"
VERSION="${1:-latest}"

# 打印带颜色的消息
info() { echo -e "${CYAN}ℹ ${NC}$1"; }
success() { echo -e "${GREEN}✓ ${NC}$1"; }
warn() { echo -e "${YELLOW}⚠ ${NC}$1"; }
error() { echo -e "${RED}✖ ${NC}$1"; }

# 检测操作系统和架构
detect_platform() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    case "$OS" in
        linux*)
            OS="linux"
            ;;
        darwin*)
            OS="darwin"
            ;;
        mingw*|msys*|cygwin*)
            OS="windows"
            ;;
        *)
            error "不支持的操作系统: $OS"
            exit 1
            ;;
    esac
    
    case "$ARCH" in
        x86_64|amd64)
            ARCH="amd64"
            ;;
        arm64|aarch64)
            ARCH="arm64"
            ;;
        *)
            error "不支持的架构: $ARCH"
            exit 1
            ;;
    esac
    
    PLATFORM="${OS}-${ARCH}"
    
    # 构建文件名
    if [ "$OS" = "windows" ]; then
        BINARY="${BINARY_NAME}-${PLATFORM}.exe"
    else
        BINARY="${BINARY_NAME}-${PLATFORM}"
    fi
    
    info "检测到平台: ${BOLD}${PLATFORM}${NC}"
}

# 获取最新版本
get_latest_version() {
    if [ "$VERSION" = "latest" ]; then
        info "获取最新版本信息..."
        VERSION=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [ -z "$VERSION" ]; then
            error "无法获取最新版本"
            exit 1
        fi
    fi
    success "版本: ${BOLD}${VERSION}${NC}"
}

# 下载安装程序
download() {
    DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${BINARY}"
    
    info "下载安装程序..."
    info "URL: ${DOWNLOAD_URL}"
    
    # 创建临时目录
    TMP_DIR=$(mktemp -d)
    TMP_FILE="${TMP_DIR}/${BINARY}"
    
    # 下载
    if command -v curl &> /dev/null; then
        curl -fsSL "$DOWNLOAD_URL" -o "$TMP_FILE"
    elif command -v wget &> /dev/null; then
        wget -q "$DOWNLOAD_URL" -O "$TMP_FILE"
    else
        error "需要 curl 或 wget"
        exit 1
    fi
    
    if [ ! -f "$TMP_FILE" ]; then
        error "下载失败"
        exit 1
    fi
    
    success "下载完成"
}

# 安装
install() {
    # 设置执行权限
    chmod +x "$TMP_FILE"
    
    # 创建安装目录
    mkdir -p "$INSTALL_DIR"
    
    # 移动到安装目录
    mv "$TMP_FILE" "${INSTALL_DIR}/${BINARY_NAME}"
    
    success "安装到: ${BOLD}${INSTALL_DIR}/${BINARY_NAME}${NC}"
    
    # 清理
    rm -rf "$TMP_DIR"
}

# 检查 PATH
check_path() {
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        warn "请将以下路径添加到你的 PATH:"
        echo ""
        echo -e "  ${CYAN}export PATH=\"\$PATH:${INSTALL_DIR}\"${NC}"
        echo ""
        
        # 提示添加到 shell 配置文件
        SHELL_NAME=$(basename "$SHELL")
        case "$SHELL_NAME" in
            bash)
                RC_FILE="$HOME/.bashrc"
                ;;
            zsh)
                RC_FILE="$HOME/.zshrc"
                ;;
            fish)
                RC_FILE="$HOME/.config/fish/config.fish"
                warn "Fish shell 请使用: set -gx PATH \$PATH ${INSTALL_DIR}"
                return
                ;;
            *)
                RC_FILE="$HOME/.profile"
                ;;
        esac
        
        echo -e "  可以运行以下命令自动添加:"
        echo -e "  ${CYAN}echo 'export PATH=\"\$PATH:${INSTALL_DIR}\"' >> ${RC_FILE}${NC}"
        echo ""
    fi
}

# 运行安装程序
run_installer() {
    echo ""
    info "启动 Claude Code 安装向导..."
    echo ""
    
    "${INSTALL_DIR}/${BINARY_NAME}"
}

# 主函数
main() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  ${BOLD}Claude Code 一键安装工具${NC}${CYAN}                  ║${NC}"
    echo -e "${CYAN}║  ${YELLOW}⚡ 万界数据 ⚡${NC}${CYAN}                            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo ""
    
    detect_platform
    get_latest_version
    download
    install
    check_path
    
    echo ""
    success "安装完成！"
    echo ""
    
    # 询问是否立即运行
    read -p "是否立即运行安装向导? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        run_installer
    else
        echo ""
        info "稍后可以运行以下命令启动安装向导:"
        echo -e "  ${CYAN}${BINARY_NAME}${NC}"
        echo ""
    fi
}

# 运行
main "$@"
