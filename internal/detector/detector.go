package detector

import (
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"time"
)

// SystemInfo 系统信息
type SystemInfo struct {
	OS            string // windows, linux, darwin
	HomeDir       string // 用户家目录
	ClaudeDir     string // ~/.claude 目录
	HasNodeJS     bool   // 是否安装了 Node.js
	NodeVersion   string // Node.js 版本
	HasNPM        bool   // 是否有 npm
	NPMVersion    string // npm 版本
	HasClaude     bool   // 是否已安装 Claude Code
	ClaudeVersion string // Claude Code 版本
	CanReachAPI   bool   // 是否能连接万界 API
}

// Detect 检测系统环境
func Detect() (*SystemInfo, error) {
	info := &SystemInfo{
		OS: runtime.GOOS,
	}

	// 获取家目录
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return nil, err
	}
	info.HomeDir = homeDir
	info.ClaudeDir = filepath.Join(homeDir, ".claude")

	// 检测 Node.js
	info.detectNodeJS()

	// 检测 npm
	info.detectNPM()

	// 检测 Claude Code
	info.detectClaude()

	// 检测网络连通性
	info.detectNetwork()

	return info, nil
}

func (info *SystemInfo) detectNodeJS() {
	cmd := exec.Command("node", "--version")
	output, err := cmd.Output()
	if err == nil {
		info.HasNodeJS = true
		info.NodeVersion = strings.TrimSpace(string(output))
	}
}

func (info *SystemInfo) detectNPM() {
	cmd := exec.Command("npm", "--version")
	output, err := cmd.Output()
	if err == nil {
		info.HasNPM = true
		info.NPMVersion = strings.TrimSpace(string(output))
	}
}

func (info *SystemInfo) detectClaude() {
	cmd := exec.Command("claude", "--version")
	output, err := cmd.Output()
	if err == nil {
		info.HasClaude = true
		info.ClaudeVersion = strings.TrimSpace(string(output))
	}
}

func (info *SystemInfo) detectNetwork() {
	client := &http.Client{
		Timeout: 10 * time.Second,
	}

	// 测试万界 API 地址
	resp, err := client.Head("https://maas-openapi.wanjiedata.com")
	if err == nil {
		resp.Body.Close()
		info.CanReachAPI = resp.StatusCode < 500
	}
}

// GetOSName 获取友好的操作系统名称
func (info *SystemInfo) GetOSName() string {
	switch info.OS {
	case "windows":
		return "Windows"
	case "darwin":
		return "macOS"
	case "linux":
		return "Linux"
	default:
		return info.OS
	}
}

// NeedsNodeJS 检查是否需要安装 Node.js
func (info *SystemInfo) NeedsNodeJS() bool {
	return !info.HasNodeJS || !info.HasNPM
}

// GetSettingsPath 获取 settings.json 路径
func (info *SystemInfo) GetSettingsPath() string {
	return filepath.Join(info.ClaudeDir, "settings.json")
}
