# 变更日志

本文档记录了 FlowSpec CLI 项目的所有重要变更。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [未发布]

### 新增
- 完整的项目文档套件
- Apache-2.0 开源许可证
- 贡献指南和开发文档

### 变更
- 优化 README.md 格式和内容
- 完善 Makefile 构建脚本

## [0.1.0] - 2024-01-XX (计划中)

### 新增
- 🎉 FlowSpec CLI Phase 1 MVP 首次发布
- 📝 多语言 ServiceSpec 解析器 (Java, TypeScript, Go)
- 📊 OpenTelemetry 轨迹数据摄取器
- ✅ JSONLogic 断言评估引擎
- 📋 Human 和 JSON 格式报告渲染器
- 🔧 完整的命令行接口
- 🧪 全面的测试套件 (单元测试 + 集成测试)
- 📖 完整的项目文档

### 功能特性
- **多语言支持**: 支持 Java、TypeScript、Go 源代码解析
- **轨迹处理**: 支持 OpenTelemetry JSON 格式轨迹数据
- **断言引擎**: 基于 JSONLogic 的强大断言表达式
- **报告生成**: 人类可读和机器可读的验证报告
- **性能优化**: 并行处理、流式解析、内存控制
- **容错处理**: 优雅的错误处理和恢复机制

### 性能基准
- 解析性能: 1,000 个源文件，200 个 ServiceSpecs，< 30 秒
- 内存使用: 100MB 轨迹文件，峰值内存 < 500MB
- 测试覆盖率: 核心模块 > 80%

### 技术栈
- **语言**: Go 1.21+
- **CLI 框架**: Cobra
- **断言引擎**: JSONLogic
- **日志系统**: Logrus
- **测试框架**: Go testing + Testify

## 开发历程

### Phase 1 开发里程碑

#### 2024-01-XX - 项目启动
- 项目初始化和架构设计
- 核心数据模型定义
- 开发环境搭建

#### 2024-01-XX - 解析器开发
- Java 文件解析器实现
- TypeScript 文件解析器实现
- Go 文件解析器实现
- 多语言解析器集成

#### 2024-01-XX - 轨迹摄取器开发
- OpenTelemetry JSON 解析器
- 轨迹数据组织和索引
- 大文件处理和内存优化
- 流式解析实现

#### 2024-01-XX - 对齐引擎开发
- JSONLogic 断言评估引擎
- 规约与轨迹匹配逻辑
- 验证上下文构建
- 断言失败详情收集

#### 2024-01-XX - CLI 和报告系统
- 命令行接口实现
- Human 格式报告渲染
- JSON 格式报告输出
- 退出码管理

#### 2024-01-XX - 测试和质量保证
- 单元测试套件完成
- 集成测试场景实现
- 性能和压力测试
- 代码覆盖率达标

#### 2024-01-XX - 文档和开源准备
- 完整项目文档编写
- 开源许可证添加
- 贡献指南制定
- 发布准备完成

## 已知问题

### 当前版本限制
- 仅支持 OpenTelemetry JSON 格式轨迹数据
- ServiceSpec 断言语言限制为 JSONLogic
- 不支持实时轨迹流处理
- 暂无 Web UI 界面

### 计划修复
这些限制将在后续版本中逐步解决。

## 路线图

### Phase 2 (计划中)
- [ ] 支持更多编程语言 (Python, C#, Rust)
- [ ] 实时轨迹流处理
- [ ] 性能分析和优化建议
- [ ] 更丰富的断言表达式语法

### Phase 3 (计划中)
- [ ] Web UI 界面
- [ ] 分布式验证支持
- [ ] 插件系统
- [ ] 云原生集成

### 长期规划
- [ ] 机器学习驱动的异常检测
- [ ] 自动化测试生成
- [ ] 服务依赖图可视化
- [ ] 多云平台支持

## 贡献者

感谢所有为 FlowSpec CLI 做出贡献的开发者：

- [@contributor1](https://github.com/contributor1) - 项目发起人和主要开发者
- [@contributor2](https://github.com/contributor2) - 解析器模块开发
- [@contributor3](https://github.com/contributor3) - 测试和文档

## 致谢

特别感谢以下开源项目和社区：

- [Cobra](https://github.com/spf13/cobra) - 强大的 CLI 框架
- [JSONLogic](https://jsonlogic.com/) - 灵活的断言表达式引擎
- [OpenTelemetry](https://opentelemetry.io/) - 可观测性标准
- [Logrus](https://github.com/sirupsen/logrus) - 结构化日志库
- [Testify](https://github.com/stretchr/testify) - 测试工具包

## 许可证变更

- **2024-01-XX**: 项目采用 Apache-2.0 许可证开源

## 安全更新

目前没有安全相关的更新。如果发现安全问题，请发送邮件到 security@example.com。

---

**注意**: 
- 所有日期为计划日期，实际发布时间可能有所调整
- 功能特性可能根据用户反馈进行调整
- 我们承诺在主要版本发布前保持向后兼容性

如果您有任何问题或建议，欢迎在 [GitHub Issues](../../issues) 中提出。