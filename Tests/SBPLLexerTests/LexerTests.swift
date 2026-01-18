import Testing

@testable import SBPLCore
@testable import SBPLLexer

@Suite("Lexer Basic Tests")
struct LexerBasicTests {
  @Test("Lex empty input")
  func testEmptyInput() {
    let lexer = Lexer(text: "")
    let tokens = lexer.tokenize()

    #expect(tokens.count == 1)
    #expect(tokens[0].kind.isEOF)
  }

  @Test("Lex whitespace only")
  func testWhitespaceOnly() {
    let lexer = Lexer(text: "   \n\t  ")
    let tokens = lexer.tokenize()

    #expect(tokens.count == 1)
    #expect(tokens[0].kind.isEOF)
    #expect(!tokens[0].leadingTrivia.isEmpty)
  }

  @Test("Lex parentheses")
  func testParentheses() {
    let lexer = Lexer(text: "(())")
    let tokens = lexer.tokenize()

    #expect(tokens.count == 5)  // ( ( ) ) eof
    #expect(tokens[0].kind == .leftParen)
    #expect(tokens[1].kind == .leftParen)
    #expect(tokens[2].kind == .rightParen)
    #expect(tokens[3].kind == .rightParen)
    #expect(tokens[4].kind.isEOF)
  }
}

@Suite("Lexer Symbol Tests")
struct LexerSymbolTests {
  @Test("Lex simple symbol")
  func testSimpleSymbol() {
    let lexer = Lexer(text: "allow")
    let tokens = lexer.tokenize()

    #expect(tokens.count == 2)
    #expect(tokens[0].kind == .symbol("allow"))
  }

  @Test("Lex hyphenated symbol")
  func testHyphenatedSymbol() {
    let lexer = Lexer(text: "file-read-data")
    let tokens = lexer.tokenize()

    #expect(tokens.count == 2)
    #expect(tokens[0].kind == .symbol("file-read-data"))
  }

  @Test("Lex symbol with asterisk")
  func testSymbolWithAsterisk() {
    let lexer = Lexer(text: "file-read*")
    let tokens = lexer.tokenize()

    #expect(tokens.count == 2)
    #expect(tokens[0].kind == .symbol("file-read*"))
  }

  @Test("Lex symbol with special characters")
  func testSymbolWithSpecialChars() {
    let lexer = Lexer(text: "require-all")
    let tokens = lexer.tokenize()

    #expect(tokens.count == 2)
    #expect(tokens[0].kind == .symbol("require-all"))
  }

  @Test("Lex version symbol")
  func testVersionSymbol() {
    let lexer = Lexer(text: "version")
    let tokens = lexer.tokenize()

    #expect(tokens.count == 2)
    #expect(tokens[0].kind == .symbol("version"))
  }
}

@Suite("Lexer Integer Tests")
struct LexerIntegerTests {
  @Test("Lex positive integer")
  func testPositiveInteger() {
    let lexer = Lexer(text: "42")
    let tokens = lexer.tokenize()

    #expect(tokens.count == 2)
    #expect(tokens[0].kind == .integer(42))
  }

  @Test("Lex negative integer")
  func testNegativeInteger() {
    let lexer = Lexer(text: "-17")
    let tokens = lexer.tokenize()

    #expect(tokens.count == 2)
    #expect(tokens[0].kind == .integer(-17))
  }

  @Test("Lex zero")
  func testZero() {
    let lexer = Lexer(text: "0")
    let tokens = lexer.tokenize()

    #expect(tokens.count == 2)
    #expect(tokens[0].kind == .integer(0))
  }
}

@Suite("Lexer Boolean Tests")
struct LexerBooleanTests {
  @Test("Lex true")
  func testTrue() {
    let lexer = Lexer(text: "#t")
    let tokens = lexer.tokenize()

    #expect(tokens.count == 2)
    #expect(tokens[0].kind == .boolean(true))
  }

  @Test("Lex false")
  func testFalse() {
    let lexer = Lexer(text: "#f")
    let tokens = lexer.tokenize()

    #expect(tokens.count == 2)
    #expect(tokens[0].kind == .boolean(false))
  }

  @Test("Lex uppercase true")
  func testUppercaseTrue() {
    let lexer = Lexer(text: "#T")
    let tokens = lexer.tokenize()

    #expect(tokens.count == 2)
    #expect(tokens[0].kind == .boolean(true))
  }
}

