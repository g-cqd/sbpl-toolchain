import SBPLCore

/// A lexer for SBPL (Sandbox Profile Language).
///
/// The lexer tokenizes SBPL source code into tokens, handling:
/// - Parentheses and structural elements
/// - String and raw string literals
/// - Boolean literals (#t, #f)
/// - Integer literals
/// - Symbols (identifiers, keywords, operators)
/// - Comments (line comments starting with `;`, block comments `#| ... |#`)
/// - Whitespace (preserved as trivia)
public final class Lexer: @unchecked Sendable {
  /// The source file being lexed.
  public let source: SourceFile

  /// Collected diagnostics.
  public private(set) var diagnostics: [Diagnostic] = []

  // Current position in the source
  private var currentOffset: Int = 0
  private var currentLine: Int = 0
  private var currentColumn: Int = 0

  // Current index in the string (for O(1) character access)
  private var currentIndex: String.Index

  // The source text
  private let text: String

  /// Creates a new lexer for the given source.
  ///
  /// - Parameter source: The source file to lex.
  public init(source: SourceFile) {
    self.source = source
    self.text = source.text
    self.currentIndex = source.text.startIndex
  }

  /// Creates a new lexer for the given source text.
  ///
  /// - Parameters:
  ///   - text: The source text.
  ///   - path: Optional file path for diagnostics.
  public convenience init(text: String, path: String? = nil) {
    self.init(source: SourceFile(path: path, text: text))
  }

  /// Tokenizes the entire source and returns all tokens.
  ///
  /// - Returns: An array of all tokens including the final EOF token.
  public func tokenize() -> [Token] {
    var tokens: [Token] = []
    while true {
      let token = nextToken()
      tokens.append(token)
      if token.kind.isEOF {
        break
      }
    }
    return tokens
  }

  /// Returns the next token from the source.
  ///
  /// - Returns: The next token, or EOF if at end of source.
  public func nextToken() -> Token {
    // Collect leading trivia
    let leadingTrivia = scanTrivia(isLeading: true)

    // Record start position
    let startPosition = currentPosition()

    // Check for EOF
    guard !isAtEnd else {
      return Token.eof(at: startPosition, leadingTrivia: leadingTrivia)
    }

    // Scan the token
    let kind = scanToken()

    // Record end position
    let endPosition = currentPosition()

    // Collect trailing trivia (up to and including first newline)
    let trailingTrivia = scanTrivia(isLeading: false)

    return Token(
      kind: kind,
      range: SourceRange(start: startPosition, end: endPosition),
      leadingTrivia: leadingTrivia,
      trailingTrivia: trailingTrivia
    )
  }

  // MARK: - Token Scanning

  private func scanToken() -> TokenKind {
    let char = peek()!

    switch char {
    case "(":
      advance()
      return .leftParen

    case ")":
      advance()
      return .rightParen

    case "\"":
      return scanString()

    case "#":
      return scanHash()

    case "-", "+":
      // Could be a number or a symbol
      if let next = peek(ahead: 1), next.isNumber {
        return scanNumber()
      }
      return scanSymbol()

    case _ where char.isNumber:
      return scanNumber()

    case _ where isSymbolStart(char):
      return scanSymbol()

    default:
      advance()
      addDiagnostic(.unknownCharacter, message: "Unknown character '\(char)'")
      return .unknown(char)
    }
  }

  // MARK: - String Scanning

  private func scanString() -> TokenKind {
    let startOffset = currentOffset
    advance()  // consume opening quote

    var value = ""
    var hasError = false

    while !isAtEnd {
      guard let char = peek() else { break }

      if char == "\"" {
        advance()  // consume closing quote
        return .string(value)
      }

      if char == "\n" || char == "\r" {
        // Unterminated string
        addDiagnostic(
          .unterminatedString,
          message: "Unterminated string literal",
          startOffset: startOffset
        )
        return .string(value)
      }

      if char == "\\" {
        advance()  // consume backslash
        if let escaped = scanEscapeSequence() {
          value.append(escaped)
        } else {
          hasError = true
        }
      } else {
        value.append(char)
        advance()
      }
    }

    // EOF before closing quote
    if !hasError {
      addDiagnostic(
        .unterminatedString,
        message: "Unterminated string literal",
        startOffset: startOffset
      )
    }
    return .string(value)
  }

