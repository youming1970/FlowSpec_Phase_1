# 简单用户服务示例

这是一个基础的用户管理服务示例，展示了如何使用 FlowSpec CLI 验证简单的 CRUD 操作。

## 项目概述

本示例实现了一个简单的用户管理 API，包含以下操作：
- 创建用户 (`createUser`)
- 获取用户 (`getUser`)
- 更新用户 (`updateUser`)
- 删除用户 (`deleteUser`)

## 文件结构

```
simple-user-service/
├── README.md
├── src/
│   └── UserService.java
├── traces/
│   ├── success-scenario.json
│   ├── precondition-failure.json
│   └── postcondition-failure.json
├── scripts/
│   └── generate-traces.sh
└── expected-results/
    ├── success-report.json
    ├── precondition-failure-report.json
    └── postcondition-failure-report.json
```

## ServiceSpec 注解示例

### 创建用户

```java
/**
 * @ServiceSpec
 * operationId: "createUser"
 * description: "创建新用户账户"
 * preconditions: {
 *   "email_required": {"!=": [{"var": "span.attributes.request.body.email"}, null]},
 *   "email_format": {"match": [{"var": "span.attributes.request.body.email"}, "^[\\w\\.-]+@[\\w\\.-]+\\.[a-zA-Z]{2,}$"]},
 *   "password_length": {">=": [{"var": "span.attributes.request.body.password.length"}, 8]}
 * }
 * postconditions: {
 *   "success_status": {"==": [{"var": "span.attributes.http.status_code"}, 201]},
 *   "user_id_generated": {"!=": [{"var": "span.attributes.response.body.userId"}, null]},
 *   "email_returned": {"==": [{"var": "span.attributes.response.body.email"}, {"var": "span.attributes.request.body.email"}]}
 * }
 */
public User createUser(CreateUserRequest request) {
    // 实现逻辑
}
```

### 获取用户

```java
/**
 * @ServiceSpec
 * operationId: "getUser"
 * description: "根据用户ID获取用户信息"
 * preconditions: {
 *   "user_id_required": {"!=": [{"var": "span.attributes.request.params.userId"}, null]},
 *   "user_id_format": {"match": [{"var": "span.attributes.request.params.userId"}, "^[0-9]+$"]}
 * }
 * postconditions: {
 *   "success_or_not_found": {"in": [{"var": "span.attributes.http.status_code"}, [200, 404]]},
 *   "user_data_if_found": {
 *     "if": [
 *       {"==": [{"var": "span.attributes.http.status_code"}, 200]},
 *       {"and": [
 *         {"!=": [{"var": "span.attributes.response.body.userId"}, null]},
 *         {"!=": [{"var": "span.attributes.response.body.email"}, null]}
 *       ]},
 *       true
 *     ]
 *   }
 * }
 */
public User getUser(Long userId) {
    // 实现逻辑
}
```

## 运行示例

### 1. 成功场景验证

```bash
# 运行成功场景验证
flowspec-cli align \
  --path=./src \
  --trace=./traces/success-scenario.json \
  --output=human

# 预期输出：
# ✅ 所有 ServiceSpec 验证通过
# 📊 汇总: 4 个总计, 4 个成功, 0 个失败, 0 个跳过
```

### 2. 前置条件失败场景

```bash
# 运行前置条件失败场景
flowspec-cli align \
  --path=./src \
  --trace=./traces/precondition-failure.json \
  --output=human

# 预期输出：
# ❌ createUser 验证失败
# 前置条件 'password_length' 失败: 密码长度不足 8 位
```

### 3. 后置条件失败场景

```bash
# 运行后置条件失败场景
flowspec-cli align \
  --path=./src \
  --trace=./traces/postcondition-failure.json \
  --output=human

# 预期输出：
# ❌ createUser 验证失败
# 后置条件 'success_status' 失败: 期望状态码 201，实际 500
```

## 轨迹数据说明

### 成功场景轨迹

`traces/success-scenario.json` 包含了所有操作成功执行的轨迹数据：

```json
{
  "resourceSpans": [{
    "scopeSpans": [{
      "spans": [{
        "name": "createUser",
        "spanId": "abc123",
        "traceId": "trace001",
        "startTimeUnixNano": "1640995200000000000",
        "endTimeUnixNano": "1640995201000000000",
        "status": {"code": "STATUS_CODE_OK"},
        "attributes": [
          {"key": "http.method", "value": {"stringValue": "POST"}},
          {"key": "http.status_code", "value": {"intValue": 201}},
          {"key": "request.body.email", "value": {"stringValue": "user@example.com"}},
          {"key": "request.body.password.length", "value": {"intValue": 12}},
          {"key": "response.body.userId", "value": {"stringValue": "12345"}},
          {"key": "response.body.email", "value": {"stringValue": "user@example.com"}}
        ]
      }]
    }]
  }]
}
```

### 失败场景轨迹

失败场景的轨迹数据故意包含了不满足 ServiceSpec 断言的数据，用于测试验证逻辑。

## 学习要点

### 1. 断言表达式编写

- **简单比较**: `{"==": [value1, value2]}`
- **空值检查**: `{"!=": [value, null]}`
- **正则匹配**: `{"match": [string, pattern]}`
- **条件判断**: `{"if": [condition, then_value, else_value]}`

### 2. 变量路径

- **请求数据**: `span.attributes.request.body.*`
- **响应数据**: `span.attributes.response.body.*`
- **HTTP 信息**: `span.attributes.http.*`
- **时间信息**: `span.startTime`, `endTime`

### 3. 最佳实践

- 使用有意义的断言名称
- 编写清晰的错误消息
- 考虑边界情况和异常处理
- 保持断言表达式简洁

## 扩展练习

### 1. 添加新的 ServiceSpec

尝试为以下操作添加 ServiceSpec 注解：
- 批量创建用户
- 用户密码重置
- 用户状态更新

### 2. 复杂断言表达式

练习编写更复杂的断言：
- 多条件组合验证
- 数组数据验证
- 时间范围验证

### 3. 错误场景测试

创建更多的错误场景轨迹：
- 网络超时
- 数据库连接失败
- 权限验证失败

## 故障排除

### 常见问题

1. **ServiceSpec 未找到**
   - 检查 Java 文件中的注解格式
   - 确保注解在方法上方

2. **轨迹匹配失败**
   - 验证 Span 名称与 `operationId` 是否匹配
   - 检查轨迹文件格式是否正确

3. **断言评估错误**
   - 使用 JSONLogic 在线工具验证表达式
   - 检查变量路径是否存在

### 调试命令

```bash
# 详细输出模式
flowspec-cli align --path=./src --trace=./traces/success-scenario.json --verbose

# JSON 输出便于分析
flowspec-cli align --path=./src --trace=./traces/success-scenario.json --output=json | jq .

# 调试日志级别
flowspec-cli align --path=./src --trace=./traces/success-scenario.json --log-level=debug
```

---

这个示例为您提供了 FlowSpec CLI 的基础使用方法。掌握这些概念后，您可以继续学习更复杂的示例项目。