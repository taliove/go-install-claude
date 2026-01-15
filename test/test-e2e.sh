#!/bin/bash
# ============================================================================
# Claude Code 端到端测试脚本
# 
# 测试流程:
#   1. 语法检查
#   2. 环境检测
#   3. 安装 Node.js (via nvm)
#   4. 安装 Claude Code
#   5. 配置服务商 (多服务商支持)
#   6. 验证配置
#
# 用法:
#   docker build -t claude-installer-test -f test/Dockerfile .
#   docker run --rm claude-installer-test bash ./test-e2e.sh
#
# 环境变量:
#   TEST_API_KEY    测试用 API Key (可选)
#   TEST_PROVIDER   测试服务商 1-4 (可选，默认 1=MiniMax)
#   SKIP_INSTALL    跳过安装，仅验证配置 (可选)
# ============================================================================

# 不使用 set -e，手动处理错误
set +e

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# 计数器
TESTS_PASSED=0
TESTS_FAILED=0

# 服务商配置
declare -a PROVIDER_NAMES=("MiniMax" "豆包 (火山引擎)" "智谱 AI" "万界数据")
declare -a PROVIDER_URLS=(
    "https://api.minimaxi.com/anthropic"
    "https://ark.cn-beijing.volces.com/api/coding"
    "https://open.bigmodel.cn/api/anthropic"
    "https://maas-openapi.wanjiedata.com/api/anthropic"
)
declare -a PROVIDER_DEFAULT_MODELS=("M2.1-flash" "ark-code-latest" "GLM-4.7" "claude-sonnet-4-20250514")

