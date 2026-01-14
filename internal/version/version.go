package version

// 版本信息 - 通过 ldflags 在编译时注入
var (
	Version   = "dev"
	GitCommit = "unknown"
	BuildTime = "unknown"
)

// GetVersion 获取完整版本信息
func GetVersion() string {
	return Version
}

// GetFullVersion 获取详细版本信息
func GetFullVersion() string {
	return Version + " (" + GitCommit + ") built at " + BuildTime
}
