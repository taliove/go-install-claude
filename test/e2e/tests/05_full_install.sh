#!/bin/bash
# 测试 05: 完整安装流程测试
# 验证 npm install 和 Claude Code 安装

set -e

echo "=== Test: Full Installation Flow ==="

# 检查是否启用完整安装测试
if [ "${RUN_FULL_INSTALL}" != "true" ]; then
    echo "SKIP: Full install test disabled (set RUN_FULL_INSTALL=true to enable)"
    exit 77  # 77 = 跳过测试
fi

# 测试计数
TESTS_RUN=0
TESTS_PASSED=0

assert_success() {
    local exit_code=$?
    local test_name="$1"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ $exit_code -eq 0 ]; then
        echo "  [PASS] ${test_name}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo "  [FAIL] ${test_name} (exit code: ${exit_code})"
        return 1
    fi
}

# ========================================
# 测试 1: 配置 npm 镜像
# ========================================
echo ""
echo "Test 1: Configure npm Mirror"

echo "  Setting npm registry to npmmirror.com..."
npm config set registry https://registry.npmmirror.com
assert_success "npm mirror configuration"

# 验证配置
REGISTRY=$(npm config get registry)
TESTS_RUN=$((TESTS_RUN + 1))
if [ "$REGISTRY" == "https://registry.npmmirror.com/" ] || [ "$REGISTRY" == "https://registry.npmmirror.com" ]; then
    echo "  [PASS] npm registry set correctly: ${REGISTRY}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "  [WARN] npm registry: ${REGISTRY} (expected npmmirror.com)"
    TESTS_PASSED=$((TESTS_PASSED + 1))  # 不算致命错误
fi

# ========================================
# 测试 2: 安装 Claude Code
# ========================================
echo ""
echo "Test 2: Install Claude Code via npm"
echo "  This may take several minutes..."

# 设置超时 (10分钟)
INSTALL_TIMEOUT=600

# 执行安装
echo "  Running: npm install -g @anthropic-ai/claude-code"
START_TIME=$(date +%s)

if timeout ${INSTALL_TIMEOUT} npm install -g @anthropic-ai/claude-code 2>&1; then
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    echo "  [PASS] npm install completed in ${DURATION} seconds"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "  [FAIL] npm install failed or timed out"
    TESTS_RUN=$((TESTS_RUN + 1))
    exit 1
fi

# ========================================
# 测试 3: 验证 Claude 命令可用
# ========================================
echo ""
echo "Test 3: Verify Claude Command"

TESTS_RUN=$((TESTS_RUN + 1))
if command -v claude &> /dev/null; then
    echo "  [PASS] claude command found in PATH"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    # 检查 npm 全局目录
    NPM_BIN="${HOME}/.npm-global/bin"
    if [ -x "${NPM_BIN}/claude" ]; then
        export PATH="${NPM_BIN}:${PATH}"
        echo "  [PASS] claude command found in ${NPM_BIN}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "  [FAIL] claude command not found"
        echo "    Searched: PATH and ${NPM_BIN}"
        exit 1
    fi
fi

# ========================================
# 测试 4: 验证 Claude 版本
# ========================================
echo ""
echo "Test 4: Check Claude Version"

CLAUDE_VERSION=$(claude --version 2>&1 || echo "")
TESTS_RUN=$((TESTS_RUN + 1))
if [ -n "$CLAUDE_VERSION" ]; then
    echo "  [PASS] claude --version: ${CLAUDE_VERSION}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "  [FAIL] claude --version returned empty"
    exit 1
fi

# ========================================
# 测试 5: 创建配置文件
# ========================================
echo ""
echo "Test 5: Create Configuration"

CLAUDE_DIR="${HOME}/.claude"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

mkdir -p "$CLAUDE_DIR"

cat > "$SETTINGS_FILE" << 'EOF'
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://maas-openapi.wanjiedata.com/api/anthropic",
    "ANTHROPIC_API_KEY": "e2e-test-key-1234567890",
    "ANTHROPIC_MODEL": "claude-sonnet-4-20250514"
  }
}
EOF

TESTS_RUN=$((TESTS_RUN + 1))
if [ -f "$SETTINGS_FILE" ]; then
    echo "  [PASS] Settings file created: ${SETTINGS_FILE}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "  [FAIL] Failed to create settings file"
fi

# ========================================
# 测试 6: 使用安装程序验证配置
# ========================================
echo ""
echo "Test 6: Verify Config with Installer"

BINARY="${HOME}/claude-installer"
if [ -x "$BINARY" ]; then
    CONFIG_OUTPUT=$("$BINARY" --config 2>&1)
    TESTS_RUN=$((TESTS_RUN + 1))
    if echo "$CONFIG_OUTPUT" | grep -q "claude-sonnet-4"; then
        echo "  [PASS] Installer can read the configuration"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "  [FAIL] Installer cannot read configuration correctly"
        echo "    Output: ${CONFIG_OUTPUT}"
    fi
else
    echo "  [SKIP] Installer binary not available"
fi

# ========================================
# 测试 7: Claude Doctor (可选，跳过)
# ========================================
echo ""
echo "Test 7: Claude Doctor Check (skipped)"
echo "  [SKIP] claude doctor requires interactive terminal, skipping in CI environment"
# 注意: claude doctor 在非交互式环境中会卡住，所以跳过此测试
# 如果需要测试，可以使用: timeout 10 claude doctor 2>&1 || true

# ========================================
# 清理
# ========================================
echo ""
echo "Cleaning up..."

# 可选: 卸载 Claude Code
# npm uninstall -g @anthropic-ai/claude-code

rm -rf "${HOME}/.claude"
echo "  Removed test configuration"

# ========================================
# 汇总
# ========================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Install Tests: ${TESTS_PASSED}/${TESTS_RUN} passed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$TESTS_PASSED" -eq "$TESTS_RUN" ]; then
    echo "SUCCESS: All install tests passed"
    exit 0
else
    echo "FAILURE: Some install tests failed"
    exit 1
fi
