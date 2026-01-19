# Contributing to SBPL Toolchain

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## Getting Started

1. **Fork the repository** and clone your fork
2. **Install dependencies**:
   ```bash
   # Swift package (no external dependencies)
   swift build

   # VS Code extension (requires Bun)
   cd vscode-sbpl
   bun install
   ```
3. **Run tests** to ensure everything works:
   ```bash
   swift test
   ```

## Development Workflow

### Swift Package

The Swift package follows standard Swift Package Manager conventions:

```bash
# Build
swift build

# Test
swift test

# Build release
swift build -c release
```

### VS Code Extension

```bash
cd vscode-sbpl

# Install dependencies
bun install

# Type check
bun run typecheck

# Compile with Bun
bun run compile

# Watch for changes (uses tsc)
npm run watch

# Package extension
vsce package
```

To test the extension in development:
1. Open the `vscode-sbpl` folder in VS Code
2. Press `F5` to launch Extension Development Host
3. Open a `.sb` file to test features

## Code Style

### Swift

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use 2-space indentation
- Maximum line length: 120 characters
- All public APIs must have documentation comments
- Prefer `struct` over `class` unless reference semantics are needed
- Mark classes as `final` by default

### TypeScript

- Use TypeScript strict mode
- 2-space indentation
- Prefer `const` over `let`
- Use explicit types for function parameters and return values

## Commit Messages

Follow conventional commit format:

```
type(scope): short description

Longer description if needed.

Co-Authored-By: Your Name <email@example.com>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

## Pull Request Process

1. **Create a feature branch** from `main`:
   ```bash
   git checkout -b feat/my-feature
   ```

2. **Make your changes** with clear, focused commits

3. **Add tests** for new functionality

4. **Update documentation** if needed

5. **Run all tests** before submitting:
   ```bash
   swift test
   cd vscode-sbpl && npm run compile
   ```

6. **Submit a pull request** with:
   - Clear title describing the change
   - Description of what and why
   - Link to related issues (if any)

## Adding New Sandbox Operations

To add support for new sandbox operations:

1. **Update SBPLCore** (`Sources/SBPLCore/SandboxTypes/SandboxOperation.swift`):
   - Add the operation to the appropriate category

2. **Update the TextMate grammar** (`vscode-sbpl/syntaxes/sbpl.tmLanguage.json`):
   - Add the operation to the `operations` pattern

3. **Update autocompletion** (`vscode-sbpl/src/completion.ts`):
   - Add the operation to the `OPERATIONS` array with documentation

4. **Add tests** to verify the operation is recognized

## Reporting Issues

When reporting issues, please include:

- **Description** of the problem
- **Steps to reproduce**
- **Expected behavior**
- **Actual behavior**
- **Environment** (macOS version, Swift version, VS Code version)
- **Sample code** if applicable

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    VS Code Extension                      │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐  │
│  │   Syntax    │  │  Diagnostics │  │  Autocompletion│  │
│  │ Highlighting│  │   Provider   │  │    Provider    │  │
│  └─────────────┘  └──────┬───────┘  └────────────────┘  │
└──────────────────────────┼──────────────────────────────┘
                           │ stdin/stdout
                           ▼
┌─────────────────────────────────────────────────────────┐
│                     sbpl-convert CLI                      │
└──────────────────────────┬──────────────────────────────┘
                           │
┌──────────────────────────┼──────────────────────────────┐
│                    Swift Package                          │
│  ┌─────────────┐  ┌──────┴───────┐  ┌────────────────┐  │
│  │  SBPLCore   │◄─┤  SBPLParser  │◄─┤ SBPLConverter  │  │
│  │             │  │              │  │                │  │
│  └──────┬──────┘  └──────────────┘  └────────────────┘  │
│         │                                                 │
│  ┌──────┴──────┐                                         │
│  │  SBPLLexer  │                                         │
│  └─────────────┘                                         │
└─────────────────────────────────────────────────────────┘
```

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
