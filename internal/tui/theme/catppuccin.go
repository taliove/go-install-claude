package theme

import "github.com/charmbracelet/lipgloss"

// NewCatppuccinTheme creates the Catppuccin Mocha theme
// Popular pastel color scheme
func NewCatppuccinTheme() Theme {
	return &BaseTheme{
		name: "catppuccin",

		// Primary colors - Catppuccin Mocha palette
		primary:   lipgloss.AdaptiveColor{Dark: "#89B4FA", Light: "#1E66F5"}, // Blue
		secondary: lipgloss.AdaptiveColor{Dark: "#CBA6F7", Light: "#8839EF"}, // Mauve
		accent:    lipgloss.AdaptiveColor{Dark: "#94E2D5", Light: "#179299"}, // Teal

		// Status colors
		success: lipgloss.AdaptiveColor{Dark: "#A6E3A1", Light: "#40A02B"}, // Green
		err:     lipgloss.AdaptiveColor{Dark: "#F38BA8", Light: "#D20F39"}, // Red
		warning: lipgloss.AdaptiveColor{Dark: "#F9E2AF", Light: "#DF8E1D"}, // Yellow
		info:    lipgloss.AdaptiveColor{Dark: "#89DCEB", Light: "#209FB5"}, // Sky

		// Text colors
		text:      lipgloss.AdaptiveColor{Dark: "#CDD6F4", Light: "#4C4F69"},
		textMuted: lipgloss.AdaptiveColor{Dark: "#A6ADC8", Light: "#6C6F85"},
		textDim:   lipgloss.AdaptiveColor{Dark: "#6C7086", Light: "#9CA0B0"},

		// Background colors
		background:          lipgloss.AdaptiveColor{Dark: "#1E1E2E", Light: "#EFF1F5"},
		backgroundSecondary: lipgloss.AdaptiveColor{Dark: "#313244", Light: "#E6E9EF"},
		backgroundHighlight: lipgloss.AdaptiveColor{Dark: "#45475A", Light: "#DCE0E8"},

		// Border colors
		border:        lipgloss.AdaptiveColor{Dark: "#45475A", Light: "#BCC0CC"},
		borderFocused: lipgloss.AdaptiveColor{Dark: "#89B4FA", Light: "#1E66F5"},
		borderDim:     lipgloss.AdaptiveColor{Dark: "#313244", Light: "#CCD0DA"},
	}
}
