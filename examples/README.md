# SBPL Examples

This directory contains example sandbox profiles for testing and learning.

## Files

| File | Description |
|------|-------------|
| `valid-profile.sb` | A complete, valid sandbox profile demonstrating common patterns |
| `invalid-profile.sb` | A profile with intentional errors for testing diagnostics |
| `partial-errors.sb` | A profile mixing valid and invalid code to test error recovery |

## Usage

Open this folder in VS Code with the SBPL extension installed:

```bash
code examples/
```

You should see:
- Syntax highlighting on all files
- No errors in `valid-profile.sb`
- Red underlines in `invalid-profile.sb` and `partial-errors.sb`
- Autocompletion when typing

## Configuration

The `.vscode/settings.json` file configures the path to `sbpl-convert`. Update this path if needed:

```json
{
  "sbpl.executablePath": "/path/to/sbpl-convert"
}
```
