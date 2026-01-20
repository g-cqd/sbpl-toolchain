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
      print("sbpl-convert 1.0.0")

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

      Use '-' as FILE to read from stdin.

      EXAMPLES:
        sbpl-convert to-json profile.sb > profile.json
        sbpl-convert to-sbpl profile.json > profile.sb
        sbpl-convert check profile.sb
        cat profile.sb | sbpl-convert check -
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

    let displayPath = path == "-" ? "<stdin>" : path
    let converter = SBPLToJSON()
    let result = converter.convert(source: source, path: displayPath)

    printDiagnostics(result.diagnostics, path: displayPath)

    let errors = result.diagnostics.filter { $0.severity == .error }.count
    let warnings = result.diagnostics.filter { $0.severity == .warning }.count

    // Only print summary to stdout when not reading from stdin
    // (VS Code extension parses stderr for diagnostics)
    if path != "-" {
      if errors == 0 && warnings == 0 {
        print("\(displayPath): No issues found")
      } else {
        print("\(displayPath): \(errors) error(s), \(warnings) warning(s)")
      }
    }

    if errors > 0 {
      Foundation.exit(1)
    }
  }

  static func readFile(at path: String) -> String? {
    // Support reading from stdin with "-"
    if path == "-" {
      var input = ""
      while let line = readLine(strippingNewline: false) {
        input += line
      }
      return input
    }

    let url = URL(fileURLWithPath: path)

    guard FileManager.default.fileExists(atPath: path) else {
      fputs("Error: File not found: \(path)\n", stderr)
      Foundation.exit(1)
    }

    do {
      return try String(contentsOf: url, encoding: .utf8)
    } catch {
      fputs("Error reading file: \(error.localizedDescription)\n", stderr)
      Foundation.exit(1)
    }
  }

  static func printDiagnostics(_ diagnostics: [Diagnostic], path _: String) {
    for diag in diagnostics {
      let severity = diag.severity.rawValue.lowercased()
      let line = diag.range.start.line + 1
      let col = diag.range.start.column + 1
      // Format: line:col: severity: message
      // This format is parseable by VS Code extension
      fputs("\(line):\(col): \(severity): \(diag.message)\n", stderr)
    }
  }
}
