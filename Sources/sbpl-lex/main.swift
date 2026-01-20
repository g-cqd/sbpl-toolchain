import Foundation
import SBPLCore
import SBPLLexer

/// Command-line tool for testing the SBPL lexer.
@main
struct SBPLLexCLI {
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
      print("sbpl-lex 1.0.0")

    case "--stdin":
      lexStdin()

    default:
      // Assume it's a file path
      lexFile(at: command)
    }
  }

  static func printUsage() {
    print(
      """
      Usage: sbpl-lex [OPTIONS] <FILE>

      Tokenize an SBPL (Sandbox Profile Language) file and print the tokens.

      OPTIONS:
        -h, --help     Show this help message
        -v, --version  Show version
        --stdin        Read from standard input instead of a file

      ARGUMENTS:
        <FILE>         Path to an SBPL file (.sb) to tokenize

      EXAMPLES:
        sbpl-lex /System/Library/Sandbox/Profiles/bsd.sb
        cat profile.sb | sbpl-lex --stdin
      """)
  }

  static func lexFile(at path: String) {
    let url = URL(fileURLWithPath: path)

    guard FileManager.default.fileExists(atPath: path) else {
      fputs("Error: File not found: \(path)\n", stderr)
      Foundation.exit(1)
    }

    do {
      let contents = try String(contentsOf: url, encoding: .utf8)
      lex(text: contents, path: path)
    } catch {
      fputs("Error reading file: \(error.localizedDescription)\n", stderr)
      Foundation.exit(1)
    }
  }

  static func lexStdin() {
    var input = ""
    while let line = readLine(strippingNewline: false) {
      input += line
    }
    lex(text: input, path: "<stdin>")
  }

  static func lex(text: String, path: String) {
    let source = SourceFile(path: path, text: text)
    let lexer = Lexer(source: source)

    let tokens = lexer.tokenize()

    // Print tokens
    print("Tokens (\(tokens.count)):")
    print(String(repeating: "-", count: 60))

    for (index, token) in tokens.enumerated() {
      printToken(token, index: index)
    }

    print(String(repeating: "-", count: 60))

    // Print diagnostics if any
    if !lexer.diagnostics.isEmpty {
      print("\nDiagnostics (\(lexer.diagnostics.count)):")
      print(String(repeating: "-", count: 60))

      for diagnostic in lexer.diagnostics {
        printDiagnostic(diagnostic, source: source)
      }
    }

    // Print summary
    print("\nSummary:")
    print("  Total tokens: \(tokens.count)")
    print("  Errors: \(lexer.diagnostics.filter { $0.severity == .error }.count)")
    print("  Warnings: \(lexer.diagnostics.filter { $0.severity == .warning }.count)")

    // Exit with error code if there were errors
    if lexer.diagnostics.contains(where: { $0.severity == .error }) {
      Foundation.exit(1)
    }
  }

  static func printToken(_ token: Token, index: Int) {
    let kindStr = formatKind(token.kind)
    let rangeStr = "\(token.range.start.line + 1):\(token.range.start.column + 1)"

    let indexStr = String(index).padding(toLength: 4, withPad: " ", startingAt: 0)
    let rangePadded = rangeStr.padding(toLength: 12, withPad: " ", startingAt: 0)
    let kindPadded = kindStr.padding(toLength: 30, withPad: " ", startingAt: 0)
    var output = "\(indexStr)  \(rangePadded)  \(kindPadded)"

    // Add text preview for some token types
    switch token.kind {
    case .string(let value):
      output += "  \"\(truncate(value, to: 30))\""
    case .rawString(let value):
      output += "  #\"\(truncate(value, to: 28))\"#"
    case .symbol(let name):
      output += "  \(truncate(name, to: 30))"
    case .integer(let value):
      output += "  \(value)"
    case .boolean(let value):
      output += "  \(value ? "#t" : "#f")"
    case .unknown(let char):
      output += "  '\(char)'"
    default:
      break
    }

    // Add trivia info
    if !token.leadingTrivia.isEmpty {
      output += "  [leading: \(formatTrivia(token.leadingTrivia))]"
    }
    if !token.trailingTrivia.isEmpty {
      output += "  [trailing: \(formatTrivia(token.trailingTrivia))]"
    }

    print(output)
  }

  static func formatKind(_ kind: TokenKind) -> String {
    switch kind {
    case .leftParen: return "("
    case .rightParen: return ")"
    case .integer: return "integer"
    case .string: return "string"
    case .rawString: return "rawString"
    case .boolean: return "boolean"
    case .symbol: return "symbol"
    case .eof: return "eof"
    case .unknown: return "unknown"
    case .missing: return "missing"
    }
  }

  static func formatTrivia(_ trivia: Trivia) -> String {
    var parts: [String] = []
    for piece in trivia.pieces {
      switch piece {
      case .spaces(let n): parts.append("sp(\(n))")
      case .tabs(let n): parts.append("tab(\(n))")
      case .newline: parts.append("nl")
      case .carriageReturn: parts.append("cr")
      case .carriageReturnLineFeed: parts.append("crlf")
      case .lineComment: parts.append("comment")
      case .blockComment: parts.append("block")
      }
    }
    return parts.joined(separator: ",")
  }

  static func printDiagnostic(_ diagnostic: Diagnostic, source: SourceFile) {
    let severity = diagnostic.severity.rawValue.uppercased()
    let line = diagnostic.range.start.line + 1
    let column = diagnostic.range.start.column + 1

    print("\(severity) [\(diagnostic.code.rawValue)] at \(line):\(column)")
    print("  \(diagnostic.message)")

    // Print source context
    if let lineText = source.lineText(diagnostic.range.start.line) {
      print("  \(lineText)")
      let pointer = String(repeating: " ", count: diagnostic.range.start.column) + "^"
      print("  \(pointer)")
    }
    print()
  }

  static func truncate(_ string: String, to length: Int) -> String {
    if string.count <= length {
      return string
    }
    return String(string.prefix(length - 3)) + "..."
  }
}
