# FlowSpec CLI

[![Go Version](https://img.shields.io/badge/Go-1.21+-00ADD8?style=flat&logo=go)](https://golang.org/)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen.svg)](#)
[![Coverage](https://img.shields.io/badge/Coverage-80%25+-brightgreen.svg)](#)

FlowSpec CLI is a powerful command-line tool for parsing ServiceSpec annotations from source code, ingesting OpenTelemetry traces, and performing alignment validation between specifications and actual execution traces. It helps developers discover service integration issues early in the development cycle, ensuring the reliability of microservice architectures.

## Project Status

🚧 **In Development** - This is the implementation of FlowSpec Phase 1 MVP and is currently under active development.

## Core Value

- 🔍 **Early Problem Detection**: Discover service integration issues during the development phase.
- 📝 **Code as Documentation**: ServiceSpec annotations are embedded directly in the source code, keeping them in sync.
- 🌐 **Multi-Language Support**: Supports mainstream languages like Java, TypeScript, and Go.
- 🚀 **CI/CD Integration**: Easily integrates into continuous integration workflows.
- 📊 **Detailed Reports**: Provides human-readable and machine-readable validation reports.

## Features

- 📝 Parse ServiceSpec annotations from multi-language source code (Java, TypeScript, Go).
- 📊 Ingest and process OpenTelemetry trace data.
- ✅ Perform alignment validation between specifications and actual traces.
- 📋 Generate detailed validation reports (Human and JSON formats).
- 🔧 Supports a command-line interface for easy integration into CI/CD pipelines.

## Quick Start

### Installation

#### Using go install (Recommended)

```bash
go install github.com/FlowSpec/flowspec-cli/cmd/flowspec-cli@latest
```

#### Build from Source

```bash
# Clone the repository
git clone https://github.com/FlowSpec/flowspec-cli.git
cd flowspec-cli

# Install dependencies
make deps

# Build
make build

# Install to GOPATH
make install
```

#### Download Pre-compiled Binaries

Visit the [Releases](https://github.com/FlowSpec/flowspec-cli/releases) page to download pre-compiled binaries for your platform.

### Verify Installation

```bash
flowspec-cli --version
flowspec-cli --help
```

## Usage

### Basic Usage

```bash
# Perform alignment validation
flowspec-cli align --path=./my-project --trace=./traces/run-1.json --output=human

# JSON format output
flowspec-cli align --path=./my-project --trace=./traces/run-1.json --output=json

# Verbose output
flowspec-cli align --path=./my-project --trace=./traces/run-1.json --output=human --verbose
```

### Command Options

- `--path, -p`: Source code directory path (default: ".")
- `--trace, -t`: OpenTelemetry trace file path (required)
- `--output, -o`: Output format (human|json, default: "human")
- `--verbose, -v`: Enable verbose output
- `--log-level`: Set log level (debug, info, warn, error)

## ServiceSpec Annotation Format

FlowSpec supports ServiceSpec annotations in various programming languages:

### Java

```java
/**
 * @ServiceSpec
 * operationId: "createUser"
 * description: "Create a new user account"
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
 * description: "Create a new user account"
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
// description: "Create a new user account"
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

## Development

### Prerequisites

- Go 1.21 or higher
- Make (optional, for build scripts)

### Build and Test

This project uses `make` to simplify common development tasks.

```bash
# Install or update dependencies
make deps

# Run all quality checks (formatting, vetting, linting)
make quality

# Run all unit tests
make test

# Run tests and generate a coverage report
make coverage

# Build the development binary
make build

# Remove all build artifacts and caches
make clean

# Run all CI checks locally (quality, tests, coverage, build)
make ci
```

### Project Structure

```
flowspec-cli/
├── cmd/flowspec-cli/     # CLI entry point
├── internal/             # Internal packages
│   ├── parser/          # ServiceSpec parser
│   ├── ingestor/        # OpenTelemetry trace ingestor
│   ├── engine/          # Alignment validation engine
│   └── renderer/        # Report renderer
├── testdata/            # Test data
├── build/               # Build output
└── Makefile            # Build scripts
```

## Example Projects

Check out the example projects in the [examples](examples/) directory to learn how to use FlowSpec CLI in a real project.

## Documentation

- 📖 [API Documentation](docs/en/API.md) - Detailed API interface documentation
- 🏗️ [Architecture Document](docs/en/ARCHITECTURE.md) - Technical architecture and design decisions
- 🤝 [Contribution Guide](CONTRIBUTING.md) - How to participate in project development
- 📋 [Changelog](CHANGELOG.md) - Version update history

## Performance Benchmarks

- **Parsing Performance**: 1,000 source files, 200 ServiceSpecs, < 30 seconds
- **Memory Usage**: 100MB trace file, peak memory < 500MB
- **Test Coverage**: Core modules > 80%

## Roadmap

- [ ] Support for more programming languages (Python, C#, Rust)
- [ ] Real-time trace stream processing
- [ ] Web UI interface
- [ ] Performance analysis and optimization suggestions
- [ ] Integration test automation

## Contribution

We welcome contributions of all forms! Please check out [CONTRIBUTING.md](CONTRIBUTING.md) to learn how to get involved.

### Contributors

Thank you to all the developers who have contributed to the FlowSpec CLI!

## License

This project is licensed under the Apache-2.0 License. See the [LICENSE](LICENSE) file for details.

## Support

If you encounter problems or have questions, please:

1. 📚 Check the [Documentation](https://github.com/FlowSpec/flowspec_cli/tree/main/docs/en) and [FAQ](https://github.com/FlowSpec/flowspec_cli/blob/main/docs/en/FAQ.md)
2. 🔍 Search existing [GitHub Issues](https://github.com/FlowSpec/flowspec_cli/issues)
3. 💬 Participate in [GitHub Discussions](https://github.com/FlowSpec/flowspec_cli/discussions)
4. 🐛 [Create a new Issue](https://github.com/FlowSpec/flowspec_cli/issues/new/choose) to describe your problem

## Community

- 💬 [GitHub Discussions](https://github.com/FlowSpec/flowspec_cli/discussions) - Discussions and Q&A
- 🐛 [GitHub Issues](https://github.com/FlowSpec/flowspec_cli/issues) - Bug reports and feature requests
- 📧 [Mailing List](mailto:youming@flowspec.org) - Project announcements
- 💬 [Discord Community](https://discord.gg/8zD56fYN) - Real-time communication

---

**Note**: This is a project under active development, and APIs and features may change. We will maintain backward compatibility before major version releases.

⭐ If you find this project helpful, please give us a Star!

---
**Disclaimer**: This project is supported and maintained by FlowSpec.