@Suite("Lexer String Tests")
struct LexerStringTests {
  @Test("Lex simple string")
  func testSimpleString() {
    let lexer = Lexer(text: "\"hello\"")
    let tokens = lexer.tokenize()

    #expect(tokens.count == 2)
    #expect(tokens[0].kind == .string("hello"))
  }

  @Test("Lex empty string")
  func testEmptyString() {
    let lexer = Lexer(text: "\"\"")
    let tokens = lexer.tokenize()

    #expect(tokens.count == 2)
    #expect(tokens[0].kind == .string(""))
  }

  @Test("Lex string with escaped quote")
  func testEscapedQuote() {
    let lexer = Lexer(text: "\"hello\\\"world\"")
    let tokens = lexer.tokenize()

    #expect(tokens.count == 2)
    #expect(tokens[0].kind == .string("hello\"world"))
  }

  @Test("Lex string with escape sequences")
  func testEscapeSequences() {
    let lexer = Lexer(text: "\"line1\\nline2\\ttab\"")
    let tokens = lexer.tokenize()

    #expect(tokens.count == 2)
    #expect(tokens[0].kind == .string("line1\nline2\ttab"))
  }

  @Test("Lex path string")
  func testPathString() {
    let lexer = Lexer(text: "\"/System/Library/Sandbox/Profiles\"")
    let tokens = lexer.tokenize()

    #expect(tokens.count == 2)
    #expect(tokens[0].kind == .string("/System/Library/Sandbox/Profiles"))
  }
}

@Suite("Lexer Raw String Tests")
struct LexerRawStringTests {
  @Test("Lex raw string")
  func testRawString() {
    // SBPL raw strings use #"..." format (not #"..."#)
    let lexer = Lexer(text: "#\"raw string\"")
    let tokens = lexer.tokenize()

    #expect(tokens.count == 2)
    #expect(tokens[0].kind == .rawString("raw string"))
  }

  @Test("Lex raw string with backslash")
  func testRawStringWithBackslash() {
    let lexer = Lexer(text: "#\"path\\to\\file\"")
    let tokens = lexer.tokenize()

    #expect(tokens.count == 2)
    #expect(tokens[0].kind == .rawString("path\\to\\file"))
  }

  @Test("Lex raw string regex")
  func testRawStringRegex() {
    let lexer = Lexer(text: "#\"/\\.CFUserTextEncoding$\"")
    let tokens = lexer.tokenize()

    #expect(tokens.count == 2)
    #expect(tokens[0].kind == .rawString("/\\.CFUserTextEncoding$"))
  }
}

@Suite("Lexer Comment Tests")
struct LexerCommentTests {
  @Test("Line comment")
  func testLineComment() {
    let lexer = Lexer(text: "; this is a comment\nallow")
    let tokens = lexer.tokenize()

    #expect(tokens.count == 2)  // allow, eof
    #expect(tokens[0].kind == .symbol("allow"))
    #expect(tokens[0].leadingTrivia.hasComments)
  }

  @Test("Block comment")
  func testBlockComment() {
    let lexer = Lexer(text: "#| block comment |# allow")
    let tokens = lexer.tokenize()

    #expect(tokens.count == 2)
    #expect(tokens[0].kind == .symbol("allow"))
    #expect(tokens[0].leadingTrivia.hasComments)
  }

  @Test("Nested block comments")
  func testNestedBlockComments() {
    let lexer = Lexer(text: "#| outer #| inner |# outer |# allow")
    let tokens = lexer.tokenize()

    #expect(tokens.count == 2)
    #expect(tokens[0].kind == .symbol("allow"))
  }

  @Test("Comment at end of line")
  func testTrailingComment() {
    let lexer = Lexer(text: "allow ; trailing comment")
    let tokens = lexer.tokenize()

    #expect(tokens.count == 2)
    #expect(tokens[0].kind == .symbol("allow"))
    #expect(tokens[0].trailingTrivia.hasComments)
  }
}

@Suite("Lexer Trivia Tests")
struct LexerTriviaTests {
  @Test("Leading whitespace")
  func testLeadingWhitespace() {
    let lexer = Lexer(text: "   allow")
    let tokens = lexer.tokenize()

    #expect(tokens[0].leadingTrivia.pieces.count == 1)
    if case .spaces(3) = tokens[0].leadingTrivia.pieces[0] {
      // OK
    } else {
      Issue.record("Expected 3 spaces")
    }
  }

