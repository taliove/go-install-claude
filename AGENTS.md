# AGENTS.md - AI Coding Agent Guidelines

This document provides guidelines for AI coding agents working on the `easy-install-claude` project.

## Project Overview

A Shell/PowerShell-based installer for Claude Code with multi-provider support (MiniMax, Doubao, Zhipu AI, Wanjie Data).
One command to install everything: Node.js, Claude Code, and configuration.

- **Scripts**: Bash (install.sh), PowerShell (install.ps1)
- **Platforms**: Windows, Linux, macOS
- **Dependencies**: curl/wget (Linux/macOS), PowerShell 5+ (Windows)

## Project Structure

```
easy-install-claude/
├── install.sh              # Linux/macOS installation script
├── install.ps1             # Windows installation script (PowerShell)
├── bootstrap.ps1           # Windows bootstrap for UTF-8 encoding (ASCII only)
├── test/
│   ├── Dockerfile          # Docker container for E2E testing
│   └── test-e2e.sh         # E2E test script
├── .github/
│   └── workflows/
│       └── ci.yml          # Script syntax validation
├── README.md               # Project documentation
├── AGENTS.md               # AI agent guidelines (this file)
├── LICENSE                 # MIT License
├── .gitignore
└── .editorconfig
```

## Supported Providers

| # | Provider | Base URL | Models | API Key URL |
|---|----------|----------|--------|-------------|
| 1 | **MiniMax** (Default) | `https://api.minimaxi.com/anthropic` | M2.1-flash, M2.1-standard | platform.minimaxi.com |
| 2 | **豆包 (Doubao)** | `https://ark.cn-beijing.volces.com/api/coding` | ark-code-latest, custom | console.volcengine.com/ark |
| 3 | **智谱 AI (Zhipu)** | `https://open.bigmodel.cn/api/anthropic` | GLM-4.7, GLM-4.5-Air | open.bigmodel.cn |
| 4 | **万界数据 (Wanjie)** | `https://maas-openapi.wanjiedata.com/api/anthropic` | Claude series | data.wanjiehuyu.com |

## Testing

### E2E Testing (Required Before Push)

**IMPORTANT**: Before every commit and push, run the full E2E test suite:

```bash
# Build the test container
docker build -t claude-installer-test -f test/Dockerfile .

# Run full E2E tests (includes nvm, Node.js, Claude Code installation)
docker run --rm claude-installer-test bash ./test-e2e.sh

# Quick syntax check only
docker run --rm claude-installer-test
```

### E2E Test Coverage

The E2E test (`test/test-e2e.sh`) validates:

1. **Syntax Check**: `bash -n` and ShellCheck validation
2. **Environment Detection**: OS detection, curl availability, --help flag
3. **Node.js Installation**: nvm installation via China mirror, Node.js LTS
4. **Claude Code Installation**: npm global install of @anthropic-ai/claude-code
5. **Provider Configuration**: settings.json creation with correct provider values
6. **Configuration Verification**: Validates ANTHROPIC_BASE_URL matches selected provider
7. **Claude Execution**: Verifies claude command is available

### Skip Options

```bash
# Skip installation tests (faster, for config testing only)
docker run --rm -e SKIP_INSTALL=true claude-installer-test bash ./test-e2e.sh
```

### Non-Interactive Mode

The install script supports non-interactive mode for testing:

```bash
# Environment variables for non-interactive installation
NONINTERACTIVE=true
PROVIDER=1                              # 1=MiniMax, 2=Doubao, 3=Zhipu, 4=Wanjie
ANTHROPIC_API_KEY=your-api-key
ANTHROPIC_MODEL=M2.1-flash              # Model depends on provider
```

### Local Syntax Validation

```bash
# Validate Bash syntax
bash -n install.sh

# Run ShellCheck (install: apt install shellcheck / brew install shellcheck)
shellcheck install.sh

# Validate PowerShell syntax (PowerShell)
$null = [System.Management.Automation.Language.Parser]::ParseFile("install.ps1", [ref]$null, [ref]$errors)
if ($errors) { $errors | ForEach-Object { Write-Error $_ } }
```

## Running Install Scripts

```bash
# Linux/macOS - Full install
./install.sh

# Linux/macOS - Config only
./install.sh --config

# Windows - Full install
.\install.ps1

# Windows - Config only
.\install.ps1 -Config
```

## Code Style Guidelines

### Bash (install.sh)

1. **Shebang**: Always use `#!/bin/bash`

2. **Error handling**: Use `set -e` at the start

3. **Function naming**: Use `snake_case`
   ```bash
   install_nodejs() { ... }
   select_provider() { ... }
   select_model() { ... }
   ```

4. **Variable naming**: 
   - Local variables: `lowercase_with_underscores`
   - Global/exported: `UPPERCASE_WITH_UNDERSCORES`
   ```bash
   local api_key="$1"
   export ANTHROPIC_API_KEY="$api_key"
   ```

5. **Quoting**: Always quote variables
   ```bash
   # Good
   echo "$variable"
   
   # Bad
   echo $variable
   ```