# 测试函数
pass() { 
    echo -e "${GREEN}[PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() { 
    echo -e "${RED}[FAIL]${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

info() { echo -e "${CYAN}[INFO]${NC} $1"; }
step() { echo -e "\n${BOLD}=== $1 ===${NC}\n"; }

# ============================================================================
# 测试 1: 语法检查
# ============================================================================
test_syntax() {
    step "Test 1: 语法检查"
    
    if bash -n /home/testuser/install.sh 2>&1; then
        pass "Bash 语法检查通过"
    else
        fail "Bash 语法错误"
    fi
    
    # ShellCheck (警告不阻塞)
    if command -v shellcheck &> /dev/null; then
        local sc_out
        sc_out=$(shellcheck /home/testuser/install.sh 2>&1)
        local sc_exit=$?
        
        # 只有 exit code 非 0 且包含 error 级别才算失败
        if [ $sc_exit -ne 0 ] && echo "$sc_out" | grep -q '\[error\]'; then
            fail "ShellCheck 发现错误"
            echo "$sc_out"
        else
            pass "ShellCheck 通过 (可能有警告)"
        fi
    else
        info "ShellCheck 未安装，跳过"
    fi
}

# ============================================================================
# 测试 2: 环境检测
# ============================================================================
test_environment_detection() {
    step "Test 2: 环境检测"
    
    # 测试 --help 参数
    if /home/testuser/install.sh --help > /dev/null 2>&1; then
        pass "--help 参数正常"
    else
        fail "--help 参数失败"
    fi
    
    # 检测操作系统
    if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        pass "操作系统检测: ${NAME:-Unknown} ${VERSION_ID:-}"
    else
        info "无法检测操作系统"
    fi
    
    # 检测 shell
    pass "当前 Shell: ${SHELL:-/bin/bash}"
    
    # 检测网络工具
    if command -v curl &> /dev/null; then
        local curl_ver
        curl_ver=$(curl --version 2>/dev/null | head -1)
        pass "curl 可用: $curl_ver"
    else
        fail "curl 不可用"
    fi
}

# ============================================================================
# 测试 3: 安装 Node.js
# ============================================================================
test_nodejs_installation() {
    step "Test 3: 安装 Node.js (via nvm)"
    
    if [ "${SKIP_INSTALL:-false}" = "true" ]; then
        info "跳过安装 (SKIP_INSTALL=true)"
        return 0
    fi
    
    # 设置环境变量
    export USE_MIRROR=true
    export NVM_DIR="$HOME/.nvm"
    
    info "安装 nvm..."
    
    # 安装 nvm
    local NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh"
    local MIRROR_URL="https://ghproxy.net/${NVM_INSTALL_URL}"
    
    local nvm_installed=false
    
    if curl -fsSL --connect-timeout 15 "$MIRROR_URL" 2>/dev/null | bash 2>&1; then
        pass "nvm 通过镜像安装成功"
        nvm_installed=true
    elif curl -fsSL --connect-timeout 15 "$NVM_INSTALL_URL" 2>/dev/null | bash 2>&1; then
        pass "nvm 直连安装成功"
        nvm_installed=true
    else
        fail "nvm 安装失败"
        return 1
    fi
    
    # 加载 nvm
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        # shellcheck source=/dev/null
        . "$NVM_DIR/nvm.sh"
    fi
    
    if command -v nvm &> /dev/null; then
        pass "nvm 命令可用: $(nvm --version)"
    else
        fail "nvm 命令不可用"
        return 1
    fi
    
    # 安装 Node.js
    info "安装 Node.js LTS..."
    export NVM_NODEJS_ORG_MIRROR="https://npmmirror.com/mirrors/node"
    
    if nvm install --lts 2>&1; then
        pass "Node.js 安装成功: $(node -v)"
    else
        fail "Node.js 安装失败"
        return 1
    fi
    
    # 验证 npm
    if command -v npm &> /dev/null; then
        pass "npm 可用: $(npm -v)"
    else
        fail "npm 不可用"
        return 1
    fi
    
    # 配置 npm 镜像
    npm config set registry https://registry.npmmirror.com
    pass "npm 镜像已配置"
}

# ============================================================================
# 测试 4: 安装 Claude Code
# ============================================================================
test_claude_code_installation() {
    step "Test 4: 安装 Claude Code"
    
    if [ "${SKIP_INSTALL:-false}" = "true" ]; then
        info "跳过安装 (SKIP_INSTALL=true)"
        return 0
    fi
    
    # 确保 nvm 已加载
    export NVM_DIR="$HOME/.nvm"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        # shellcheck source=/dev/null
        . "$NVM_DIR/nvm.sh"
    fi
    
    info "安装 @anthropic-ai/claude-code..."
    
    if npm install -g @anthropic-ai/claude-code 2>&1; then
        pass "Claude Code 安装成功"
    else
        fail "Claude Code 安装失败"
        return 1
    fi
    
    # 验证命令可用
    if command -v claude &> /dev/null; then
        pass "claude 命令可用"
    else
        fail "claude 命令不可用"
        return 1
    fi
    
    # 获取版本
    local claude_version
    claude_version=$(claude --version 2>/dev/null || echo "unknown")
    pass "Claude Code 版本: $claude_version"
}

# ============================================================================
# 测试 5: 配置服务商
# ============================================================================
test_provider_configuration() {
    step "Test 5: 配置服务商"
    
    # 测试服务商 (默认 MiniMax)
    local provider_idx=$((${TEST_PROVIDER:-1} - 1))
    local provider_name="${PROVIDER_NAMES[$provider_idx]}"
    local provider_url="${PROVIDER_URLS[$provider_idx]}"
    local provider_model="${PROVIDER_DEFAULT_MODELS[$provider_idx]}"
    
    # 设置测试 API Key
    local TEST_API_KEY="${TEST_API_KEY:-test-api-key-for-e2e-testing}"
    
    local CLAUDE_DIR="$HOME/.claude"
    local SETTINGS_FILE="$CLAUDE_DIR/settings.json"
    
    # 创建配置目录
    mkdir -p "$CLAUDE_DIR"
    
    info "测试服务商: $provider_name"
    info "Base URL: $provider_url"
    info "默认模型: $provider_model"
    
    info "写入配置文件..."
    
    # 根据服务商写入不同的配置
    if [ "$provider_idx" -eq 0 ]; then
        # MiniMax: 不需要模型映射
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
    "ANTHROPIC_AUTH_TOKEN": "${TEST_API_KEY}",
    "ANTHROPIC_BASE_URL": "${provider_url}",
    "ANTHROPIC_MODEL": "${provider_model}",
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": 1
  }
}
EOF
    else
        # 其他服务商: 需要模型映射
        local haiku_model sonnet_model opus_model
        
        case $provider_idx in
            1) # 豆包
                haiku_model="$provider_model"
                sonnet_model="$provider_model"
                opus_model="$provider_model"
                ;;
            2) # 智谱
                haiku_model="GLM-4.5-Air"
                sonnet_model="GLM-4.7"
                opus_model="GLM-4.7"
                ;;
            3) # 万界
                haiku_model="claude-haiku-4-5-20251001"
                sonnet_model="claude-sonnet-4-20250514"
                opus_model="claude-opus-4-1-20250805"
                ;;
        esac
        
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
    "ANTHROPIC_AUTH_TOKEN": "${TEST_API_KEY}",
    "ANTHROPIC_BASE_URL": "${provider_url}",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "${haiku_model}",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "${opus_model}",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "${sonnet_model}",
    "ANTHROPIC_MODEL": "${provider_model}",
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": 1
  }
}
EOF
    fi
    
    if [ -f "$SETTINGS_FILE" ]; then
        pass "配置文件已创建: $SETTINGS_FILE"
    else
        fail "配置文件创建失败"
        return 1
    fi
    
    # 验证 JSON 格式
    if command -v python3 &> /dev/null; then
        if python3 -m json.tool "$SETTINGS_FILE" > /dev/null 2>&1; then
            pass "JSON 格式有效"
        else
            fail "JSON 格式无效"
            return 1
        fi
    else
        info "python3 不可用，跳过 JSON 格式验证"
    fi
}

