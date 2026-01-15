# Claude Installer E2E Test Environment
# 从 GitHub Release 下载最新版本进行沙盒测试

FROM node:20-bookworm-slim

# 安装必要工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    jq \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 创建非 root 用户 (模拟真实用户环境)
RUN useradd -m -s /bin/bash testuser

# 切换到测试用户
USER testuser
WORKDIR /home/testuser

# 环境变量
ENV HOME=/home/testuser
ENV GITHUB_REPO=taliove/go-install-claude
ENV PATH="/home/testuser/.npm-global/bin:${PATH}"

# npm 全局安装目录设置 (避免权限问题)
RUN mkdir -p ~/.npm-global \
    && npm config set prefix '~/.npm-global'

# 复制测试脚本
COPY --chown=testuser:testuser test/e2e/run_tests.sh ./e2e/
COPY --chown=testuser:testuser test/e2e/tests/ ./e2e/tests/

# 复制安装脚本 (供测试验证)
COPY --chown=testuser:testuser install.sh ./
COPY --chown=testuser:testuser install.ps1 ./

# 设置脚本可执行权限
RUN chmod +x ./e2e/run_tests.sh ./e2e/tests/*.sh ./install.sh

# 入口
ENTRYPOINT ["bash", "./e2e/run_tests.sh"]
