# SBPL Toolchain

A complete toolchain for Apple's **Sandbox Profile Language (SBPL)** — the configuration language used by macOS and iOS to define application sandbox rules.

## Features

- **Lexer & Parser**: Full syntax analysis with error recovery and precise diagnostics
- **Bidirectional Conversion**: Convert between SBPL and JSON formats
- **VS Code Extension**: Syntax highlighting, real-time diagnostics, and autocompletion
- **CLI Tools**: Command-line utilities for validation and conversion

## Installation

### Swift Package

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/g-cqd/sbpl-toolchain.git", from: "0.1.0")
]
```

Available products:
- `SBPLCore` — Core types (diagnostics, source locations, sandbox types)
- `SBPLLexer` — Tokenizer with trivia preservation
- `SBPLParser` — Recursive descent parser producing AST
- `SBPLConverter` — SBPL ↔ JSON conversion

### CLI Tools

```bash
# Build from source
swift build -c release

# Install globally (optional)
cp .build/release/sbpl-convert /usr/local/bin/
cp .build/release/sbpl-lex /usr/local/bin/
```

### VS Code Extension

```bash
cd vscode-sbpl
bun install
bun run compile
vsce package
code --install-extension sbpl-language-*.vsix
```

Or install from the VS Code Marketplace (coming soon).

## Usage

### CLI: Syntax Checking

```bash
# Check a sandbox profile
sbpl-convert check profile.sb

# Check from stdin
cat profile.sb | sbpl-convert check -
```

### CLI: Format Conversion

```bash
# SBPL to JSON
sbpl-convert to-json profile.sb > profile.json

# JSON to SBPL
sbpl-convert to-sbpl profile.json > profile.sb
```

### Swift API

```swift
import SBPLParser
import SBPLConverter

// Parse SBPL source
let parser = Parser(source: sbplSource)
let (profile, diagnostics) = parser.parse()

// Check for errors
for diagnostic in diagnostics where diagnostic.severity == .error {
    print("\(diagnostic.range.start.line):\(diagnostic.range.start.column): \(diagnostic.message)")
}

// Convert to JSON
let converter = SBPLToJSON()
let result = converter.convert(source: sbplSource)
```

### VS Code

The extension provides:

| Feature | Description |
|---------|-------------|
| Syntax Highlighting | Full TextMate grammar for `.sb` and `.sbpl` files |
| Diagnostics | Real-time error and warning highlighting |
| Autocompletion | Context-aware suggestions for keywords, operations, and filters |
| Commands | `SBPL: Check Syntax`, `SBPL: Convert to JSON` |

## SBPL Overview

SBPL (Sandbox Profile Language) is a Scheme-like DSL used by Apple's sandbox system. Profiles define what operations an application is allowed or denied.

```scheme
(version 1)

(debug deny)

(import "system.sb")

; Deny everything by default
(deny default)

; Allow reading from /usr
(allow file-read-data
  (subpath "/usr"))

; Allow specific Mach services
(allow mach-lookup
  (global-name "com.apple.system.logger"))

; Compound filters
(allow file-read-data
  (require-all
    (subpath "/Library")
    (require-not
      (subpath "/Library/Preferences"))))
```

### Key Concepts

- **Rules**: `(allow ...)` or `(deny ...)` — permit or block operations
- **Operations**: `file-read-data`, `mach-lookup`, `network-outbound`, etc.
- **Filters**: `literal`, `subpath`, `regex`, `global-name`, `require-all`, `require-any`, `require-not`
- **Declarations**: `version`, `debug`, `import`, `define`

## Project Structure

```
sbpl-toolchain/
├── Sources/
│   ├── SBPLCore/           # Core types and diagnostics
│   ├── SBPLLexer/          # Tokenizer
│   ├── SBPLParser/         # Parser and AST
│   ├── SBPLConverter/      # JSON conversion
│   ├── sbpl-lex/           # Lexer CLI
│   └── sbpl-convert/       # Converter CLI
├── Tests/
│   ├── SBPLCoreTests/
│   ├── SBPLLexerTests/
│   ├── SBPLParserTests/
│   └── SBPLConverterTests/
├── vscode-sbpl/            # VS Code extension
├── examples/               # Example sandbox profiles
└── Fixtures/               # Test fixtures
```

## Requirements

- **Swift**: 6.2+
- **Platforms**: macOS 14+, iOS 17+
- **VS Code**: 1.85+ (for extension)
- **Bun**: 1.0+ (for extension development)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License — see [LICENSE](LICENSE) for details.

## Acknowledgments

- Apple's sandbox documentation and system profiles
- The Swift community for excellent tooling
