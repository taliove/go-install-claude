package theme

import "github.com/charmbracelet/lipgloss"

// NewTokyoNightTheme creates the Tokyo Night theme
// Popular dark theme with blue/purple accents
func NewTokyoNightTheme() Theme {
	return &BaseTheme{
		name: "tokyonight",

		// Primary colors - Tokyo Night palette
		primary:   lipgloss.AdaptiveColor{Dark: "#7AA2F7", Light: "#2E7DE9"},
		secondary: lipgloss.AdaptiveColor{Dark: "#BB9AF7", Light: "#9854F1"},
		accent:    lipgloss.AdaptiveColor{Dark: "#7DCFFF", Light: "#007197"},

		// Status colors
		success: lipgloss.AdaptiveColor{Dark: "#9ECE6A", Light: "#587539"},
		err:     lipgloss.AdaptiveColor{Dark: "#F7768E", Light: "#C64343"},
		warning: lipgloss.AdaptiveColor{Dark: "#E0AF68", Light: "#8C6C3E"},
		info:    lipgloss.AdaptiveColor{Dark: "#2AC3DE", Light: "#007197"},

		// Text colors
		text:      lipgloss.AdaptiveColor{Dark: "#C0CAF5", Light: "#3760BF"},
		textMuted: lipgloss.AdaptiveColor{Dark: "#9AA5CE", Light: "#6172B0"},
		textDim:   lipgloss.AdaptiveColor{Dark: "#565F89", Light: "#8990B3"},

		// Background colors
		background:          lipgloss.AdaptiveColor{Dark: "#1A1B26", Light: "#D5D6DB"},
		backgroundSecondary: lipgloss.AdaptiveColor{Dark: "#24283B", Light: "#CBCCD1"},
		backgroundHighlight: lipgloss.AdaptiveColor{Dark: "#414868", Light: "#B7B8BD"},

		// Border colors
		border:        lipgloss.AdaptiveColor{Dark: "#3B4261", Light: "#A1A6C5"},
		borderFocused: lipgloss.AdaptiveColor{Dark: "#7AA2F7", Light: "#2E7DE9"},
		borderDim:     lipgloss.AdaptiveColor{Dark: "#292E42", Light: "#C4C8DA"},
	}
}
