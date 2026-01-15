#!/bin/bash
# 测试 04: 系统环境检测测试
# 验证 Node.js、npm 检测和网络连通性

set -e

echo "=== Test: System Environment Detection ==="

# 测试计数
TESTS_RUN=0
TESTS_PASSED=0

check_command() {
    local cmd="$1"
    local test_name="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if command -v "$cmd" &> /dev/null; then
        local version
        version=$("$cmd" --version 2>&1 | head -1)
        echo "  [PASS] ${test_name}: ${version}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo "  [FAIL] ${test_name}: command not found"
        return 1
    fi
}

check_network() {
    local url="$1"
    local test_name="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if curl -sL --head --fail --connect-timeout 10 "$url" > /dev/null 2>&1; then
        echo "  [PASS] ${test_name}: reachable"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo "  [WARN] ${test_name}: unreachable (may be expected in some environments)"
        # 网络测试失败不算致命错误
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    fi
}

# ========================================
# 测试 1: Node.js 检测
# ========================================
echo ""
echo "Test 1: Node.js Detection"
check_command "node" "Node.js"

# 验证版本格式
NODE_VERSION=$(node --version 2>&1)
TESTS_RUN=$((TESTS_RUN + 1))
if [[ "$NODE_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    echo "  [PASS] Node.js version format valid: ${NODE_VERSION}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "  [FAIL] Node.js version format invalid: ${NODE_VERSION}"
fi

# ========================================
# 测试 2: npm 检测
# ========================================
echo ""
echo "Test 2: npm Detection"
check_command "npm" "npm"

# 验证版本格式
NPM_VERSION=$(npm --version 2>&1)
TESTS_RUN=$((TESTS_RUN + 1))
if [[ "$NPM_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    echo "  [PASS] npm version format valid: ${NPM_VERSION}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "  [FAIL] npm version format invalid: ${NPM_VERSION}"
fi

# ========================================
# 测试 3: npm 全局安装目录
# ========================================
echo ""
echo "Test 3: npm Global Install Directory"

NPM_PREFIX=$(npm config get prefix 2>&1)
TESTS_RUN=$((TESTS_RUN + 1))

if [ -n "$NPM_PREFIX" ] && [ -d "$NPM_PREFIX" ]; then
    echo "  [PASS] npm prefix directory exists: ${NPM_PREFIX}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "  [WARN] npm prefix directory: ${NPM_PREFIX}"
    # 不是致命错误
    TESTS_PASSED=$((TESTS_PASSED + 1))
fi

# ========================================
# 测试 4: 网络连通性 - GitHub API
# ========================================
echo ""
echo "Test 4: Network - GitHub API"
check_network "https://api.github.com" "GitHub API"

# ========================================
# 测试 5: 网络连通性 - 万界 API
# ========================================
echo ""
echo "Test 5: Network - Wanjie API"
check_network "https://maas-openapi.wanjiedata.com" "Wanjie API"

# ========================================
# 测试 6: 网络连通性 - npm 镜像
# ========================================
echo ""
echo "Test 6: Network - npm Mirror"
check_network "https://registry.npmmirror.com" "npm Mirror"

# ========================================
# 测试 7: 环境变量
# ========================================
echo ""
echo "Test 7: Environment Variables"

TESTS_RUN=$((TESTS_RUN + 1))
if [ -n "$HOME" ]; then
    echo "  [PASS] HOME is set: ${HOME}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "  [FAIL] HOME is not set"
fi

TESTS_RUN=$((TESTS_RUN + 1))
if [ -n "$PATH" ]; then
    echo "  [PASS] PATH is set"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "  [FAIL] PATH is not set"
fi

# ========================================
# 测试 8: 用户权限
# ========================================
echo ""
echo "Test 8: User Permissions"

TESTS_RUN=$((TESTS_RUN + 1))
TEST_DIR="${HOME}/.claude-test-$$"
if mkdir -p "$TEST_DIR" 2>/dev/null; then
    echo "  [PASS] Can create directories in HOME"
    rm -rf "$TEST_DIR"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "  [FAIL] Cannot create directories in HOME"
fi

TESTS_RUN=$((TESTS_RUN + 1))
TEST_FILE="${HOME}/.test-write-$$"
if echo "test" > "$TEST_FILE" 2>/dev/null; then
    echo "  [PASS] Can write files in HOME"
    rm -f "$TEST_FILE"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "  [FAIL] Cannot write files in HOME"
fi

# ========================================
# 汇总
# ========================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Detector Tests: ${TESTS_PASSED}/${TESTS_RUN} passed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$TESTS_PASSED" -eq "$TESTS_RUN" ]; then
    echo "SUCCESS: All detector tests passed"
    exit 0
else
    echo "FAILURE: Some detector tests failed"
    exit 1
fi
