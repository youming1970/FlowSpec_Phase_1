#!/bin/bash

# FlowSpec CLI 发布准备脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# 显示帮助信息
show_help() {
    echo "FlowSpec CLI 发布准备脚本"
    echo ""
    echo "用法: $0 [选项] VERSION"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示帮助信息"
    echo "  -d, --dry-run  干运行模式，不执行实际操作"
    echo "  -f, --force    强制执行，跳过某些检查"
    echo ""
    echo "参数:"
    echo "  VERSION        发布版本号 (例如: 1.0.0)"
    echo ""
    echo "示例:"
    echo "  $0 1.0.0                    # 准备 1.0.0 版本发布"
    echo "  $0 --dry-run 1.0.0          # 干运行模式"
    echo "  $0 --force 1.0.0            # 强制执行"
}

# 解析命令行参数
DRY_RUN=false
FORCE=false
VERSION=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -*)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
        *)
            if [ -z "$VERSION" ]; then
                VERSION="$1"
            else
                log_error "多余的参数: $1"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# 检查版本号参数
if [ -z "$VERSION" ]; then
    log_error "缺少版本号参数"
    show_help
    exit 1
fi

# 验证版本号格式
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$ ]]; then
    log_error "版本号格式无效: $VERSION"
    log_info "正确格式: x.y.z 或 x.y.z-suffix (例如: 1.0.0, 1.0.0-beta)"
    exit 1
fi

echo "🚀 FlowSpec CLI 发布准备"
echo "======================="
echo "版本: $VERSION"
echo "干运行模式: $DRY_RUN"
echo "强制模式: $FORCE"
echo ""

# 执行命令 (支持干运行模式)
execute_command() {
    local cmd="$1"
    local description="$2"
    
    log_info "$description"
    
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] $cmd"
        return 0
    else
        if eval "$cmd"; then
            log_success "$description 完成"
            return 0
        else
            log_error "$description 失败"
            return 1
        fi
    fi
}

# 检查前置条件
check_prerequisites() {
    log_info "检查发布前置条件..."
    
    # 检查是否在 Git 仓库中
    if [ ! -d ".git" ]; then
        log_error "不在 Git 仓库中"
        exit 1
    fi
    
    # 检查工作目录是否干净
    if [ "$FORCE" != true ] && [ -n "$(git status --porcelain)" ]; then
        log_error "Git 工作目录不干净，有未提交的更改"
        log_info "请提交所有更改或使用 --force 选项"
        git status --short
        exit 1
    fi
    
    # 检查是否在主分支
    current_branch=$(git branch --show-current)
    if [ "$FORCE" != true ] && [ "$current_branch" != "main" ] && [ "$current_branch" != "master" ]; then
        log_error "当前不在主分支 (当前分支: $current_branch)"
        log_info "请切换到主分支或使用 --force 选项"
        exit 1
    fi
    
    # 检查标签是否已存在
    if git tag -l | grep -q "^v$VERSION$"; then
        log_error "标签 v$VERSION 已存在"
        exit 1
    fi
    
    # 检查必要的工具
    local required_tools=("go" "make" "git")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "缺少必要工具: $tool"
            exit 1
        fi
    done
    
    log_success "前置条件检查通过"
}

# 更新版本信息
update_version_info() {
    log_info "更新版本信息..."
    
    # 更新 version.go 文件
    if [ -f "version.go" ]; then
        if [ "$DRY_RUN" != true ]; then
            sed -i.bak "s/Version = \".*\"/Version = \"$VERSION\"/" version.go
            rm -f version.go.bak
        fi
        log_success "version.go 更新完成"
    else
        log_warning "version.go 文件不存在"
    fi
    
    # 更新 CHANGELOG.md
    if [ -f "CHANGELOG.md" ]; then
        if [ "$DRY_RUN" != true ]; then
            # 创建临时文件
            temp_file=$(mktemp)
            
            # 添加新版本条目
            {
                echo "# 变更日志"
                echo ""
                echo "本文档记录了 FlowSpec CLI 项目的所有重要变更。"
                echo ""
                echo "格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，"
                echo "版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。"
                echo ""
                echo "## [未发布]"
                echo ""
                echo "## [$VERSION] - $(date +%Y-%m-%d)"
                echo ""
                echo "### 新增"
                echo "- FlowSpec CLI Phase 1 MVP 发布"
                echo "- 完整的多语言 ServiceSpec 解析器支持"
                echo "- OpenTelemetry 轨迹数据摄取和处理"
                echo "- JSONLogic 断言评估引擎"
                echo "- Human 和 JSON 格式报告输出"
                echo "- 完整的项目文档和示例"
                echo ""
                # 保留原有内容 (跳过前面的标题部分)
                tail -n +8 CHANGELOG.md
            } > "$temp_file"
            
            mv "$temp_file" CHANGELOG.md
        fi
        log_success "CHANGELOG.md 更新完成"
    else
        log_warning "CHANGELOG.md 文件不存在"
    fi
}