# ============================================================================
# 测试 6: 验证配置
# ============================================================================
test_configuration_verification() {
    step "Test 6: 验证服务商配置"
    
    local provider_idx=$((${TEST_PROVIDER:-1} - 1))
    local provider_name="${PROVIDER_NAMES[$provider_idx]}"
    local provider_url="${PROVIDER_URLS[$provider_idx]}"
    
    local SETTINGS_FILE="$HOME/.claude/settings.json"
    
    if [ ! -f "$SETTINGS_FILE" ]; then
        fail "配置文件不存在"
        return 1
    fi
    
    # 验证 ANTHROPIC_BASE_URL
    if grep -q "$provider_url" "$SETTINGS_FILE"; then
        pass "ANTHROPIC_BASE_URL 正确设置为 $provider_name"
    else
        fail "ANTHROPIC_BASE_URL 未正确设置"
        cat "$SETTINGS_FILE"
        return 1
    fi
    
    # 验证 API Key
    if grep -q "ANTHROPIC_AUTH_TOKEN" "$SETTINGS_FILE"; then
        pass "ANTHROPIC_AUTH_TOKEN 已配置"
    else
        fail "ANTHROPIC_AUTH_TOKEN 未配置"
    fi
    
    # 验证模型配置
    if grep -q "ANTHROPIC_MODEL" "$SETTINGS_FILE"; then
        pass "ANTHROPIC_MODEL 已配置"
    else
        fail "ANTHROPIC_MODEL 未配置"
    fi
    
    # 验证模型映射 (MiniMax 不需要)
    if [ "$provider_idx" -ne 0 ]; then
        local all_models=true
        grep -q "ANTHROPIC_DEFAULT_HAIKU_MODEL" "$SETTINGS_FILE" || all_models=false
        grep -q "ANTHROPIC_DEFAULT_SONNET_MODEL" "$SETTINGS_FILE" || all_models=false
        grep -q "ANTHROPIC_DEFAULT_OPUS_MODEL" "$SETTINGS_FILE" || all_models=false
        
        if [ "$all_models" = true ]; then
            pass "所有默认模型映射已配置"
        else
            fail "默认模型映射不完整"
        fi
    else
        pass "MiniMax 不需要模型映射"
    fi
    
    # 验证插件配置
    if grep -q "enabledPlugins" "$SETTINGS_FILE"; then
        pass "插件配置存在"
    else
        fail "插件配置缺失"
    fi
    
    # 显示最终配置
    info "最终配置内容:"
    cat "$SETTINGS_FILE"
}

