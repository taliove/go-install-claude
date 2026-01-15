# Claude Code 一键安装脚本 (Windows PowerShell)
#
# 国内用户（推荐，使用加速镜像）:
#   iwr -useb https://ghproxy.net/https://raw.githubusercontent.com/taliove/easy-install-claude/main/bootstrap.ps1 | iex
#
# 海外用户（直连 GitHub）:
#   iwr -useb https://raw.githubusercontent.com/taliove/easy-install-claude/main/bootstrap.ps1 | iex
#
# 本地运行（已下载）:
#   .\install.ps1
#
# 仅重新配置:
#   .\install.ps1 -Config
#
# 环境变量:
#   $env:USE_MIRROR="true"   强制使用国内镜像加速
#   $env:USE_MIRROR="false"  强制直连（海外用户）
#   不设置则自动检测

param(
    [switch]$Config,  # 仅配置模式
    [switch]$Help     # 显示帮助
)

$ErrorActionPreference = "Stop"

# ============================================================================
# 控制台编码设置 (解决中文乱码问题)
# ============================================================================

# 保存原始编码设置以便恢复
$script:OriginalOutputEncoding = [Console]::OutputEncoding
$script:OriginalInputEncoding = [Console]::InputEncoding
$script:OriginalPSOutputEncoding = $OutputEncoding
$script:OriginalCodePage = $null

function Initialize-ConsoleEncoding {
    # 尝试设置控制台代码页为 UTF-8 (65001)
    try {
        # 保存当前代码页
        $chcpOutput = cmd /c chcp 2>$null
        if ($chcpOutput -match '\d+') {
            $script:OriginalCodePage = $matches[0]
        }
        
        # 设置 UTF-8 代码页
        $null = cmd /c chcp 65001 2>$null
    }
    catch {
        # 忽略错误，继续执行
    }
    
    # 设置 PowerShell 编码
    try {
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        [Console]::InputEncoding = [System.Text.Encoding]::UTF8
        $script:OutputEncoding = [System.Text.Encoding]::UTF8
        $global:OutputEncoding = [System.Text.Encoding]::UTF8
    }
    catch {
        # 在某些受限环境中可能失败，忽略
    }
    
    # 设置默认编码参数
    $PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
    $PSDefaultParameterValues['Set-Content:Encoding'] = 'utf8'
}

function Restore-ConsoleEncoding {
    # 恢复原始编码设置
    try {
        if ($script:OriginalCodePage) {
            $null = cmd /c chcp $script:OriginalCodePage 2>$null
        }
        [Console]::OutputEncoding = $script:OriginalOutputEncoding
        [Console]::InputEncoding = $script:OriginalInputEncoding
        $global:OutputEncoding = $script:OriginalPSOutputEncoding
    }
    catch {
        # 忽略恢复错误
    }
}

# 立即初始化编码
Initialize-ConsoleEncoding

# ============================================================================
# 配置常量
# ============================================================================

$script:NpmRegistry = "https://registry.npmmirror.com"
$script:ClaudePackage = "@anthropic-ai/claude-code"
$script:ClaudeDir = "$env:USERPROFILE\.claude"
$script:SettingsFile = "$script:ClaudeDir\settings.json"

# GitHub 加速镜像列表
$script:GitHubMirrors = @(
    "https://ghproxy.net"
    "https://mirror.ghproxy.com"
    "https://gh-proxy.com"
)

