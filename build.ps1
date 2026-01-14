# Claude Code 一键安装工具
# 跨平台构建脚本 (PowerShell)

param(
    [string]$Target = "all"
)

$ErrorActionPreference = "Stop"

# 创建输出目录
if (-not (Test-Path "dist")) {
    New-Item -ItemType Directory -Path "dist" | Out-Null
}

function Build-Windows {
    Write-Host "🔨 构建 Windows 版本..." -ForegroundColor Cyan
    $env:GOOS = "windows"
    $env:GOARCH = "amd64"
    go build -ldflags="-s -w" -o "dist/claude-installer-windows-amd64.exe" ./cmd/installer
    Write-Host "✅ Windows 版本构建完成" -ForegroundColor Green
}

function Build-Linux {
    Write-Host "🔨 构建 Linux 版本..." -ForegroundColor Cyan
    $env:GOOS = "linux"
    $env:GOARCH = "amd64"
    go build -ldflags="-s -w" -o "dist/claude-installer-linux-amd64" ./cmd/installer
    Write-Host "✅ Linux 版本构建完成" -ForegroundColor Green
}

function Build-DarwinAMD64 {
    Write-Host "🔨 构建 macOS (Intel) 版本..." -ForegroundColor Cyan
    $env:GOOS = "darwin"
    $env:GOARCH = "amd64"
    go build -ldflags="-s -w" -o "dist/claude-installer-darwin-amd64" ./cmd/installer
    Write-Host "✅ macOS (Intel) 版本构建完成" -ForegroundColor Green
}

function Build-DarwinARM64 {
    Write-Host "🔨 构建 macOS (Apple Silicon) 版本..." -ForegroundColor Cyan
    $env:GOOS = "darwin"
    $env:GOARCH = "arm64"
    go build -ldflags="-s -w" -o "dist/claude-installer-darwin-arm64" ./cmd/installer
    Write-Host "✅ macOS (Apple Silicon) 版本构建完成" -ForegroundColor Green
}

function Build-All {
    Write-Host "🚀 开始构建所有平台版本..." -ForegroundColor Yellow
    Write-Host ""
    Build-Windows
    Build-Linux
    Build-DarwinAMD64
    Build-DarwinARM64
    Write-Host ""
    Write-Host "🎉 所有平台构建完成！" -ForegroundColor Green
    Write-Host ""
    Write-Host "输出文件:" -ForegroundColor Yellow
    Get-ChildItem dist | ForEach-Object {
        $size = [math]::Round($_.Length / 1MB, 2)
        Write-Host "  📦 $($_.Name) ($size MB)" -ForegroundColor Cyan
    }
}

# 主逻辑
switch ($Target.ToLower()) {
    "windows" { Build-Windows }
    "linux" { Build-Linux }
    "darwin" { Build-DarwinAMD64; Build-DarwinARM64 }
    "darwin-amd64" { Build-DarwinAMD64 }
    "darwin-arm64" { Build-DarwinARM64 }
    "all" { Build-All }
    "clean" {
        Write-Host "🧹 清理构建目录..." -ForegroundColor Yellow
        Remove-Item -Recurse -Force dist -ErrorAction SilentlyContinue
        Write-Host "✅ 清理完成" -ForegroundColor Green
    }
    default {
        Write-Host "用法: .\build.ps1 [target]" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "可用目标:" -ForegroundColor Cyan
        Write-Host "  all          - 构建所有平台 (默认)"
        Write-Host "  windows      - 仅构建 Windows"
        Write-Host "  linux        - 仅构建 Linux"
        Write-Host "  darwin       - 构建 macOS (Intel + ARM)"
        Write-Host "  darwin-amd64 - 仅构建 macOS Intel"
        Write-Host "  darwin-arm64 - 仅构建 macOS Apple Silicon"
        Write-Host "  clean        - 清理构建目录"
    }
}
