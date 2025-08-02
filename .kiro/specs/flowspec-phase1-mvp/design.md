# FlowSpec Phase 1 MVP 设计文档

## 概述

FlowSpec Phase 1 MVP 是一个命令行工具，实现了从源代码解析 ServiceSpec 注解、摄取 OpenTelemetry 轨迹数据，并执行规约与实际执行轨迹对齐验证的完整流程。本设计遵循"吃自己的狗粮"原则，严格按照 task.md 中定义的 `phase1_mvp.flowspec.yaml` 规约进行架构设计。

## 架构设计

### 整体架构

系统采用模块化设计，遵循 task.md 中定义的 FlowSpec 流程编排：

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   CLI 入口       │───▶│  SpecParser     │───▶│ TraceIngestor   │───▶│ AlignmentEngine │
│                 │    │                 │    │                 │    │                 │
│ • 参数解析       │    │ • 源码扫描       │    │ • OTel 解析     │    │ • 断言验证       │
│ • 流程编排       │    │ • 注解提取       │    │ • 轨迹组织       │    │ • 报告生成       │
│ • 报告渲染       │    │ • JSON 转换     │    │ • 内存优化       │    │ • 状态判定       │
└─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
         │                                                                      │
         │                                                                      ▼
         │                                                            ┌─────────────────┐
         └────────────────────────────────────────────────────────────│  Report Renderer │
                                                                      │                 │
                                                                      │ • Human 格式    │
                                                                      │ • JSON 格式     │
                                                                      │ • 退出码管理     │
                                                                      └─────────────────┘
```

### 技术栈选择

- **主语言**: Go 1.21+
- **断言引擎**: JSONLogic (github.com/diegoholiveira/jsonlogic)
- **CLI 框架**: Cobra (github.com/spf13/cobra)
- **配置管理**: Viper (github.com/spf13/viper)
- **日志系统**: Logrus (github.com/sirupsen/logrus)
- **测试框架**: Go 标准库 testing + Testify (github.com/stretchr/testify)

## 组件设计

### 1. CLI 入口层 (cmd/flowspec-cli)

#### 职责
- 命令行参数解析和验证
- 按照 `phase1_mvp.flowspec.yaml` 编排各模块调用
- 管理模块间数据流转
- 错误处理和用户反馈

#### 接口设计
```go
type CLI struct {
    specParser      SpecParser
    traceIngestor   TraceIngestor
    alignmentEngine AlignmentEngine
    reportRenderer  ReportRenderer
    logger          *logrus.Logger
}

type CLIConfig struct {
    SourcePath   string
    TracePath    string
    OutputFormat string // "human" | "json"
    Verbose      bool
    LogLevel     string
}

func (c *CLI) Execute(config CLIConfig) error
```

#### 命令结构
```bash
flowspec-cli align --path=./my-project --trace=./traces/run-1.json --output=human
flowspec-cli align --path=./my-project --trace=./traces/run-1.json --output=json
flowspec-cli --help
flowspec-cli align --help
```

### 2. SpecParser 模块 (internal/parser)

#### 职责
- 递归扫描指定目录下的源文件 (.java, .ts, .go)
- 提取和解析 `@ServiceSpec` 注解
- 将注解内容转换为结构化的 JSON 对象
- 验证 ServiceSpec 语法的正确性

#### 核心数据结构
```go
type ServiceSpec struct {
    OperationID    string                 `json:"operationId"`
    Description    string                 `json:"description"`
    Preconditions  map[string]interface{} `json:"preconditions"`
    Postconditions map[string]interface{} `json:"postconditions"`
    SourceFile     string                 `json:"sourceFile"`
    LineNumber     int                    `json:"lineNumber"`
}

type ParseResult struct {
    Specs  []ServiceSpec `json:"specs"`
    Errors []ParseError  `json:"errors"`
}

type ParseError struct {
    File    string `json:"file"`
    Line    int    `json:"line"`
    Message string `json:"message"`
}
```

#### 接口定义
```go
type SpecParser interface {
    ParseFromSource(sourcePath string) (*ParseResult, error)
}

