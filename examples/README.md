# FlowSpec CLI 示例项目

本目录包含了使用 FlowSpec CLI 的示例项目，展示了如何在不同语言和场景中使用 ServiceSpec 注解。

## 示例列表

### 1. [简单用户服务](simple-user-service/)
- **语言**: Java
- **场景**: 基本的 CRUD 操作
- **特点**: 展示基础的前置条件和后置条件

### 2. [电商订单服务](ecommerce-order-service/)
- **语言**: TypeScript
- **场景**: 复杂的业务逻辑验证
- **特点**: 多步骤流程验证，错误处理

### 3. [微服务网关](microservice-gateway/)
- **语言**: Go
- **场景**: 服务间通信验证
- **特点**: 分布式轨迹验证，性能监控

### 4. [多语言混合项目](polyglot-project/)
- **语言**: Java + TypeScript + Go
- **场景**: 多语言项目集成
- **特点**: 跨语言服务验证

## 快速开始

### 运行示例

```bash
# 进入示例目录
cd examples/simple-user-service

# 运行 FlowSpec 验证
flowspec-cli align \
  --path=./src \
  --trace=./traces/success-scenario.json \
  --output=human

# 查看 JSON 格式报告
flowspec-cli align \
  --path=./src \
  --trace=./traces/success-scenario.json \
  --output=json
```

### 生成轨迹数据

每个示例项目都包含了生成轨迹数据的脚本：

```bash
# 运行应用并生成轨迹
./scripts/generate-traces.sh

# 查看生成的轨迹文件
ls -la traces/
```

## 示例场景

### 成功场景
- 所有 ServiceSpec 断言都通过
- 展示正常的业务流程验证

### 失败场景
- 前置条件失败
- 后置条件失败
- 混合场景（部分成功，部分失败）

### 边界情况
- 缺失轨迹数据
- 格式错误的注解
- 性能压力测试

## 学习路径

### 初学者
1. 从 [简单用户服务](simple-user-service/) 开始
2. 理解基本的 ServiceSpec 注解格式
3. 学习如何编写简单的断言表达式

### 进阶用户
1. 查看 [电商订单服务](ecommerce-order-service/) 的复杂业务逻辑
2. 学习 JSONLogic 的高级用法
3. 了解错误处理和边界情况

### 高级用户
1. 研究 [微服务网关](microservice-gateway/) 的分布式验证
2. 学习性能优化技巧
3. 探索 [多语言混合项目](polyglot-project/) 的集成方案

## 最佳实践

### ServiceSpec 注解编写
- 使用有意义的 `operationId`
- 编写清晰的 `description`
- 保持断言表达式简洁明了
- 考虑边界情况和错误处理

### 轨迹数据生成
- 确保 Span 名称与 `operationId` 匹配
- 包含足够的属性信息用于断言
- 记录完整的请求和响应数据
- 保持轨迹数据的时间顺序

### 项目集成
- 将 FlowSpec 验证集成到 CI/CD 流程
- 定期更新轨迹数据
- 监控验证结果趋势
- 建立验证失败的处理流程

## 故障排除

### 常见问题

1. **找不到 ServiceSpec**
   - 检查文件路径和扩展名
   - 验证注解格式是否正确

2. **轨迹匹配失败**
   - 确保 `operationId` 与 Span 名称匹配
   - 检查轨迹数据的完整性

3. **断言评估错误**
   - 验证 JSONLogic 表达式语法
   - 检查变量路径是否正确

### 调试技巧

```bash
# 启用详细输出
flowspec-cli align --path=./src --trace=./trace.json --verbose

# 使用调试日志级别
flowspec-cli align --path=./src --trace=./trace.json --log-level=debug

# 检查解析结果
flowspec-cli align --path=./src --trace=./trace.json --output=json | jq .
```

## 贡献示例

我们欢迎贡献新的示例项目！请遵循以下指南：

### 示例项目结构
```
example-name/
├── README.md           # 示例说明
├── src/               # 源代码
├── traces/            # 轨迹数据文件
├── scripts/           # 辅助脚本
└── expected-results/  # 预期验证结果
```

### 提交要求
- 包含完整的 README.md 说明
- 提供多种场景的轨迹数据
- 包含预期的验证结果
- 添加必要的注释和文档

## 反馈和建议

如果您对示例有任何建议或发现问题，请：

1. 在 [GitHub Issues](../../../issues) 中报告问题
2. 在 [GitHub Discussions](../../../discussions) 中讨论改进建议
3. 提交 Pull Request 贡献新的示例

---

**提示**: 这些示例会随着 FlowSpec CLI 的发展而持续更新，建议定期查看最新版本。