# 模型列表
$script:Models = @(
    @{
        ID          = "claude-sonnet-4-20250514"
        Name        = "Claude Sonnet 4"
        Tag         = "[推荐]"
        Description = "性价比之选，日常使用"
        Family      = "sonnet"
    },
    @{
        ID          = "claude-sonnet-4-5-20250929"
        Name        = "Claude Sonnet 4.5"
        Tag         = ""
        Description = "增强版，更强推理能力"
        Family      = "sonnet"
    },
    @{
        ID          = "claude-haiku-4-5-20251001"
        Name        = "Claude Haiku 4.5"
        Tag         = ""
        Description = "快速响应，适合简单任务"
        Family      = "haiku"
    },
    @{
        ID          = "claude-opus-4-1-20250805"
        Name        = "Claude Opus 4.1"
        Tag         = ""
        Description = "强大性能，适合复杂任务"
        Family      = "opus"
    },
    @{
        ID          = "claude-opus-4-5-20251101"
        Name        = "Claude Opus 4.5"
        Tag         = ""
        Description = "旗舰模型，最强性能"
        Family      = "opus"
    }
)

# 全局状态
$script:MirrorMode = $false
$script:ActiveMirror = ""

# ============================================================================
# 输出函数 (使用 ASCII 兼容符号)
# ============================================================================

function Write-Info { 
    Write-Host "[i] " -ForegroundColor Cyan -NoNewline
    Write-Host $args[0] 
}

function Write-Success { 
    Write-Host "[+] " -ForegroundColor Green -NoNewline
    Write-Host $args[0] 
}

function Write-Warn { 
    Write-Host "[!] " -ForegroundColor Yellow -NoNewline
    Write-Host $args[0] 
}

function Write-Err { 
    Write-Host "[x] " -ForegroundColor Red -NoNewline
    Write-Host $args[0] 
}

function Write-Step {
    param([int]$Step, [int]$Total, [string]$Message)
    Write-Host ""
    Write-Host "[$Step/$Total] " -ForegroundColor Magenta -NoNewline
    Write-Host $Message -ForegroundColor White
    Write-Host ("-" * 50) -ForegroundColor DarkGray
}

# ============================================================================
# Banner
# ============================================================================

