package styles

// Unicode icons for the TUI
const (
	// Status icons
	IconCheck   = "✓"
	IconCross   = "✗"
	IconError   = "✖"
	IconWarning = "⚠"
	IconInfo    = "ℹ"

	// Navigation icons
	IconArrow        = "→"
	IconArrowLeft    = "←"
	IconArrowUp      = "↑"
	IconArrowDown    = "↓"
	IconBullet       = "•"
	IconDot          = "●"
	IconCircle       = "○"
	IconBox          = "☐"
	IconBoxChecked   = "☑"
	IconBoxCrossed   = "☒"
	IconTriangle     = "▶"
	IconTriangleUp   = "▲"
	IconTriangleDown = "▼"

	// Spinner icons
	IconSpinner0 = "⠋"
	IconSpinner1 = "⠙"
	IconSpinner2 = "⠹"
	IconSpinner3 = "⠸"
	IconSpinner4 = "⠼"
	IconSpinner5 = "⠴"
	IconSpinner6 = "⠦"
	IconSpinner7 = "⠧"
	IconSpinner8 = "⠇"
	IconSpinner9 = "⠏"

	// Progress bar
	IconProgressFull  = "█"
	IconProgressHalf  = "▓"
	IconProgressEmpty = "░"
	IconProgressLight = "▒"

	// Feature icons
	IconKey       = "🔑"
	IconLock      = "🔒"
	IconUnlock    = "🔓"
	IconPackage   = "📦"
	IconFolder    = "📁"
	IconFile      = "📄"
	IconRocket    = "🚀"
	IconGear      = "⚙"
	IconWrench    = "🔧"
	IconCloud     = "☁"
	IconDownload  = "⬇"
	IconUpload    = "⬆"
	IconRefresh   = "🔄"
	IconStar      = "★"
	IconStarEmpty = "☆"
	IconHeart     = "♥"
	IconLightning = "⚡"
	IconFire      = "🔥"
	IconShield    = "🛡"
	IconFlag      = "🚩"
	IconPin       = "📌"
	IconLink      = "🔗"
	IconSearch    = "🔍"
	IconEye       = "👁"
	IconEyeClosed = "👁‍🗨"
	IconTerminal  = "💻"
	IconServer    = "🖥"
	IconGlobe     = "🌐"
	IconClock     = "🕐"
	IconTimer     = "⏱"
	IconBell      = "🔔"
	IconMuted     = "🔕"

	// Emoji-free alternatives (for better terminal compatibility)
	AltKey      = "󰌋"
	AltPackage  = "󰏗"
	AltRocket   = "󱓞"
	AltCloud    = "󰅟"
	AltGear     = "󰒓"
	AltCheck    = "󰄬"
	AltCross    = "󰅖"
	AltInfo     = "󰋽"
	AltWarning  = "󰀦"
	AltTerminal = "󰆍"
)

// SpinnerFrames returns the spinner animation frames
func SpinnerFrames() []string {
	return []string{
		IconSpinner0,
		IconSpinner1,
		IconSpinner2,
		IconSpinner3,
		IconSpinner4,
		IconSpinner5,
		IconSpinner6,
		IconSpinner7,
		IconSpinner8,
		IconSpinner9,
	}
}

// ProgressBar creates a progress bar string
func RenderProgressBar(percent float64, width int) string {
	if width <= 0 {
		width = 20
	}
	if percent < 0 {
		percent = 0
	}
	if percent > 100 {
		percent = 100
	}

	filled := int(float64(width) * percent / 100)
	empty := width - filled

	bar := ""
	for i := 0; i < filled; i++ {
		bar += IconProgressFull
	}
	for i := 0; i < empty; i++ {
		bar += IconProgressEmpty
	}

	return bar
}