type FileParser interface {
    CanParse(filename string) bool
    ParseFile(filepath string) ([]ServiceSpec, []ParseError)
}
```

#### 多语言支持策略

**重要说明**: Phase 1 的 ServiceSpec 断言语言完全基于 JSONLogic，提供强大的表达能力和良好的扩展性。所有断言部分（preconditions/postconditions）必须遵循有效的 JSON/YAML 格式，并能被 JSONLogic 引擎解析。

**容错处理策略**: 解析器对格式错误的注解块采用优雅降级策略：
- 跳过格式错误的注解块，继续处理其他正确的注解
- 在 ParseResult.Errors 中精确记录错误信息（文件路径、行号、具体错误）
- 确保单个文件的解析错误不影响整个项目的处理流程

**Java 文件解析**:
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

**TypeScript 文件解析**:
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

**Go 文件解析**:
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

### 3. TraceIngestor 模块 (internal/ingestor)

#### 职责
- 读取和解析 OpenTelemetry JSON 轨迹文件
- 将轨迹数据按 traceId 组织为易查询的内存结构
- 构建 span 之间的父子关系树
- 提供高效的 span 查询接口

#### 核心数据结构
```go
type TraceData struct {
    TraceID   string             `json:"traceId"`
    RootSpan  *Span             `json:"rootSpan"`
    Spans     map[string]*Span  `json:"spans"`
    SpanTree  *SpanNode         `json:"spanTree"`
}

type Span struct {
    SpanID     string                 `json:"spanId"`
    TraceID    string                 `json:"traceId"`
    ParentID   string                 `json:"parentSpanId,omitempty"`
    Name       string                 `json:"name"`
    StartTime  time.Time              `json:"startTime"`
    EndTime    time.Time              `json:"endTime"`
    Status     SpanStatus             `json:"status"`
    Attributes map[string]interface{} `json:"attributes"`
    Events     []SpanEvent            `json:"events"`
}

type SpanStatus struct {
    Code    string `json:"code"`    // "OK", "ERROR", "TIMEOUT"
    Message string `json:"message"`
}

type SpanEvent struct {
    Name       string                 `json:"name"`
    Timestamp  time.Time              `json:"timestamp"`
    Attributes map[string]interface{} `json:"attributes"`
}

type SpanNode struct {
    Span     *Span      `json:"span"`
    Children []*SpanNode `json:"children"`
}
```

#### 接口定义
```go
type TraceIngestor interface {
    IngestFromFile(tracePath string) (*TraceStore, error)
}

type TraceQuery interface {
    FindSpanByName(traceName string, spanName string) (*Span, error)
    FindSpansByOperationId(operationId string) ([]*Span, error)
    GetTraceByID(traceId string) (*TraceData, error)
}

// TraceStore 实现 TraceQuery 接口，作为 AlignmentEngine 的输入
type TraceStore struct {
    traces map[string]*TraceData
}

func (ts *TraceStore) FindSpanByName(traceName string, spanName string) (*Span, error)
func (ts *TraceStore) FindSpansByOperationId(operationId string) ([]*Span, error)
func (ts *TraceStore) GetTraceByID(traceId string) (*TraceData, error)
```

**设计说明**: TraceStore 实现 TraceQuery 接口，实现了完美的依赖倒置。AlignmentEngine 接收 TraceQuery 接口类型，便于单元测试中使用 Mock 对象，无需依赖真实的文件解析。

#### 内存优化策略
- 使用流式解析避免一次性加载整个文件到内存
- 实现 span 索引以提高查询效率
- 支持大文件的分块处理
- 提供内存使用监控和限制

### 4. AlignmentEngine 模块 (internal/engine)

#### 职责
- 执行 ServiceSpec 与 Trace 数据的对齐验证
- 使用 JSONLogic 评估断言表达式
- 生成详细的验证报告
- 管理验证上下文和变量作用域

#### 核心数据结构
```go
type AlignmentReport struct {
    Summary AlignmentSummary `json:"summary"`
    Results []AlignmentResult `json:"results"`
}

