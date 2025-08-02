好的，我们已经圆满完成了 Phase 0 的 PoC 验证，证明了 FlowSpec 核心理念的可行性与价值。现在，我们将正式启动 **Phase 1**，其核心目标是交付一个可供开源社区使用的 **MVP (Minimum Viable Product)**。

为了确保 Phase 1 的执行过程清晰、高效且成果精确，我们将严格遵循 FlowSpec 的核心原则，将本次开发计划本身也视为一个需要被“规约”和“编排”的系统。

-----

### **FlowSpec Phase 1 实施规划与设计规约**

本文件旨在为 Phase 1 的所有开发活动提供一个统一的、可执行的“唯一真相来源”。

#### **一、 指导原则 (Guiding Principles)**

我们将采用“**吃自己的狗粮 (Eating Your Own Dog Food)**”策略。整个 Phase 1 的开发过程将围绕我们为最终产出物所定义的 `FlowSpec` 和 `ServiceSpec` 来组织。这意味着：

1.  **规约先行 (Specification First)**: 我们首先为 Phase 1 需要交付的核心软件组件定义清晰的 `ServiceSpec`（行为契约）。
2.  **流程驱动 (Flow Driven)**: 我们将通过一个顶层的 `FlowSpec` 来描述这些组件如何被最终的 MVP CLI 工具编排，以完成其核心功能。
3.  **持续验证 (Continuous Validation)**: 每个组件的开发都必须满足其 `ServiceSpec` 中定义的“后置条件”，并通过自动化测试来保证。

#### **二、Phase 1 宏观 `FlowSpec`：定义 MVP 的核心用户流程**

在着手开发任何代码之前，我们首先定义 Phase 1 MVP 交付物——一个名为 `flowspec-cli` 的命令行工具——其核心业务流程的规约。

  * **文件**: `phase1_mvp.flowspec.yaml`
  * **目的**: 该规约描述了用户使用 MVP CLI 完成一次“Trace 对齐校验”的完整端到端流程。它是我们 Phase 1 的最终目标。

<!-- end list -->

```yaml
# phase1_mvp.flowspec.yaml
info:
  title: "MVP CLI 核心流程：基于 OTel Trace 的 ServiceSpec 对齐校验"
  version: "1.0.0"

# 定义本次流程涉及的“服务”，在这里，它们是我们待开发的“软件模块”
services:
  specParser: { spec: "./specs/spec-parser.spec.yaml" }
  traceIngestor: { spec: "./specs/trace-ingestor.spec.yaml" }
  alignmentEngine: { spec: "./specs/alignment-engine.spec.yaml" }

# 核心流程编排
flow:
  - step: "1. 解析代码库中的 ServiceSpec"
    call: specParser.parseFromSource
    input:
      sourcePath: "${cli.args.path}"  # 从 CLI 参数接收代码库路径
    output: { parsedSpecs: response.body }
    preconditions:
      - "输入路径必须存在且可读"
    postconditions:
      - "输出必须是结构化的 ServiceSpec 对象数组"

  - step: "2. 摄取 OpenTelemetry Trace 数据"
    call: traceIngestor.ingestFromFile
    input:
      tracePath: "${cli.args.trace}" # 从 CLI 参数接收 Trace 文件路径
    output: { structuredTraces: response.body }
    preconditions:
      - "输入的 Trace 文件必须是合法的 OTel JSON 格式"
    postconditions:
      - "输出必须是按 traceId 组织的结构化 Span 树"

  - step: "3. 执行 Trace 与 Spec 的对齐校验"
    call: alignmentEngine.align
    input:
      specs: "${parsedSpecs}"
      traces: "${structuredTraces}"
    output: { alignmentReport: response.body }
    postconditions:
      - "报告必须明确指出每个 Spec 的校验状态 (SUCCESS, FAILED, SKIPPED)"
      - "对于 FAILED 的情况，必须提供不匹配的具体断言和相关 Trace 证据"

  - step: "4. 输出校验报告"
    # 此步骤由 CLI 本身实现，非调用外部服务
    action: "cli.renderReport"
    input:
      report: "${alignmentReport}"
```