  private func scanEscapeSequence() -> Character? {
    guard let char = peek() else {
      addDiagnostic(.invalidEscapeSequence, message: "Expected escape character after '\\'")
      return nil
    }

    advance()

    switch char {
    case "n": return "\n"
    case "r": return "\r"
    case "t": return "\t"
    case "\\": return "\\"
    case "\"": return "\""
    case "0": return "\0"
    case "x":
      // Hex escape \xNN
      return scanHexEscape(digits: 2)
    case "u":
      // Unicode escape \uNNNN
      return scanHexEscape(digits: 4)
    default:
      addDiagnostic(.invalidEscapeSequence, message: "Invalid escape sequence '\\\\(char)'")
      return char
    }
  }

  private func scanHexEscape(digits: Int) -> Character? {
    var hexString = ""
    for _ in 0..<digits {
      guard let char = peek(), char.isHexDigit else {
        addDiagnostic(
          .invalidHexEscape,
          message: "Expected \(digits) hexadecimal digits in escape sequence"
        )
        return nil
      }
      hexString.append(char)
      advance()
    }

    guard let codePoint = UInt32(hexString, radix: 16),
      let scalar = Unicode.Scalar(codePoint)
    else {
      addDiagnostic(.invalidHexEscape, message: "Invalid Unicode code point")
      return nil
    }

    return Character(scalar)
  }

  // MARK: - Hash Scanning (#t, #f, raw strings, block comments)

  private func scanHash() -> TokenKind {
    advance()  // consume #

    guard let char = peek() else {
      addDiagnostic(.unexpectedEOF, message: "Unexpected end of file after '#'")
      return .unknown(Character("#"))
    }

    switch char {
    case "t", "T":
      advance()
      return .boolean(true)

    case "f", "F":
      advance()
      return .boolean(false)

    case "\"":
      return scanRawString()

    case "|":
      // Block comment - but we shouldn't get here as trivia handles it
      // This is for recovery if # is followed by | but not handled as trivia
      return .unknown(Character("#"))

    default:
      // Could be an unknown directive or a symbol starting with #
      addDiagnostic(.unknownCharacter, message: "Unknown directive '#\(char)'")
      return .unknown(Character("#"))
    }
  }

  private func scanRawString() -> TokenKind {
    let startOffset = currentOffset - 1  // include the #
    advance()  // consume opening quote

    var value = ""

    while !isAtEnd {
      guard let char = peek() else { break }

      if char == "\"" {
        advance()  // consume closing "
        return .rawString(value)
      }

      value.append(char)
      if char == "\n" {
        currentLine += 1
        currentColumn = 0
      }
      advance()
    }

    // EOF before closing
    addDiagnostic(
      .unterminatedRawString,
      message: "Unterminated raw string literal",
      startOffset: startOffset
    )
    return .rawString(value)
  }

  // MARK: - Number Scanning

  private func scanNumber() -> TokenKind {
    var numberString = ""

    // Handle sign
    if let char = peek(), (char == "-" || char == "+") {
      numberString.append(char)
      advance()
    }

    // Scan digits
    while let char = peek(), char.isNumber {
      numberString.append(char)
      advance()
    }

    // Parse the integer
    if let value = Int(numberString) {
      return .integer(value)
    } else {
      addDiagnostic(.invalidIntegerLiteral, message: "Invalid integer literal '\(numberString)'")
      return .integer(0)
    }
  }

  // MARK: - Symbol Scanning

  private func scanSymbol() -> TokenKind {
    var symbol = ""

    while let char = peek(), isSymbolContinue(char) {
      symbol.append(char)
      advance()
    }

    return .symbol(symbol)
  }

  private func isSymbolStart(_ char: Character) -> Bool {
    // Symbols can start with letters, underscore, or many special characters
    // SBPL symbols are quite permissive
    if char.isLetter || char == "_" || char == "$" {
      return true
    }
    // Additional symbol start characters common in SBPL
    // Note: @ is NOT a valid symbol character
    // % is used for predicates like %string-prefix?
    let symbolChars: Set<Character> = ["*", "-", "+", "/", "<", ">", "=", "?", "!", ".", ":", "'", "%"]
    return symbolChars.contains(char)
  }

  private func isSymbolContinue(_ char: Character) -> Bool {
    if char.isLetter || char.isNumber || char == "_" || char == "$" {
      return true
    }
    // Symbol continuation characters
    // Note: @ is NOT a valid symbol character
    // % is used in predicates
    let symbolChars: Set<Character> = ["*", "-", "+", "/", "<", ">", "=", "?", "!", ".", ":", "'", "%"]
    return symbolChars.contains(char)
  }

