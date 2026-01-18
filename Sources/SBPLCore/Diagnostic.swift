/// The severity of a diagnostic.
public enum DiagnosticSeverity: String, Sendable, Codable {
  /// An error that prevents successful compilation.
  case error
  /// A warning that doesn't prevent compilation.
  case warning
  /// Informational message.
  case information
  /// A hint or suggestion.
  case hint
}

/// A text edit for a code fix.
public struct TextEdit: Hashable, Sendable {
  /// The range to replace.
  public let range: SourceRange

  /// The replacement text.
  public let newText: String

  /// Creates a new text edit.
  ///
  /// - Parameters:
  ///   - range: The range to replace.
  ///   - newText: The replacement text.
  public init(range: SourceRange, newText: String) {
    self.range = range
    self.newText = newText
  }

  /// Creates an insertion at a position.
  ///
  /// - Parameters:
  ///   - position: The position to insert at.
  ///   - text: The text to insert.
  public static func insert(at position: SourcePosition, text: String) -> TextEdit {
    TextEdit(range: SourceRange(position: position), newText: text)
  }

  /// Creates a deletion of a range.
  ///
  /// - Parameter range: The range to delete.
  public static func delete(range: SourceRange) -> TextEdit {
    TextEdit(range: range, newText: "")
  }
}

/// A code fix that can be applied to resolve a diagnostic.
public struct CodeFix: Hashable, Sendable {
  /// A human-readable title for the fix.
  public let title: String

  /// The edits to apply.
  public let edits: [TextEdit]

  /// Whether this fix is the preferred fix for the diagnostic.
  public let isPreferred: Bool

  /// Creates a new code fix.
  ///
  /// - Parameters:
  ///   - title: A human-readable title for the fix.
  ///   - edits: The edits to apply.
  ///   - isPreferred: Whether this is the preferred fix.
  public init(title: String, edits: [TextEdit], isPreferred: Bool = false) {
    self.title = title
    self.edits = edits
    self.isPreferred = isPreferred
  }

  /// Creates a code fix with a single edit.
  ///
  /// - Parameters:
  ///   - title: A human-readable title for the fix.
  ///   - edit: The edit to apply.
  ///   - isPreferred: Whether this is the preferred fix.
  public init(title: String, edit: TextEdit, isPreferred: Bool = false) {
    self.title = title
    self.edits = [edit]
    self.isPreferred = isPreferred
  }
}

/// A diagnostic message about the source code.
public struct Diagnostic: Hashable, Sendable {
  /// The diagnostic code.
  public let code: DiagnosticCode

  /// The human-readable message.
  public let message: String

  /// The severity of this diagnostic.
  public let severity: DiagnosticSeverity

  /// The source range this diagnostic applies to.
  public let range: SourceRange

  /// Optional code fixes for this diagnostic.
  public let fixes: [CodeFix]

  /// Optional related information (e.g., "see also" references).
  public let relatedInformation: [DiagnosticRelatedInformation]

  /// Creates a new diagnostic.
  ///
  /// - Parameters:
  ///   - code: The diagnostic code.
  ///   - message: The human-readable message.
  ///   - severity: The severity.
  ///   - range: The source range.
  ///   - fixes: Optional code fixes.
  ///   - relatedInformation: Optional related information.
  public init(
    code: DiagnosticCode,
    message: String,
    severity: DiagnosticSeverity,
    range: SourceRange,
    fixes: [CodeFix] = [],
    relatedInformation: [DiagnosticRelatedInformation] = []
  ) {
    self.code = code
    self.message = message
    self.severity = severity
    self.range = range
    self.fixes = fixes
    self.relatedInformation = relatedInformation
  }

  /// Creates an error diagnostic.
  public static func error(
    _ code: DiagnosticCode,
    message: String,
    at range: SourceRange,
    fixes: [CodeFix] = []
  ) -> Diagnostic {
    Diagnostic(code: code, message: message, severity: .error, range: range, fixes: fixes)
  }

