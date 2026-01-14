# Claude Code 一键安装工具

## 构建命令

# 构建所有平台
build-all: build-windows build-linux build-darwin

# Windows 64位
build-windows:
	$env:GOOS="windows"; $env:GOARCH="amd64"; go build -ldflags="-s -w" -o dist/claude-installer-windows-amd64.exe ./cmd/installer

# Linux 64位
build-linux:
	$env:GOOS="linux"; $env:GOARCH="amd64"; go build -ldflags="-s -w" -o dist/claude-installer-linux-amd64 ./cmd/installer

# macOS Intel
build-darwin-amd64:
	$env:GOOS="darwin"; $env:GOARCH="amd64"; go build -ldflags="-s -w" -o dist/claude-installer-darwin-amd64 ./cmd/installer

# macOS Apple Silicon
build-darwin-arm64:
	$env:GOOS="darwin"; $env:GOARCH="arm64"; go build -ldflags="-s -w" -o dist/claude-installer-darwin-arm64 ./cmd/installer

# macOS 通用二进制
build-darwin: build-darwin-amd64 build-darwin-arm64

# 清理
clean:
	rm -rf dist/

# 运行开发版本
run:
	go run ./cmd/installer

.PHONY: build-all build-windows build-linux build-darwin build-darwin-amd64 build-darwin-arm64 clean run