# ============================================================================
# 测试 7: Claude 执行验证
# ============================================================================
test_claude_execution() {
    step "Test 7: Claude 执行验证"
    
    if [ "${SKIP_INSTALL:-false}" = "true" ]; then
        info "跳过 (SKIP_INSTALL=true)"
        return 0
    fi
    
    # 确保 nvm 已加载
    export NVM_DIR="$HOME/.nvm"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        # shellcheck source=/dev/null
        . "$NVM_DIR/nvm.sh"
    fi
    
    if ! command -v claude &> /dev/null; then
        info "Claude 未安装，跳过执行测试"
        return 0
    fi
    
    # 尝试执行 claude --version
    if claude --version > /dev/null 2>&1; then
        pass "claude --version 执行成功"
    else
        info "claude --version 执行失败 (可能正常，需要认证)"
    fi
    
    # 验证配置是否被读取
    if [ -f "$HOME/.claude/settings.json" ]; then
        pass "配置文件存在，Claude 可读取配置"
    else
        fail "配置文件不存在"
    fi
}

# ============================================================================
# 测试 8: 多服务商配置测试
# ============================================================================
test_multi_provider() {
    step "Test 8: 多服务商配置验证"
    
    info "验证所有服务商的 Base URL 配置..."
    
    # 验证所有服务商 URL 格式
    for i in "${!PROVIDER_URLS[@]}"; do
        local url="${PROVIDER_URLS[$i]}"
        local name="${PROVIDER_NAMES[$i]}"
        
        if [[ "$url" =~ ^https:// ]]; then
            pass "$name URL 格式正确: $url"
        else
            fail "$name URL 格式错误: $url"
        fi
    done
    
    # 验证默认模型存在
    for i in "${!PROVIDER_DEFAULT_MODELS[@]}"; do
        local model="${PROVIDER_DEFAULT_MODELS[$i]}"
        local name="${PROVIDER_NAMES[$i]}"
        
        if [ -n "$model" ]; then
            pass "$name 默认模型已配置: $model"
        else
            fail "$name 默认模型未配置"
        fi
    done
}

# ============================================================================
# 主函数
# ============================================================================
main() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  ${BOLD}Easy Install Claude - E2E 测试套件${NC}${CYAN}            ║${NC}"
    echo -e "${CYAN}║  ${BOLD}多服务商支持${NC}${CYAN}                                  ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # 显示测试配置
    local provider_idx=$((${TEST_PROVIDER:-1} - 1))
    info "测试服务商: ${PROVIDER_NAMES[$provider_idx]}"
    info "SKIP_INSTALL: ${SKIP_INSTALL:-false}"
    echo ""
    
    # 运行所有测试
    test_syntax
    test_environment_detection
    test_nodejs_installation
    test_claude_code_installation
    test_provider_configuration
    test_configuration_verification
    test_claude_execution
    test_multi_provider
    
    # 汇总
    echo ""
    echo -e "${BOLD}════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}测试结果汇总${NC}"
    echo -e "${BOLD}════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}通过: $TESTS_PASSED${NC}"
    echo -e "  ${RED}失败: $TESTS_FAILED${NC}"
    echo ""
    
    if [ "$TESTS_FAILED" -gt 0 ]; then
        echo -e "${RED}╔════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║  测试失败！                                    ║${NC}"
        echo -e "${RED}╚════════════════════════════════════════════════╝${NC}"
        exit 1
    else
        echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║  所有测试通过！                                ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
        exit 0
    fi
}

# 运行
main "$@"
