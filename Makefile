# FlowSpec CLI Makefile

.PHONY: build test clean install lint fmt vet coverage help release

# 变量定义
BINARY_NAME=flowspec-cli
BUILD_DIR=build
MAIN_PATH=./cmd/flowspec-cli
GO_FILES=$(shell find . -name "*.go" -type f -not -path "./vendor/*")

# 版本信息
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "0.1.0-dev")
GIT_COMMIT ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_DATE ?= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
GO_VERSION ?= $(shell go version | cut -d' ' -f3)

# 构建标志
LDFLAGS = -ldflags "\
	-X main.Version=$(VERSION) \
	-X main.GitCommit=$(GIT_COMMIT) \
	-X main.BuildDate=$(BUILD_DATE) \
	-s -w"

# 发布标志 (优化构建)
RELEASE_LDFLAGS = -ldflags "\
	-X main.Version=$(VERSION) \
	-X main.GitCommit=$(GIT_COMMIT) \
	-X main.BuildDate=$(BUILD_DATE) \
	-s -w -extldflags '-static'"

# 默认目标
all: fmt vet test build

# 构建二进制文件
build:
	@echo "构建 $(BINARY_NAME) $(VERSION)..."
	@mkdir -p $(BUILD_DIR)
	go build $(LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME) $(MAIN_PATH)

# 构建发布版本
build-release:
	@echo "构建发布版本 $(BINARY_NAME) $(VERSION)..."
	@mkdir -p $(BUILD_DIR)
	CGO_ENABLED=0 go build $(RELEASE_LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME) $(MAIN_PATH)

# 运行测试
test:
	@echo "运行测试..."
	go test -v ./...

# 运行测试并生成覆盖率报告
coverage:
	@echo "生成测试覆盖率报告..."
	@if [ -f "scripts/coverage.sh" ]; then \
		./scripts/coverage.sh; \
	else \
		go test -coverprofile=coverage.out ./...; \
		go tool cover -html=coverage.out -o coverage.html; \
		echo "覆盖率报告已生成: coverage.html"; \
	fi

# 代码格式化
fmt:
	@echo "格式化代码..."
	go fmt ./...

# 代码检查
vet:
	@echo "运行 go vet..."
	go vet ./...

# 代码检查 (使用 golangci-lint)
lint:
	@echo "运行 golangci-lint..."
	@if command -v golangci-lint >/dev/null 2>&1; then \
		golangci-lint run; \
	else \
		echo "⚠️  golangci-lint 未安装，跳过 lint 检查"; \
		echo "💡 安装方法: https://golangci-lint.run/usage/install/"; \
	fi

# 安装依赖
deps:
	@echo "下载依赖..."
	go mod download
	go mod tidy

# 安装到 GOPATH
install:
	@echo "安装 $(BINARY_NAME)..."
	go install $(MAIN_PATH)

# 清理构建文件
clean:
	@echo "清理构建文件..."
	rm -rf $(BUILD_DIR)
	rm -f coverage.out coverage.html

# 运行开发模式
dev: build
	@echo "运行开发模式..."
	./$(BUILD_DIR)/$(BINARY_NAME) --help

# CI/CD 相关目标
ci: fmt vet lint test coverage build
	@echo "✅ CI 检查全部通过"

# 开发模式 CI (较低的覆盖率要求)
ci-dev: fmt vet lint test build
	@echo "运行开发模式覆盖率检查..."
	@DEV_MODE=true ./scripts/coverage.sh || true
	@echo "✅ 开发模式 CI 检查完成"

# 检查代码质量
quality: fmt vet lint
	@echo "✅ 代码质量检查通过"