  @Test("Trailing whitespace")
  func testTrailingWhitespace() {
    let lexer = Lexer(text: "allow   \n")
    let tokens = lexer.tokenize()

    #expect(!tokens[0].trailingTrivia.isEmpty)
    #expect(tokens[0].trailingTrivia.containsNewline)
  }

  @Test("Mixed trivia")
  func testMixedTrivia() {
    let lexer = Lexer(text: "  \t\n  allow")
    let tokens = lexer.tokenize()

    #expect(tokens[0].leadingTrivia.containsNewline)
    #expect(tokens[0].leadingTrivia.pieces.count > 1)
  }
}

@Suite("Lexer Error Recovery Tests")
struct LexerErrorRecoveryTests {
  @Test("Unknown character")
  func testUnknownCharacter() {
    let lexer = Lexer(text: "@allow")
    let tokens = lexer.tokenize()

    #expect(tokens.count == 3)  // @ allow eof
    #expect(tokens[0].kind == .unknown(Character("@")))
    #expect(tokens[1].kind == .symbol("allow"))
    #expect(lexer.diagnostics.count == 1)
  }

  @Test("Unterminated string")
  func testUnterminatedString() {
    let lexer = Lexer(text: "\"unterminated\nallow")
    let tokens = lexer.tokenize()

    #expect(lexer.diagnostics.count >= 1)
    #expect(lexer.diagnostics[0].code == .unterminatedString)
  }

  @Test("Unterminated raw string")
  func testUnterminatedRawString() {
    let lexer = Lexer(text: "#\"unterminated")
    let tokens = lexer.tokenize()

    #expect(lexer.diagnostics.count >= 1)
    #expect(lexer.diagnostics[0].code == .unterminatedRawString)
  }
}

@Suite("Lexer Real Profile Tests")
struct LexerRealProfileTests {
  @Test("Lex simple SBPL expression")
  func testSimpleExpression() {
    let source = "(version 1)"
    let lexer = Lexer(text: source)
    let tokens = lexer.tokenize()

    #expect(tokens.count == 5)  // ( version 1 ) eof
    #expect(tokens[0].kind == .leftParen)
    #expect(tokens[1].kind == .symbol("version"))
    #expect(tokens[2].kind == .integer(1))
    #expect(tokens[3].kind == .rightParen)
    #expect(tokens[4].kind.isEOF)
  }

  @Test("Lex allow rule")
  func testAllowRule() {
    let source = "(allow file-read-data (literal \"/etc/passwd\"))"
    let lexer = Lexer(text: source)
    let tokens = lexer.tokenize()

    #expect(lexer.diagnostics.isEmpty)
    // ( allow file-read-data ( literal "/etc/passwd" ) ) eof
    #expect(tokens.count == 9)
  }

  @Test("Lex deny rule")
  func testDenyRule() {
    let source = "(deny default)"
    let lexer = Lexer(text: source)
    let tokens = lexer.tokenize()

    #expect(tokens.count == 5)  // ( deny default ) eof
    #expect(tokens[1].kind == .symbol("deny"))
    #expect(tokens[2].kind == .symbol("default"))
  }

  @Test("Lex multiline profile")
  func testMultilineProfile() {
    let source = """
      (version 1)

      ; Allow reading files
      (allow file-read-data
        (subpath "/usr"))

      (deny default)
      """
    let lexer = Lexer(text: source)
    let tokens = lexer.tokenize()

    #expect(lexer.diagnostics.isEmpty)

    // Count significant tokens (excluding eof)
    let significantTokens = tokens.filter { !$0.kind.isEOF }
    #expect(significantTokens.count > 10)
  }

  @Test("Lex with mach-lookup")
  func testMachLookup() {
    let source = "(allow mach-lookup (global-name \"com.apple.system.logger\"))"
    let lexer = Lexer(text: source)
    let tokens = lexer.tokenize()

    #expect(lexer.diagnostics.isEmpty)
  }

  @Test("Lex require-all filter")
  func testRequireAllFilter() {
    let source = """
      (allow file-read-data
        (require-all
          (subpath "/Applications")
          (extension "com.apple.app-sandbox.read")))
      """
    let lexer = Lexer(text: source)
    let tokens = lexer.tokenize()

    #expect(lexer.diagnostics.isEmpty)
  }
}