6. **Command substitution**: Use `$()` instead of backticks
   ```bash
   # Good
   version=$(node -v)
   
   # Bad
   version=`node -v`
   ```

7. **Conditionals**: Use `[[ ]]` for tests
   ```bash
   if [[ -z "$var" ]]; then
       echo "var is empty"
   fi
   ```

8. **Colors**: Define at the top
   ```bash
   RED='\033[0;31m'
   GREEN='\033[0;32m'
   NC='\033[0m'
   ```

### PowerShell (install.ps1)

1. **Function naming**: Use `Verb-Noun` pattern (PascalCase)
   ```powershell
   function Install-NodeJS { ... }
   function Select-Provider { ... }
   function Select-Model { ... }
   ```

2. **Variable naming**: Use `$PascalCase` for script-scope, `$camelCase` for local
   ```powershell
   $script:ApiKey = "..."
   $localVar = "..."
   ```

3. **Parameters**: Use `param()` block at the top
   ```powershell
   param(
       [switch]$Config,
       [switch]$Help
   )
   ```

4. **Error handling**: Use `$ErrorActionPreference = "Stop"`

5. **Output functions**: Use consistent ASCII-safe prefixes
   ```powershell
   function Write-Info { Write-Host "[i] " -ForegroundColor Cyan -NoNewline; Write-Host $args[0] }
   function Write-Success { Write-Host "[+] " -ForegroundColor Green -NoNewline; Write-Host $args[0] }
   ```

## Provider Configuration

### Provider Data Structure (install.sh)

```bash
# Provider arrays
declare -a PROVIDER_NAMES=("MiniMax" "豆包 (火山引擎)" "智谱 AI" "万界数据")
declare -a PROVIDER_URLS=(
    "https://api.minimaxi.com/anthropic"
    "https://ark.cn-beijing.volces.com/api/coding"
    "https://open.bigmodel.cn/api/anthropic"
    "https://maas-openapi.wanjiedata.com/api/anthropic"
)
declare -a PROVIDER_KEY_URLS=(
    "https://platform.minimaxi.com"
    "https://console.volcengine.com/ark"
    "https://open.bigmodel.cn"
    "https://data.wanjiehuyu.com"
)
```

### Model Configuration by Provider

#### MiniMax Models
| Model ID | Name | Description |
|----------|------|-------------|
| `M2.1-flash` | M2.1 Flash | 免费模型，推荐日常使用 (Default) |
| `M2.1-standard` | M2.1 Standard | 标准模型，更强性能 |

#### Doubao Models
| Model ID | Name | Description |
|----------|------|-------------|
| `ark-code-latest` | Ark Code Latest | 默认模型 (Default) |
| Custom | - | 支持用户自定义输入 |

#### Zhipu Models
| Model ID | Name | Description |
|----------|------|-------------|
| `GLM-4.7` | GLM-4.7 | 推荐使用 (Default) |
| `GLM-4.5-Air` | GLM-4.5 Air | 快速响应 |

#### Wanjie Models (Claude)
| Model ID | Name | Description |
|----------|------|-------------|
| `claude-sonnet-4-20250514` | Claude Sonnet 4 | 性价比之选 (Default) |
| `claude-sonnet-4-5-20250929` | Claude Sonnet 4.5 | 增强版 Sonnet |
| `claude-haiku-4-5-20251001` | Claude Haiku 4.5 | 快速响应 |
| `claude-opus-4-1-20250805` | Claude Opus 4.1 | 复杂任务 |
| `claude-opus-4-5-20251101` | Claude Opus 4.5 | 旗舰模型 |

### Model Mapping Rules

| Provider | Haiku Mapping | Sonnet Mapping | Opus Mapping |
|----------|---------------|----------------|--------------|
| MiniMax | (empty) | (empty) | (empty) |
| Doubao | User's model | User's model | User's model |
| Zhipu | `GLM-4.5-Air` | `GLM-4.7` | `GLM-4.7` |
| Wanjie | `claude-haiku-4-5-20251001` | Based on selection | Based on selection |

### settings.json Template

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
    "ANTHROPIC_AUTH_TOKEN": "<API_KEY>",
    "ANTHROPIC_BASE_URL": "<PROVIDER_URL>",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "<MAPPED_VALUE>",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "<MAPPED_VALUE>",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "<MAPPED_VALUE>",
    "ANTHROPIC_MODEL": "<SELECTED_MODEL>",
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": 1
  }
}
```

Note: For MiniMax provider, the Haiku/Sonnet/Opus mapping fields are omitted or set to empty strings.

## China Network Acceleration

### Network Sources

| Component | URL | China Mirror |
|-----------|-----|--------------|
| NPM Registry | `https://registry.npmmirror.com` | 淘宝镜像 |
| Node.js (nvm) | `https://npmmirror.com/mirrors/node` | npmmirror |
| GitHub Raw | `https://raw.githubusercontent.com/...` | ghproxy.net |
| nvm Git Clone | `https://ghproxy.net/https://github.com/nvm-sh/nvm.git` | NVM_SOURCE |

### GitHub Mirror Strategy

