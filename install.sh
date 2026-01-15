#!/bin/bash
# Claude Code 一键安装脚本
#
# 国内用户（推荐，使用加速镜像）:
#   curl -fsSL https://ghproxy.net/https://raw.githubusercontent.com/taliove/claude-installer/main/install.sh | bash
#
# 海外用户（直连 GitHub）:
#   curl -fsSL https://raw.githubusercontent.com/taliove/claude-installer/main/install.sh | bash
#
# 重新配置:
#   curl -fsSL <url> | bash -s -- --config
#
# 环境变量:
#   USE_MIRROR=true   强制使用国内镜像加速
#   USE_MIRROR=false  强制直连 GitHub（海外用户）
#   USE_MIRROR=auto   自动检测（默认）

set -e

# ============================================================================
# 颜色定义
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ============================================================================
# 配置
# ============================================================================
NVM_DIR="${HOME}/.nvm"
CLAUDE_DIR="${HOME}/.claude"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"
NODE_MIN_VERSION=18

# npm 淘宝镜像
NPM_MIRROR="https://registry.npmmirror.com"
# Node.js 淘宝镜像（nvm 使用）
NODE_MIRROR="https://npmmirror.com/mirrors/node"

# GitHub 加速镜像列表
GITHUB_MIRRORS=(
    "https://ghproxy.net"
    "https://mirror.ghproxy.com"
    "https://gh-proxy.com"
)

# nvm 安装脚本地址
NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh"

# 是否使用镜像加速（默认自动检测）
USE_MIRROR="${USE_MIRROR:-auto}"
MIRROR_MODE=false
ACTIVE_MIRROR=""

# 万界数据 API 配置
WANJIE_BASE_URL="https://maas-openapi.wanjiedata.com/api/anthropic"

# 非交互式模式（用于自动化测试）
# 设置以下环境变量可跳过交互输入:
#   ANTHROPIC_API_KEY=sk-xxx   预设 API Key
#   ANTHROPIC_MODEL=claude-sonnet-4-20250514  预设模型
NONINTERACTIVE="${NONINTERACTIVE:-false}"

# 模型列表
declare -a MODEL_IDS=(
    "claude-sonnet-4-20250514"
    "claude-sonnet-4-5-20250929"
    "claude-haiku-4-5-20251001"
    "claude-opus-4-1-20250805"
    "claude-opus-4-5-20251101"
)

declare -a MODEL_NAMES=(
    "Claude Sonnet 4"
    "Claude Sonnet 4.5"
    "Claude Haiku 4.5"
    "Claude Opus 4.1"
    "Claude Opus 4.5"
)

declare -a MODEL_DESCS=(
    "[推荐] 性价比之选，日常使用"
    "增强版，更强推理能力"
    "快速响应，适合简单任务"
    "强大性能，适合复杂任务"
    "旗舰模型，最强性能"
)

# ============================================================================
# 工具函数
# ============================================================================
info() { echo -e "${CYAN}ℹ ${NC}$1"; }
success() { echo -e "${GREEN}✓ ${NC}$1"; }
warn() { echo -e "${YELLOW}⚠ ${NC}$1"; }
error() { echo -e "${RED}✖ ${NC}$1"; }
step() { echo -e "${BLUE}▶ ${NC}${BOLD}$1${NC}"; }

# 打印分隔线
divider() {
    echo -e "${DIM}────────────────────────────────────────────────${NC}"
}

# 检测是否需要使用镜像
detect_mirror_need() {
    if [ "$USE_MIRROR" = "true" ]; then
        MIRROR_MODE=true
        info "强制使用镜像模式"
        return
    elif [ "$USE_MIRROR" = "false" ]; then
        MIRROR_MODE=false
        info "强制使用直连模式"
        return
    fi
    
    # 自动检测：尝试快速访问 GitHub
    info "检测网络环境..."
    
    if curl -fsSL --connect-timeout 3 --max-time 5 "https://github.com" -o /dev/null 2>/dev/null; then
        if curl -fsSL --connect-timeout 3 --max-time 5 "https://raw.githubusercontent.com" -o /dev/null 2>/dev/null; then
            MIRROR_MODE=false
            success "可以直连 GitHub"
            return
        fi
    fi
    
    MIRROR_MODE=true
    warn "GitHub 访问较慢或不可用，将使用国内镜像加速"
}

# 查找可用的镜像
find_working_mirror() {
    for mirror in "${GITHUB_MIRRORS[@]}"; do
        if curl -fsSL --connect-timeout 5 "${mirror}" &> /dev/null; then
            ACTIVE_MIRROR="$mirror"
            success "使用镜像: ${BOLD}${mirror}${NC}"
            return 0
        fi
    done
    error "所有镜像均不可用"
    return 1
}