# 多平台构建
build-all:
	@echo "构建多平台二进制文件 $(VERSION)..."
	@mkdir -p $(BUILD_DIR)
	@echo "构建 Linux AMD64..."
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build $(RELEASE_LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-$(VERSION)-linux-amd64 $(MAIN_PATH)
	@echo "构建 Linux ARM64..."
	GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build $(RELEASE_LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-$(VERSION)-linux-arm64 $(MAIN_PATH)
	@echo "构建 macOS AMD64..."
	GOOS=darwin GOARCH=amd64 CGO_ENABLED=0 go build $(RELEASE_LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-$(VERSION)-darwin-amd64 $(MAIN_PATH)
	@echo "构建 macOS ARM64..."
	GOOS=darwin GOARCH=arm64 CGO_ENABLED=0 go build $(RELEASE_LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-$(VERSION)-darwin-arm64 $(MAIN_PATH)
	@echo "构建 Windows AMD64..."
	GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build $(RELEASE_LDFLAGS) -o $(BUILD_DIR)/$(BINARY_NAME)-$(VERSION)-windows-amd64.exe $(MAIN_PATH)
	@echo "✅ 多平台构建完成"

# 创建发布包
package: build-all
	@echo "创建发布包..."
	@mkdir -p $(BUILD_DIR)/packages
	@for binary in $(BUILD_DIR)/$(BINARY_NAME)-$(VERSION)-*; do \
		if [ -f "$$binary" ]; then \
			base=$$(basename $$binary); \
			platform=$$(echo $$base | sed 's/$(BINARY_NAME)-$(VERSION)-//'); \
			mkdir -p $(BUILD_DIR)/packages/$$platform; \
			cp $$binary $(BUILD_DIR)/packages/$$platform/$(BINARY_NAME)$$(echo $$platform | grep -q windows && echo .exe || echo ""); \
			cp README.md $(BUILD_DIR)/packages/$$platform/; \
			cp LICENSE $(BUILD_DIR)/packages/$$platform/; \
			cp CHANGELOG.md $(BUILD_DIR)/packages/$$platform/; \
			cd $(BUILD_DIR)/packages && tar -czf $(BINARY_NAME)-$(VERSION)-$$platform.tar.gz $$platform/; \
			cd ../..; \
		fi \
	done
	@echo "✅ 发布包创建完成"

# 性能测试相关目标
performance-test:
	@echo "运行性能测试..."
	@if [ -f "scripts/performance-test.sh" ]; then \
		./scripts/performance-test.sh; \
	else \
		echo "⚠️  性能测试脚本未找到"; \
	fi

performance-tests-only:
	@echo "仅运行性能测试用例..."
	go test -v -run "TestLargeScale|TestMemoryUsage|TestConcurrency|TestPerformanceRegression" ./cmd/flowspec-cli/ -timeout 60m

stress-test:
	@echo "运行压力测试..."
	go test -v -run "TestStress" ./cmd/flowspec-cli/ -timeout 90m

benchmark:
	@echo "运行基准测试..."
	go test -bench=. -benchmem -count=3 ./...

benchmark-cli:
	@echo "运行 CLI 基准测试..."
	go test -bench=BenchmarkCLI -benchmem -count=5 ./cmd/flowspec-cli/

performance-monitor:
	@echo "运行性能监控测试..."
	go test -v ./internal/monitor/ -timeout 10m

# 版本管理
version:
	@echo "当前版本: $(VERSION)"
	@echo "Git 提交: $(GIT_COMMIT)"
	@echo "构建日期: $(BUILD_DATE)"
	@echo "Go 版本: $(GO_VERSION)"

# 创建 Git 标签
tag:
	@if [ "$(VERSION)" = "0.1.0-dev" ]; then \
		echo "❌ 不能为开发版本创建标签"; \
		exit 1; \
	fi
	@echo "创建标签 v$(VERSION)..."
	git tag -a v$(VERSION) -m "Release v$(VERSION)"
	@echo "✅ 标签 v$(VERSION) 创建完成"
	@echo "💡 使用 'git push origin v$(VERSION)' 推送标签"

# 发布准备
release-prepare: clean deps fmt vet lint test coverage
	@echo "🚀 准备发布 $(VERSION)..."
	@if [ "$(VERSION)" = "0.1.0-dev" ]; then \
		echo "❌ 请设置正确的版本号: make release-prepare VERSION=x.y.z"; \
		exit 1; \
	fi
	@echo "✅ 发布准备检查通过"

# 完整发布流程
release: release-prepare build-all package
	@echo "🎉 发布 $(VERSION) 完成!"
	@echo "📦 发布包位置: $(BUILD_DIR)/packages/"
	@ls -la $(BUILD_DIR)/packages/*.tar.gz
	@echo ""
	@echo "📋 发布检查清单:"
	@echo "  ✅ 代码质量检查通过"
	@echo "  ✅ 测试覆盖率达标"
	@echo "  ✅ 多平台二进制文件构建完成"
	@echo "  ✅ 发布包创建完成"
	@echo ""
	@echo "🔄 下一步操作:"
	@echo "  1. 创建 Git 标签: make tag VERSION=$(VERSION)"
	@echo "  2. 推送标签: git push origin v$(VERSION)"
	@echo "  3. 在 GitHub 上创建 Release"
	@echo "  4. 上传发布包到 GitHub Release"

# 快速发布 (跳过一些检查，用于开发测试)
release-dev: clean build-all
	@echo "🚀 开发版本发布..."
	@echo "📦 构建文件位置: $(BUILD_DIR)/"
	@ls -la $(BUILD_DIR)/$(BINARY_NAME)-*

# 检查发布就绪性
release-check:
	@echo "🔍 检查发布就绪性..."
	@echo "检查 Git 状态..."
	@if [ -n "$$(git status --porcelain)" ]; then \
		echo "❌ 工作目录不干净，请提交所有更改"; \
		git status --short; \
		exit 1; \
	fi
	@echo "✅ Git 工作目录干净"
	@echo "检查版本号..."
	@if [ "$(VERSION)" = "0.1.0-dev" ]; then \
		echo "❌ 请设置正确的版本号"; \
		exit 1; \
	fi
	@echo "✅ 版本号: $(VERSION)"
	@echo "检查标签是否已存在..."
	@if git tag -l | grep -q "^v$(VERSION)$$"; then \
		echo "❌ 标签 v$(VERSION) 已存在"; \
		exit 1; \
	fi
	@echo "✅ 标签 v$(VERSION) 可用"
	@echo "🎯 发布就绪性检查通过"

# 显示帮助信息
help:
	@echo "FlowSpec CLI 构建系统"
	@echo "====================="
	@echo ""
	@echo "🔨 构建目标:"
	@echo "  build           - 构建二进制文件"
	@echo "  build-release   - 构建发布版本 (优化)"
	@echo "  build-all       - 构建多平台二进制文件"
	@echo "  package         - 创建发布包"
	@echo ""
	@echo "🧪 测试目标:"
	@echo "  test            - 运行测试"
	@echo "  coverage        - 生成测试覆盖率报告"
	@echo "  performance-test - 运行性能测试"
	@echo "  stress-test     - 运行压力测试"
	@echo "  benchmark       - 运行基准测试"
	@echo ""
	@echo "🔍 质量检查:"
	@echo "  fmt             - 格式化代码"
	@echo "  vet             - 运行 go vet"
	@echo "  lint            - 运行 golangci-lint"
	@echo "  quality         - 运行所有代码质量检查"
	@echo ""
	@echo "🚀 CI/CD 目标:"
	@echo "  ci              - 运行完整的 CI 检查"
	@echo "  ci-dev          - 运行开发模式 CI 检查"
	@echo ""
	@echo "📦 发布目标:"
	@echo "  version         - 显示版本信息"
	@echo "  tag             - 创建 Git 标签"
	@echo "  release-check   - 检查发布就绪性"
	@echo "  release-prepare - 发布准备检查"
	@echo "  release         - 完整发布流程"
	@echo "  release-dev     - 快速开发版本发布"
	@echo ""
	@echo "🛠️  其他目标:"
	@echo "  deps            - 下载并整理依赖"
	@echo "  install         - 安装到 GOPATH"
	@echo "  clean           - 清理构建文件"
	@echo "  dev             - 构建并运行开发模式"
	@echo "  help            - 显示此帮助信息"
	@echo ""
	@echo "💡 示例用法:"
	@echo "  make build                    # 构建开发版本"
	@echo "  make release VERSION=1.0.0   # 发布 1.0.0 版本"
	@echo "  make ci                       # 运行 CI 检查"