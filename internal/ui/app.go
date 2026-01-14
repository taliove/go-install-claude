package ui

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/bubbles/spinner"
	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"github.com/anthropic/go-install-claude/internal/config"
	"github.com/anthropic/go-install-claude/internal/detector"
	"github.com/anthropic/go-install-claude/internal/installer"
)

// 安装阶段
type Stage int

const (
	StageWelcome Stage = iota
	StageDetecting
	StageInputKey
	StageSelectModel
	StageConfirm
	StageInstalling
	StageComplete
	StageError
)

// Model TUI 主模型
type Model struct {
	stage  Stage
	width  int
	height int

	// 组件
	keyInput textinput.Model
	spinner  spinner.Model

	// 数据
	systemInfo  *detector.SystemInfo
	installCfg  *config.InstallConfig
	selectedIdx int

	// 安装状态
	installResult *installer.Result
	errorMessage  string

	// 检测状态
	detecting  bool
	detectDone bool
}

// 消息类型
type detectDoneMsg struct {
	info *detector.SystemInfo
	err  error
}

type installDoneMsg struct {
	result *installer.Result
}

type configWriteDoneMsg struct {
	err error
}

// NewModel 创建新模型
func NewModel() Model {
	// 初始化文本输入
	ti := textinput.New()
	ti.Placeholder = "请输入您的万界 API Key"
	ti.Focus()
	ti.CharLimit = 128
	ti.Width = InputWidth
	ti.EchoMode = textinput.EchoPassword
	ti.EchoCharacter = '•'

	// 初始化 spinner
	sp := spinner.New()
	sp.Spinner = spinner.Dot
	sp.Style = lipgloss.NewStyle().Foreground(PrimaryColor)

	return Model{
		stage:      StageWelcome,
		keyInput:   ti,
		spinner:    sp,
		installCfg: config.NewDefaultConfig(),
	}
}

// Init 初始化
func (m Model) Init() tea.Cmd {
	return tea.Batch(
		textinput.Blink,
		m.spinner.Tick,
	)
}

// Update 更新
func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmds []tea.Cmd

	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "q":
			if m.stage != StageInstalling {
				return m, tea.Quit
			}
		case "enter":
			return m.handleEnter()
		case "up", "k":
			if m.stage == StageSelectModel && m.selectedIdx > 0 {
				m.selectedIdx--
			}
		case "down", "j":
			if m.stage == StageSelectModel && m.selectedIdx < len(config.SupportedModels)-1 {
				m.selectedIdx++
			}
		case "esc":
			if m.stage == StageError {
				m.stage = StageWelcome
				m.errorMessage = ""
			}
		}

	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height

	case detectDoneMsg:
		m.detecting = false
		m.detectDone = true
		if msg.err != nil {
			m.errorMessage = msg.err.Error()
			m.stage = StageError
		} else {
			m.systemInfo = msg.info
			if msg.info.NeedsNodeJS() {
				m.errorMessage = "未检测到 Node.js 或 npm，请先安装 Node.js 18+\n\n下载地址: https://nodejs.org/"
				m.stage = StageError
			} else {
				m.stage = StageInputKey
			}
		}

	case installDoneMsg:
		if msg.result.Success {
			m.installResult = msg.result
			m.stage = StageComplete
		} else {
			m.errorMessage = fmt.Sprintf("安装失败:\n%s\n\n详细日志:\n%s", msg.result.Message, msg.result.Error)
			m.stage = StageError
		}

	case configWriteDoneMsg:
		if msg.err != nil {
			m.errorMessage = fmt.Sprintf("配置写入失败: %s", msg.err.Error())
			m.stage = StageError
		} else {
			// 配置写入成功，开始安装
			return m, m.doInstall()
		}

	case spinner.TickMsg:
		var cmd tea.Cmd
		m.spinner, cmd = m.spinner.Update(msg)
		cmds = append(cmds, cmd)
	}

	// 更新文本输入
	if m.stage == StageInputKey {
		var cmd tea.Cmd
		m.keyInput, cmd = m.keyInput.Update(msg)
		cmds = append(cmds, cmd)
	}

	return m, tea.Batch(cmds...)
}

// handleEnter 处理回车键
func (m Model) handleEnter() (tea.Model, tea.Cmd) {
	switch m.stage {
	case StageWelcome:
		m.stage = StageDetecting
		m.detecting = true
		return m, m.doDetect()

	case StageInputKey:
		key := strings.TrimSpace(m.keyInput.Value())
		if !config.ValidateAPIKey(key) {
			m.errorMessage = "API Key 格式不正确，请检查后重试"
			return m, nil
		}
		m.installCfg.APIKey = key
		m.stage = StageSelectModel
		// 找到默认选中的模型索引
		for i, model := range config.SupportedModels {
			if model.Default {
				m.selectedIdx = i
				break
			}
		}
		return m, nil

	case StageSelectModel:
		m.installCfg.Model = config.SupportedModels[m.selectedIdx].ID
		m.stage = StageConfirm
		return m, nil

	case StageConfirm:
		m.stage = StageInstalling
		return m, m.doWriteConfig()

	case StageComplete:
		return m, tea.Quit

	case StageError:
		return m, tea.Quit
	}

	return m, nil
}