# 获取带镜像前缀的 URL
get_url() {
    local url="$1"
    if [ "$MIRROR_MODE" = true ] && [ -n "$ACTIVE_MIRROR" ]; then
        echo "${ACTIVE_MIRROR}/${url}"
    else
        echo "$url"
    fi
}

# 通用下载函数
do_download() {
    local url="$1"
    local final_url
    
    final_url=$(get_url "$url")
    
    if command -v curl &> /dev/null; then
        curl -fsSL "$final_url"
        return $?
    elif command -v wget &> /dev/null; then
        wget -qO- "$final_url"
        return $?
    else
        error "需要 curl 或 wget"
        exit 1
    fi
}

# ============================================================================
# 检测函数
# ============================================================================

# 检测用户 shell
detect_shell() {
    SHELL_NAME=$(basename "$SHELL")
    case "$SHELL_NAME" in
        zsh)
            RC_FILE="$HOME/.zshrc"
            ;;
        bash)
            # macOS 可能用 .bash_profile
            if [ -f "$HOME/.bash_profile" ] && [ "$(uname)" = "Darwin" ]; then
                RC_FILE="$HOME/.bash_profile"
            else
                RC_FILE="$HOME/.bashrc"
            fi
            ;;
        fish)
            RC_FILE="$HOME/.config/fish/config.fish"
            ;;
        *)
            RC_FILE="$HOME/.profile"
            ;;
    esac
}

# 检测 Node.js 版本
check_node_version() {
    if command -v node &> /dev/null; then
        local version
        version=$(node -v 2>/dev/null | sed 's/v//' | cut -d. -f1)
        if [ -n "$version" ] && [ "$version" -ge "$NODE_MIN_VERSION" ]; then
            return 0
        fi
    fi
    return 1
}

# 检测 nvm
check_nvm() {
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        return 0
    fi
    return 1
}

# 加载 nvm
load_nvm() {
    export NVM_DIR="$HOME/.nvm"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        # shellcheck source=/dev/null
        . "$NVM_DIR/nvm.sh"
        return 0
    fi
    return 1
}

# ============================================================================
# 安装函数
# ============================================================================

# 安装 nvm
install_nvm() {
    step "安装 nvm (Node Version Manager)..."
    
    local install_script
    install_script=$(get_url "$NVM_INSTALL_URL")
    
    info "下载 nvm 安装脚本..."
    
    # 下载并执行安装脚本
    if ! curl -fsSL "$install_script" | bash; then
        # 如果镜像失败，尝试直连
        if [ "$MIRROR_MODE" = true ]; then
            warn "镜像下载失败，尝试直连..."
            if ! curl -fsSL "$NVM_INSTALL_URL" | bash; then
                error "nvm 安装失败"
                exit 1
            fi
        else
            error "nvm 安装失败"
            exit 1
        fi
    fi
    
    # 加载 nvm
    if ! load_nvm; then
        error "无法加载 nvm"
        exit 1
    fi
    
    success "nvm 安装完成"
}

# 安装 Node.js
install_nodejs() {
    step "安装 Node.js (v${NODE_MIN_VERSION}+)..."
    
    # 设置 Node.js 镜像
    export NVM_NODEJS_ORG_MIRROR="$NODE_MIRROR"
    info "使用镜像: $NODE_MIRROR"
    
    # 安装 LTS 版本
    if ! nvm install --lts; then
        error "Node.js 安装失败"
        exit 1
    fi
    
    # 设为默认
    nvm alias default node
    
    success "Node.js $(node -v) 安装完成"
}

# 配置 npm 镜像
configure_npm_mirror() {
    step "配置 npm 镜像..."
    npm config set registry "$NPM_MIRROR"
    success "npm 镜像已配置: $NPM_MIRROR"
}

# 安装 Claude Code
install_claude_code() {
    step "安装 Claude Code..."
    
    if ! npm install -g @anthropic-ai/claude-code; then
        error "Claude Code 安装失败"
        exit 1
    fi
    
    success "Claude Code 安装完成"
}

# ============================================================================
# 配置函数
# ============================================================================

