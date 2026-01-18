import Foundation
import SBPLConverter
import SBPLCore

/// Command-line tool for converting between SBPL and JSON.
@main
struct SBPLConvertCLI {
  static func main() {
    let arguments = CommandLine.arguments

    guard arguments.count >= 2 else {
      printUsage()
      Foundation.exit(1)
    }

    let command = arguments[1]

    switch command {
    case "-h", "--help":
      printUsage()

    case "-v", "--version":
      print("sbpl-convert 0.1.0")

    case "to-json":
      guard arguments.count >= 3 else {
        fputs("Error: Missing input file\n", stderr)
        Foundation.exit(1)
      }
      convertToJSON(path: arguments[2])

    case "to-sbpl":
      guard arguments.count >= 3 else {
        fputs("Error: Missing input file\n", stderr)
        Foundation.exit(1)
      }
      convertToSBPL(path: arguments[2])

    case "check":
      guard arguments.count >= 3 else {
        fputs("Error: Missing input file\n", stderr)
        Foundation.exit(1)
      }
      checkSyntax(path: arguments[2])

    default:
      // Assume it's a file path for syntax checking
      checkSyntax(path: command)
    }
  }

  static func printUsage() {
    print(
      """
      Usage: sbpl-convert <COMMAND> [FILE]

      Convert between SBPL and JSON formats, or check SBPL syntax.

      COMMANDS:
        to-json <FILE>    Convert SBPL file to JSON
        to-sbpl <FILE>    Convert JSON file to SBPL
        check <FILE>      Check SBPL syntax without converting
        -h, --help        Show this help message
        -v, --version     Show version

      EXAMPLES:
        sbpl-convert to-json profile.sb > profile.json
        sbpl-convert to-sbpl profile.json > profile.sb
        sbpl-convert check profile.sb
      """)
  }

  static func convertToJSON(path: String) {
    guard let source = readFile(at: path) else { return }

    let converter = SBPLToJSON()
    let (json, diagnostics) = converter.convertToString(source: source, path: path)

    printDiagnostics(diagnostics, path: path)

    if let json = json {
      print(json)
    }

    if diagnostics.contains(where: { $0.severity == .error }) {
      Foundation.exit(1)
    }
  }

  static func convertToSBPL(path: String) {
    guard let jsonString = readFile(at: path) else { return }

    let converter = JSONToSBPL()
    do {
      let sbpl = try converter.convert(jsonString: jsonString)
      print(sbpl)
    } catch {
      fputs("Error: \(error.localizedDescription)\n", stderr)
      Foundation.exit(1)
    }
  }

  static func checkSyntax(path: String) {
    guard let source = readFile(at: path) else { return }

    let converter = SBPLToJSON()
    let result = converter.convert(source: source, path: path)

    printDiagnostics(result.diagnostics, path: path)

    let errors = result.diagnostics.filter { $0.severity == .error }.count
    let warnings = result.diagnostics.filter { $0.severity == .warning }.count

    if errors == 0 && warnings == 0 {
      print("✓ \(path): No issues found")
    } else {
      print("\n\(path): \(errors) error(s), \(warnings) warning(s)")
    }

    if errors > 0 {
      Foundation.exit(1)
    }
  }

  static func readFile(at path: String) -> String? {
    let url = URL(fileURLWithPath: path)

    guard FileManager.default.fileExists(atPath: path) else {
      fputs("Error: File not found: \(path)\n", stderr)
      Foundation.exit(1)
      return nil
    }

    do {
      return try String(contentsOf: url, encoding: .utf8)
    } catch {
      fputs("Error reading file: \(error.localizedDescription)\n", stderr)
      Foundation.exit(1)
      return nil
    }
  }

  static func printDiagnostics(_ diagnostics: [Diagnostic], path: String) {
    for diag in diagnostics {
      let severity = diag.severity.rawValue.uppercased()
      let line = diag.range.start.line + 1
      let col = diag.range.start.column + 1
      fputs("\(path):\(line):\(col): \(severity): \(diag.message) [\(diag.code.rawValue)]\n", stderr)
    }
  }
}