// doDetect 执行环境检测
func (m Model) doDetect() tea.Cmd {
	return func() tea.Msg {
		info, err := detector.Detect()
		return detectDoneMsg{info: info, err: err}
	}
}

// doWriteConfig 写入配置
func (m Model) doWriteConfig() tea.Cmd {
	return func() tea.Msg {
		err := m.installCfg.WriteSettings(m.systemInfo.ClaudeDir)
		return configWriteDoneMsg{err: err}
	}
}

// doInstall 执行安装
func (m Model) doInstall() tea.Cmd {
	return func() tea.Msg {
		inst := installer.NewInstaller()
		result := inst.Install()
		return installDoneMsg{result: result}
	}
}

// View 渲染视图
func (m Model) View() string {
	var content string

	switch m.stage {
	case StageWelcome:
		content = m.viewWelcome()
	case StageDetecting:
		content = m.viewDetecting()
	case StageInputKey:
		content = m.viewInputKey()
	case StageSelectModel:
		content = m.viewSelectModel()
	case StageConfirm:
		content = m.viewConfirm()
	case StageInstalling:
		content = m.viewInstalling()
	case StageComplete:
		content = m.viewComplete()
	case StageError:
		content = m.viewError()
	}

	// 外框 - 使用固定宽度确保边框完整
	boxStyle := lipgloss.NewStyle().
		BorderStyle(lipgloss.NormalBorder()).
		BorderForeground(BorderColor).
		Padding(1, 2).
		Width(BoxWidth)

	return lipgloss.Place(
		m.width,
		m.height,
		lipgloss.Center,
		lipgloss.Center,
		boxStyle.Render(content),
	)
}

// 欢迎页面
func (m Model) viewWelcome() string {
	var b strings.Builder

	b.WriteString(RenderLogo())
	b.WriteString("\n\n")
	b.WriteString(NormalStyle.Render("欢迎使用 Claude Code 一键安装工具！"))
	b.WriteString("\n\n")
	b.WriteString(InfoStyle.Render("本工具将帮助您："))
	b.WriteString("\n")
	b.WriteString(DimStyle.Render(fmt.Sprintf("  %s 自动配置万界数据代理", IconBullet)))
	b.WriteString("\n")
	b.WriteString(DimStyle.Render(fmt.Sprintf("  %s 安装 Claude Code CLI", IconBullet)))
	b.WriteString("\n")
	b.WriteString(DimStyle.Render(fmt.Sprintf("  %s 配置 API Key 和模型", IconBullet)))
	b.WriteString("\n\n")
	b.WriteString(HelpStyle.Render("按 Enter 开始安装 • 按 q 退出"))

	return b.String()
}

// 检测中页面
func (m Model) viewDetecting() string {
	var b strings.Builder

	b.WriteString(TitleStyle.Render(fmt.Sprintf("%s 环境检测", IconGear)))
	b.WriteString("\n\n")
	b.WriteString(fmt.Sprintf("%s 正在检测系统环境...", m.spinner.View()))
	b.WriteString("\n\n")
	b.WriteString(DimStyle.Render("检查 Node.js、npm、网络连接..."))

	return b.String()
}

// 输入 Key 页面
func (m Model) viewInputKey() string {
	var b strings.Builder

	b.WriteString(m.renderSteps(1))
	b.WriteString("\n\n")
	b.WriteString(TitleStyle.Render(fmt.Sprintf("%s 输入 API Key", IconKey)))
	b.WriteString("\n\n")

	// 系统信息
	if m.systemInfo != nil {
		b.WriteString(SuccessStyle.Render(fmt.Sprintf("%s 系统: %s", IconCheck, m.systemInfo.GetOSName())))
		b.WriteString("\n")
		b.WriteString(SuccessStyle.Render(fmt.Sprintf("%s Node.js: %s", IconCheck, m.systemInfo.NodeVersion)))
		b.WriteString("\n")
		b.WriteString(SuccessStyle.Render(fmt.Sprintf("%s npm: %s", IconCheck, m.systemInfo.NPMVersion)))
		b.WriteString("\n\n")
	}

	b.WriteString(NormalStyle.Render("请输入您的万界数据 API Key："))
	b.WriteString("\n\n")
	b.WriteString(InputFocusedStyle.Render(m.keyInput.View()))
	b.WriteString("\n\n")

	if m.errorMessage != "" {
		b.WriteString(ErrorStyle.Render(fmt.Sprintf("%s %s", IconError, m.errorMessage)))
		b.WriteString("\n\n")
		m.errorMessage = ""
	}

	b.WriteString(HelpStyle.Render("获取 Key: https://www.wanjiedata.com"))
	b.WriteString("\n")
	b.WriteString(HelpStyle.Render("按 Enter 继续 • 按 q 退出"))

	return b.String()
}

