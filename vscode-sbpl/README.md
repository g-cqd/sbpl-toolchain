# SBPL Language Support for VS Code

[![VS Code Marketplace](https://img.shields.io/badge/VS%20Code-Marketplace-blue?logo=visual-studio-code)](https://marketplace.visualstudio.com/items?itemName=sbpl-toolchain.sbpl-language)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Syntax highlighting, real-time diagnostics, and intelligent autocompletion for Apple **Sandbox Profile Language (SBPL)** files.

![SBPL Extension Demo](images/demo.png)

## Features

### Syntax Highlighting

Full TextMate grammar support for `.sb` and `.sbpl` files:

- **Keywords**: `version`, `debug`, `import`, `define`, `allow`, `deny`
- **Filters**: `require-all`, `require-any`, `require-not`, `literal`, `subpath`, `regex`, `global-name`, etc.
- **Operations**: 100+ sandbox operations (`file-read-data`, `mach-lookup`, `network*`, etc.)
- **Literals**: Strings, raw strings (`#"..."`), booleans (`#t`, `#f`), integers
- **Comments**: Line (`;`) and block (`#| ... |#`)

### Real-time Diagnostics

Syntax checking as you type:

- Error highlighting with precise source locations
- Warning detection for potential issues
- Requires `sbpl-convert` CLI tool (see Installation)

### Intelligent Autocompletion

Context-aware suggestions with documentation:

| Context | Suggestions |
|---------|-------------|
| Top-level | `version`, `debug`, `import`, `define`, `allow`, `deny` |
| After `allow`/`deny` | Operations by category (file, mach, network, etc.) |
| Filter position | `require-all`, `require-any`, `literal`, `subpath`, etc. |
| Value position | `#t`, `#f`, variable references |

Each completion includes:
- Detail description
- Documentation with examples
- Snippets with tab stops

### Commands

- **SBPL: Check Syntax** — Manually trigger syntax validation
- **SBPL: Convert to JSON** — Convert current file to JSON representation

## Installation

### From VS Code Marketplace

Search for "SBPL" in the Extensions view (`Cmd+Shift+X`).

### From VSIX

```bash
# Build from source (requires Bun)
cd vscode-sbpl
bun install
bun run compile
vsce package

# Install
code --install-extension sbpl-language-*.vsix
```

### Installing the CLI Tool (for diagnostics)

Diagnostics require the `sbpl-convert` CLI from the [sbpl-toolchain](https://github.com/g-cqd/sbpl-toolchain) project:

```bash
# Clone and build
git clone https://github.com/g-cqd/sbpl-toolchain.git
cd sbpl-toolchain
swift build -c release

# Option 1: Add to PATH
cp .build/release/sbpl-convert /usr/local/bin/

# Option 2: Configure extension setting
# Set sbpl.executablePath to the full path
```

## Extension Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `sbpl.executablePath` | `""` | Path to `sbpl-convert`. If empty, searches PATH. |
| `sbpl.enableDiagnostics` | `true` | Enable real-time syntax checking. |

## Example

```scheme
(version 1)

; Deny by default
(deny default)

; Allow reading from system directories
(allow file-read-data
  (require-any
    (subpath "/usr")
    (subpath "/System")))

; Allow specific Mach services
(allow mach-lookup
  (global-name "com.apple.system.logger"))
```

## Supported File Extensions

- `.sb` — Standard macOS sandbox profile extension
- `.sbpl` — Alternative extension

## Requirements

- **VS Code**: 1.85.0 or later
- **Bun**: 1.0+ (for building from source)
- **sbpl-convert**: Required for diagnostics (optional for highlighting only)

## Contributing

See [CONTRIBUTING.md](https://github.com/g-cqd/sbpl-toolchain/blob/main/CONTRIBUTING.md) in the main repository.

## License

MIT License — see [LICENSE](https://github.com/g-cqd/sbpl-toolchain/blob/main/LICENSE).

## Related

- [sbpl-toolchain](https://github.com/g-cqd/sbpl-toolchain) — Swift package with lexer, parser, and converter
- [Apple Sandbox Documentation](https://developer.apple.com/documentation/security/app_sandbox)
