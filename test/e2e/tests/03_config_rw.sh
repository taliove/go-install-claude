#!/bin/bash
# 测试 03: 配置文件读写测试
# 验证 settings.json 的读取和显示功能

set -e

echo "=== Test: Configuration File Read/Write ==="

# 二进制文件路径
BINARY="${HOME}/claude-installer"
CLAUDE_DIR="${HOME}/.claude"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

if [ ! -x "$BINARY" ]; then
    echo "ERROR: Binary not found at ${BINARY}"
    exit 1
fi

# 测试计数
TESTS_RUN=0
TESTS_PASSED=0

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

# ========================================
# 准备测试环境
# ========================================
echo ""
echo "Preparing test environment..."

# 清理并创建配置目录
rm -rf "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR"
echo "  Created: ${CLAUDE_DIR}"

# ========================================
# 测试 1: 创建有效配置文件
# ========================================
echo ""
echo "Test 1: Create valid settings.json"

cat > "$SETTINGS_FILE" << 'EOF'
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://maas-openapi.wanjiedata.com/api/anthropic",
    "ANTHROPIC_API_KEY": "test-api-key-1234567890",
    "ANTHROPIC_MODEL": "claude-sonnet-4-20250514"
  }
}
EOF

echo "  Created settings.json with test data"

# 验证文件存在
if [ -f "$SETTINGS_FILE" ]; then
    echo "  [PASS] Settings file created"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "  [FAIL] Settings file not created"
    TESTS_RUN=$((TESTS_RUN + 1))
    exit 1
fi

# ========================================
# 测试 2: --config 读取配置
# ========================================
echo ""
echo "Test 2: Read config with --config"

CONFIG_OUTPUT=$("$BINARY" --config 2>&1)

assert_contains "$CONFIG_OUTPUT" "当前配置" "--config shows header"
assert_contains "$CONFIG_OUTPUT" "maas-openapi.wanjiedata.com" "--config shows API URL"
assert_contains "$CONFIG_OUTPUT" "claude-sonnet-4" "--config shows model"

# ========================================
# 测试 3: API Key 脱敏显示
# ========================================
echo ""
echo "Test 3: API Key masking"

# API Key 应该显示为 test****7890 格式
assert_contains "$CONFIG_OUTPUT" "test" "--config shows API key prefix"
assert_contains "$CONFIG_OUTPUT" "7890" "--config shows API key suffix"
assert_contains "$CONFIG_OUTPUT" "****" "--config masks API key middle"

# 确保完整的 API Key 没有显示
if echo "$CONFIG_OUTPUT" | grep -q "test-api-key-1234567890"; then
    echo "  [FAIL] API Key not properly masked - full key visible"
    TESTS_RUN=$((TESTS_RUN + 1))
    exit 1
else
    echo "  [PASS] API Key is properly masked"
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_PASSED=$((TESTS_PASSED + 1))
fi

# ========================================
# 测试 4: 不同模型配置
# ========================================
echo ""
echo "Test 4: Different model configuration"

cat > "$SETTINGS_FILE" << 'EOF'
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://maas-openapi.wanjiedata.com/api/anthropic",
    "ANTHROPIC_API_KEY": "another-test-key-abc123",
    "ANTHROPIC_MODEL": "claude-opus-4-5-20251101"
  }
}
EOF

CONFIG_OUTPUT=$("$BINARY" --config 2>&1)
assert_contains "$CONFIG_OUTPUT" "claude-opus" "--config shows updated model"

# ========================================
# 测试 5: 缺少 API Key 的配置
# ========================================
echo ""
echo "Test 5: Config without API Key"

cat > "$SETTINGS_FILE" << 'EOF'
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://maas-openapi.wanjiedata.com/api/anthropic",
    "ANTHROPIC_MODEL": "claude-sonnet-4-20250514"
  }
}
EOF

CONFIG_OUTPUT=$("$BINARY" --config 2>&1)
assert_contains "$CONFIG_OUTPUT" "未配置" "--config shows 'not configured' for missing API key"

# ========================================
# 测试 6: 空配置文件
# ========================================
echo ""
echo "Test 6: Empty/invalid config file"

echo "{}" > "$SETTINGS_FILE"

CONFIG_OUTPUT=$("$BINARY" --config 2>&1 || true)
# 应该能处理空配置而不崩溃
TESTS_RUN=$((TESTS_RUN + 1))
if [ -n "$CONFIG_OUTPUT" ]; then
    echo "  [PASS] Handles empty config gracefully"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "  [FAIL] Crashed on empty config"
fi

# ========================================
# 清理
# ========================================
echo ""
echo "Cleaning up test environment..."
rm -rf "$CLAUDE_DIR"

# ========================================
# 汇总
# ========================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Config Tests: ${TESTS_PASSED}/${TESTS_RUN} passed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$TESTS_PASSED" -eq "$TESTS_RUN" ]; then
    echo "SUCCESS: All config tests passed"
    exit 0
else
    echo "FAILURE: Some config tests failed"
    exit 1
fi
