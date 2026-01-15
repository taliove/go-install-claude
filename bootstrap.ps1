# Claude Code Installer Bootstrap (ASCII only)
# This script downloads and runs install.ps1 with correct UTF-8 encoding
#
# Usage:
#   iwr -useb https://ghproxy.net/https://raw.githubusercontent.com/taliove/easy-install-claude/main/bootstrap.ps1 | iex
#   iwr -useb https://raw.githubusercontent.com/taliove/easy-install-claude/main/bootstrap.ps1 | iex

$ErrorActionPreference = "Stop"

# Set console to UTF-8 before downloading
try {
    $null = cmd /c chcp 65001 2>$null
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8
}
catch { }

Write-Host ""
Write-Host "+----------------------------------------------+" -ForegroundColor Cyan
Write-Host "|  Claude Code Installer                       |" -ForegroundColor Cyan
Write-Host "|  Wanjie Data Proxy                           |" -ForegroundColor Cyan
Write-Host "+----------------------------------------------+" -ForegroundColor Cyan
Write-Host ""
Write-Host "[i] Downloading installer..." -ForegroundColor Cyan

# Script URLs
$DirectUrl = "https://raw.githubusercontent.com/taliove/easy-install-claude/main/install.ps1"
$MirrorUrls = @(
    "https://ghproxy.net/$DirectUrl"
    "https://mirror.ghproxy.com/$DirectUrl"
    "https://gh-proxy.com/$DirectUrl"
)

# Try to download with mirrors first, then direct
$scriptContent = $null
$downloadSuccess = $false

# Check if GitHub is accessible
$useMirror = $true
try {
    $null = Invoke-WebRequest -Uri "https://github.com" -TimeoutSec 3 -UseBasicParsing
    $useMirror = $false
}
catch {
    $useMirror = $true
}

# Build URL list based on network detection
$urlList = if ($useMirror) { $MirrorUrls + $DirectUrl } else { @($DirectUrl) + $MirrorUrls }

foreach ($url in $urlList) {
    try {
        Write-Host "[i] Trying: $url" -ForegroundColor DarkGray
        
        # Download as bytes to preserve encoding
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30
        $bytes = $response.Content
        
        # Convert bytes to UTF-8 string
        if ($bytes -is [byte[]]) {
            $scriptContent = [System.Text.Encoding]::UTF8.GetString($bytes)
        }
        else {
            # If already string, re-encode
            $scriptContent = $bytes
        }
        
        $downloadSuccess = $true
        Write-Host "[+] Download successful" -ForegroundColor Green
        break
    }
    catch {
        Write-Host "[!] Failed: $url" -ForegroundColor Yellow
        continue
    }
}

if (-not $downloadSuccess -or [string]::IsNullOrEmpty($scriptContent)) {
    Write-Host "[x] Failed to download installer" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please try manual download:" -ForegroundColor Yellow
    Write-Host "  1. Visit: https://github.com/taliove/easy-install-claude" -ForegroundColor White
    Write-Host "  2. Download install.ps1" -ForegroundColor White
    Write-Host "  3. Run: .\install.ps1" -ForegroundColor White
    exit 1
}

# Execute the script content directly in memory
# This bypasses Windows execution policy restrictions on script files
Write-Host "[i] Running installer..." -ForegroundColor Cyan
Write-Host ""

Invoke-Expression $scriptContent
