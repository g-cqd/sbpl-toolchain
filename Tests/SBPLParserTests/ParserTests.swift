import Testing

@testable import SBPLCore
@testable import SBPLParser

@Suite("Parser Basic Tests")
struct ParserBasicTests {
  @Test("Parse version declaration")
  func testParseVersion() {
    let source = "(version 1)"
    let parser = Parser(source: source)
    let (profile, diagnostics) = parser.parse()

    #expect(diagnostics.isEmpty)
    #expect(profile.version?.version == 1)
  }

  @Test("Parse debug declaration")
  func testParseDebug() {
    let source = "(debug deny)"
    let parser = Parser(source: source)
    let (profile, diagnostics) = parser.parse()

    #expect(diagnostics.isEmpty)
    #expect(profile.debugMode?.action == .deny)
  }

  @Test("Parse import declaration")
  func testParseImport() {
    let source = "(import \"system.sb\")"
    let parser = Parser(source: source)
    let (profile, diagnostics) = parser.parse()

    #expect(diagnostics.isEmpty)
    #expect(profile.imports.count == 1)
    #expect(profile.imports[0].path == "system.sb")
  }

  @Test("Parse simple rule")
  func testParseSimpleRule() {
    let source = "(allow file-read-data)"
    let parser = Parser(source: source)
    let (profile, diagnostics) = parser.parse()

    #expect(diagnostics.isEmpty)
    #expect(profile.rules.count == 1)
    #expect(profile.rules[0].action == .allow)
    #expect(profile.rules[0].operations.count == 1)
    #expect(profile.rules[0].operations[0].name == "file-read-data")
  }

  @Test("Parse rule with multiple operations")
  func testParseMultipleOperations() {
    let source = "(deny file-read-data file-write-data)"
    let parser = Parser(source: source)
    let (profile, diagnostics) = parser.parse()

    #expect(diagnostics.isEmpty)
    #expect(profile.rules[0].operations.count == 2)
    #expect(profile.rules[0].operations[0].name == "file-read-data")
    #expect(profile.rules[0].operations[1].name == "file-write-data")
  }
}

@Suite("Parser Filter Tests")
struct ParserFilterTests {
  @Test("Parse literal filter")
  func testParseLiteralFilter() {
    let source = "(allow file-read-data (literal \"/etc/passwd\"))"
    let parser = Parser(source: source)
    let (profile, diagnostics) = parser.parse()

    #expect(diagnostics.isEmpty)
    #expect(profile.rules[0].filters.count == 1)
    if case .simple(let type, _, let value, _) = profile.rules[0].filters[0] {
      #expect(type == "literal")
      #expect(value.stringValue == "/etc/passwd")
    } else {
      Issue.record("Expected simple filter")
    }
  }

  @Test("Parse subpath filter")
  func testParseSubpathFilter() {
    let source = "(allow file-read-data (subpath \"/usr\"))"
    let parser = Parser(source: source)
    let (profile, diagnostics) = parser.parse()

    #expect(diagnostics.isEmpty)
    if case .simple(let type, _, _, _) = profile.rules[0].filters[0] {
      #expect(type == "subpath")
    } else {
      Issue.record("Expected simple filter")
    }
  }

  @Test("Parse require-all filter")
  func testParseRequireAll() {
    let source = """
      (allow file-read-data
        (require-all
          (subpath "/usr")
          (extension "com.apple.app-sandbox.read")))
      """
    let parser = Parser(source: source)
    let (profile, diagnostics) = parser.parse()

    #expect(diagnostics.isEmpty)
    if case .compound(let type, let subFilters, _) = profile.rules[0].filters[0] {
      #expect(type == .requireAll)
      #expect(subFilters.count == 2)
    } else {
      Issue.record("Expected compound filter")
    }
  }

  @Test("Parse require-any filter")
  func testParseRequireAny() {
    let source = """
      (allow file-read-data
        (require-any
          (literal "/a")
          (literal "/b")))
      """
    let parser = Parser(source: source)
    let (profile, diagnostics) = parser.parse()

    #expect(diagnostics.isEmpty)
    if case .compound(let type, let subFilters, _) = profile.rules[0].filters[0] {
      #expect(type == .requireAny)
      #expect(subFilters.count == 2)
    } else {
      Issue.record("Expected compound filter")
    }
  }

  @Test("Parse require-not filter")
  func testParseRequireNot() {
    let source = "(allow file-read-data (require-not (literal \"/secret\")))"
    let parser = Parser(source: source)
    let (profile, diagnostics) = parser.parse()

    #expect(diagnostics.isEmpty)
    if case .not(let subFilter, _) = profile.rules[0].filters[0] {
      if case .simple(let type, _, _, _) = subFilter {
        #expect(type == "literal")
      } else {
        Issue.record("Expected simple sub-filter")
      }
    } else {
      Issue.record("Expected not filter")
    }
  }
}

@Suite("Parser Complete Profile Tests")
struct ParserCompleteProfileTests {
  @Test("Parse complete profile")
  func testParseCompleteProfile() {
    let source = """
      (version 1)

      (debug deny)

      (import "system.sb")

      (deny default)

      (allow file-read-data
        (subpath "/usr"))

      (allow mach-lookup
        (global-name "com.apple.system.logger"))
      """
    let parser = Parser(source: source)
    let (profile, diagnostics) = parser.parse()

    #expect(diagnostics.isEmpty)
    #expect(profile.version?.version == 1)
    #expect(profile.debugMode?.action == .deny)
    #expect(profile.imports.count == 1)
    #expect(profile.rules.count == 3)
  }
}

@Suite("Parser Error Recovery Tests")
struct ParserErrorRecoveryTests {
  @Test("Missing closing paren")
  func testMissingCloseParen() {
    let source = "(version 1"
    let parser = Parser(source: source)
    let (_, diagnostics) = parser.parse()

    #expect(!diagnostics.isEmpty)
    #expect(diagnostics.contains { $0.code == .expectedCloseParen })
  }

  @Test("Invalid form continues parsing")
  func testInvalidFormContinues() {
    let source = """
      (invalid-form)
      (version 1)
      """
    let parser = Parser(source: source)
    let (profile, _) = parser.parse()

    // Should still parse the version
    #expect(profile.version?.version == 1)
  }
}
