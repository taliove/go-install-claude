package main

import (
	"fmt"
	"os"

	tea "github.com/charmbracelet/bubbletea"

	"github.com/anthropic/go-install-claude/internal/tui"
)

func main() {
	// 创建程序
	p := tea.NewProgram(
		tui.NewModel(),
		tea.WithAltScreen(),       // 使用备用屏幕
		tea.WithMouseCellMotion(), // 支持鼠标
	)

	// 运行程序
	if _, err := p.Run(); err != nil {
		fmt.Printf("程序运行出错: %v\n", err)
		os.Exit(1)
	}
}