  // MARK: - Trivia Scanning

  private func scanTrivia(isLeading: Bool) -> Trivia {
    var pieces: [TriviaPiece] = []

    while !isAtEnd {
      guard let char = peek() else { break }

      switch char {
      case " ":
        pieces.append(scanSpaces())

      case "\t":
        pieces.append(scanTabs())

      case "\n":
        advance()
        currentLine += 1
        currentColumn = 0
        pieces.append(.newline)
        if !isLeading {
          // Trailing trivia stops after first newline
          return Trivia(pieces)
        }

      case "\r":
        advance()
        if peek() == "\n" {
          advance()
          currentLine += 1
          currentColumn = 0
          pieces.append(.carriageReturnLineFeed)
        } else {
          currentLine += 1
          currentColumn = 0
          pieces.append(.carriageReturn)
        }
        if !isLeading {
          return Trivia(pieces)
        }

      case ";":
        pieces.append(scanLineComment())

      case "#" where peek(ahead: 1) == "|":
        pieces.append(scanBlockComment())

      default:
        // Not trivia
        return Trivia(pieces)
      }
    }

    return Trivia(pieces)
  }

  private func scanSpaces() -> TriviaPiece {
    var count = 0
    while peek() == " " {
      advance()
      count += 1
    }
    return .spaces(count)
  }

  private func scanTabs() -> TriviaPiece {
    var count = 0
    while peek() == "\t" {
      advance()
      count += 1
    }
    return .tabs(count)
  }

  private func scanLineComment() -> TriviaPiece {
    advance()  // consume ;

    var content = ""
    while let char = peek(), char != "\n" && char != "\r" {
      content.append(char)
      advance()
    }

    return .lineComment(content)
  }

  private func scanBlockComment() -> TriviaPiece {
    let startOffset = currentOffset
    advance()  // consume #
    advance()  // consume |

    var content = ""
    var depth = 1

    while !isAtEnd && depth > 0 {
      guard let char = peek() else { break }

      if char == "#" && peek(ahead: 1) == "|" {
        content.append(char)
        advance()
        content.append("|")
        advance()
        depth += 1
      } else if char == "|" && peek(ahead: 1) == "#" {
        depth -= 1
        if depth > 0 {
          content.append(char)
          advance()
          content.append("#")
          advance()
        } else {
          advance()  // consume |
          advance()  // consume #
        }
      } else {
        if char == "\n" {
          currentLine += 1
          currentColumn = 0
        }
        content.append(char)
        advance()
      }
    }

    if depth > 0 {
      addDiagnostic(
        .unterminatedComment,
        message: "Unterminated block comment",
        startOffset: startOffset
      )
    }

    return .blockComment(content)
  }

  // MARK: - Position Tracking

  private var isAtEnd: Bool {
    currentIndex >= text.endIndex
  }

  private func peek(ahead: Int = 0) -> Character? {
    guard currentIndex < text.endIndex else { return nil }

    if ahead == 0 {
      return text[currentIndex]
    }

    // For lookahead, we need to advance ahead characters
    var idx = currentIndex
    for _ in 0..<ahead {
      guard idx < text.endIndex else { return nil }
      idx = text.index(after: idx)
    }

    guard idx < text.endIndex else { return nil }
    return text[idx]
  }

  private func advance() {
    guard currentIndex < text.endIndex else { return }

    let char = text[currentIndex]
    currentOffset += char.utf8.count
    currentColumn += 1
    currentIndex = text.index(after: currentIndex)
  }

  private func currentPosition() -> SourcePosition {
    SourcePosition(line: currentLine, column: currentColumn, offset: currentOffset)
  }

  // MARK: - Diagnostics

  private func addDiagnostic(
    _ code: DiagnosticCode,
    message: String,
    startOffset: Int? = nil
  ) {
    let start = startOffset.flatMap { source.position(at: $0) } ?? currentPosition()
    let end = currentPosition()

    let diagnostic = Diagnostic(
      code: code,
      message: message,
      severity: code.defaultSeverity,
      range: SourceRange(start: start, end: end)
    )
    diagnostics.append(diagnostic)
  }
}

// MARK: - Character Extensions

extension Character {
  fileprivate var isHexDigit: Bool {
    isNumber || ("a"..."f").contains(self) || ("A"..."F").contains(self)
  }
}