function Show-Banner {
    Write-Host ""
    Write-Host "+----------------------------------------------+" -ForegroundColor Cyan
    Write-Host "|  " -ForegroundColor Cyan -NoNewline
    Write-Host "Claude Code Installer" -ForegroundColor White -NoNewline
    Write-Host "                       |" -ForegroundColor Cyan
    Write-Host "|  " -ForegroundColor Cyan -NoNewline
    Write-Host "Wanjie Data (万界数据)" -ForegroundColor Yellow -NoNewline
    Write-Host "                    |" -ForegroundColor Cyan
    Write-Host "+----------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================================
# 帮助信息
# ============================================================================

function Show-Help {
    Show-Banner
    Write-Host "用法: install.ps1 [选项]" -ForegroundColor White
    Write-Host ""
    Write-Host "选项:" -ForegroundColor Yellow
    Write-Host "  -Config    仅运行配置向导（跳过安装步骤）"
    Write-Host "  -Help      显示此帮助信息"
    Write-Host ""
    Write-Host "示例:" -ForegroundColor Yellow
    Write-Host "  # 完整安装（首次使用）"
    Write-Host "  iwr -useb <url> | iex"
    Write-Host ""
    Write-Host "  # 仅重新配置 API Key 和模型"
    Write-Host "  .\install.ps1 -Config"
    Write-Host ""
    Write-Host "环境变量:" -ForegroundColor Yellow
    Write-Host "  USE_MIRROR=true   强制使用国内镜像"
    Write-Host "  USE_MIRROR=false  强制直连 GitHub"
    Write-Host ""
}

# ============================================================================
# 网络检测和镜像
# ============================================================================

function Test-MirrorNeed {
    $useMirror = $env:USE_MIRROR
    
    if ($useMirror -eq "true") {
        $script:MirrorMode = $true
        Write-Info "强制使用镜像模式"
        return
    }
    elseif ($useMirror -eq "false") {
        $script:MirrorMode = $false
        Write-Info "强制使用直连模式"
        return
    }
    
    Write-Info "正在检测网络环境..."
    
    try {
        $null = Invoke-WebRequest -Uri "https://github.com" -TimeoutSec 3 -UseBasicParsing
        $script:MirrorMode = $false
        Write-Success "GitHub 可直接访问"
    }
    catch {
        $script:MirrorMode = $true
        Write-Warn "GitHub 访问较慢，将使用镜像加速"
    }
}

function Find-WorkingMirror {
    foreach ($mirror in $script:GitHubMirrors) {
        try {
            $null = Invoke-WebRequest -Uri $mirror -TimeoutSec 5 -UseBasicParsing
            $script:ActiveMirror = $mirror
            Write-Success "使用镜像: $mirror"
            return $true
        }
        catch {
            continue
        }
    }
    Write-Warn "所有镜像不可用，将尝试直连"
    return $false
}

# ============================================================================
# Node.js 检测和安装
# ============================================================================

function Test-NodeJS {
    try {
        $nodeVersion = & node --version 2>$null
        if ($nodeVersion) {
            # 提取主版本号
            $major = [int]($nodeVersion -replace '^v(\d+)\..*', '$1')
            if ($major -ge 18) {
                Write-Success "Node.js 已安装: $nodeVersion"
                return $true
            }
            else {
                Write-Warn "Node.js 版本过低: $nodeVersion (需要 v18+)"
                return $false
            }
        }
    }
    catch {
        # Node.js 未安装
    }
    return $false
}

function Test-Winget {
    try {
        $null = & winget --version 2>$null
        return $true
    }
    catch {
        return $false
    }
}

function Install-NodeJS {
    Write-Info "正在安装 Node.js LTS..."
    
    if (Test-Winget) {
        Write-Info "使用 winget 安装..."
        try {
            # 使用 winget 安装 Node.js LTS
            & winget install OpenJS.NodeJS.LTS --silent --accept-package-agreements --accept-source-agreements
            
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Node.js 安装成功"
                
                # 刷新 PATH
                Update-PathEnvironment
                return $true
            }
        }
        catch {
            Write-Warn "winget 安装失败: $_"
        }
    }
    else {
        Write-Warn "winget 不可用"
    }
    
    # 提示手动安装
    Write-Host ""
    Write-Err "无法自动安装 Node.js"
    Write-Host ""
    Write-Host "请手动安装 Node.js:" -ForegroundColor Yellow
    Write-Host "  1. 访问 https://nodejs.org/zh-cn" -ForegroundColor White
    Write-Host "  2. 下载 LTS 版本（推荐 v20 或 v22）" -ForegroundColor White
    Write-Host "  3. 运行安装程序" -ForegroundColor White
    Write-Host "  4. 重新打开终端，再次运行此脚本" -ForegroundColor White
    Write-Host ""
    return $false
}

function Update-PathEnvironment {
    # 刷新当前会话的 PATH 环境变量
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
    
    # 常见 Node.js 安装路径
    $nodePaths = @(
        "$env:ProgramFiles\nodejs"
        "${env:ProgramFiles(x86)}\nodejs"
        "$env:LOCALAPPDATA\Programs\nodejs"
    )
    
    foreach ($nodePath in $nodePaths) {
        if ((Test-Path $nodePath) -and ($env:Path -notlike "*$nodePath*")) {
            $env:Path = "$env:Path;$nodePath"
        }
    }
}

# ============================================================================
# npm 配置
# ============================================================================

function Set-NpmRegistry {
    Write-Info "配置 npm 淘宝镜像..."
    try {
        & npm config set registry $script:NpmRegistry 2>$null
        Write-Success "npm 镜像已配置: $script:NpmRegistry"
        return $true
    }
    catch {
        Write-Warn "npm 镜像配置失败: $_"
        return $false
    }
}

# ============================================================================
# Claude Code 安装
# ============================================================================

function Test-ClaudeCode {
    try {
        $version = & claude --version 2>$null
        if ($version) {
            Write-Success "Claude Code 已安装: $version"
            return $true
        }
    }
    catch {
        # 未安装
    }
    return $false
}

