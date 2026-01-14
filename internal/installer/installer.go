package installer

import (
	"bytes"
	"fmt"
	"os/exec"
	"runtime"
	"strings"
)

// Result 安装结果
type Result struct {
	Success bool
	Message string
	Output  string
	Error   string
}

// Installer 安装器
type Installer struct {
	UseNPMMirror bool // 是否使用国内 NPM 镜像
}

// NewInstaller 创建安装器
func NewInstaller() *Installer {
	return &Installer{
		UseNPMMirror: true,
	}
}

// Install 执行安装
func (i *Installer) Install() *Result {
	// 先配置 NPM 镜像
	if i.UseNPMMirror {
		if result := i.configureNPMMirror(); !result.Success {
			// 镜像配置失败不是致命错误，继续安装
			fmt.Println("NPM 镜像配置失败，尝试继续安装...")
		}
	}

	// 执行 npm install
	return i.npmInstall()
}

// configureNPMMirror 配置 NPM 淘宝镜像
func (i *Installer) configureNPMMirror() *Result {
	cmd := exec.Command("npm", "config", "set", "registry", "https://registry.npmmirror.com")
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	err := cmd.Run()
	if err != nil {
		return &Result{
			Success: false,
			Message: "NPM 镜像配置失败",
			Output:  stdout.String(),
			Error:   stderr.String(),
		}
	}

	return &Result{
		Success: true,
		Message: "NPM 镜像配置成功",
		Output:  stdout.String(),
	}
}

// npmInstall 使用 npm 安装 Claude Code
func (i *Installer) npmInstall() *Result {
	var cmd *exec.Cmd

	// 根据操作系统选择命令
	if runtime.GOOS == "windows" {
		cmd = exec.Command("cmd", "/C", "npm", "install", "-g", "@anthropic-ai/claude-code")
	} else {
		cmd = exec.Command("npm", "install", "-g", "@anthropic-ai/claude-code")
	}

	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	err := cmd.Run()
	if err != nil {
		return &Result{
			Success: false,
			Message: "Claude Code 安装失败",
			Output:  stdout.String(),
			Error:   fmt.Sprintf("%s\n%s", err.Error(), stderr.String()),
		}
	}

	return &Result{
		Success: true,
		Message: "Claude Code 安装成功",
		Output:  stdout.String(),
	}
}

// Verify 验证安装
func (i *Installer) Verify() *Result {
	cmd := exec.Command("claude", "--version")
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	err := cmd.Run()
	if err != nil {
		return &Result{
			Success: false,
			Message: "Claude Code 验证失败",
			Output:  stdout.String(),
			Error:   stderr.String(),
		}
	}

	version := strings.TrimSpace(stdout.String())
	return &Result{
		Success: true,
		Message: fmt.Sprintf("Claude Code %s 已安装", version),
		Output:  version,
	}
}

// RunDoctor 运行 claude doctor 检查
func (i *Installer) RunDoctor() *Result {
	cmd := exec.Command("claude", "doctor")
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	err := cmd.Run()
	if err != nil {
		return &Result{
			Success: false,
			Message: "健康检查未通过",
			Output:  stdout.String(),
			Error:   stderr.String(),
		}
	}

	return &Result{
		Success: true,
		Message: "健康检查通过",
		Output:  stdout.String(),
	}
}
