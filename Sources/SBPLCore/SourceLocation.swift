/// A position in source code.
///
/// Positions are 0-indexed. For LSP compatibility, columns are measured
/// in UTF-16 code units.
public struct SourcePosition: Hashable, Sendable, Comparable {
  /// The 0-indexed line number.
  public let line: Int

  /// The 0-indexed column in UTF-16 code units.
  public let column: Int

  /// The byte offset from the start of the file.
  public let offset: Int

  /// Creates a new source position.
  ///
  /// - Parameters:
  ///   - line: The 0-indexed line number.
  ///   - column: The 0-indexed column in UTF-16 code units.
  ///   - offset: The byte offset from the start of the file.
  public init(line: Int, column: Int, offset: Int) {
    self.line = line
    self.column = column
    self.offset = offset
  }

  /// The start of a file (line 0, column 0, offset 0).
  public static let zero = SourcePosition(line: 0, column: 0, offset: 0)

  public static func < (lhs: SourcePosition, rhs: SourcePosition) -> Bool {
    lhs.offset < rhs.offset
  }
}

/// A range in source code.
public struct SourceRange: Hashable, Sendable {
  /// The start position (inclusive).
  public let start: SourcePosition

  /// The end position (exclusive).
  public let end: SourcePosition

  /// Creates a new source range.
  ///
  /// - Parameters:
  ///   - start: The start position (inclusive).
  ///   - end: The end position (exclusive).
  public init(start: SourcePosition, end: SourcePosition) {
    self.start = start
    self.end = end
  }

  /// Creates a range from a single position (zero-length).
  ///
  /// - Parameter position: The position.
  public init(position: SourcePosition) {
    self.start = position
    self.end = position
  }

  /// Whether this range contains the given position.
  ///
  /// - Parameter position: The position to check.
  /// - Returns: `true` if the position is within this range.
  public func contains(_ position: SourcePosition) -> Bool {
    position.offset >= start.offset && position.offset < end.offset
  }

  /// Whether this range overlaps with another range.
  ///
  /// - Parameter other: The other range to check.
  /// - Returns: `true` if the ranges overlap.
  public func overlaps(_ other: SourceRange) -> Bool {
    start.offset < other.end.offset && end.offset > other.start.offset
  }

  /// The length of this range in bytes.
  public var length: Int {
    end.offset - start.offset
  }

  /// Whether this is an empty (zero-length) range.
  public var isEmpty: Bool {
    start.offset == end.offset
  }
}

/// A source file with efficient position lookups.
///
/// This class caches line start offsets for O(1) line lookups and provides
/// utilities for converting between byte offsets and line/column positions.
public final class SourceFile: @unchecked Sendable {
  /// The file path, if known.
  public let path: String?

  /// The source text.
  public let text: String

  /// Cached line start offsets (byte offsets where each line begins).
  private let lineStartOffsets: [Int]

  /// Creates a new source file.
  ///
  /// - Parameters:
  ///   - path: The file path, if known.
  ///   - text: The source text.
  public init(path: String? = nil, text: String) {
    self.path = path
    self.text = text
    self.lineStartOffsets = SourceFile.computeLineStartOffsets(text)
  }

  /// The number of lines in the file.
  public var lineCount: Int {
    lineStartOffsets.count
  }

  /// Gets the position for a byte offset.
  ///
  /// - Parameter offset: The byte offset.
  /// - Returns: The position at that offset, or `nil` if out of bounds.
  public func position(at offset: Int) -> SourcePosition? {
    guard offset >= 0 && offset <= text.utf8.count else { return nil }

    // Binary search for the line containing this offset
    let line = findLine(containing: offset)
    let lineStart = lineStartOffsets[line]

    // Calculate column in UTF-16 code units
    let lineStartIndex = text.utf8.index(text.startIndex, offsetBy: lineStart)
    let offsetIndex = text.utf8.index(text.startIndex, offsetBy: offset)
    let column = text[lineStartIndex..<offsetIndex].utf16.count

    return SourcePosition(line: line, column: column, offset: offset)
  }