function Install-ClaudeCodePackage {
    Write-Info "正在安装 Claude Code..."
    Write-Info "这可能需要几分钟，请耐心等待..."
    
    try {
        # 使用 npm 全局安装
        $process = Start-Process -FilePath "npm" -ArgumentList "install", "-g", $script:ClaudePackage -NoNewWindow -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            # 刷新 PATH
            Update-PathEnvironment
            
            # 添加 npm 全局目录到 PATH
            $npmGlobalDir = & npm config get prefix 2>$null
            if ($npmGlobalDir -and (Test-Path $npmGlobalDir)) {
                if ($env:Path -notlike "*$npmGlobalDir*") {
                    $env:Path = "$env:Path;$npmGlobalDir"
                }
            }
            
            Write-Success "Claude Code 安装成功"
            return $true
        }
        else {
            Write-Err "npm install 失败，退出码: $($process.ExitCode)"
            return $false
        }
    }
    catch {
        Write-Err "安装失败: $_"
        return $false
    }
}

# ============================================================================
# 配置向导
# ============================================================================

function Read-ApiKey {
    Write-Host ""
    Write-Host "请输入您的 API Key:" -ForegroundColor Yellow
    Write-Host "(从 万界数据 获取: https://data.wanjie.info)" -ForegroundColor DarkGray
    Write-Host ""
    
    # 尝试读取现有配置
    $existingKey = ""
    if (Test-Path $script:SettingsFile) {
        try {
            $settings = Get-Content $script:SettingsFile -Raw | ConvertFrom-Json
            $existingKey = $settings.env.ANTHROPIC_AUTH_TOKEN
            if ($existingKey) {
                $masked = $existingKey.Substring(0, [Math]::Min(8, $existingKey.Length)) + "..."
                Write-Host "当前 Key: $masked" -ForegroundColor DarkGray
            }
        }
        catch { }
    }
    
    $key = Read-Host "API Key"
    
    # 如果用户直接回车且有现有 key，使用现有的
    if ([string]::IsNullOrWhiteSpace($key) -and $existingKey) {
        Write-Info "保留现有 API Key"
        return $existingKey
    }
    
    # 验证 key 格式
    if ([string]::IsNullOrWhiteSpace($key)) {
        Write-Err "API Key 不能为空"
        return Read-ApiKey
    }
    
    return $key.Trim()
}

function Select-Model {
    Write-Host ""
    Write-Host "请选择默认模型:" -ForegroundColor Yellow
    Write-Host ""
    
    # 显示模型列表
    for ($i = 0; $i -lt $script:Models.Count; $i++) {
        $model = $script:Models[$i]
        $num = $i + 1
        
        # 构建显示行
        $tag = if ($model.Tag) { " $($model.Tag)" } else { "       " }
        
        Write-Host "  $num. " -ForegroundColor Cyan -NoNewline
        Write-Host "$($model.Name)" -ForegroundColor White -NoNewline
        Write-Host "$tag " -ForegroundColor Green -NoNewline
        Write-Host "$($model.Description)" -ForegroundColor DarkGray
        Write-Host "     ($($model.ID))" -ForegroundColor DarkGray
    }
    
    Write-Host ""
    $choice = Read-Host "请输入数字 [1-$($script:Models.Count)]，默认 1"
    
    # 默认选择第一个
    if ([string]::IsNullOrWhiteSpace($choice)) {
        $choice = "1"
    }
    
    # 验证输入
    $index = 0
    if (-not [int]::TryParse($choice, [ref]$index) -or $index -lt 1 -or $index -gt $script:Models.Count) {
        Write-Warn "无效选择，使用默认模型"
        $index = 1
    }
    
    $selected = $script:Models[$index - 1]
    Write-Success "已选择: $($selected.Name)"
    
    return $selected
}