# 运行完整的质量检查
run_quality_checks() {
    log_info "运行质量检查..."
    
    execute_command "make deps" "下载依赖"
    execute_command "make fmt" "代码格式化"
    execute_command "make vet" "静态分析检查"
    
    # Lint 检查 (可选)
    if command -v golangci-lint &> /dev/null; then
        execute_command "make lint" "代码检查"
    else
        log_warning "golangci-lint 不可用，跳过 lint 检查"
    fi
    
    execute_command "make test" "单元测试"
    execute_command "make coverage" "测试覆盖率"
}

# 构建发布版本
build_release() {
    log_info "构建发布版本..."
    
    execute_command "make clean" "清理构建文件"
    execute_command "make build-release VERSION=$VERSION" "构建发布版本"
    execute_command "make build-all VERSION=$VERSION" "多平台构建"
    execute_command "make package VERSION=$VERSION" "创建发布包"
    
    if [ "$DRY_RUN" != true ]; then
        # 显示构建结果
        log_info "构建结果:"
        if [ -d "build" ]; then
            ls -la build/
        fi
        
        if [ -d "build/packages" ]; then
            log_info "发布包:"
            ls -la build/packages/
        fi
    fi
}

# 运行集成测试
run_integration_tests() {
    log_info "运行集成测试..."
    
    if [ -f "scripts/integration-validation.sh" ]; then
        if [ "$DRY_RUN" != true ]; then
            if ./scripts/integration-validation.sh; then
                log_success "集成测试通过"
            else
                log_error "集成测试失败"
                exit 1
            fi
        else
            log_info "[DRY RUN] 运行集成测试"
        fi
    else
        log_warning "集成测试脚本不存在"
    fi
}

# 创建发布提交和标签
create_release_commit() {
    log_info "创建发布提交和标签..."
    
    if [ "$DRY_RUN" != true ]; then
        # 添加更改的文件
        if [ -f "version.go" ]; then
            git add version.go
        fi
        if [ -f "CHANGELOG.md" ]; then
            git add CHANGELOG.md
        fi
        
        # 检查是否有更改需要提交
        if [ -n "$(git diff --cached --name-only)" ]; then
            git commit -m "chore: prepare release v$VERSION"
            log_success "发布提交创建完成"
        else
            log_info "没有需要提交的更改"
        fi
        
        # 创建标签
        git tag -a "v$VERSION" -m "Release v$VERSION"
        log_success "标签 v$VERSION 创建完成"
    else
        log_info "[DRY RUN] 创建发布提交和标签"
    fi
}

