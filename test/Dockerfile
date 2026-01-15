# ============================================================================
# Claude Code 安装脚本测试容器
# ============================================================================
#
# 用法:
#   # 构建镜像
#   docker build -t claude-installer-test -f test/Dockerfile .
#
#   # 快速语法检查 (默认)
#   docker run --rm claude-installer-test
#
#   # 完整 E2E 测试 (包含 nvm + Node.js + Claude Code 安装)
#   docker run --rm claude-installer-test bash ./test-e2e.sh
#
#   # 带真实 API Key 的 E2E 测试
#   docker run --rm -e TEST_API_KEY=sk-xxx claude-installer-test bash ./test-e2e.sh
#
#   # 跳过安装，仅测试配置逻辑
#   docker run --rm -e SKIP_INSTALL=true claude-installer-test bash ./test-e2e.sh
#
#   # 交互式调试
#   docker run -it --rm claude-installer-test bash
#
# ============================================================================

FROM ubuntu:22.04

# 设置非交互模式
ENV DEBIAN_FRONTEND=noninteractive

# 安装基础依赖
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    ca-certificates \
    shellcheck \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# 创建非 root 用户 (nvm 需要非 root)
RUN useradd -m -s /bin/bash testuser
USER testuser
WORKDIR /home/testuser

# 复制脚本
COPY --chown=testuser:testuser install.sh /home/testuser/install.sh
COPY --chown=testuser:testuser test/test-e2e.sh /home/testuser/test-e2e.sh
RUN chmod +x /home/testuser/install.sh /home/testuser/test-e2e.sh

# 默认命令: 仅语法检查 (快速)
CMD ["bash", "-c", "echo '=== 语法检查 ===' && bash -n install.sh && echo '[PASS] Bash 语法正确' && echo '' && echo '=== ShellCheck ===' && shellcheck install.sh; echo '' && echo '=== 检查完成 ==='"]
