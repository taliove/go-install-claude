package theme

import "sync"

var (
	themes       = make(map[string]Theme)
	currentTheme Theme
	mu           sync.RWMutex
)

func init() {
	// Register default themes
	RegisterTheme("opencode", NewOpenCodeTheme())
	RegisterTheme("catppuccin", NewCatppuccinTheme())
	RegisterTheme("tokyonight", NewTokyoNightTheme())

	// Set default theme
	SetTheme("opencode")
}

// RegisterTheme registers a theme by name
func RegisterTheme(name string, t Theme) {
	mu.Lock()
	defer mu.Unlock()
	themes[name] = t
}

// SetTheme sets the current theme by name
func SetTheme(name string) bool {
	mu.Lock()
	defer mu.Unlock()
	if t, ok := themes[name]; ok {
		currentTheme = t
		return true
	}
	return false
}

// Current returns the current theme
func Current() Theme {
	mu.RLock()
	defer mu.RUnlock()
	return currentTheme
}

// Available returns all available theme names
func Available() []string {
	mu.RLock()
	defer mu.RUnlock()
	names := make([]string, 0, len(themes))
	for name := range themes {
		names = append(names, name)
	}
	return names
}