function Get-ModelMappings {
    param($SelectedModel)
    
    # 默认值
    $haikuModel = "claude-haiku-4-5-20251001"
    $sonnetModel = "claude-sonnet-4-20250514"
    $opusModel = "claude-opus-4-1-20250805"
    
    # 根据选择的模型调整
    switch ($SelectedModel.Family) {
        "sonnet" {
            if ($SelectedModel.ID -like "*4-5*") {
                $sonnetModel = "claude-sonnet-4-5-20250929"
            }
        }
        "opus" {
            if ($SelectedModel.ID -like "*4-5*") {
                $opusModel = "claude-opus-4-5-20251101"
            }
        }
    }
    
    return @{
        Haiku  = $haikuModel
        Sonnet = $sonnetModel
        Opus   = $opusModel
    }
}

function Write-SettingsFile {
    param(
        [string]$ApiKey,
        $Model
    )
    
    # 获取模型映射
    $mappings = Get-ModelMappings -SelectedModel $Model
    
    # 构建配置对象
    $settings = @{
        enabledPlugins = @{
            "commit-commands@claude-plugins-official"  = $true
            "context7@claude-plugins-official"         = $true
            "frontend-design@claude-plugins-official"  = $true
            "github@claude-plugins-official"           = $true
            "planning-with-files@planning-with-files"  = $true
            "superpowers@superpowers-marketplace"      = $true
        }
        env            = @{
            ANTHROPIC_AUTH_TOKEN                    = $ApiKey
            ANTHROPIC_BASE_URL                      = "https://maas-openapi.wanjiedata.com/api/anthropic"
            ANTHROPIC_DEFAULT_HAIKU_MODEL           = $mappings.Haiku
            ANTHROPIC_DEFAULT_OPUS_MODEL            = $mappings.Opus
            ANTHROPIC_DEFAULT_SONNET_MODEL          = $mappings.Sonnet
            ANTHROPIC_MODEL                         = $Model.ID
            API_TIMEOUT_MS                          = "3000000"
            CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = 1
        }
    }
    
    # 创建目录
    if (-not (Test-Path $script:ClaudeDir)) {
        New-Item -ItemType Directory -Path $script:ClaudeDir -Force | Out-Null
    }
    
    # 写入 JSON（格式化输出）
    $json = $settings | ConvertTo-Json -Depth 10
    Set-Content -Path $script:SettingsFile -Value $json -Encoding UTF8
    
    Write-Success "配置已保存: $script:SettingsFile"
}

# ============================================================================
# PATH 配置
# ============================================================================

function Add-NpmToPath {
    # 获取 npm 全局安装目录
    try {
        $npmPrefix = & npm config get prefix 2>$null
        if (-not $npmPrefix) {
            return
        }
        
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
        
        if ($currentPath -notlike "*$npmPrefix*") {
            Write-Info "添加 npm 全局目录到 PATH..."
            $newPath = "$currentPath;$npmPrefix"
            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            $env:Path = "$env:Path;$npmPrefix"
            Write-Success "PATH 已更新"
        }
    }
    catch {
        Write-Warn "无法更新 PATH: $_"
    }
}

# ============================================================================
# 安装完成
# ============================================================================

function Show-Completion {
    Write-Host ""
    Write-Host "+----------------------------------------------+" -ForegroundColor Green
    Write-Host "|  " -ForegroundColor Green -NoNewline
    Write-Host "Installation Complete!" -ForegroundColor White -NoNewline
    Write-Host "                      |" -ForegroundColor Green
    Write-Host "+----------------------------------------------+" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "开始使用:" -ForegroundColor Yellow
    Write-Host "  1. 打开新的终端窗口" -ForegroundColor White
    Write-Host "  2. 进入任意项目目录" -ForegroundColor White
    Write-Host "  3. 运行 " -ForegroundColor White -NoNewline
    Write-Host "claude" -ForegroundColor Cyan -NoNewline
    Write-Host " 启动" -ForegroundColor White
    Write-Host ""
    
    Write-Host "常用命令:" -ForegroundColor Yellow
    Write-Host "  claude              启动交互式对话" -ForegroundColor DarkGray
    Write-Host "  claude --help       查看帮助" -ForegroundColor DarkGray
    Write-Host "  claude --version    查看版本" -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host "重新配置:" -ForegroundColor Yellow
    Write-Host "  .\install.ps1 -Config" -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host "配置文件位置:" -ForegroundColor Yellow
    Write-Host "  $script:SettingsFile" -ForegroundColor DarkGray
    Write-Host ""
}

