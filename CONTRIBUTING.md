# 贡献指南

感谢您对 FlowSpec CLI 项目的关注！我们欢迎各种形式的贡献，包括但不限于：

- 🐛 报告 Bug
- 💡 提出新功能建议
- 📝 改进文档
- 🔧 提交代码修复或新功能
- 🧪 编写测试用例
- 📖 翻译文档

## 开发环境设置

### 前置要求

- **Go**: 1.21 或更高版本
- **Git**: 用于版本控制
- **Make**: 用于构建脚本（可选）
- **golangci-lint**: 用于代码质量检查（推荐）

### 安装 golangci-lint

```bash
# macOS
brew install golangci-lint

# Linux
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.54.2

# Windows
go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.54.2
```

### 克隆和设置项目

```bash
# 1. Fork 项目到您的 GitHub 账户
# 2. 克隆您的 fork
git clone https://github.com/YOUR_USERNAME/flowspec-cli.git
cd flowspec-cli

# 3. 添加上游仓库
git remote add upstream https://github.com/ORIGINAL_OWNER/flowspec-cli.git

# 4. 安装依赖
make deps

# 5. 验证环境设置
make ci-dev
```

## 开发工作流

### 1. 创建功能分支

```bash
# 从最新的 main 分支创建新分支
git checkout main
git pull upstream main
git checkout -b feature/your-feature-name

# 或者修复 bug
git checkout -b fix/issue-number-description
```

### 2. 开发和测试

```bash
# 格式化代码
make fmt

# 运行代码检查
make vet
make lint

# 运行测试
make test

# 生成测试覆盖率报告
make coverage

# 构建项目
make build

# 运行完整的 CI 检查
make ci-dev
```

### 3. 提交代码

我们使用 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

```bash
# 提交格式
git commit -m "type(scope): description"

# 示例
git commit -m "feat(parser): add support for Python ServiceSpec annotations"
git commit -m "fix(engine): resolve JSONLogic evaluation context issue"
git commit -m "docs(readme): update installation instructions"
git commit -m "test(ingestor): add unit tests for large file processing"
```

#### 提交类型

- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档更新
- `style`: 代码格式化（不影响功能）
- `refactor`: 代码重构
- `test`: 测试相关
- `chore`: 构建过程或辅助工具的变动
- `perf`: 性能优化
- `ci`: CI/CD 相关

### 4. 推送和创建 Pull Request

```bash
# 推送到您的 fork
git push origin feature/your-feature-name

# 在 GitHub 上创建 Pull Request
```

## 代码规范

### Go 代码风格

我们遵循标准的 Go 代码风格：