  /// Creates a warning diagnostic.
  public static func warning(
    _ code: DiagnosticCode,
    message: String,
    at range: SourceRange,
    fixes: [CodeFix] = []
  ) -> Diagnostic {
    Diagnostic(code: code, message: message, severity: .warning, range: range, fixes: fixes)
  }

  /// Creates an information diagnostic.
  public static func information(
    _ code: DiagnosticCode,
    message: String,
    at range: SourceRange
  ) -> Diagnostic {
    Diagnostic(code: code, message: message, severity: .information, range: range)
  }

  /// Creates a hint diagnostic.
  public static func hint(
    _ code: DiagnosticCode,
    message: String,
    at range: SourceRange
  ) -> Diagnostic {
    Diagnostic(code: code, message: message, severity: .hint, range: range)
  }
}

/// Related information for a diagnostic.
public struct DiagnosticRelatedInformation: Hashable, Sendable {
  /// The location of the related information.
  public let range: SourceRange

  /// The file path, if different from the main diagnostic.
  public let filePath: String?

  /// The message describing the relation.
  public let message: String

  /// Creates related information.
  ///
  /// - Parameters:
  ///   - range: The location.
  ///   - filePath: The file path, if different.
  ///   - message: The message.
  public init(range: SourceRange, filePath: String? = nil, message: String) {
    self.range = range
    self.filePath = filePath
    self.message = message
  }
}

/// A collector for diagnostics with deduplication support.
public final class DiagnosticCollector: @unchecked Sendable {
  /// The collected diagnostics.
  public private(set) var diagnostics: [Diagnostic] = []

  /// Set of diagnostic hashes for deduplication.
  private var seenHashes: Set<Int> = []

  /// Creates a new diagnostic collector.
  public init() {}

  /// Adds a diagnostic if it hasn't been seen before.
  ///
  /// - Parameter diagnostic: The diagnostic to add.
  /// - Returns: `true` if the diagnostic was added (not a duplicate).
  @discardableResult
  public func add(_ diagnostic: Diagnostic) -> Bool {
    let hash = diagnostic.hashValue
    if seenHashes.contains(hash) {
      return false
    }
    seenHashes.insert(hash)
    diagnostics.append(diagnostic)
    return true
  }

  /// Adds multiple diagnostics, deduplicating as necessary.
  ///
  /// - Parameter diagnostics: The diagnostics to add.
  public func add(_ diagnostics: [Diagnostic]) {
    for diagnostic in diagnostics {
      add(diagnostic)
    }
  }

  /// Whether there are any error diagnostics.
  public var hasErrors: Bool {
    diagnostics.contains { $0.severity == .error }
  }

  /// Whether there are any warning diagnostics.
  public var hasWarnings: Bool {
    diagnostics.contains { $0.severity == .warning }
  }

  /// The number of error diagnostics.
  public var errorCount: Int {
    diagnostics.filter { $0.severity == .error }.count
  }

  /// The number of warning diagnostics.
  public var warningCount: Int {
    diagnostics.filter { $0.severity == .warning }.count
  }

  /// Clears all diagnostics.
  public func clear() {
    diagnostics.removeAll()
    seenHashes.removeAll()
  }

  /// Returns diagnostics sorted by position.
  public func sorted() -> [Diagnostic] {
    diagnostics.sorted { $0.range.start < $1.range.start }
  }

  /// Returns diagnostics filtered by severity.
  ///
  /// - Parameter severity: The severity to filter by.
  /// - Returns: Diagnostics matching the severity.
  public func filtered(by severity: DiagnosticSeverity) -> [Diagnostic] {
    diagnostics.filter { $0.severity == severity }
  }
}

// MARK: - CustomStringConvertible

extension DiagnosticSeverity: CustomStringConvertible {
  public var description: String {
    rawValue
  }
}

extension Diagnostic: CustomStringConvertible {
  public var description: String {
    "\(range): \(severity): [\(code)] \(message)"
  }
}