# 交互式输入 API Key
input_api_key() {
    # 非交互式模式：使用环境变量
    if [ "$NONINTERACTIVE" = "true" ] && [ -n "${ANTHROPIC_API_KEY:-}" ]; then
        API_KEY="$ANTHROPIC_API_KEY"
        success "API Key 已从环境变量设置"
        return
    fi
    
    echo ""
    step "配置 API Key"
    echo ""
    echo -e "  请输入万界数据 API Key"
    echo -e "  ${DIM}获取地址: https://data.wanjiehuyu.com${NC}"
    echo ""
    
    while true; do
        read -rp "  API Key: " API_KEY
        if [ -n "$API_KEY" ]; then
            # 简单验证格式
            if [[ "$API_KEY" =~ ^sk- ]]; then
                success "API Key 已设置"
                break
            else
                warn "API Key 格式可能不正确（通常以 sk- 开头），是否继续? [y/N]"
                read -rn1 confirm
                echo
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    break
                fi
            fi
        else
            error "API Key 不能为空"
        fi
    done
}

# 交互式选择模型
select_model() {
    # 非交互式模式：使用环境变量
    if [ "$NONINTERACTIVE" = "true" ] && [ -n "${ANTHROPIC_MODEL:-}" ]; then
        SELECTED_MODEL="$ANTHROPIC_MODEL"
        success "模型已从环境变量设置: $SELECTED_MODEL"
        return
    fi
    
    echo ""
    step "选择默认模型"
    echo ""
    
    for i in "${!MODEL_IDS[@]}"; do
        local num=$((i + 1))
        local name="${MODEL_NAMES[$i]}"
        local desc="${MODEL_DESCS[$i]}"
        local id="${MODEL_IDS[$i]}"
        
        if [ "$i" -eq 0 ]; then
            echo -e "  ${GREEN}${num}.${NC} ${BOLD}${name}${NC}  ${YELLOW}${desc}${NC}"
        else
            echo -e "  ${num}. ${name}  ${DIM}${desc}${NC}"
        fi
        echo -e "     ${DIM}(${id})${NC}"
    done
    
    echo ""
    while true; do
        read -rp "  请选择 [1-5，默认 1]: " choice
        choice="${choice:-1}"
        
        if [[ "$choice" =~ ^[1-5]$ ]]; then
            local idx=$((choice - 1))
            SELECTED_MODEL="${MODEL_IDS[$idx]}"
            success "已选择: ${MODEL_NAMES[$idx]}"
            break
        else
            error "请输入 1-5 之间的数字"
        fi
    done
}

# 计算模型映射
calculate_model_mappings() {
    # ANTHROPIC_DEFAULT_HAIKU_MODEL 始终为 claude-haiku-4-5-20251001
    DEFAULT_HAIKU="claude-haiku-4-5-20251001"
    
    # ANTHROPIC_DEFAULT_SONNET_MODEL：如果选择 Sonnet 4.5 则用 4.5，否则用 Sonnet 4
    if [ "$SELECTED_MODEL" = "claude-sonnet-4-5-20250929" ]; then
        DEFAULT_SONNET="claude-sonnet-4-5-20250929"
    else
        DEFAULT_SONNET="claude-sonnet-4-20250514"
    fi
    
    # ANTHROPIC_DEFAULT_OPUS_MODEL：如果选择 Opus 4.5 则用 4.5，否则用 Opus 4.1
    if [ "$SELECTED_MODEL" = "claude-opus-4-5-20251101" ]; then
        DEFAULT_OPUS="claude-opus-4-5-20251101"
    else
        DEFAULT_OPUS="claude-opus-4-1-20250805"
    fi
}

# 写入配置文件
write_settings() {
    step "写入配置文件..."
    
    # 创建配置目录
    mkdir -p "$CLAUDE_DIR"
    
    # 计算模型映射
    calculate_model_mappings
    
    # 生成 JSON 配置
    cat > "$SETTINGS_FILE" << EOF
{
  "enabledPlugins": {
    "commit-commands@claude-plugins-official": true,
    "context7@claude-plugins-official": true,
    "frontend-design@claude-plugins-official": true,
    "github@claude-plugins-official": true,
    "planning-with-files@planning-with-files": true,
    "superpowers@superpowers-marketplace": true
  },
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "${API_KEY}",
    "ANTHROPIC_BASE_URL": "${WANJIE_BASE_URL}",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "${DEFAULT_HAIKU}",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "${DEFAULT_OPUS}",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "${DEFAULT_SONNET}",
    "ANTHROPIC_MODEL": "${SELECTED_MODEL}",
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": 1
  }
}
EOF
    
    success "配置已写入: $SETTINGS_FILE"
}

# ============================================================================
# PATH 配置
# ============================================================================

