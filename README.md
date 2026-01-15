# Claude Code 一键安装工具

[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-blue?style=flat-square)](https://github.com/taliove/easy-install-claude)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

专为国内用户设计的 Claude Code 一键安装工具，预配置万界数据代理，一行命令完成所有安装配置。

```
  ╔════════════════════════════════════════════╗
  ║  Claude Code 一键安装工具                  ║
  ║  ⚡ 万界数据 ⚡                            ║
  ╚════════════════════════════════════════════╝
```

## ✨ 特性

- 🚀 **一键安装** - 自动安装 Node.js、配置 NPM 镜像、安装 Claude Code
- 🔧 **预设万界代理** - 无需手动配置代理地址
- 📦 **多模型支持** - 支持选择 Claude Sonnet/Opus/Haiku 系列
- 🔄 **随时重配** - 使用 `--config` 参数重新配置 API Key 和模型
- 💻 **跨平台支持** - Windows、Linux、macOS 全平台覆盖
- 🔑 **安全配置** - API Key 自动写入 `~/.claude/settings.json`
- 🌐 **网络加速** - 自动检测并使用国内镜像加速

## 📥 一键安装

### 国内用户（推荐，使用加速镜像）

#### Linux / macOS

```bash
curl -fsSL https://ghproxy.net/https://raw.githubusercontent.com/taliove/easy-install-claude/main/install.sh | bash
```

#### Windows (PowerShell)

```powershell
iwr -useb https://ghproxy.net/https://raw.githubusercontent.com/taliove/easy-install-claude/main/install.ps1 | iex
```

### 海外用户（直连 GitHub）

#### Linux / macOS

```bash
curl -fsSL https://raw.githubusercontent.com/taliove/easy-install-claude/main/install.sh | bash
```

#### Windows (PowerShell)

```powershell
iwr -useb https://raw.githubusercontent.com/taliove/easy-install-claude/main/install.ps1 | iex
```

## 🔄 重新配置

已安装用户可随时重新配置 API Key 和模型：

#### Linux / macOS

```bash
curl -fsSL https://ghproxy.net/https://raw.githubusercontent.com/taliove/easy-install-claude/main/install.sh | bash -s -- --config
```

#### Windows (PowerShell)

```powershell
# 下载后运行
Invoke-WebRequest -Uri "https://ghproxy.net/https://raw.githubusercontent.com/taliove/easy-install-claude/main/install.ps1" -OutFile install.ps1; .\install.ps1 -Config
```

## 🔧 支持的模型

| 模型 ID | 名称 | 说明 |
|---------|------|------|
| `claude-sonnet-4-20250514` | Claude Sonnet 4 | 性价比之选，推荐日常使用 ⭐ |
| `claude-sonnet-4-5-20250929` | Claude Sonnet 4.5 | 增强版 Sonnet，更强推理能力 |
| `claude-haiku-4-5-20251001` | Claude Haiku 4.5 | 快速响应，适合简单任务 |
| `claude-opus-4-1-20250805` | Claude Opus 4.1 | 强大性能，适合复杂任务 |
| `claude-opus-4-5-20251101` | Claude Opus 4.5 | 旗舰模型，最强性能 |

## 🎮 命令行选项

### install.sh (Linux/macOS)

```bash
# 完整安装（默认）
curl -fsSL <URL> | bash

# 仅重新配置
curl -fsSL <URL> | bash -s -- --config

# 显示帮助
curl -fsSL <URL> | bash -s -- --help
```

### install.ps1 (Windows)

```powershell
# 完整安装（默认）
.\install.ps1

# 仅重新配置
.\install.ps1 -Config

# 显示帮助
.\install.ps1 -Help
```

## 🌐 环境变量控制

```bash
# 强制使用国内镜像加速
USE_MIRROR=true curl -fsSL <URL> | bash

# 强制直连 GitHub（海外用户）
USE_MIRROR=false curl -fsSL <URL> | bash

# 自动检测（默认）
curl -fsSL <URL> | bash
```

## 📁 配置文件

安装完成后，配置将写入 `~/.claude/settings.json`：

```json
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
    "ANTHROPIC_AUTH_TOKEN": "your-api-key",
    "ANTHROPIC_BASE_URL": "https://maas-openapi.wanjiedata.com/api/anthropic",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "claude-haiku-4-5-20251001",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-4-1-20250805",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-4-20250514",
    "ANTHROPIC_MODEL": "claude-sonnet-4-20250514",
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": 1
  }
}
```

## 🎯 使用方法

安装完成后，在终端中运行：

```bash
claude
```

开始使用 Claude Code 进行 AI 编程！

## ❓ 常见问题

### Q: 安装过程自动做了什么？

1. 检测/安装 Node.js 18+（使用 nvm/winget）
2. 配置 npm 使用淘宝镜像
3. 安装 Claude Code CLI
4. 交互式输入 API Key 和选择模型
5. 写入配置到 `~/.claude/settings.json`
6. 配置 PATH 环境变量

### Q: Node.js 安装失败

**Linux/macOS**: 脚本使用 nvm 安装 Node.js，如果失败请手动安装：
```bash
# 安装 nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# 安装 Node.js
nvm install 18
```

**Windows**: 脚本使用 winget 安装，如果失败请从 https://nodejs.org/ 下载安装。

### Q: Claude Code 安装失败

检查网络连接，然后手动安装：
```bash
npm config set registry https://registry.npmmirror.com
npm install -g @anthropic-ai/claude-code
```

### Q: 如何修改配置？

方式一：重新运行配置脚本
```bash
curl -fsSL <URL> | bash -s -- --config
```

方式二：直接编辑配置文件
```bash
vim ~/.claude/settings.json
```

### Q: 如何获取 API Key？

访问 [万界数据](https://www.wanjiedata.com) 注册并获取 API Key。

## 📄 开源协议

MIT License

## 🙏 致谢

- [Anthropic](https://anthropic.com) - Claude AI
- [万界数据](https://www.wanjiedata.com) - API 代理服务
- [nvm](https://github.com/nvm-sh/nvm) - Node Version Manager
