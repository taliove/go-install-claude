package theme

import "github.com/charmbracelet/lipgloss"

// NewOpenCodeTheme creates the OpenCode-inspired theme (default)
// This is a cyan/teal theme similar to the OpenCode CLI
func NewOpenCodeTheme() Theme {
	return &BaseTheme{
		name: "opencode",

		// Primary colors - cyan/teal theme
		primary:   lipgloss.AdaptiveColor{Dark: "#00D4AA", Light: "#00A080"},
		secondary: lipgloss.AdaptiveColor{Dark: "#00A8E8", Light: "#0080B8"},
		accent:    lipgloss.AdaptiveColor{Dark: "#00FFD4", Light: "#00D4AA"},

		// Status colors
		success: lipgloss.AdaptiveColor{Dark: "#00D26A", Light: "#00A050"},
		err:     lipgloss.AdaptiveColor{Dark: "#FF6B6B", Light: "#E05050"},
		warning: lipgloss.AdaptiveColor{Dark: "#FFD93D", Light: "#D4B030"},
		info:    lipgloss.AdaptiveColor{Dark: "#4ECDC4", Light: "#3ABDB4"},

		// Text colors
		text:      lipgloss.AdaptiveColor{Dark: "#E8E8E8", Light: "#1A1A1A"},
		textMuted: lipgloss.AdaptiveColor{Dark: "#888888", Light: "#666666"},
		textDim:   lipgloss.AdaptiveColor{Dark: "#555555", Light: "#999999"},

		// Background colors
		background:          lipgloss.AdaptiveColor{Dark: "#1A1B26", Light: "#FAFAFA"},
		backgroundSecondary: lipgloss.AdaptiveColor{Dark: "#24283B", Light: "#F0F0F0"},
		backgroundHighlight: lipgloss.AdaptiveColor{Dark: "#2F3549", Light: "#E8E8E8"},

		// Border colors
		border:        lipgloss.AdaptiveColor{Dark: "#3D4F5F", Light: "#CCCCCC"},
		borderFocused: lipgloss.AdaptiveColor{Dark: "#00D4AA", Light: "#00A080"},
		borderDim:     lipgloss.AdaptiveColor{Dark: "#2A2F3D", Light: "#DDDDDD"},
	}
}
