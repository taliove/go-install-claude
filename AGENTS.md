# AGENTS.md - AI Coding Agent Guidelines

This document provides guidelines for AI coding agents working on the `claude-installer` project.

## Project Overview

A Shell/PowerShell-based installer for Claude Code with pre-configured Wanjie Data proxy (万界数据).
One command to install everything: Node.js, Claude Code, and configuration.

- **Scripts**: Bash (install.sh), PowerShell (install.ps1)
- **Platforms**: Windows, Linux, macOS
- **Dependencies**: curl/wget (Linux/macOS), PowerShell 5+ (Windows)

## Project Structure

```
claude-installer/
├── install.sh              # Linux/macOS installation script
├── install.ps1             # Windows installation script (PowerShell)
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
5. **Wanjie Proxy Configuration**: settings.json creation with correct values
6. **Configuration Verification**: Validates ANTHROPIC_BASE_URL points to Wanjie
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
ANTHROPIC_API_KEY=sk-xxx
ANTHROPIC_MODEL=claude-sonnet-4-20250514
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
   prompt_api_key() { ... }
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
   function Get-LatestVersion { ... }
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

## Model Configuration

### Supported Models

| Model ID | Name | Description |
|----------|------|-------------|
| `claude-sonnet-4-20250514` | Claude Sonnet 4 | 性价比之选，推荐日常使用 (Default) |
| `claude-sonnet-4-5-20250929` | Claude Sonnet 4.5 | 增强版 Sonnet，更强推理能力 |
| `claude-haiku-4-5-20251001` | Claude Haiku 4.5 | 快速响应，适合简单任务 |
| `claude-opus-4-1-20250805` | Claude Opus 4.1 | 强大性能，适合复杂任务 |
| `claude-opus-4-5-20251101` | Claude Opus 4.5 | 旗舰模型，最强性能 |

### Model Mapping Rules

| Variable | Logic |
|----------|-------|
| `ANTHROPIC_MODEL` | User's selected model |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | Always `claude-haiku-4-5-20251001` |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | Use 4.5 if user selected Sonnet 4.5, otherwise Sonnet 4 |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | Use 4.5 if user selected Opus 4.5, otherwise Opus 4.1 |

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
    "ANTHROPIC_BASE_URL": "https://maas-openapi.wanjiedata.com/api/anthropic",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "claude-haiku-4-5-20251001",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "<MAPPED_VALUE>",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "<MAPPED_VALUE>",
    "ANTHROPIC_MODEL": "<SELECTED_MODEL>",
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": 1
  }
}
```

## China Network Acceleration

### Network Sources

| Component | URL | China Mirror |
|-----------|-----|--------------|
| Claude API | `https://maas-openapi.wanjiedata.com/api/anthropic` | Built-in (万界数据) |
| NPM Registry | `https://registry.npmmirror.com` | 淘宝镜像 |
| Node.js (nvm) | `https://npmmirror.com/mirrors/node` | npmmirror |
| GitHub Raw | `https://raw.githubusercontent.com/...` | ghproxy.net |

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

### Adding a New Model

1. Add model to the selection menu in both scripts
2. Update model mapping logic if needed
3. Update AGENTS.md model table
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

## Release Process

Since there are no binary builds, releases are simply for versioning:

```bash
# Create version tag
git tag -a v2.0.0 -m "v2.0.0: Pure shell script installer"
git push origin v2.0.0
```

The scripts are always fetched from `main` branch, so users always get the latest version.