# 配置 PATH
configure_path() {
    step "配置环境变量..."
    
    detect_shell
    
    # 需要添加的 PATH 项
    local npm_bin
    npm_bin="$(npm config get prefix)/bin"
    local nvm_init='export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
    
    # 检查并添加 nvm 初始化
    if ! grep -q 'NVM_DIR' "$RC_FILE" 2>/dev/null; then
        echo "" >> "$RC_FILE"
        echo "# nvm" >> "$RC_FILE"
        echo "$nvm_init" >> "$RC_FILE"
        info "已添加 nvm 初始化到 $RC_FILE"
    fi
    
    # 检查并添加 npm bin 到 PATH
    if ! grep -q "$npm_bin" "$RC_FILE" 2>/dev/null; then
        echo "" >> "$RC_FILE"
        echo "# npm global bin" >> "$RC_FILE"
        echo "export PATH=\"\$PATH:$npm_bin\"" >> "$RC_FILE"
        info "已添加 npm bin 到 PATH"
    fi
    
    # 当前 session 生效
    export PATH="$PATH:$npm_bin"
    
    success "环境变量配置完成"
}

# ============================================================================
# 主流程
# ============================================================================

# 显示帮助
show_help() {
    echo ""
    echo -e "${BOLD}Claude Code 一键安装脚本${NC}"
    echo ""
    echo "用法:"
    echo "  bash install.sh           完整安装流程"
    echo "  bash install.sh --config  仅重新配置（API Key + 模型选择）"
    echo "  bash install.sh --help    显示此帮助"
    echo ""
    echo "在线安装:"
    echo "  国内用户: curl -fsSL https://ghproxy.net/https://raw.githubusercontent.com/taliove/claude-installer/main/install.sh | bash"
    echo "  海外用户: curl -fsSL https://raw.githubusercontent.com/taliove/claude-installer/main/install.sh | bash"
    echo ""
    echo "环境变量:"
    echo "  USE_MIRROR=true   强制使用国内镜像加速"
    echo "  USE_MIRROR=false  强制直连 GitHub"
    echo ""
}

# 显示 banner
show_banner() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  ${BOLD}Claude Code 一键安装${NC}${CYAN}                          ║${NC}"
    echo -e "${CYAN}║  ${YELLOW}⚡ 万界数据 ⚡${NC}${CYAN}                                ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
    echo ""
}

# 仅配置模式
config_only() {
    show_banner
    step "重新配置 Claude Code"
    divider
    
    # 检查 Claude Code 是否已安装
    if ! command -v claude &> /dev/null; then
        error "Claude Code 未安装，请先运行完整安装"
        exit 1
    fi
    
    input_api_key
    select_model
    write_settings
    
    divider
    echo ""
    success "配置完成！"
    echo ""
    echo -e "  运行 ${CYAN}claude${NC} 开始使用"
    echo ""
}

# 完整安装流程
full_install() {
    show_banner
    
    # 检测网络环境
    detect_mirror_need
    
    if [ "$MIRROR_MODE" = true ]; then
        if ! find_working_mirror; then
            warn "将尝试直连..."
            MIRROR_MODE=false
        fi
    fi
    
    divider
    
    # Step 1: 检测/安装 Node.js
    step "Step 1: 检查 Node.js 环境"
    
    if check_node_version; then
        success "Node.js $(node -v) 已安装"
    else
        info "需要安装 Node.js ${NODE_MIN_VERSION}+"
        
        # 检查/安装 nvm
        if check_nvm; then
            info "nvm 已安装"
            load_nvm
        else
            install_nvm
        fi
        
        # 安装 Node.js
        install_nodejs
    fi
    
    divider
    
    # Step 2: 配置 npm 镜像
    step "Step 2: 配置 npm"
    configure_npm_mirror
    
    divider
    
    # Step 3: 安装 Claude Code
    step "Step 3: 安装 Claude Code"
    install_claude_code
    
    divider
    
    # Step 4: 配置 API Key 和模型
    step "Step 4: 配置 Claude Code"
    input_api_key
    select_model
    write_settings
    
    divider
    
    # Step 5: 配置 PATH
    step "Step 5: 配置环境变量"
    configure_path
    
    divider
    
    # 完成
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ${BOLD}安装完成！${NC}${GREEN}                                    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  请运行以下命令使配置生效:"
    echo ""
    echo -e "    ${CYAN}source $RC_FILE${NC}"
    echo ""
    echo -e "  然后运行 ${CYAN}claude${NC} 开始使用"
    echo ""
    echo -e "  ${DIM}如需重新配置，运行:${NC}"
    echo -e "    ${CYAN}curl -fsSL <url> | bash -s -- --config${NC}"
    echo ""
}

# 主函数
main() {
    case "${1:-}" in
        --help|-h)
            show_help
            exit 0
            ;;
        --config)
            config_only
            exit 0
            ;;
        "")
            full_install
            ;;
        *)
            error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
}

# 运行
main "$@"
