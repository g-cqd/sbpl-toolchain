import SBPLCore

/// A piece of trivia (whitespace or comment).
public enum TriviaPiece: Hashable, Sendable {
  /// One or more space characters.
  case spaces(Int)

  /// One or more tab characters.
  case tabs(Int)

  /// A newline character (`\n`).
  case newline

  /// A carriage return (`\r`).
  case carriageReturn

  /// A carriage return followed by a newline (`\r\n`).
  case carriageReturnLineFeed

  /// A line comment (from `;` to end of line).
  case lineComment(String)

  /// A block comment (`#| ... |#`).
  case blockComment(String)
}

// MARK: - TriviaPiece Properties

extension TriviaPiece {
  /// The text representation of this trivia piece.
  public var text: String {
    switch self {
    case .spaces(let count):
      return String(repeating: " ", count: count)
    case .tabs(let count):
      return String(repeating: "\t", count: count)
    case .newline:
      return "\n"
    case .carriageReturn:
      return "\r"
    case .carriageReturnLineFeed:
      return "\r\n"
    case .lineComment(let content):
      return ";\(content)"
    case .blockComment(let content):
      return "#|\(content)|#"
    }
  }

  /// The byte length of this trivia piece.
  public var byteLength: Int {
    text.utf8.count
  }

  /// Whether this trivia piece contains a newline.
  public var containsNewline: Bool {
    switch self {
    case .newline, .carriageReturn, .carriageReturnLineFeed:
      return true
    case .lineComment:
      return false  // The newline after a line comment is separate trivia
    case .spaces, .tabs, .blockComment:
      return false
    }
  }

  /// Whether this trivia piece is a comment.
  public var isComment: Bool {
    switch self {
    case .lineComment, .blockComment:
      return true
    default:
      return false
    }
  }
}

/// A collection of trivia pieces.
public struct Trivia: Hashable, Sendable {
  /// The trivia pieces.
  public let pieces: [TriviaPiece]

  /// Creates a new trivia collection.
  ///
  /// - Parameter pieces: The trivia pieces.
  public init(_ pieces: [TriviaPiece]) {
    self.pieces = pieces
  }

  /// Empty trivia.
  public static let empty = Trivia([])

  /// The text representation of this trivia.
  public var text: String {
    pieces.map(\.text).joined()
  }

  /// The byte length of this trivia.
  public var byteLength: Int {
    pieces.reduce(0) { $0 + $1.byteLength }
  }

  /// Whether this trivia is empty.
  public var isEmpty: Bool {
    pieces.isEmpty
  }

  /// Whether this trivia contains any newlines.
  public var containsNewline: Bool {
    pieces.contains { $0.containsNewline }
  }

  /// Whether this trivia contains any comments.
  public var hasComments: Bool {
    pieces.contains { $0.isComment }
  }

  /// The comments in this trivia.
  public var comments: [String] {
    pieces.compactMap { piece in
      switch piece {
      case .lineComment(let content), .blockComment(let content):
        return content
      default:
        return nil
      }
    }
  }
}

// MARK: - Convenience Initializers

extension Trivia {
  /// Creates trivia with spaces.
  public static func spaces(_ count: Int) -> Trivia {
    Trivia([.spaces(count)])
  }

  /// Creates trivia with tabs.
  public static func tabs(_ count: Int) -> Trivia {
    Trivia([.tabs(count)])
  }

  /// Creates trivia with a single newline.
  public static let newline = Trivia([.newline])

  /// Creates trivia with a line comment.
  public static func lineComment(_ content: String) -> Trivia {
    Trivia([.lineComment(content)])
  }

  /// Creates trivia with a block comment.
  public static func blockComment(_ content: String) -> Trivia {
    Trivia([.blockComment(content)])
  }
}

// MARK: - Operators

extension Trivia {
  /// Concatenates two trivia collections.
  public static func + (lhs: Trivia, rhs: Trivia) -> Trivia {
    Trivia(lhs.pieces + rhs.pieces)
  }
}

// MARK: - CustomStringConvertible

extension TriviaPiece: CustomStringConvertible {
  public var description: String {
    switch self {
    case .spaces(let count):
      return "spaces(\(count))"
    case .tabs(let count):
      return "tabs(\(count))"
    case .newline:
      return "newline"
    case .carriageReturn:
      return "carriageReturn"
    case .carriageReturnLineFeed:
      return "carriageReturnLineFeed"
    case .lineComment(let content):
      return "lineComment(\"\(content)\")"
    case .blockComment(let content):
      return "blockComment(\"\(content)\")"
    }
  }
}

extension Trivia: CustomStringConvertible {
  public var description: String {
    if isEmpty {
      return "Trivia([])"
    }
    return "Trivia([\(pieces.map(\.description).joined(separator: ", "))])"
  }
}