type AlignmentSummary struct {
    Total   int `json:"total"`
    Success int `json:"success"`
    Failed  int `json:"failed"`
    Skipped int `json:"skipped"`
}

type AlignmentResult struct {
    SpecOperationID string            `json:"specOperationId"`
    Status          AlignmentStatus   `json:"status"`
    Details         []ValidationDetail `json:"details"`
    ExecutionTime   time.Duration     `json:"executionTime"`
}

type AlignmentStatus string

const (
    StatusSuccess AlignmentStatus = "SUCCESS"
    StatusFailed  AlignmentStatus = "FAILED"
    StatusSkipped AlignmentStatus = "SKIPPED"
)

type ValidationDetail struct {
    Type        string      `json:"type"`        // "precondition" | "postcondition"
    Expression  string      `json:"expression"`
    Expected    interface{} `json:"expected"`
    Actual      interface{} `json:"actual"`
    Message     string      `json:"message"`
    SpanContext *Span       `json:"spanContext,omitempty"`
}
```

#### 接口定义
```go
type AlignmentEngine interface {
    Align(specs []ServiceSpec, traceQuery TraceQuery) (*AlignmentReport, error)
}

type AssertionEvaluator interface {
    EvaluatePreconditions(spec ServiceSpec, span *Span) ([]ValidationDetail, error)
    EvaluatePostconditions(spec ServiceSpec, span *Span) ([]ValidationDetail, error)
}
```

#### JSONLogic 集成策略

**表达式上下文设计**:
```go
type EvaluationContext struct {
    // Precondition 上下文
    Span struct {
        Attributes map[string]interface{} `json:"attributes"`
        StartTime  time.Time              `json:"startTime"`
        Name       string                 `json:"name"`
    } `json:"span"`
    
    // Postcondition 上下文 (包含 Precondition 的所有字段)
    EndTime time.Time   `json:"endTime,omitempty"`
    Status  SpanStatus  `json:"status,omitempty"`
    Events  []SpanEvent `json:"events,omitempty"`
}
```

**断言表达式示例**:
```json
{
  "preconditions": {
    "request_validation": {
      "and": [
        {"!=": [{"var": "span.attributes.http.method"}, null]},
        {"==": [{"var": "span.attributes.http.method"}, "POST"]}
      ]
    }
  },
  "postconditions": {
    "response_validation": {
      "and": [
        {"==": [{"var": "status.code"}, "OK"]},
        {">=": [{"var": "span.attributes.http.status_code"}, 200]},
        {"<": [{"var": "span.attributes.http.status_code"}, 300]}
      ]
    }
  }
}
```

### 5. ReportRenderer 模块 (internal/renderer)

#### 职责
- 将 AlignmentReport 渲染为人类可读格式
- 支持 JSON 和 Human 两种输出格式
- 管理退出码逻辑
- 提供进度反馈和日志输出

#### 接口定义
```go
type ReportRenderer interface {
    RenderHuman(report *AlignmentReport) (string, error)
    RenderJSON(report *AlignmentReport) (string, error)
    GetExitCode(report *AlignmentReport) int
}
```

#### Human 格式输出示例
```
FlowSpec 验证报告
==================================================

📊 汇总统计
  总计: 15 个 ServiceSpec
  ✅ 成功: 12 个
  ❌ 失败: 2 个  
  ⏭️  跳过: 1 个

🔍 详细结果
──────────────────────────────────────────────────

✅ createUser (SUCCESS)
   前置条件: ✅ 通过 (2/2)
   后置条件: ✅ 通过 (3/3)
   执行时间: 15ms

❌ updateUser (FAILED)
   前置条件: ✅ 通过 (1/1)
   后置条件: ❌ 失败 (1/2)
   
   失败详情:
   • 后置条件 'response_status_check' 失败
     期望: response.status == 200
     实际: response.status == 500
     Span: updateUser (trace: abc123, span: def456)
   
   执行时间: 23ms

