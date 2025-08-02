# FlowSpec CLI

FlowSpec CLI 是一个命令行工具，用于从源代码中解析 ServiceSpec 注解，摄取 OpenTelemetry 轨迹数据，并执行规约与实际执行轨迹之间的对齐验证。

## 项目状态

🚧 **开发中** - 这是 FlowSpec Phase 1 MVP 的实现，目前正在积极开发中。

## 功能特性

- 📝 从多语言源代码中解析 ServiceSpec 注解 (Java, TypeScript, Go)
- 📊 摄取和处理 OpenTelemetry 轨迹数据
- ✅ 执行规约与实际轨迹的对齐验证
- 📋 生成详细的验证报告 (Human 和 JSON 格式)
- 🔧 支持命令行界面，易于集成到 CI/CD 流程

## 安装

### 从源码构建

```bash
# 克隆仓库
git clone <repository-url>
cd flowspec-cli

# 构建
make build

# 或者直接安装到 GOPATH
make install
```

### 使用 go install

```bash
go install github.com/your-org/flowspec-cli/cmd/flowspec-cli@latest
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

## 贡献

我们欢迎贡献！请查看 [CONTRIBUTING.md](CONTRIBUTING.md) 了解如何参与项目开发。

## 许可证

本项目采用 Apache-2.0 许可证。详情请查看 [LICENSE](LICENSE) 文件。

## 支持

如果您遇到问题或有疑问，请：

1. 查看现有的 [Issues](../../issues)
2. 创建新的 Issue 描述您的问题
3. 参与 [Discussions](../../discussions) 进行讨论

---

**注意**: 这是一个正在开发中的项目，API 和功能可能会发生变化。