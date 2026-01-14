// Package theme provides theming support for the TUI
package theme

import "github.com/charmbracelet/lipgloss"

// Theme defines the interface for TUI themes
type Theme interface {
	// Name returns the theme name
	Name() string

	// Primary colors
	Primary() lipgloss.AdaptiveColor
	Secondary() lipgloss.AdaptiveColor
	Accent() lipgloss.AdaptiveColor

	// Status colors
	Success() lipgloss.AdaptiveColor
	Error() lipgloss.AdaptiveColor
	Warning() lipgloss.AdaptiveColor
	Info() lipgloss.AdaptiveColor

	// Text colors
	Text() lipgloss.AdaptiveColor
	TextMuted() lipgloss.AdaptiveColor
	TextDim() lipgloss.AdaptiveColor

	// Background colors
	Background() lipgloss.AdaptiveColor
	BackgroundSecondary() lipgloss.AdaptiveColor
	BackgroundHighlight() lipgloss.AdaptiveColor

	// Border colors
	Border() lipgloss.AdaptiveColor
	BorderFocused() lipgloss.AdaptiveColor
	BorderDim() lipgloss.AdaptiveColor
}

// BaseTheme provides a base implementation with common defaults
type BaseTheme struct {
	name string

	primary   lipgloss.AdaptiveColor
	secondary lipgloss.AdaptiveColor
	accent    lipgloss.AdaptiveColor

	success lipgloss.AdaptiveColor
	err     lipgloss.AdaptiveColor
	warning lipgloss.AdaptiveColor
	info    lipgloss.AdaptiveColor

	text      lipgloss.AdaptiveColor
	textMuted lipgloss.AdaptiveColor
	textDim   lipgloss.AdaptiveColor

	background          lipgloss.AdaptiveColor
	backgroundSecondary lipgloss.AdaptiveColor
	backgroundHighlight lipgloss.AdaptiveColor

	border        lipgloss.AdaptiveColor
	borderFocused lipgloss.AdaptiveColor
	borderDim     lipgloss.AdaptiveColor
}

func (t *BaseTheme) Name() string                                { return t.name }
func (t *BaseTheme) Primary() lipgloss.AdaptiveColor             { return t.primary }
func (t *BaseTheme) Secondary() lipgloss.AdaptiveColor           { return t.secondary }
func (t *BaseTheme) Accent() lipgloss.AdaptiveColor              { return t.accent }
func (t *BaseTheme) Success() lipgloss.AdaptiveColor             { return t.success }
func (t *BaseTheme) Error() lipgloss.AdaptiveColor               { return t.err }
func (t *BaseTheme) Warning() lipgloss.AdaptiveColor             { return t.warning }
func (t *BaseTheme) Info() lipgloss.AdaptiveColor                { return t.info }
func (t *BaseTheme) Text() lipgloss.AdaptiveColor                { return t.text }
func (t *BaseTheme) TextMuted() lipgloss.AdaptiveColor           { return t.textMuted }
func (t *BaseTheme) TextDim() lipgloss.AdaptiveColor             { return t.textDim }
func (t *BaseTheme) Background() lipgloss.AdaptiveColor          { return t.background }
func (t *BaseTheme) BackgroundSecondary() lipgloss.AdaptiveColor { return t.backgroundSecondary }
func (t *BaseTheme) BackgroundHighlight() lipgloss.AdaptiveColor { return t.backgroundHighlight }
func (t *BaseTheme) Border() lipgloss.AdaptiveColor              { return t.border }
func (t *BaseTheme) BorderFocused() lipgloss.AdaptiveColor       { return t.borderFocused }
func (t *BaseTheme) BorderDim() lipgloss.AdaptiveColor           { return t.borderDim }
