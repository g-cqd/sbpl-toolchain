import SBPLCore

/// A token in SBPL source code.
public struct Token: Hashable, Sendable {
  /// The kind of this token.
  public let kind: TokenKind

  /// The source range of this token (excluding trivia).
  public let range: SourceRange

  /// Trivia appearing before this token.
  public let leadingTrivia: Trivia

  /// Trivia appearing after this token.
  public let trailingTrivia: Trivia

  /// Creates a new token.
  ///
  /// - Parameters:
  ///   - kind: The kind of token.
  ///   - range: The source range of the token text.
  ///   - leadingTrivia: Trivia before the token.
  ///   - trailingTrivia: Trivia after the token.
  public init(
    kind: TokenKind,
    range: SourceRange,
    leadingTrivia: Trivia = .empty,
    trailingTrivia: Trivia = .empty
  ) {
    self.kind = kind
    self.range = range
    self.leadingTrivia = leadingTrivia
    self.trailingTrivia = trailingTrivia
  }

  /// The full range including trivia.
  ///
  /// This extends from the start of leading trivia to the end of trailing trivia.
  public var fullRange: SourceRange {
    let fullStart = SourcePosition(
      line: range.start.line,
      column: range.start.column,
      offset: range.start.offset - leadingTrivia.byteLength
    )
    let fullEnd = SourcePosition(
      line: range.end.line,
      column: range.end.column,
      offset: range.end.offset + trailingTrivia.byteLength
    )
    return SourceRange(start: fullStart, end: fullEnd)
  }

  /// The text of this token (excluding trivia).
  public var text: String {
    switch kind {
    case .leftParen:
      return "("
    case .rightParen:
      return ")"
    case .integer(let value):
      return String(value)
    case .string(let value):
      // Reconstruct the source representation
      return "\"\(escapeString(value))\""
    case .rawString(let value):
      return "#\"\(value)\""
    case .boolean(let value):
      return value ? "#t" : "#f"
    case .symbol(let name):
      return name
    case .eof:
      return ""
    case .unknown(let char):
      return String(char)
    case .missing:
      return ""
    }
  }

  /// The full text including trivia.
  public var fullText: String {
    leadingTrivia.text + text + trailingTrivia.text
  }

  /// Whether this token has any leading comments.
  public var hasLeadingComments: Bool {
    leadingTrivia.hasComments
  }

  /// Whether this token has any trailing comments.
  public var hasTrailingComments: Bool {
    trailingTrivia.hasComments
  }

  /// All comments associated with this token.
  public var comments: [String] {
    leadingTrivia.comments + trailingTrivia.comments
  }
}

// MARK: - Private Helpers

private func escapeString(_ value: String) -> String {
  var result = ""
  for char in value {
    switch char {
    case "\"": result += "\\\""
    case "\\": result += "\\\\"
    case "\n": result += "\\n"
    case "\r": result += "\\r"
    case "\t": result += "\\t"
    default: result.append(char)
    }
  }
  return result
}

// MARK: - Convenience Factories

extension Token {
  /// Creates an EOF token at the given position.
  public static func eof(at position: SourcePosition, leadingTrivia: Trivia = .empty) -> Token {
    Token(
      kind: .eof,
      range: SourceRange(position: position),
      leadingTrivia: leadingTrivia
    )
  }

  /// Creates a missing token for error recovery.
  public static func missing(
    _ expected: String,
    at position: SourcePosition
  ) -> Token {
    Token(
      kind: .missing(expected: expected),
      range: SourceRange(position: position)
    )
  }
}

// MARK: - CustomStringConvertible

extension Token: CustomStringConvertible {
  public var description: String {
    var parts: [String] = []
    parts.append("Token(\(kind)")
    parts.append("at: \(range)")
    if !leadingTrivia.isEmpty {
      parts.append("leading: \(leadingTrivia)")
    }
    if !trailingTrivia.isEmpty {
      parts.append("trailing: \(trailingTrivia)")
    }
    return parts.joined(separator: ", ") + ")"
  }
}
