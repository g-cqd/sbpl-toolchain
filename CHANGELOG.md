# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-01-18

### Added

#### Swift Package
- **SBPLCore**: Core types for source locations, diagnostics, and sandbox types
  - `SourcePosition`, `SourceRange`, `SourceFile` with LSP-compatible UTF-16 columns
  - `Diagnostic`, `DiagnosticCode`, `DiagnosticCollector` for error reporting
  - `SandboxOperation`, `FilterType`, `SandboxAction` type definitions

- **SBPLLexer**: Complete tokenizer for SBPL
  - Support for all token types: symbols, strings, raw strings, integers, booleans
  - Trivia preservation (whitespace, comments)
  - Error recovery for malformed input
  - Block and line comment support

- **SBPLParser**: Recursive descent parser
  - Full AST representation: `Profile`, `Rule`, `Filter`, `Expr`, declarations
  - Support for compound filters: `require-all`, `require-any`, `require-not`
  - Error recovery with synchronization
  - Precise source range tracking

- **SBPLConverter**: Bidirectional conversion
  - `SBPLToJSON`: Parse and convert SBPL to JSON
  - `JSONToSBPL`: Convert JSON back to SBPL source
  - Round-trip tested

- **CLI Tools**
  - `sbpl-lex`: Tokenize SBPL files (debugging tool)
  - `sbpl-convert`: Check syntax, convert between formats
  - Support for stdin input with `-` argument

#### VS Code Extension
- **Syntax Highlighting**: Full TextMate grammar
  - Keywords, operations, filters, strings, comments
  - 100+ sandbox operations recognized

- **Real-time Diagnostics**
  - Error and warning display via `sbpl-convert`
  - Automatic validation on document changes

- **Autocompletion**
  - Context-aware suggestions
  - Snippets with placeholders
  - Documentation for all completions

- **Commands**
  - `SBPL: Check Syntax`
  - `SBPL: Convert to JSON`

### Technical Details
- Swift 6.0+ with strict concurrency
- macOS 14+, iOS 17+ platform support
- VS Code 1.85+ compatibility
- Comprehensive test suite (83 tests)

[Unreleased]: https://github.com/g-cqd/sbpl-toolchain/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/g-cqd/sbpl-toolchain/releases/tag/v0.1.0