# 生成发布说明
generate_release_notes() {
    log_info "生成发布说明..."
    
    local release_notes_file="release-notes-v$VERSION.md"
    
    if [ "$DRY_RUN" != true ]; then
        cat > "$release_notes_file" << EOF
# FlowSpec CLI v$VERSION 发布说明

## 🎉 新版本发布

FlowSpec CLI v$VERSION 现已发布！这是 FlowSpec Phase 1 MVP 的正式版本。

## 📦 下载

### 使用 go install 安装

\`\`\`bash
go install github.com/flowspec/flowspec-cli/cmd/flowspec-cli@v$VERSION
\`\`\`

### 下载预编译二进制文件

选择适合您平台的二进制文件：

- **Linux AMD64**: [flowspec-cli-$VERSION-linux-amd64.tar.gz](../../releases/download/v$VERSION/flowspec-cli-$VERSION-linux-amd64.tar.gz)
- **Linux ARM64**: [flowspec-cli-$VERSION-linux-arm64.tar.gz](../../releases/download/v$VERSION/flowspec-cli-$VERSION-linux-arm64.tar.gz)
- **macOS AMD64**: [flowspec-cli-$VERSION-darwin-amd64.tar.gz](../../releases/download/v$VERSION/flowspec-cli-$VERSION-darwin-amd64.tar.gz)
- **macOS ARM64**: [flowspec-cli-$VERSION-darwin-arm64.tar.gz](../../releases/download/v$VERSION/flowspec-cli-$VERSION-darwin-arm64.tar.gz)
- **Windows AMD64**: [flowspec-cli-$VERSION-windows-amd64.tar.gz](../../releases/download/v$VERSION/flowspec-cli-$VERSION-windows-amd64.tar.gz)

## ✨ 主要功能

- 🔍 **多语言支持**: 支持 Java、TypeScript、Go 源代码中的 ServiceSpec 注解解析
- 📊 **轨迹处理**: 完整的 OpenTelemetry 轨迹数据摄取和处理
- ✅ **智能验证**: 基于 JSONLogic 的强大断言评估引擎
- 📋 **丰富报告**: 支持 Human 和 JSON 两种输出格式
- 🚀 **高性能**: 优化的并行处理和内存管理
- 📖 **完整文档**: 详细的使用指南和示例项目

## 🚀 快速开始

\`\`\`bash
# 安装 FlowSpec CLI
go install github.com/flowspec/flowspec-cli/cmd/flowspec-cli@v$VERSION

# 验证安装
flowspec-cli --version

# 运行示例
flowspec-cli align --path=./my-project --trace=./traces/run-1.json --output=human
\`\`\`

## 📋 完整变更日志

详细的变更信息请查看 [CHANGELOG.md](./CHANGELOG.md)。

## 🐛 问题报告

如果您遇到问题，请在 [Issues](../../issues) 中报告。

## 🤝 贡献

我们欢迎贡献！请查看 [CONTRIBUTING.md](./CONTRIBUTING.md) 了解如何参与。

## 📄 许可证

本项目采用 Apache-2.0 许可证。详情请查看 [LICENSE](./LICENSE) 文件。

---

感谢所有为 FlowSpec CLI 做出贡献的开发者！

发布日期: $(date +%Y-%m-%d)
EOF
        log_success "发布说明已生成: $release_notes_file"
    else
        log_info "[DRY RUN] 生成发布说明"
    fi
}

# 显示下一步操作
show_next_steps() {
    echo ""
    echo "🎉 发布准备完成！"
    echo "=================="
    echo ""
    echo "📋 下一步操作:"
    echo ""
    
    if [ "$DRY_RUN" = true ]; then
        echo "1. 重新运行脚本 (不使用 --dry-run):"
        echo "   $0 $VERSION"
        echo ""
    else
        echo "1. 推送提交和标签到远程仓库:"
        echo "   git push origin main"
        echo "   git push origin v$VERSION"
        echo ""
        echo "2. 在 GitHub 上创建 Release:"
        echo "   - 访问: https://github.com/your-org/flowspec-cli/releases/new"
        echo "   - 选择标签: v$VERSION"
        echo "   - 使用生成的发布说明: release-notes-v$VERSION.md"
        echo ""
        echo "3. 上传发布包:"
        echo "   - 上传 build/packages/ 目录下的所有 .tar.gz 文件"
        echo "   - 上传 checksums.txt 文件"
        echo ""
    fi
    
    echo "4. 更新项目文档和公告"
    echo "5. 通知用户和社区"
    echo ""
    echo "📁 生成的文件:"
    if [ "$DRY_RUN" != true ]; then
        echo "  - build/packages/ (发布包)"
        echo "  - release-notes-v$VERSION.md (发布说明)"
        if [ -f "acceptance-report.md" ]; then
            echo "  - acceptance-report.md (验收报告)"
        fi
    else
        echo "  (干运行模式，未生成实际文件)"
    fi
    echo ""
    echo "🎯 发布版本: v$VERSION"
    echo "📅 准备时间: $(date)"
}

# 主函数
main() {
    check_prerequisites
    update_version_info
    run_quality_checks
    build_release
    run_integration_tests
    create_release_commit
    generate_release_notes
    show_next_steps
}

# 运行主函数
main