⏭️ deleteUser (SKIPPED)
   原因: 未找到对应的 trace 数据

==================================================
验证结果: ❌ 失败 (2 个断言失败)
```

## 数据流设计

### 完整数据流程

1. **CLI 参数解析**
   ```
   用户输入 → 参数验证 → CLIConfig 对象
   ```

2. **ServiceSpec 解析**
   ```
   源码目录 → 文件扫描 → 注解提取 → JSON 转换 → ServiceSpec[]
   ```

3. **Trace 数据摄取**
   ```
   OTel JSON 文件 → 流式解析 → 数据组织 → TraceData Map
   ```

4. **对齐验证**
   ```
   ServiceSpec[] + TraceData Map → 断言评估 → AlignmentReport
   ```

5. **报告渲染**
   ```
   AlignmentReport → 格式化 → 终端输出 + 退出码
   ```

### 错误处理策略

- **解析错误**: 收集所有错误，继续处理其他文件，最后统一报告
- **验证错误**: 记录详细的失败信息，包含上下文和建议
- **系统错误**: 立即终止，返回明确的错误码和信息
- **资源限制**: 提供清晰的资源使用反馈和限制说明

## 测试策略

### 单元测试覆盖

- **SpecParser**: 测试各种语言的注解解析，边界情况处理，**特别包含格式错误注解的容错处理测试用例**
- **TraceIngestor**: 测试 OTel 格式解析，大文件处理，内存优化，TraceQuery 接口实现
- **AlignmentEngine**: 测试 JSONLogic 表达式评估，各种断言场景，使用 Mock TraceQuery 进行隔离测试
- **ReportRenderer**: 测试输出格式，退出码逻辑

### 集成测试场景

1. **成功场景**: 完整的端到端流程，所有断言通过
2. **前置条件失败**: ServiceSpec 前置条件不满足
3. **后置条件失败**: ServiceSpec 后置条件验证失败
4. **混合场景**: 部分成功、部分失败、部分跳过的复杂情况

### 性能测试

- **大规模解析**: 1,000 个源文件，200 个 ServiceSpecs，30 秒内完成
- **内存限制**: 100MB 轨迹文件，峰值内存不超过 500MB
- **并发安全**: 多线程环境下的数据一致性验证

## 错误处理

### 错误分类

1. **用户输入错误** (退出码 2)
   - 无效的命令行参数
   - 文件路径不存在
   - 文件格式错误

2. **解析错误** (退出码 2)
   - ServiceSpec 语法错误
   - OTel JSON 格式错误
   - 不支持的文件类型

3. **验证失败** (退出码 1)
   - 断言评估失败
   - 规约与轨迹不匹配

4. **系统错误** (退出码 2)
   - 内存不足
   - 文件权限问题
   - 网络连接问题

### 错误报告格式

```go
type Error struct {
    Code    string `json:"code"`
    Message string `json:"message"`
    Details string `json:"details,omitempty"`
    File    string `json:"file,omitempty"`
    Line    int    `json:"line,omitempty"`
}
```

## 性能优化

### 解析优化
- 并行文件扫描
- 增量解析缓存
- 智能文件过滤

### 内存优化
- 流式 JSON 解析
- 对象池复用
- 垃圾回收调优

### 查询优化
- Span 名称索引
- 操作 ID 映射表
- 时间范围索引

## 安全考虑

### 输入验证
- 文件路径遍历防护
- JSON 解析深度限制
- 表达式沙盒执行

### 资源限制
- 内存使用上限
- 文件大小限制
- 执行时间超时

### 错误信息安全
- 敏感信息过滤
- 路径信息脱敏
- 堆栈跟踪清理

这个设计文档为 FlowSpec Phase 1 MVP 提供了完整的技术架构和实现指导，确保所有组件都能按照需求规约正确实现，并为后续的开发工作提供了清晰的技术路线图。