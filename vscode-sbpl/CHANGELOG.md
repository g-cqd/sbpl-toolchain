# Change Log

All notable changes to the "sbpl-language" extension will be documented in this file.

## [1.0.0] - 2025-01-20

### Changed
- Migrated from Node.js to Bun for faster builds
- Converted to ES modules
- Updated process spawning to use Bun.spawn API

## [0.1.0] - 2025-01-18

### Added
- Syntax highlighting for SBPL files (`.sb`, `.sbpl`)
  - Keywords, operations, filters, strings, comments
  - 100+ sandbox operations recognized
- Real-time diagnostics via `sbpl-convert` CLI
- Context-aware autocompletion
  - Top-level declarations
  - Sandbox operations by category
  - Filters with documentation
  - Snippets with placeholders
- Commands: `SBPL: Check Syntax`, `SBPL: Convert to JSON`
- Configuration options for executable path and diagnostics toggle