-----

#### **三、核心组件 `ServiceSpec`：定义开发任务的行为契约**

现在，我们为上述 `FlowSpec` 中引用的每一个“服务”（即待开发的软件模块）提供详细的 `ServiceSpec`。这将是各开发任务的具体需求和验收标准。

##### **1. `spec-parser` (规约解析器)**

  * **目标**: 从源代码文件中发现并解析 `@ServiceSpec` 注解，将其转换为结构化的 JSON 对象。
  * **位置**: `src/modules/parser/`
  * **语言**: TypeScript

<!-- end list -->

```java
/**
 * @ServiceSpec
 * operationId: "parseFromSource"
 * description: "递归扫描指定目录下的所有源文件（.java, .ts, .go），提取所有`@ServiceSpec`注解并解析为结构化对象。"
 *
 * preconditions: {
 * "输入路径`sourcePath`必须是一个存在的目录": "fs.existsSync(request.sourcePath) && fs.statSync(request.sourcePath).isDirectory()"
 * }
 *
 * postconditions: {
 * "返回体必须是一个数组": "Array.isArray(response.body)",
 * "数组中每个元素都必须包含`operationId`字段": "response.body.every(spec => spec.hasOwnProperty('operationId'))",
 * "解析出的`preconditions`和`postconditions`必须被转换为结构化断言对象": "response.body.every(spec => typeof spec.preconditions === 'object')"
 * }
 */
public SpecObject[] parseFromSource(ParseRequest request);
```

##### **2. `trace-ingestor` (Trace 摄取器)**

  * **目标**: 读取并解析标准的 OpenTelemetry JSON 文件。
  * **位置**: `src/modules/ingestor/`
  * **语言**: Go

<!-- end list -->

```java
/**
 * @ServiceSpec
 * operationId: "ingestFromFile"
 * description: "读取一个包含 OpenTelemetry trace 数据的 JSON 文件，并将其转换为按 traceId 归类的、易于查询的内存结构。"
 *
 * preconditions: {
 * "输入路径`tracePath`必须是一个存在的 JSON 文件": "fs.existsSync(request.tracePath) && path.extname(request.tracePath) === '.json'",
 * "文件内容必须是合法的 JSON": "try { JSON.parse(fs.readFileSync(request.tracePath)); return true; } catch { return false; }"
 * }
 *
 * postconditions: {
 * "返回的 Map 的键必须是`traceId`字符串": "Object.keys(response.body).every(key => typeof key === 'string' && key.length > 0)",
 * "返回的 Map 的值必须是一个包含`rootSpan`和`spans`数组的 Trace 对象": "Object.values(response.body).every(trace => trace.hasOwnProperty('rootSpan') && Array.isArray(trace.spans))"
 * }
 */
public Map<TraceId, TraceObject> ingestFromFile(IngestRequest request);
```

##### **3. `alignment-engine` (对齐引擎)**

  * **目标**: Phase 1 的核心逻辑。比对 `ServiceSpec` 的断言与 `Trace` 的实际执行轨迹。
  * **位置**: `src/modules/aligner/`
  * **语言**: Go

<!-- end list -->

```java
/**
 * @ServiceSpec
 * operationId: "align"
 * description: "核心对齐逻辑。对于每一个`ServiceSpec`，在`traces`中找到对应的 Span，并根据规约中的前置/后置条件进行断言校验。"
 *
 * preconditions: {
 * "输入`specs`必须是有效的 SpecObject 数组": "Array.isArray(request.specs)",
 * "输入`traces`必须是有效的 TraceObject Map": "typeof request.traces === 'object'"
 * }
 *
 * postconditions: {
 * "报告中的`summary`字段必须包含总数、成功数、失败数": "response.body.summary.total === request.specs.length",
 * "报告中的`results`数组长度必须等于输入的 spec 数量": "response.body.results.length === request.specs.length",
 * "每个`result`对象必须包含`specOperationId`和`status`字段": "response.body.results.every(r => r.hasOwnProperty('specOperationId') && r.hasOwnProperty('status'))",
 * "对于失败的`result`，`details`字段必须提供不匹配的断言和相关 Span 数据": "response.body.results.filter(r => r.status === 'FAILED').every(r => r.details.length > 0)"
 * }
 */
public AlignmentReport align(AlignmentRequest request);
```

