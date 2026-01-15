#!/bin/bash
# 测试 02: CLI 基础功能测试
# 验证命令行参数解析和基本输出

set -e

echo "=== Test: CLI Basic Functionality ==="

# 二进制文件路径
BINARY="${HOME}/claude-installer"

if [ ! -x "$BINARY" ]; then
    echo "ERROR: Binary not found at ${BINARY}"
    echo "Please run 01_download.sh first"
    exit 1
fi

# 测试计数
TESTS_RUN=0
TESTS_PASSED=0

# 测试函数
assert_contains() {
    local output="$1"
    local expected="$2"
    local test_name="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if echo "$output" | grep -q "$expected"; then
        echo "  [PASS] ${test_name}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo "  [FAIL] ${test_name}"
        echo "    Expected to contain: ${expected}"
        echo "    Actual output: ${output}"
        return 1
    fi
}

assert_not_empty() {
    local output="$1"
    local test_name="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ -n "$output" ]; then
        echo "  [PASS] ${test_name}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo "  [FAIL] ${test_name} - output is empty"
        return 1
    fi
}

# ========================================
# 测试 --version
# ========================================
echo ""
echo "Testing: --version"
VERSION_OUTPUT=$("$BINARY" --version 2>&1)

assert_not_empty "$VERSION_OUTPUT" "--version returns output"
assert_contains "$VERSION_OUTPUT" "Claude Code Installer" "--version contains product name"

# ========================================
# 测试 --list-models
# ========================================
echo ""
echo "Testing: --list-models"
MODELS_OUTPUT=$("$BINARY" --list-models 2>&1)

assert_not_empty "$MODELS_OUTPUT" "--list-models returns output"
assert_contains "$MODELS_OUTPUT" "claude-sonnet-4" "--list-models contains claude-sonnet-4"
assert_contains "$MODELS_OUTPUT" "claude-opus" "--list-models contains claude-opus"
assert_contains "$MODELS_OUTPUT" "claude-haiku" "--list-models contains claude-haiku"

# ========================================
# 测试 --config (无配置文件时)
# ========================================
echo ""
echo "Testing: --config (no existing config)"

# 确保没有配置文件
rm -rf "${HOME}/.claude"

CONFIG_OUTPUT=$("$BINARY" --config 2>&1 || true)

assert_not_empty "$CONFIG_OUTPUT" "--config returns output"
assert_contains "$CONFIG_OUTPUT" "未找到配置文件" "--config shows 'config not found' message"

# ========================================
# 测试 --help (如果支持)
# ========================================
echo ""
echo "Testing: --help or -h"
HELP_OUTPUT=$("$BINARY" --help 2>&1 || "$BINARY" -h 2>&1 || echo "")

if [ -n "$HELP_OUTPUT" ]; then
    assert_contains "$HELP_OUTPUT" "Usage" "--help shows usage (if supported)"
else
    echo "  [SKIP] --help not supported or no output"
fi

# ========================================
# 汇总
# ========================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "CLI Tests: ${TESTS_PASSED}/${TESTS_RUN} passed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$TESTS_PASSED" -eq "$TESTS_RUN" ]; then
    echo "SUCCESS: All CLI tests passed"
    exit 0
else
    echo "FAILURE: Some CLI tests failed"
    exit 1
fi
