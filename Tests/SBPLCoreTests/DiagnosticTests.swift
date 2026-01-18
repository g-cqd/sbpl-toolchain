import Testing

@testable import SBPLCore

@Suite("Diagnostic Tests")
struct DiagnosticTests {
  @Test("Create error diagnostic")
  func testErrorDiagnostic() {
    let range = SourceRange(
      start: SourcePosition(line: 0, column: 5, offset: 5),
      end: SourcePosition(line: 0, column: 10, offset: 10)
    )

    let diagnostic = Diagnostic.error(
      .unknownCharacter,
      message: "Unknown character '@'",
      at: range
    )

    #expect(diagnostic.severity == .error)
    #expect(diagnostic.code == .unknownCharacter)
    #expect(diagnostic.message == "Unknown character '@'")
    #expect(diagnostic.range.start.offset == 5)
  }

  @Test("Create warning diagnostic")
  func testWarningDiagnostic() {
    let range = SourceRange(
      start: SourcePosition(line: 2, column: 0, offset: 20),
      end: SourcePosition(line: 2, column: 15, offset: 35)
    )

    let diagnostic = Diagnostic.warning(
      .unreachableCode,
      message: "This rule is unreachable",
      at: range
    )

    #expect(diagnostic.severity == .warning)
    #expect(diagnostic.code == .unreachableCode)
  }

  @Test("Diagnostic with fix")
  func testDiagnosticWithFix() {
    let range = SourceRange(
      start: SourcePosition(line: 0, column: 0, offset: 0),
      end: SourcePosition(line: 0, column: 1, offset: 1)
    )

    let fix = CodeFix(
      title: "Remove character",
      edit: TextEdit.delete(range: range),
      isPreferred: true
    )

    let diagnostic = Diagnostic.error(
      .unknownCharacter,
      message: "Unknown character",
      at: range,
      fixes: [fix]
    )

    #expect(diagnostic.fixes.count == 1)
    #expect(diagnostic.fixes[0].isPreferred)
    #expect(diagnostic.fixes[0].edits[0].newText == "")
  }
}

@Suite("DiagnosticCollector Tests")
struct DiagnosticCollectorTests {
  @Test("Add diagnostics")
  func testAddDiagnostics() {
    let collector = DiagnosticCollector()

    let range = SourceRange(position: SourcePosition.zero)

    collector.add(Diagnostic.error(.unknownCharacter, message: "error 1", at: range))
    collector.add(Diagnostic.warning(.unreachableCode, message: "warning 1", at: range))

    #expect(collector.diagnostics.count == 2)
    #expect(collector.hasErrors)
    #expect(collector.hasWarnings)
    #expect(collector.errorCount == 1)
    #expect(collector.warningCount == 1)
  }

  @Test("Deduplicate diagnostics")
  func testDeduplication() {
    let collector = DiagnosticCollector()

    let range = SourceRange(position: SourcePosition.zero)
    let diagnostic = Diagnostic.error(.unknownCharacter, message: "same error", at: range)

    let added1 = collector.add(diagnostic)
    let added2 = collector.add(diagnostic)

    #expect(added1 == true)
    #expect(added2 == false)
    #expect(collector.diagnostics.count == 1)
  }

  @Test("Filter by severity")
  func testFilterBySeverity() {
    let collector = DiagnosticCollector()

    let range = SourceRange(position: SourcePosition.zero)

    collector.add(Diagnostic.error(.unknownCharacter, message: "error", at: range))
    collector.add(Diagnostic.warning(.unreachableCode, message: "warning", at: range))
    collector.add(Diagnostic.error(.unterminatedString, message: "error 2", at: range))

    let errors = collector.filtered(by: .error)
    let warnings = collector.filtered(by: .warning)

    #expect(errors.count == 2)
    #expect(warnings.count == 1)
  }

  @Test("Sort by position")
  func testSortByPosition() {
    let collector = DiagnosticCollector()

    let range1 = SourceRange(
      start: SourcePosition(line: 2, column: 0, offset: 20),
      end: SourcePosition(line: 2, column: 5, offset: 25)
    )
    let range2 = SourceRange(
      start: SourcePosition(line: 0, column: 0, offset: 0),
      end: SourcePosition(line: 0, column: 5, offset: 5)
    )
    let range3 = SourceRange(
      start: SourcePosition(line: 1, column: 0, offset: 10),
      end: SourcePosition(line: 1, column: 5, offset: 15)
    )

    collector.add(Diagnostic.error(.unknownCharacter, message: "3", at: range1))
    collector.add(Diagnostic.error(.unknownCharacter, message: "1", at: range2))
    collector.add(Diagnostic.error(.unknownCharacter, message: "2", at: range3))

    let sorted = collector.sorted()

    #expect(sorted[0].message == "1")
    #expect(sorted[1].message == "2")
    #expect(sorted[2].message == "3")
  }

  @Test("Clear diagnostics")
  func testClear() {
    let collector = DiagnosticCollector()

    let range = SourceRange(position: SourcePosition.zero)
    collector.add(Diagnostic.error(.unknownCharacter, message: "error", at: range))

    #expect(collector.diagnostics.count == 1)

    collector.clear()

    #expect(collector.diagnostics.isEmpty)
    #expect(!collector.hasErrors)
  }
}

@Suite("DiagnosticCode Tests")
struct DiagnosticCodeTests {
  @Test("Lexer errors have error severity")
  func testLexerErrorSeverity() {
    #expect(DiagnosticCode.unknownCharacter.defaultSeverity == .error)
    #expect(DiagnosticCode.unterminatedString.defaultSeverity == .error)
    #expect(DiagnosticCode.invalidEscapeSequence.defaultSeverity == .error)
  }

  @Test("Warnings have warning severity")
  func testWarningSeverity() {
    #expect(DiagnosticCode.unreachableCode.defaultSeverity == .warning)
    #expect(DiagnosticCode.deprecated.defaultSeverity == .warning)
    #expect(DiagnosticCode.unusedDefinition.defaultSeverity == .warning)
  }

  @Test("Codes have descriptions")
  func testCodeDescriptions() {
    #expect(DiagnosticCode.unknownCharacter.description == "Unknown character")
    #expect(DiagnosticCode.unterminatedString.description == "Unterminated string literal")
  }
}
