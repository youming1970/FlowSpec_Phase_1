# FlowSpec CLI

[![Go Version](https://img.shields.io/badge/Go-1.21+-00ADD8?style=flat&logo=go)](https://golang.org/)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen.svg)](#)
[![Coverage](https://img.shields.io/badge/Coverage-80%25+-brightgreen.svg)](#)

FlowSpec CLI 是一个强大的命令行工具，用于从源代码中解析 ServiceSpec 注解，摄取 OpenTelemetry 轨迹数据，并执行规约与实际执行轨迹之间的对齐验证。它帮助开发者在开发周期早期发现服务集成问题，确保微服务架构的可靠性。

## 项目状态

🚧 **开发中** - 这是 FlowSpec Phase 1 MVP 的实现，目前正在积极开发中。

## 核心价值

- 🔍 **早期发现问题**: 在开发阶段就能发现服务集成问题
- 📝 **代码即文档**: ServiceSpec 注解直接嵌入源代码，保持同步
- 🌐 **多语言支持**: 支持 Java、TypeScript、Go 等主流语言
- 🚀 **CI/CD 集成**: 轻松集成到持续集成流程中
- 📊 **详细报告**: 提供人类可读和机器可读的验证报告

## 功能特性

- 📝 从多语言源代码中解析 ServiceSpec 注解 (Java, TypeScript, Go)
- 📊 摄取和处理 OpenTelemetry 轨迹数据
- ✅ 执行规约与实际轨迹的对齐验证
- 📋 生成详细的验证报告 (Human 和 JSON 格式)
- 🔧 支持命令行界面，易于集成到 CI/CD 流程

## 快速开始

### 安装

#### 使用 go install（推荐）

```bash
go install github.com/your-org/flowspec-cli/cmd/flowspec-cli@latest
```

#### 从源码构建

```bash
# 克隆仓库
git clone https://github.com/your-org/flowspec-cli.git
cd flowspec-cli

# 安装依赖
make deps

# 构建
make build

# 安装到 GOPATH
make install
```

#### 下载预编译二进制文件

访问 [Releases](https://github.com/your-org/flowspec-cli/releases) 页面下载适合您平台的预编译二进制文件。

### 验证安装

```bash
flowspec-cli --version
flowspec-cli --help
```

## 使用方法

### 基本用法

```bash
# 执行对齐验证
flowspec-cli align --path=./my-project --trace=./traces/run-1.json --output=human

# JSON 格式输出
flowspec-cli align --path=./my-project --trace=./traces/run-1.json --output=json

# 详细输出
flowspec-cli align --path=./my-project --trace=./traces/run-1.json --output=human --verbose
```

### 命令选项

- `--path, -p`: 源代码目录路径 (默认: ".")
- `--trace, -t`: OpenTelemetry 轨迹文件路径 (必需)
- `--output, -o`: 输出格式 (human|json, 默认: "human")
- `--verbose, -v`: 启用详细输出
- `--log-level`: 设置日志级别 (debug, info, warn, error)

## ServiceSpec 注解格式

FlowSpec 支持在多种编程语言中使用 ServiceSpec 注解：

### Java

```java
/**
 * @ServiceSpec
 * operationId: "createUser"
 * description: "创建新用户账户"
 * preconditions: {
 *   "request.body.email": {"!=": null},
 *   "request.body.password": {">=": 8}
 * }
 * postconditions: {
 *   "response.status": {"==": 201},
 *   "response.body.userId": {"!=": null}
 * }
 */
public User createUser(CreateUserRequest request) { ... }
```

### TypeScript

```typescript
/**
 * @ServiceSpec
 * operationId: "createUser"
 * description: "创建新用户账户"
 * preconditions: {
 *   "request.body.email": {"!=": null},
 *   "request.body.password": {">=": 8}
 * }
 * postconditions: {
 *   "response.status": {"==": 201},
 *   "response.body.userId": {"!=": null}
 * }
 */
function createUser(request: CreateUserRequest): Promise<User> { ... }
```

### Go

```go
// @ServiceSpec
// operationId: "createUser"
// description: "创建新用户账户"
// preconditions: {
//   "request.body.email": {"!=": null},
//   "request.body.password": {">=": 8}
// }
// postconditions: {
//   "response.status": {"==": 201},
//   "response.body.userId": {"!=": null}
// }
func CreateUser(request CreateUserRequest) (*User, error) { ... }
```

## 开发

### 前置要求

- Go 1.21 或更高版本
- Make (可选，用于构建脚本)

### 构建和测试

```bash
# 安装依赖
make deps

# 格式化代码
make fmt

# 运行代码检查
make vet

# 运行测试
make test

# 生成测试覆盖率报告
make coverage

# 构建二进制文件
make build

# 清理构建文件
make clean
```

### 项目结构

```
flowspec-cli/
├── cmd/flowspec-cli/     # CLI 入口点
├── internal/             # 内部包
│   ├── parser/          # ServiceSpec 解析器
│   ├── ingestor/        # OpenTelemetry 轨迹摄取器
│   ├── engine/          # 对齐验证引擎
│   └── renderer/        # 报告渲染器
├── pkg/                 # 公共包
├── testdata/            # 测试数据
├── build/               # 构建输出
└── Makefile            # 构建脚本
```

## 示例项目

查看 [examples](examples/) 目录中的示例项目，了解如何在实际项目中使用 FlowSpec CLI。

## 文档

- 📖 [API 文档](docs/API.md) - 详细的 API 接口文档
- 🏗️ [架构文档](docs/ARCHITECTURE.md) - 技术架构和设计决策
- 🤝 [贡献指南](CONTRIBUTING.md) - 如何参与项目开发
- 📋 [变更日志](CHANGELOG.md) - 版本更新记录

## 性能基准

- **解析性能**: 1,000 个源文件，200 个 ServiceSpecs，< 30 秒
- **内存使用**: 100MB 轨迹文件，峰值内存 < 500MB
- **测试覆盖率**: 核心模块 > 80%

## 路线图

- [ ] 支持更多编程语言（Python、C#、Rust）
- [ ] 实时轨迹流处理
- [ ] Web UI 界面
- [ ] 性能分析和优化建议
- [ ] 集成测试自动化

## 贡献

我们欢迎各种形式的贡献！请查看 [CONTRIBUTING.md](CONTRIBUTING.md) 了解如何参与项目开发。

### 贡献者

感谢所有为 FlowSpec CLI 做出贡献的开发者！

## 许可证

本项目采用 Apache-2.0 许可证。详情请查看 [LICENSE](LICENSE) 文件。

## 支持

如果您遇到问题或有疑问，请：

1. 📚 查看 [文档](docs/) 和 [FAQ](docs/FAQ.md)
2. 🔍 搜索现有的 [Issues](../../issues)
3. 💬 参与 [Discussions](../../discussions) 进行讨论
4. 🐛 创建新的 Issue 描述您的问题

## 社区

- 💬 [GitHub Discussions](../../discussions) - 讨论和问答
- 🐛 [GitHub Issues](../../issues) - Bug 报告和功能请求
- 📧 [邮件列表](mailto:flowspec@example.com) - 项目公告

---

**注意**: 这是一个正在开发中的项目，API 和功能可能会发生变化。我们会在主要版本发布前保持向后兼容性。

⭐ 如果这个项目对您有帮助，请给我们一个 Star！