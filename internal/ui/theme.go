package ui

import "github.com/charmbracelet/lipgloss"

// 布局常量
const (
	ContentWidth = 60 // 内容区域宽度
	BoxWidth     = 66 // 外框宽度 (ContentWidth + padding)
	InputWidth   = 52 // 输入框宽度
)

// 蓝绿色主题配色
var (
	// 主色调
	PrimaryColor   = lipgloss.Color("#00D4AA") // 青绿色
	SecondaryColor = lipgloss.Color("#00A8E8") // 天蓝色
	AccentColor    = lipgloss.Color("#00FFD4") // 亮青色

	// 状态色
	SuccessColor = lipgloss.Color("#00D26A") // 绿色
	ErrorColor   = lipgloss.Color("#FF6B6B") // 红色
	WarningColor = lipgloss.Color("#FFD93D") // 黄色
	InfoColor    = lipgloss.Color("#4ECDC4") // 信息蓝

	// 文本色
	TextColor      = lipgloss.Color("#E8E8E8") // 主文本
	TextMutedColor = lipgloss.Color("#888888") // 次要文本
	TextDimColor   = lipgloss.Color("#555555") // 暗淡文本

	// 背景色
	BackgroundColor     = lipgloss.Color("#1A1B26") // 深色背景
	BackgroundAltColor  = lipgloss.Color("#24283B") // 次级背景
	BackgroundHighlight = lipgloss.Color("#2F3549") // 高亮背景

	// 边框色
	BorderColor      = lipgloss.Color("#3D4F5F") // 默认边框
	BorderFocusColor = lipgloss.Color("#00D4AA") // 聚焦边框
	BorderDimColor   = lipgloss.Color("#2A2F3D") // 暗淡边框
)

// 样式定义
var (
	// 标题样式
	TitleStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(PrimaryColor).
			MarginBottom(1)

	// 大标题
	BigTitleStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(AccentColor).
			Background(BackgroundAltColor).
			Padding(1, 3).
			MarginBottom(1)

	// 副标题
	SubtitleStyle = lipgloss.NewStyle().
			Foreground(TextMutedColor).
			MarginBottom(1)

	// 正常文本
	NormalStyle = lipgloss.NewStyle().
			Foreground(TextColor)

	// 成功文本
	SuccessStyle = lipgloss.NewStyle().
			Foreground(SuccessColor).
			Bold(true)

	// 错误文本
	ErrorStyle = lipgloss.NewStyle().
			Foreground(ErrorColor).
			Bold(true)

	// 警告文本
	WarningStyle = lipgloss.NewStyle().
			Foreground(WarningColor)

	// 信息文本
	InfoStyle = lipgloss.NewStyle().
			Foreground(InfoColor)

	// 暗淡文本
	DimStyle = lipgloss.NewStyle().
			Foreground(TextDimColor)

	// 高亮文本
	HighlightStyle = lipgloss.NewStyle().
			Foreground(AccentColor).
			Bold(true)

	// 输入框样式
	InputStyle = lipgloss.NewStyle().
			BorderStyle(lipgloss.RoundedBorder()).
			BorderForeground(BorderColor).
			Padding(0, 1)

	// 聚焦输入框
	InputFocusedStyle = lipgloss.NewStyle().
				BorderStyle(lipgloss.RoundedBorder()).
				BorderForeground(BorderFocusColor).
				Padding(0, 1)

	// 按钮样式
	ButtonStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#FFFFFF")).
			Background(PrimaryColor).
			Padding(0, 3).
			MarginRight(1)

	// 禁用按钮
	ButtonDisabledStyle = lipgloss.NewStyle().
				Foreground(TextDimColor).
				Background(BackgroundAltColor).
				Padding(0, 3).
				MarginRight(1)

	// 选中项
	SelectedStyle = lipgloss.NewStyle().
			Foreground(AccentColor).
			Bold(true)

	// 列表项
	ListItemStyle = lipgloss.NewStyle().
			PaddingLeft(2)

	// 选中的列表项
	ListItemSelectedStyle = lipgloss.NewStyle().
				Foreground(AccentColor).
				Bold(true).
				PaddingLeft(2)

	// 容器/卡片样式
	CardStyle = lipgloss.NewStyle().
			BorderStyle(lipgloss.RoundedBorder()).
			BorderForeground(BorderColor).
			Padding(1, 2).
			MarginBottom(1)

	// 聚焦卡片
	CardFocusedStyle = lipgloss.NewStyle().
				BorderStyle(lipgloss.RoundedBorder()).
				BorderForeground(BorderFocusColor).
				Padding(1, 2).
				MarginBottom(1)

	// 状态栏
	StatusBarStyle = lipgloss.NewStyle().
			Background(BackgroundAltColor).
			Foreground(TextMutedColor).
			Padding(0, 1)

	// 帮助文本
	HelpStyle = lipgloss.NewStyle().
			Foreground(TextDimColor).
			MarginTop(1)

	// 进度条容器
	ProgressStyle = lipgloss.NewStyle().
			Foreground(PrimaryColor)

	// Logo 样式
	LogoStyle = lipgloss.NewStyle().
			Foreground(PrimaryColor).
			Bold(true)

	// 步骤指示器 - 已完成
	StepDoneStyle = lipgloss.NewStyle().
			Foreground(SuccessColor)

	// 步骤指示器 - 当前
	StepCurrentStyle = lipgloss.NewStyle().
				Foreground(AccentColor).
				Bold(true)

	// 步骤指示器 - 待完成
	StepPendingStyle = lipgloss.NewStyle().
				Foreground(TextDimColor)
)

// 图标定义
const (
	IconCheck    = "✓"
	IconCross    = "✗"
	IconArrow    = "→"
	IconBullet   = "•"
	IconStar     = "★"
	IconSpinner  = "◐"
	IconBox      = "□"
	IconBoxCheck = "☑"
	IconKey      = "🔑"
	IconRocket   = "🚀"
	IconPackage  = "📦"
	IconGear     = "⚙️"
	IconInfo     = "ℹ️"
	IconWarn     = "⚠️"
	IconError    = "❌"
	IconSuccess  = "✅"
)

// ASCII Logo
const Logo = `
   _____ _                 _        _____          _      
  / ____| |               | |      / ____|        | |     
 | |    | | __ _ _   _  __| | ___ | |     ___   __| | ___ 
 | |    | |/ _` + "`" + ` | | | |/ _` + "`" + ` |/ _ \| |    / _ \ / _` + "`" + ` |/ _ \
 | |____| | (_| | |_| | (_| |  __/| |___| (_) | (_| |  __/
  \_____|_|\__,_|\__,_|\__,_|\___| \_____\___/ \__,_|\___|
                                                          
        ⚡ 万界数据一键安装工具 ⚡
`

// 渲染 Logo
func RenderLogo() string {
	return LogoStyle.Render(Logo)
}
