# SBPL Language Support for VS Code

Syntax highlighting and real-time diagnostics for Apple Sandbox Profile Language (SBPL) files.

## Features

- **Syntax Highlighting**: Full TextMate grammar support for `.sb` and `.sbpl` files
  - Keywords: `version`, `debug`, `import`, `define`, `allow`, `deny`
  - Filters: `require-all`, `require-any`, `require-not`, `literal`, `subpath`, `regex`, etc.
  - Operations: `file-read-data`, `mach-lookup`, `network*`, and 100+ sandbox operations
  - Strings, raw strings, booleans, integers, comments

- **Real-time Diagnostics**: Syntax checking as you type (requires `sbpl-convert`)
  - Error and warning highlighting
  - Precise source location markers

- **Commands**:
  - `SBPL: Check Syntax` - Manually trigger syntax check
  - `SBPL: Convert to JSON` - Convert current file to JSON representation

## Requirements

For syntax checking, you need the `sbpl-convert` CLI tool from the sbpl-toolchain project:

```bash
# Build from source
cd sbpl-toolchain
swift build -c release

# Copy to PATH or configure extension setting
cp .build/release/sbpl-convert /usr/local/bin/
```

## Extension Settings

- `sbpl.executablePath`: Path to the `sbpl-convert` executable. Leave empty to search in PATH.
- `sbpl.enableDiagnostics`: Enable/disable real-time syntax checking (default: `true`)

## Installation

### From Source

1. Clone the repository
2. Install dependencies: `npm install`
3. Compile: `npm run compile`
4. Press F5 to run in Extension Development Host

### Package as VSIX

```bash
npm install -g @vscode/vsce
vsce package
code --install-extension sbpl-language-*.vsix
```

## Supported File Types

- `.sb` - Standard macOS sandbox profile extension
- `.sbpl` - Alternative extension for sandbox profiles

## Example

```sbpl
(version 1)

(debug deny)

(import "system.sb")

(deny default)

(allow file-read-data
  (subpath "/usr"))

(allow mach-lookup
  (global-name "com.apple.system.logger"))
```

## License

MIT