  /// Gets the byte offset for a line and column.
  ///
  /// - Parameters:
  ///   - line: The 0-indexed line number.
  ///   - column: The 0-indexed column in UTF-16 code units.
  /// - Returns: The byte offset, or `nil` if out of bounds.
  public func offset(line: Int, column: Int) -> Int? {
    guard line >= 0 && line < lineStartOffsets.count else { return nil }

    let lineStart = lineStartOffsets[line]
    let lineEnd = line + 1 < lineStartOffsets.count
      ? lineStartOffsets[line + 1]
      : text.utf8.count

    // Find the byte offset for the given UTF-16 column
    let lineStartIndex = text.utf8.index(text.startIndex, offsetBy: lineStart)
    let lineEndIndex = text.utf8.index(text.startIndex, offsetBy: lineEnd)

    var currentColumn = 0
    var currentIndex = lineStartIndex

    while currentIndex < lineEndIndex && currentColumn < column {
      let char = text[currentIndex]
      if char == "\n" || char == "\r" {
        break
      }
      currentColumn += char.utf16.count
      currentIndex = text.index(after: currentIndex)
    }

    return text.utf8.distance(from: text.startIndex, to: currentIndex)
  }

  /// Gets the text for a source range.
  ///
  /// - Parameter range: The source range.
  /// - Returns: The text in that range.
  public func text(in range: SourceRange) -> String {
    let startIndex = text.utf8.index(text.startIndex, offsetBy: range.start.offset)
    let endIndex = text.utf8.index(text.startIndex, offsetBy: range.end.offset)
    return String(text[startIndex..<endIndex])
  }

  /// Gets the text for a specific line.
  ///
  /// - Parameter line: The 0-indexed line number.
  /// - Returns: The text of that line (without trailing newline), or `nil` if out of bounds.
  public func lineText(_ line: Int) -> String? {
    guard line >= 0 && line < lineStartOffsets.count else { return nil }

    let lineStart = lineStartOffsets[line]
    let lineEnd = line + 1 < lineStartOffsets.count
      ? lineStartOffsets[line + 1]
      : text.utf8.count

    let startIndex = text.utf8.index(text.startIndex, offsetBy: lineStart)
    let endIndex = text.utf8.index(text.startIndex, offsetBy: lineEnd)

    var lineText = String(text[startIndex..<endIndex])
    // Remove trailing newline characters
    while lineText.last == "\n" || lineText.last == "\r" {
      lineText.removeLast()
    }
    return lineText
  }

  /// Gets the range of a specific line.
  ///
  /// - Parameter line: The 0-indexed line number.
  /// - Returns: The range of that line, or `nil` if out of bounds.
  public func lineRange(_ line: Int) -> SourceRange? {
    guard line >= 0 && line < lineStartOffsets.count else { return nil }

    let startOffset = lineStartOffsets[line]
    let endOffset = line + 1 < lineStartOffsets.count
      ? lineStartOffsets[line + 1]
      : text.utf8.count

    guard let start = position(at: startOffset),
      let end = position(at: endOffset)
    else {
      return nil
    }

    return SourceRange(start: start, end: end)
  }

  // MARK: - Private

  private static func computeLineStartOffsets(_ text: String) -> [Int] {
    var offsets = [0]
    var offset = 0

    for char in text.utf8 {
      offset += 1
      if char == UInt8(ascii: "\n") {
        offsets.append(offset)
      }
    }

    return offsets
  }

  private func findLine(containing offset: Int) -> Int {
    // Binary search
    var low = 0
    var high = lineStartOffsets.count - 1

    while low < high {
      let mid = (low + high + 1) / 2
      if lineStartOffsets[mid] <= offset {
        low = mid
      } else {
        high = mid - 1
      }
    }

    return low
  }
}

// MARK: - CustomStringConvertible

extension SourcePosition: CustomStringConvertible {
  public var description: String {
    "\(line + 1):\(column + 1)"
  }
}

extension SourceRange: CustomStringConvertible {
  public var description: String {
    if start.line == end.line {
      return "\(start.line + 1):\(start.column + 1)-\(end.column + 1)"
    } else {
      return "\(start)-\(end)"
    }
  }
}