# ============================================================================
# 仅配置模式
# ============================================================================

function Invoke-ConfigOnly {
    Show-Banner
    Write-Info "配置模式"
    Write-Host ""
    
    # 检查 Claude Code 是否已安装
    if (-not (Test-ClaudeCode)) {
        Write-Err "Claude Code 尚未安装"
        Write-Host "请先运行完整安装: iwr -useb <url> | iex" -ForegroundColor Yellow
        exit 1
    }
    
    # 配置向导
    Write-Step -Step 1 -Total 2 -Message "输入 API Key"
    $apiKey = Read-ApiKey
    
    Write-Step -Step 2 -Total 2 -Message "选择模型"
    $model = Select-Model
    
    # 写入配置
    Write-SettingsFile -ApiKey $apiKey -Model $model
    
    Write-Host ""
    Write-Success "配置完成!"
    Write-Host ""
}

# ============================================================================
# 完整安装流程
# ============================================================================

function Invoke-FullInstall {
    Show-Banner
    
    $totalSteps = 5
    $currentStep = 0
    
    # Step 1: 检测网络环境
    $currentStep++
    Write-Step -Step $currentStep -Total $totalSteps -Message "检测网络环境"
    Test-MirrorNeed
    if ($script:MirrorMode) {
        Find-WorkingMirror | Out-Null
    }
    
    # Step 2: 检测/安装 Node.js
    $currentStep++
    Write-Step -Step $currentStep -Total $totalSteps -Message "检测 Node.js"
    
    if (-not (Test-NodeJS)) {
        if (-not (Install-NodeJS)) {
            exit 1
        }
        
        # 等待安装完成后再次检测
        Start-Sleep -Seconds 2
        Update-PathEnvironment
        
        if (-not (Test-NodeJS)) {
            Write-Err "Node.js 安装后仍无法检测到"
            Write-Host "请重新打开终端后再次运行此脚本" -ForegroundColor Yellow
            exit 1
        }
    }
    
    # 配置 npm 镜像
    Set-NpmRegistry
    
    # Step 3: 安装 Claude Code
    $currentStep++
    Write-Step -Step $currentStep -Total $totalSteps -Message "安装 Claude Code"
    
    if (-not (Test-ClaudeCode)) {
        if (-not (Install-ClaudeCodePackage)) {
            Write-Err "Claude Code 安装失败"
            exit 1
        }
    }
    else {
        Write-Info "跳过安装（已安装）"
    }
    
    # Step 4: 配置 API Key
    $currentStep++
    Write-Step -Step $currentStep -Total $totalSteps -Message "配置 API Key"
    $apiKey = Read-ApiKey
    
    # Step 5: 选择模型
    $currentStep++
    Write-Step -Step $currentStep -Total $totalSteps -Message "选择模型"
    $model = Select-Model
    
    # 写入配置
    Write-Info "正在保存配置..."
    Write-SettingsFile -ApiKey $apiKey -Model $model
    
    # 确保 PATH 正确
    Add-NpmToPath
    
    # 完成
    Show-Completion
}

# ============================================================================
# 主入口
# ============================================================================

function Main {
    # 检查管理员权限（仅警告，不强制）
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        # Write-Warn "建议以管理员身份运行以确保最佳兼容性"
    }
    
    # 处理参数
    if ($Help) {
        Show-Help
        exit 0
    }
    
    if ($Config) {
        Invoke-ConfigOnly
        exit 0
    }
    
    # 完整安装
    Invoke-FullInstall
}

# 运行
try {
    Main
}
finally {
    # 恢复控制台编码
    Restore-ConsoleEncoding
}
