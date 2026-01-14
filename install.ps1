# Claude Code 一键安装脚本 (PowerShell)
# 使用方法: iwr -useb https://raw.githubusercontent.com/anthropic/go-install-claude/main/install.ps1 | iex
#
# 或者保存后运行:
# .\install.ps1 -Version v1.0.0

param(
    [string]$Version = "latest"
)

$ErrorActionPreference = "Stop"

# 配置
$Repo = "anthropic/go-install-claude"
$BinaryName = "claude-installer"
$InstallDir = "$env:LOCALAPPDATA\Programs\claude-installer"

# 颜色输出函数
function Write-Info { Write-Host "ℹ " -ForegroundColor Cyan -NoNewline; Write-Host $args[0] }
function Write-Success { Write-Host "✓ " -ForegroundColor Green -NoNewline; Write-Host $args[0] }
function Write-Warn { Write-Host "⚠ " -ForegroundColor Yellow -NoNewline; Write-Host $args[0] }
function Write-Err { Write-Host "✖ " -ForegroundColor Red -NoNewline; Write-Host $args[0] }

# Banner
function Show-Banner {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  " -ForegroundColor Cyan -NoNewline
    Write-Host "Claude Code 一键安装工具" -ForegroundColor White -NoNewline
    Write-Host "                  ║" -ForegroundColor Cyan
    Write-Host "║  " -ForegroundColor Cyan -NoNewline
    Write-Host "⚡ 万界数据 ⚡" -ForegroundColor Yellow -NoNewline
    Write-Host "                            ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# 检测架构
function Get-Platform {
    $arch = [System.Environment]::Is64BitOperatingSystem
    if (-not $arch) {
        Write-Err "需要 64 位 Windows"
        exit 1
    }
    
    $script:Platform = "windows-amd64"
    $script:Binary = "$BinaryName-$Platform.exe"
    
    Write-Info "检测到平台: $Platform"
}

# 获取最新版本
function Get-LatestVersion {
    if ($Version -eq "latest") {
        Write-Info "获取最新版本信息..."
        try {
            $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest"
            $script:Version = $release.tag_name
        }
        catch {
            Write-Err "无法获取最新版本: $_"
            exit 1
        }
    }
    Write-Success "版本: $Version"
}

# 下载
function Download-Binary {
    $downloadUrl = "https://github.com/$Repo/releases/download/$Version/$Binary"
    
    Write-Info "下载安装程序..."
    Write-Info "URL: $downloadUrl"
    
    # 创建临时文件
    $tmpFile = [System.IO.Path]::GetTempFileName() + ".exe"
    
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tmpFile -UseBasicParsing
    }
    catch {
        Write-Err "下载失败: $_"
        exit 1
    }
    
    if (-not (Test-Path $tmpFile)) {
        Write-Err "下载失败"
        exit 1
    }
    
    $script:TmpFile = $tmpFile
    Write-Success "下载完成"
}

# 安装
function Install-Binary {
    # 创建安装目录
    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }
    
    # 目标路径
    $targetPath = Join-Path $InstallDir "$BinaryName.exe"
    
    # 移动文件
    Move-Item -Path $TmpFile -Destination $targetPath -Force
    
    Write-Success "安装到: $targetPath"
    
    $script:TargetPath = $targetPath
}

# 添加到 PATH
function Add-ToPath {
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    
    if ($currentPath -notlike "*$InstallDir*") {
        Write-Info "添加到 PATH..."
        
        $newPath = "$currentPath;$InstallDir"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        
        # 更新当前会话
        $env:Path = "$env:Path;$InstallDir"
        
        Write-Success "已添加到 PATH (需要重新打开终端生效)"
    }
}

# 运行安装程序
function Run-Installer {
    Write-Host ""
    Write-Info "启动 Claude Code 安装向导..."
    Write-Host ""
    
    & $TargetPath
}

# 主函数
function Main {
    Show-Banner
    Get-Platform
    Get-LatestVersion
    Download-Binary
    Install-Binary
    Add-ToPath
    
    Write-Host ""
    Write-Success "安装完成！"
    Write-Host ""
    
    # 询问是否立即运行
    $response = Read-Host "是否立即运行安装向导? [Y/n]"
    if ($response -eq "" -or $response -match "^[Yy]") {
        Run-Installer
    }
    else {
        Write-Host ""
        Write-Info "稍后可以运行以下命令启动安装向导:"
        Write-Host "  $BinaryName" -ForegroundColor Cyan
        Write-Host ""
    }
}

# 运行
Main