-----

#### **四、实施细节与要求**

1.  [cite\_start]**`ServiceSpec` DSL v1.0 最终确定** [cite: 141, 180-189]

      * **语法**: 严格遵循白皮书附录中的 BNF 草案。
      * [cite\_start]**断言表达式 (`Expr`)**: Phase 1 MVP 将采用 **JSONLogic** [cite: 124] 作为断言表达式语言。它具备良好的沙盒能力、易于解释执行，且有成熟的 Go 和 TS 实现。
      * **表达式上下文**:
          * `preconditions`: 可访问 `Span` 的 `attributes` 和 `startTime`。
          * `postconditions`: 可访问 `Span` 的 `attributes`, `endTime`, `status` (e.g., `OK`, `ERROR`) 以及 `events`。

2.  **`flowspec-cli` 设计**

      * **语言**: Go
      * **命令结构**:
        ```bash
        # 主命令
        flowspec-cli align --path=./my-project --trace=./traces/run-1.json --output=human # or json

        # 帮助
        flowspec-cli --help
        flowspec-cli align --help
        ```
      * **功能**:
          * 解析命令行参数。
          * 按照 `phase1_mvp.flowspec.yaml` 中定义的流程，依次调用内部模块（Parser, Ingestor, Aligner）。
          * 管理模块间的数据流转。
          * 根据 `--output` 参数，将最终的 `alignmentReport` 渲染为人类可读的终端格式或纯 JSON。

3.  [cite\_start]**开源准备工作 (MVP 开源)** [cite: 141, 126]

      * **代码仓库**: 在 GitHub 创建 `flowspec/flowspec-cli` 公开仓库。
      * [cite\_start]**协议**: 必须包含 `LICENSE` 文件，内容为 **Apache-2.0** [cite: 126]。
      * **文档**:
          * `README.md`: 清晰说明项目是什么、解决什么问题、如何安装和使用 `flowspec-cli`。
          * `CONTRIBUTING.md`: 贡献指南，包括开发环境设置、行为准则、PR 流程。
      * **CI/CD**:
          * 使用 GitHub Actions。
          * 必须包含 `build`, `lint`, `test` 三个阶段。
          * 每一次向 `main` 分支的合并，都必须通过所有检查。

#### **五、Phase 1 验收标准 (Definition of Done)**

当且仅当以下所有条件被满足时，Phase 1 方可被视为完成：

  * **[ ] 功能完备**:
      * `flowspec-cli` 可执行，并能成功完成 `align` 命令的完整流程。
      * 成功解析 Java 源代码中的 `@ServiceSpec` 注解。
      * 成功摄取 OTel Collector 输出的 JSON 格式 Trace。
      * 能正确识别 Trace 与 Spec 的匹配、不匹配（断言失败）和未找到 Trace 三种状态。
  * **[ ] 质量保证**:
      * 核心模块（Parser, Ingestor, Aligner）的单元测试覆盖率 \>= 80%。
      * 提供至少 3 个端到端集成测试用例（成功、前置条件失败、后置条件失败），并通过 CI 验证。
  * **[ ] 开源就绪**:
      * 所有代码已推送至公开的 GitHub 仓库。
      * `LICENSE`, `README.md`, `CONTRIBUTING.md` 文件已按要求创建并填充内容。
      * CI/CD 流水线工作正常。

这份规划文件就是我们 Phase 1 的“规约”。请以此为基准，将任务分解到具体的开发周期中，并以此作为代码设计、评审和最终验收的依据。