Scripts automatically detect and use mirrors:

1. **Auto-detection**: Test if GitHub is accessible (3s timeout)
2. **Mirror fallback**: If blocked, try mirrors in order:
   - `https://ghproxy.net`
   - `https://mirror.ghproxy.com`
   - `https://gh-proxy.com`
3. **Direct fallback**: If all mirrors fail, try direct connection

### Environment Variables

```bash
# Force mirror (China users)
USE_MIRROR=true curl -fsSL ... | bash

# Force direct (overseas users)
USE_MIRROR=false curl -fsSL ... | bash

# Auto-detect (default)
curl -fsSL ... | bash

# Non-interactive with provider selection
NONINTERACTIVE=true PROVIDER=1 ANTHROPIC_API_KEY=xxx ANTHROPIC_MODEL=M2.1-flash curl -fsSL ... | bash
```

## CI/CD Pipeline

### Workflow: ci.yml

Triggered on push/PR to main branch:

1. **validate-bash**: Check install.sh syntax with `bash -n` and ShellCheck
2. **validate-powershell**: Check install.ps1 syntax with PowerShell Parser

## Commit and Push Protocol

When the user requests "签入推送" (commit and push):

1. **Run E2E tests first** (REQUIRED):
   ```bash
   docker build -t claude-installer-test -f test/Dockerfile .
   docker run --rm claude-installer-test bash ./test-e2e.sh
   ```

2. **Only commit and push after ALL tests pass**

3. **If tests fail**: Fix the issue first, re-run tests, then commit

### Pre-Push Checklist

- [ ] E2E tests pass: `docker run --rm claude-installer-test bash ./test-e2e.sh`
- [ ] Bash syntax OK: `bash -n install.sh`
- [ ] ShellCheck passes (warnings OK, errors NOT OK)
- [ ] PowerShell syntax OK (if install.ps1 changed)

## Common Tasks

### Adding a New Provider

1. Add provider to `PROVIDER_NAMES`, `PROVIDER_URLS`, `PROVIDER_KEY_URLS` arrays in install.sh
2. Add provider to `$script:Providers` array in install.ps1
3. Add model arrays for the new provider
4. Update model mapping logic in `calculate_model_mappings()` / `Get-ModelMappings`
5. Update AGENTS.md provider table
6. Update README.md provider table
7. Run E2E tests to verify

### Adding a New Model to Existing Provider

1. Add model to the provider's model arrays in both scripts
2. Update model mapping logic if needed
3. Update AGENTS.md model table for that provider
4. Update README.md model table
5. Run E2E tests to verify

### Updating GitHub Mirrors

Update both scripts' mirror arrays:

**install.sh:**
```bash
GITHUB_MIRRORS=(
    "https://ghproxy.net"
    "https://mirror.ghproxy.com"
    "https://gh-proxy.com"
    "https://new-mirror.example.com"  # Add here
)
```

**install.ps1:**
```powershell
$GitHubMirrors = @(
    "https://ghproxy.net"
    "https://mirror.ghproxy.com"
    "https://gh-proxy.com"
    "https://new-mirror.example.com"  # Add here
)
```

### Updating nvm Version

Update the nvm install URL in install.sh:
```bash
NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh"
```

### Updating Version Number

Version number is hardcoded in both scripts and displayed in the banner when the script runs.

**When to update version:**
- New feature added → bump minor version (e.g., 1.0.0 → 1.1.0)
- Bug fix → bump patch version (e.g., 1.0.0 → 1.0.1)
- Breaking change → bump major version (e.g., 1.0.0 → 2.0.0)

**Files to update:**

1. **install.sh** - Update `VERSION` variable:
   ```bash
   VERSION="1.1.0"
   ```

2. **install.ps1** - Update `$script:Version` variable:
   ```powershell
   $script:Version = "1.1.0"
   ```

**Important:** Both scripts must have the same version number.

## Release Process

When the user requests to release a new version ("发布版本"):

### Pre-Release Checklist

1. **Update version numbers in BOTH scripts** (REQUIRED):
   - `install.sh`: Update `VERSION="x.y.z"`
   - `install.ps1`: Update `$script:Version = "x.y.z"`
   - Both must have the SAME version number

2. **Run E2E tests** (REQUIRED):
   ```bash
   docker build -t claude-installer-test -f test/Dockerfile .
   docker run --rm claude-installer-test bash ./test-e2e.sh
   ```

3. **Validate syntax**:
   - Bash: `bash -n install.sh`
   - PowerShell: Parse test via scriptblock

### Release Steps

```bash
# 1. Stage and commit changes (include version bump)
git add install.sh install.ps1
git commit -m "feat/fix: description of changes

- Change details
- Version bump to x.y.z"

# 2. Push to main
git push origin main

# 3. Create and push version tag
git tag -a vx.y.z -m "vx.y.z: Brief description"
git push origin vx.y.z
```

### Version Numbering

- **Major** (x.0.0): Breaking changes
- **Minor** (0.x.0): New features
- **Patch** (0.0.x): Bug fixes

The scripts are always fetched from `main` branch, so users always get the latest version.
