# FlowSpec CLI Makefile

.PHONY: build test clean install lint fmt vet coverage help

# 变量定义
BINARY_NAME=flowspec-cli
BUILD_DIR=build
MAIN_PATH=./cmd/flowspec-cli
GO_FILES=$(shell find . -name "*.go" -type f -not -path "./vendor/*")

# 默认目标
all: fmt vet test build

# 构建二进制文件
build:
	@echo "构建 $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	go build -o $(BUILD_DIR)/$(BINARY_NAME) $(MAIN_PATH)

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
	@echo "构建多平台二进制文件..."
	@mkdir -p $(BUILD_DIR)
	GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o $(BUILD_DIR)/$(BINARY_NAME)-linux-amd64 $(MAIN_PATH)
	GOOS=linux GOARCH=arm64 go build -ldflags="-s -w" -o $(BUILD_DIR)/$(BINARY_NAME)-linux-arm64 $(MAIN_PATH)
	GOOS=darwin GOARCH=amd64 go build -ldflags="-s -w" -o $(BUILD_DIR)/$(BINARY_NAME)-darwin-amd64 $(MAIN_PATH)
	GOOS=darwin GOARCH=arm64 go build -ldflags="-s -w" -o $(BUILD_DIR)/$(BINARY_NAME)-darwin-arm64 $(MAIN_PATH)
	GOOS=windows GOARCH=amd64 go build -ldflags="-s -w" -o $(BUILD_DIR)/$(BINARY_NAME)-windows-amd64.exe $(MAIN_PATH)
	@echo "✅ 多平台构建完成"

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

# 显示帮助信息
help:
	@echo "可用的 make 目标:"
	@echo "  build      - 构建二进制文件"
	@echo "  build-all  - 构建多平台二进制文件"
	@echo "  test       - 运行测试"
	@echo "  coverage   - 生成测试覆盖率报告"
	@echo "  fmt        - 格式化代码"
	@echo "  vet        - 运行 go vet"
	@echo "  lint       - 运行 golangci-lint"
	@echo "  quality    - 运行所有代码质量检查"
	@echo "  ci         - 运行完整的 CI 检查"
	@echo "  ci-dev     - 运行开发模式 CI 检查 (较低覆盖率要求)"
	@echo "  deps       - 下载并整理依赖"
	@echo "  install    - 安装到 GOPATH"
	@echo "  clean      - 清理构建文件"
	@echo "  dev        - 构建并运行开发模式"
	@echo "  performance-test    - 运行完整性能测试套件"
	@echo "  performance-tests-only - 仅运行性能测试用例"
	@echo "  stress-test         - 运行压力测试"
	@echo "  benchmark          - 运行基准测试"
	@echo "  benchmark-cli      - 运行 CLI 基准测试"
	@echo "  performance-monitor - 运行性能监控测试"
	@echo "  help       - 显示此帮助信息"