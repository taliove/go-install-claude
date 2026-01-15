#!/bin/bash
# Claude Installer E2E 测试入口脚本
# 从 GitHub Release 下载最新版本并运行所有测试

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="${SCRIPT_DIR}/tests"

# 统计
PASSED=0
FAILED=0
SKIPPED=0

# 打印带颜色的消息
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[SKIP]${NC} $1"
}

# 运行单个测试
run_test() {
    local test_file="$1"
    local test_name
    test_name=$(basename "$test_file" .sh)
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    info "Running: ${test_name}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if bash "$test_file"; then
        success "${test_name} - PASSED"
        ((PASSED++))
        return 0
    else
        local exit_code=$?
        if [ $exit_code -eq 77 ]; then
            # 退出码 77 表示跳过测试
            warn "${test_name} - SKIPPED"
            ((SKIPPED++))
            return 0
        else
            error "${test_name} - FAILED (exit code: ${exit_code})"
            ((FAILED++))
            return 1
        fi
    fi
}

# 主函数
main() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║       Claude Installer E2E Tests (GitHub Release)            ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    info "GitHub Repo: ${GITHUB_REPO:-taliove/go-install-claude}"
    info "Full Install Test: ${RUN_FULL_INSTALL:-false}"
    info "Test Directory: ${TESTS_DIR}"
    echo ""
    
    # 检查测试目录
    if [ ! -d "$TESTS_DIR" ]; then
        error "Tests directory not found: ${TESTS_DIR}"
        exit 1
    fi
    
    # 获取所有测试文件并排序
    local test_files
    test_files=$(find "$TESTS_DIR" -name "*.sh" -type f | sort)
    
    if [ -z "$test_files" ]; then
        error "No test files found in ${TESTS_DIR}"
        exit 1
    fi
    
    local total
    total=$(echo "$test_files" | wc -l)
    info "Found ${total} test files"
    
    # 运行所有测试
    local failed_tests=()
    for test_file in $test_files; do
        if ! run_test "$test_file"; then
            failed_tests+=("$(basename "$test_file")")
        fi
    done
    
    # 打印汇总
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}                        TEST SUMMARY                          ${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}Passed:${NC}  ${PASSED}"
    echo -e "  ${RED}Failed:${NC}  ${FAILED}"
    echo -e "  ${YELLOW}Skipped:${NC} ${SKIPPED}"
    echo -e "  Total:   $((PASSED + FAILED + SKIPPED))"
    echo ""
    
    if [ ${#failed_tests[@]} -gt 0 ]; then
        echo -e "${RED}Failed tests:${NC}"
        for t in "${failed_tests[@]}"; do
            echo -e "  - ${t}"
        done
        echo ""
    fi
    
    # 返回最终状态
    if [ $FAILED -gt 0 ]; then
        echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║                    TESTS FAILED                              ║${NC}"
        echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
        exit 1
    else
        echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                  ALL TESTS PASSED!                           ║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
        exit 0
    fi
}

# 运行主函数
main "$@"