- 使用 `go fmt` 格式化代码
- 遵循 [Effective Go](https://golang.org/doc/effective_go.html) 指南
- 使用有意义的变量和函数名
- 为公共函数和类型添加文档注释
- 保持函数简洁，单一职责

### 代码组织

```
flowspec-cli/
├── cmd/flowspec-cli/     # CLI 入口点
│   ├── main.go          # 主函数
│   └── *_test.go        # CLI 测试
├── internal/            # 内部包（不对外暴露）
│   ├── parser/          # ServiceSpec 解析器
│   ├── ingestor/        # OpenTelemetry 轨迹摄取器
│   ├── engine/          # 对齐验证引擎
│   ├── renderer/        # 报告渲染器
│   └── models/          # 数据模型
├── pkg/                 # 公共包（可被外部使用）
├── testdata/            # 测试数据文件
├── scripts/             # 构建和测试脚本
└── docs/                # 项目文档
```

### 测试要求

- **单元测试**: 所有新功能必须包含单元测试
- **测试覆盖率**: 核心模块需要达到 80% 以上的覆盖率
- **集成测试**: 重要功能需要包含集成测试
- **测试命名**: 使用 `TestFunctionName_Scenario_ExpectedResult` 格式

```go
func TestSpecParser_ParseJavaFile_ValidAnnotation_ReturnsServiceSpec(t *testing.T) {
    // 测试实现
}

func TestAlignmentEngine_Align_PreconditionFails_ReturnsFailedStatus(t *testing.T) {
    // 测试实现
}
```

### 错误处理

- 使用 Go 标准的错误处理模式
- 为错误提供足够的上下文信息
- 使用 `fmt.Errorf` 包装错误
- 在适当的地方使用自定义错误类型

```go
// 好的错误处理示例
func (p *SpecParser) parseFile(filepath string) (*ServiceSpec, error) {
    content, err := os.ReadFile(filepath)
    if err != nil {
        return nil, fmt.Errorf("failed to read file %s: %w", filepath, err)
    }
    
    spec, err := p.parseContent(content)
    if err != nil {
        return nil, fmt.Errorf("failed to parse ServiceSpec in %s: %w", filepath, err)
    }
    
    return spec, nil
}
```

## 测试指南

### 运行测试

```bash
# 运行所有测试
make test

# 运行特定包的测试
go test ./internal/parser/

# 运行特定测试
go test -run TestSpecParser_ParseJavaFile ./internal/parser/

# 运行测试并显示覆盖率
make coverage

# 运行性能测试
make performance-tests-only

# 运行压力测试
make stress-test
```

### 编写测试

#### 单元测试示例

```go
func TestSpecParser_ParseJavaFile_ValidAnnotation_ReturnsServiceSpec(t *testing.T) {
    // Arrange
    parser := NewSpecParser()
    testFile := "testdata/valid_java_annotation.java"
    
    // Act
    result, err := parser.ParseFile(testFile)
    
    // Assert
    assert.NoError(t, err)
    assert.NotNil(t, result)
    assert.Equal(t, "createUser", result.OperationID)
    assert.NotEmpty(t, result.Preconditions)
    assert.NotEmpty(t, result.Postconditions)
}
```

#### 集成测试示例

```go
func TestCLI_AlignCommand_EndToEnd_Success(t *testing.T) {
    // 准备测试数据
    tempDir := t.TempDir()
    setupTestProject(t, tempDir)
    
    // 执行 CLI 命令
    cmd := exec.Command("./build/flowspec-cli", 
        "align", 
        "--path", tempDir,
        "--trace", "testdata/success-trace.json",
        "--output", "json")
    
    output, err := cmd.CombinedOutput()
    
    // 验证结果
    assert.NoError(t, err)
    
    var report AlignmentReport
    err = json.Unmarshal(output, &report)
    assert.NoError(t, err)
    assert.Equal(t, 3, report.Summary.Total)
    assert.Equal(t, 3, report.Summary.Success)
}
```

## 性能要求

### 性能基准

- **解析性能**: 1,000 个源文件，200 个 ServiceSpecs，30 秒内完成
- **内存使用**: 100MB 轨迹文件，峰值内存不超过 500MB
- **并发安全**: 支持多线程环境下的安全操作

### 性能测试

```bash
# 运行性能基准测试
make benchmark

# 运行大规模测试
make performance-tests-only

# 运行内存使用测试
go test -run TestMemoryUsage ./cmd/flowspec-cli/ -timeout 30m
```

## 文档贡献

### 文档类型

- **README.md**: 项目介绍和基本使用说明
- **API 文档**: 使用 `godoc` 生成的 API 文档
- **技术文档**: 架构设计、实现细节等
- **用户指南**: 详细的使用教程和示例

### 文档规范

- 使用清晰、简洁的语言
- 提供实际的代码示例
- 保持文档与代码同步更新
- 支持中英文双语（优先中文）

## Pull Request 指南

### PR 标题格式

```
type(scope): description

# 示例
feat(parser): add Python ServiceSpec annotation support
fix(engine): resolve JSONLogic context variable issue
docs(contributing): update development setup instructions
```

### PR 描述模板

```markdown
## 变更类型
- [ ] Bug 修复
- [ ] 新功能
- [ ] 文档更新
- [ ] 性能优化
- [ ] 代码重构
- [ ] 测试改进

## 变更描述
简要描述此 PR 的变更内容和目的。

## 相关 Issue
Fixes #123
Closes #456

## 测试
- [ ] 添加了新的单元测试
- [ ] 添加了集成测试
- [ ] 所有现有测试通过
- [ ] 手动测试通过

## 检查清单
- [ ] 代码遵循项目规范
- [ ] 添加了必要的文档
- [ ] 测试覆盖率满足要求
- [ ] CI 检查全部通过
```

### 代码审查

所有 PR 都需要经过代码审查：

1. **自动检查**: CI/CD 流水线会自动运行测试和代码检查
2. **人工审查**: 至少需要一位维护者的批准
3. **反馈处理**: 及时响应审查意见并进行修改

## 发布流程

### 版本号规范

我们使用 [Semantic Versioning](https://semver.org/)：

- `MAJOR.MINOR.PATCH` (例如: 1.2.3)
- `MAJOR`: 不兼容的 API 变更
- `MINOR`: 向后兼容的功能新增
- `PATCH`: 向后兼容的问题修正

### 发布检查清单

- [ ] 所有测试通过
- [ ] 文档更新完成
- [ ] 变更日志更新
- [ ] 版本号更新
- [ ] 性能基准测试通过

## 社区行为准则

### 我们的承诺

为了营造一个开放和友好的环境，我们承诺：

- 使用友好和包容的语言
- 尊重不同的观点和经验
- 优雅地接受建设性批评
- 关注对社区最有利的事情
- 对其他社区成员表示同理心

### 不可接受的行为

- 使用性别化语言或图像，以及不受欢迎的性关注或性骚扰
- 恶意评论、人身攻击或政治攻击
- 公开或私下的骚扰
- 未经明确许可发布他人的私人信息
- 其他在专业环境中可能被认为不当的行为

## 获得帮助

如果您在贡献过程中遇到问题，可以通过以下方式获得帮助：

- 📧 **邮件**: 发送邮件到项目维护者
- 💬 **Discussions**: 在 GitHub Discussions 中提问
- 🐛 **Issues**: 创建 Issue 描述问题
- 📖 **文档**: 查看项目文档和 Wiki

## 致谢

感谢所有为 FlowSpec CLI 项目做出贡献的开发者！您的贡献让这个项目变得更好。

---

**注意**: 这是一个活跃开发的项目，贡献指南可能会随着项目发展而更新。请定期查看最新版本。