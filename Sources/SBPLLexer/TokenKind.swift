/// The kind of a token in SBPL source.
public enum TokenKind: Hashable, Sendable {
  // MARK: - Structural

  /// Opening parenthesis `(`.
  case leftParen

  /// Closing parenthesis `)`.
  case rightParen

  // MARK: - Literals

  /// An integer literal (e.g., `42`, `-17`).
  case integer(Int)

  /// A regular string literal (e.g., `"hello"`).
  case string(String)

  /// A raw string literal (e.g., `#"raw string"#`).
  case rawString(String)

  /// A boolean literal (`#t` or `#f`).
  case boolean(Bool)

  // MARK: - Identifiers

  /// A symbol (identifier, keyword, or operator).
  ///
  /// Examples: `allow`, `deny`, `file-read-data`, `version`
  case symbol(String)

  // MARK: - Special

  /// End of file.
  case eof

  /// An unknown or invalid character.
  case unknown(Character)

  /// A missing token (used for error recovery).
  case missing(expected: String)
}

// MARK: - Properties

extension TokenKind {
  /// Whether this is a literal token.
  public var isLiteral: Bool {
    switch self {
    case .integer, .string, .rawString, .boolean:
      return true
    default:
      return false
    }
  }

  /// Whether this is a structural token (parentheses).
  public var isStructural: Bool {
    switch self {
    case .leftParen, .rightParen:
      return true
    default:
      return false
    }
  }

  /// Whether this is an error token.
  public var isError: Bool {
    switch self {
    case .unknown, .missing:
      return true
    default:
      return false
    }
  }

  /// Whether this is the end of file token.
  public var isEOF: Bool {
    if case .eof = self {
      return true
    }
    return false
  }

  /// The string value if this is a symbol, nil otherwise.
  public var symbolValue: String? {
    if case .symbol(let value) = self {
      return value
    }
    return nil
  }

  /// The string value if this is a string literal, nil otherwise.
  public var stringValue: String? {
    switch self {
    case .string(let value), .rawString(let value):
      return value
    default:
      return nil
    }
  }

  /// The integer value if this is an integer literal, nil otherwise.
  public var integerValue: Int? {
    if case .integer(let value) = self {
      return value
    }
    return nil
  }

  /// The boolean value if this is a boolean literal, nil otherwise.
  public var booleanValue: Bool? {
    if case .boolean(let value) = self {
      return value
    }
    return nil
  }
}

// MARK: - CustomStringConvertible

extension TokenKind: CustomStringConvertible {
  public var description: String {
    switch self {
    case .leftParen:
      return "("
    case .rightParen:
      return ")"
    case .integer(let value):
      return "integer(\(value))"
    case .string(let value):
      return "string(\"\(value)\")"
    case .rawString(let value):
      return "rawString(\"\(value)\")"
    case .boolean(let value):
      return value ? "#t" : "#f"
    case .symbol(let name):
      return "symbol(\(name))"
    case .eof:
      return "eof"
    case .unknown(let char):
      return "unknown('\(char)')"
    case .missing(let expected):
      return "missing(\(expected))"
    }
  }
}