// 选择模型页面
func (m Model) viewSelectModel() string {
	var b strings.Builder

	b.WriteString(m.renderSteps(2))
	b.WriteString("\n\n")
	b.WriteString(TitleStyle.Render(fmt.Sprintf("%s 选择模型", IconRocket)))
	b.WriteString("\n\n")
	b.WriteString(NormalStyle.Render("请选择默认使用的 Claude 模型："))
	b.WriteString("\n\n")

	for i, model := range config.SupportedModels {
		cursor := "  "
		style := ListItemStyle
		if i == m.selectedIdx {
			cursor = IconArrow + " "
			style = ListItemSelectedStyle
		}

		line := fmt.Sprintf("%s%s", cursor, model.Name)
		if model.Default {
			line += " (推荐)"
		}
		b.WriteString(style.Render(line))
		b.WriteString("\n")
		b.WriteString(DimStyle.Render(fmt.Sprintf("     %s", model.Description)))
		b.WriteString("\n")
	}

	b.WriteString("\n")
	b.WriteString(HelpStyle.Render("↑/↓ 选择 • Enter 确认 • q 退出"))

	return b.String()
}

// 确认页面
func (m Model) viewConfirm() string {
	var b strings.Builder

	b.WriteString(m.renderSteps(3))
	b.WriteString("\n\n")
	b.WriteString(TitleStyle.Render(fmt.Sprintf("%s 确认配置", IconPackage)))
	b.WriteString("\n\n")

	// 配置摘要卡片
	cardContent := fmt.Sprintf(`代理服务: %s
API 地址: %s
默认模型: %s
API Key:  %s`,
		config.WanjieName,
		m.installCfg.BaseURL,
		m.installCfg.Model,
		maskKey(m.installCfg.APIKey),
	)

	b.WriteString(CardStyle.Render(cardContent))
	b.WriteString("\n\n")
	b.WriteString(NormalStyle.Render("配置将写入: "))
	b.WriteString(HighlightStyle.Render(m.systemInfo.GetSettingsPath()))
	b.WriteString("\n\n")
	b.WriteString(HelpStyle.Render("按 Enter 开始安装 • 按 q 退出"))

	return b.String()
}

// 安装中页面
func (m Model) viewInstalling() string {
	var b strings.Builder

	b.WriteString(m.renderSteps(4))
	b.WriteString("\n\n")
	b.WriteString(TitleStyle.Render(fmt.Sprintf("%s 正在安装", IconRocket)))
	b.WriteString("\n\n")
	b.WriteString(fmt.Sprintf("%s 配置 NPM 镜像...", m.spinner.View()))
	b.WriteString("\n")
	b.WriteString(fmt.Sprintf("%s 安装 @anthropic-ai/claude-code...", m.spinner.View()))
	b.WriteString("\n\n")
	b.WriteString(DimStyle.Render("请稍候，这可能需要几分钟..."))
	b.WriteString("\n")
	b.WriteString(WarningStyle.Render("请勿关闭此窗口"))

	return b.String()
}

// 完成页面
func (m Model) viewComplete() string {
	var b strings.Builder

	b.WriteString(m.renderSteps(5))
	b.WriteString("\n\n")
	b.WriteString(SuccessStyle.Render(fmt.Sprintf("%s 安装完成！", IconSuccess)))
	b.WriteString("\n\n")

	successCard := fmt.Sprintf(`Claude Code 已成功安装并配置！

现在您可以在终端中运行:
  $ claude

开始使用 Claude Code 进行 AI 编程！`)

	b.WriteString(CardStyle.Render(successCard))
	b.WriteString("\n\n")
	b.WriteString(HelpStyle.Render("按 Enter 或 q 退出"))

	return b.String()
}

// 错误页面
func (m Model) viewError() string {
	var b strings.Builder

	b.WriteString(ErrorStyle.Render(fmt.Sprintf("%s 出错了", IconError)))
	b.WriteString("\n\n")

	errorCard := CardStyle.Copy().BorderForeground(ErrorColor)
	b.WriteString(errorCard.Render(m.errorMessage))
	b.WriteString("\n\n")
	b.WriteString(HelpStyle.Render("按 Esc 返回 • 按 q 退出"))

	return b.String()
}

// 渲染步骤指示器
func (m Model) renderSteps(current int) string {
	steps := []string{"检测", "密钥", "模型", "确认", "完成"}
	var parts []string

	for i, step := range steps {
		idx := i + 1
		var style lipgloss.Style
		var icon string

		if idx < current {
			style = StepDoneStyle
			icon = IconCheck
		} else if idx == current {
			style = StepCurrentStyle
			icon = IconArrow
		} else {
			style = StepPendingStyle
			icon = IconBox
		}

		parts = append(parts, style.Render(fmt.Sprintf("%s %s", icon, step)))
	}

	return strings.Join(parts, DimStyle.Render(" → "))
}

// 遮蔽 Key 显示
func maskKey(key string) string {
	if len(key) <= 8 {
		return "****"
	}
	return key[:4] + "..." + key[len(key)-4:]
}
