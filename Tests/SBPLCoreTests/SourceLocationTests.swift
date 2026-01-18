import Testing

@testable import SBPLCore

@Suite("SourcePosition Tests")
struct SourcePositionTests {
  @Test("Zero position")
  func testZeroPosition() {
    let pos = SourcePosition.zero
    #expect(pos.line == 0)
    #expect(pos.column == 0)
    #expect(pos.offset == 0)
  }

  @Test("Position comparison")
  func testPositionComparison() {
    let pos1 = SourcePosition(line: 0, column: 5, offset: 5)
    let pos2 = SourcePosition(line: 0, column: 10, offset: 10)
    let pos3 = SourcePosition(line: 1, column: 0, offset: 15)

    #expect(pos1 < pos2)
    #expect(pos2 < pos3)
    #expect(!(pos2 < pos1))
  }

  @Test("Position description")
  func testPositionDescription() {
    let pos = SourcePosition(line: 4, column: 9, offset: 50)
    #expect(pos.description == "5:10")  // 1-indexed in description
  }
}

@Suite("SourceRange Tests")
struct SourceRangeTests {
  @Test("Range contains position")
  func testRangeContainsPosition() {
    let start = SourcePosition(line: 0, column: 0, offset: 0)
    let end = SourcePosition(line: 0, column: 10, offset: 10)
    let range = SourceRange(start: start, end: end)

    let inside = SourcePosition(line: 0, column: 5, offset: 5)
    let outside = SourcePosition(line: 0, column: 15, offset: 15)
    let atStart = SourcePosition(line: 0, column: 0, offset: 0)
    let atEnd = SourcePosition(line: 0, column: 10, offset: 10)

    #expect(range.contains(inside))
    #expect(!range.contains(outside))
    #expect(range.contains(atStart))
    #expect(!range.contains(atEnd))  // end is exclusive
  }

  @Test("Range overlaps")
  func testRangeOverlaps() {
    let range1 = SourceRange(
      start: SourcePosition(line: 0, column: 0, offset: 0),
      end: SourcePosition(line: 0, column: 10, offset: 10)
    )
    let range2 = SourceRange(
      start: SourcePosition(line: 0, column: 5, offset: 5),
      end: SourcePosition(line: 0, column: 15, offset: 15)
    )
    let range3 = SourceRange(
      start: SourcePosition(line: 0, column: 20, offset: 20),
      end: SourcePosition(line: 0, column: 25, offset: 25)
    )

    #expect(range1.overlaps(range2))
    #expect(range2.overlaps(range1))
    #expect(!range1.overlaps(range3))
  }

  @Test("Range length")
  func testRangeLength() {
    let range = SourceRange(
      start: SourcePosition(line: 0, column: 5, offset: 5),
      end: SourcePosition(line: 0, column: 15, offset: 15)
    )
    #expect(range.length == 10)
  }

  @Test("Empty range")
  func testEmptyRange() {
    let pos = SourcePosition(line: 0, column: 5, offset: 5)
    let range = SourceRange(position: pos)
    #expect(range.isEmpty)
    #expect(range.length == 0)
  }
}

@Suite("SourceFile Tests")
struct SourceFileTests {
  @Test("Line count")
  func testLineCount() {
    let text = "line1\nline2\nline3"
    let file = SourceFile(text: text)
    #expect(file.lineCount == 3)
  }

  @Test("Position at offset")
  func testPositionAtOffset() {
    let text = "abc\ndef\nghi"
    let file = SourceFile(text: text)

    // Start of file
    let pos0 = file.position(at: 0)
    #expect(pos0?.line == 0)
    #expect(pos0?.column == 0)

    // Middle of first line
    let pos2 = file.position(at: 2)
    #expect(pos2?.line == 0)
    #expect(pos2?.column == 2)

    // Start of second line
    let pos4 = file.position(at: 4)
    #expect(pos4?.line == 1)
    #expect(pos4?.column == 0)

    // End of file
    let posEnd = file.position(at: 11)
    #expect(posEnd?.line == 2)
    #expect(posEnd?.column == 3)
  }

  @Test("Line text")
  func testLineText() {
    let text = "first line\nsecond line\nthird line"
    let file = SourceFile(text: text)

    #expect(file.lineText(0) == "first line")
    #expect(file.lineText(1) == "second line")
    #expect(file.lineText(2) == "third line")
    #expect(file.lineText(3) == nil)
  }

  @Test("Text in range")
  func testTextInRange() {
    let text = "hello world"
    let file = SourceFile(text: text)

    let range = SourceRange(
      start: SourcePosition(line: 0, column: 0, offset: 0),
      end: SourcePosition(line: 0, column: 5, offset: 5)
    )

    #expect(file.text(in: range) == "hello")
  }

  @Test("UTF-16 column counting")
  func testUTF16ColumnCounting() {
    // Emoji takes 2 UTF-16 code units
    let text = "a\u{1F600}b"  // "a😀b"
    let file = SourceFile(text: text)

    // Position after emoji
    let pos = file.position(at: 5)  // 1 (a) + 4 (emoji UTF-8) = 5
    #expect(pos?.column == 3)  // a=1, emoji=2 UTF-16 units, so column 3 for 'b'
  }
}
