# Claude Code 一键安装工具

[![Go Version](https://img.shields.io/badge/Go-1.21+-00ADD8?style=flat-square&logo=go)](https://go.dev/)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-blue?style=flat-square)](https://github.com/anthropic/go-install-claude)

专为国内用户设计的 Claude Code 一键安装工具，预配置万界数据代理，只需输入 API Key 即可完成安装。

![demo](https://via.placeholder.com/800x400/1A1B26/00D4AA?text=Claude+Code+Installer+TUI)

## ✨ 特性

- 🎨 **精美 TUI 界面** - 模仿 OpenCode 的蓝绿色主题设计
- 🚀 **一键安装** - 自动配置 NPM 镜像、安装 Claude Code
- 🔧 **预设万界代理** - 无需手动配置代理地址
- 📦 **多模型支持** - 支持选择 Claude Sonnet/Opus/Haiku 系列
- 💻 **跨平台支持** - Windows、Linux、macOS 全平台覆盖
- 🔑 **安全配置** - API Key 自动写入 `~/.claude/settings.json`

## 📥 一键下载运行

### Windows (PowerShell)

```powershell
# 下载并运行安装程序
irm https://github.com/your-repo/releases/download/v1.0.0/claude-installer-windows-amd64.exe -OutFile claude-installer.exe; .\claude-installer.exe
```

### Linux / macOS (Bash)

```bash
# Linux x64
curl -fsSL https://github.com/your-repo/releases/download/v1.0.0/claude-installer-linux-amd64 -o claude-installer && chmod +x claude-installer && ./claude-installer

# macOS Intel
curl -fsSL https://github.com/your-repo/releases/download/v1.0.0/claude-installer-darwin-amd64 -o claude-installer && chmod +x claude-installer && ./claude-installer

# macOS Apple Silicon (M1/M2/M3)
curl -fsSL https://github.com/your-repo/releases/download/v1.0.0/claude-installer-darwin-arm64 -o claude-installer && chmod +x claude-installer && ./claude-installer
```

## 📋 前置要求

- **Node.js 18+** - [下载地址](https://nodejs.org/)
- **万界数据 API Key** - [获取地址](https://www.wanjiedata.com)

## 🔧 支持的模型

| 模型 | 说明 |
|------|------|
| `claude-sonnet-4-20250514` | 性价比之选，推荐日常使用 ⭐ |
| `claude-sonnet-4-5-20250929` | 增强版 Sonnet，更强推理能力 |
| `claude-haiku-4-5-20251001` | 快速响应，适合简单任务 |
| `claude-opus-4-1-20250805` | 强大性能，适合复杂任务 |
| `claude-opus-4-5-20251101` | 旗舰模型，最强性能 |

## 🏗️ 自行构建

### 前置条件

- Go 1.21+

### 构建命令

```bash
# 克隆仓库
git clone https://github.com/your-repo/go-install-claude.git
cd go-install-claude

# 下载依赖
go mod tidy

# 构建所有平台
# Windows PowerShell
.\build.ps1

# Linux/macOS
chmod +x build.sh && ./build.sh

# 仅构建当前平台
go build -o claude-installer ./cmd/installer
```

### 构建输出

```
dist/
├── claude-installer-windows-amd64.exe  # Windows 64位
├── claude-installer-linux-amd64        # Linux 64位
├── claude-installer-darwin-amd64       # macOS Intel
└── claude-installer-darwin-arm64       # macOS Apple Silicon
```

## 📁 配置文件

安装完成后，配置将写入 `~/.claude/settings.json`：

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://maas-openapi.wanjiedata.com/api/anthropic",
    "ANTHROPIC_API_KEY": "your-api-key",
    "ANTHROPIC_MODEL": "claude-sonnet-4-20250514"
  }
}
```

## 🎮 使用方法

安装完成后，在终端中运行：

```bash
claude
```

开始使用 Claude Code 进行 AI 编程！

## ❓ 常见问题

### Q: 提示 "未检测到 Node.js"

请先安装 Node.js 18 或更高版本：https://nodejs.org/

### Q: 安装失败，显示网络错误

1. 检查网络连接
2. 程序会自动使用淘宝 NPM 镜像
3. 如果仍失败，请尝试手动安装：
   ```bash
   npm config set registry https://registry.npmmirror.com
   npm install -g @anthropic-ai/claude-code
   ```

### Q: 如何修改配置？

直接编辑 `~/.claude/settings.json` 文件即可。

## 📄 开源协议

MIT License

## 🙏 致谢

- [Anthropic](https://anthropic.com) - Claude AI
- [万界数据](https://www.wanjiedata.com) - API 代理服务
- [Charm](https://charm.sh) - Bubble Tea TUI 框架
- [OpenCode](https://github.com/opencode-ai/opencode) - TUI 设计灵感
