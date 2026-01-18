import SBPLCore
import SBPLLexer

/// A parser for SBPL (Sandbox Profile Language).
public final class Parser: @unchecked Sendable {
  private let tokens: [Token]
  private var current: Int = 0
  private var diagnostics: [Diagnostic] = []

  /// Creates a new parser for the given tokens.
  public init(tokens: [Token]) {
    self.tokens = tokens
  }

  /// Creates a new parser for the given source text.
  public convenience init(source: String, path: String? = nil) {
    let lexer = Lexer(text: source, path: path)
    self.init(tokens: lexer.tokenize())
  }

  /// Parses the source and returns the AST.
  public func parse() -> (profile: Profile, diagnostics: [Diagnostic]) {
    let startPos = currentToken.range.start
    var version: VersionDecl?
    var debugMode: DebugDecl?
    var imports: [ImportDecl] = []
    var definitions: [DefineDecl] = []
    var rules: [Rule] = []

    while !isAtEnd {
      do {
        if let decl = try parseTopLevel() {
          switch decl {
          case .version(let v):
            if version != nil {
              addError(.duplicateDefinition, "Duplicate version declaration", at: v.range)
            }
            version = v
          case .debug(let d):
            debugMode = d
          case .import_(let i):
            imports.append(i)
          case .define(let d):
            definitions.append(d)
          case .rule(let r):
            rules.append(r)
          case .other:
            break  // Skip unrecognized top-level forms
          }
        }
      } catch {
        // Error recovery: skip to next top-level form
        synchronize()
      }
    }

    let endPos = tokens.last?.range.end ?? startPos
    let profile = Profile(
      range: SourceRange(start: startPos, end: endPos),
      version: version,
      imports: imports,
      definitions: definitions,
      rules: rules,
      debugMode: debugMode
    )

    return (profile, diagnostics)
  }

  /// Parses a single expression (for testing/REPL use).
  public func parseExpression() -> Expr? {
    try? scanExpr()
  }

  // MARK: - Top-Level Parsing

  private enum TopLevelDecl {
    case version(VersionDecl)
    case debug(DebugDecl)
    case import_(ImportDecl)
    case define(DefineDecl)
    case rule(Rule)
    case other
  }

  private func parseTopLevel() throws -> TopLevelDecl? {
    guard !isAtEnd else { return nil }

    // Expect a list starting with (
    guard case .leftParen = currentToken.kind else {
      addError(.unexpectedToken, "Expected '(' to start a declaration", at: currentToken.range)
      advance()
      return nil
    }

    let startToken = currentToken
    advance()  // consume (

    // Get the form name
    guard case .symbol(let formName) = currentToken.kind else {
      addError(.expectedExpression, "Expected form name", at: currentToken.range)
      skipToCloseParen()
      return nil
    }

    let formNameRange = currentToken.range
    advance()  // consume form name

    let result: TopLevelDecl

    switch formName {
    case "version":
      result = try .version(parseVersionBody(startToken: startToken))

    case "debug":
      result = try .debug(parseDebugBody(startToken: startToken))

    case "import":
      result = try .import_(parseImportBody(startToken: startToken))

    case "define":
      result = try .define(parseDefineBody(startToken: startToken))

    case "allow":
      result = try .rule(parseRuleBody(action: .allow, startToken: startToken))

    case "deny":
      result = try .rule(parseRuleBody(action: .deny, startToken: startToken))

    default:
      // Unknown form - skip it but don't error (could be macro, etc.)
      skipToCloseParen()
      result = .other
    }

    return result
  }

  // MARK: - Declaration Parsing

  private func parseVersionBody(startToken: Token) throws -> VersionDecl {
    guard case .integer(let version) = currentToken.kind else {
      addError(.expectedExpression, "Expected version number", at: currentToken.range)
      skipToCloseParen()
      throw ParseError.expected("version number")
    }
    advance()

    try expectCloseParen()

    return VersionDecl(
      range: SourceRange(start: startToken.range.start, end: previousToken.range.end),
      version: version
    )
  }

  private func parseDebugBody(startToken: Token) throws -> DebugDecl {
    guard case .symbol(let actionName) = currentToken.kind else {
      addError(.expectedExpression, "Expected 'allow' or 'deny'", at: currentToken.range)
      skipToCloseParen()
      throw ParseError.expected("action")
    }

    let action: SandboxAction
    switch actionName {
    case "allow":
      action = .allow
    case "deny":
      action = .deny
    default:
      addError(.invalidForm, "Expected 'allow' or 'deny', got '\(actionName)'", at: currentToken.range)
      action = .deny
    }
    advance()

    try expectCloseParen()

    return DebugDecl(
      range: SourceRange(start: startToken.range.start, end: previousToken.range.end),
      action: action
    )
  }

  private func parseImportBody(startToken: Token) throws -> ImportDecl {
    guard case .string(let path) = currentToken.kind else {
      addError(.expectedExpression, "Expected import path string", at: currentToken.range)
      skipToCloseParen()
      throw ParseError.expected("import path")
    }

    let pathRange = currentToken.range
    advance()

    try expectCloseParen()

    return ImportDecl(
      range: SourceRange(start: startToken.range.start, end: previousToken.range.end),
      path: path,
      pathRange: pathRange
    )
  }

  private func parseDefineBody(startToken: Token) throws -> DefineDecl {
    let name: String
    let nameRange: SourceRange

    // Name could be a symbol or a list (for function definitions)
    if case .symbol(let n) = currentToken.kind {
      name = n
      nameRange = currentToken.range
      advance()
    } else if case .leftParen = currentToken.kind {
      // Function definition: (define (name args...) body)
      advance()
      guard case .symbol(let n) = currentToken.kind else {
        addError(.expectedExpression, "Expected function name", at: currentToken.range)
        throw ParseError.expected("function name")
      }
      name = n
      nameRange = currentToken.range
      advance()

      // Skip arguments - we'll just capture them as part of the value expression
      // Backtrack and parse the whole thing as a list
      skipToCloseParen()
    } else {
      addError(.expectedExpression, "Expected definition name", at: currentToken.range)
      skipToCloseParen()
      throw ParseError.expected("definition name")
    }

    // Parse the value expression
    let value = try scanExpr()

    try expectCloseParen()

    return DefineDecl(
      range: SourceRange(start: startToken.range.start, end: previousToken.range.end),
      name: name,
      nameRange: nameRange,
      value: value
    )
  }

  private func parseRuleBody(action: SandboxAction, startToken: Token) throws -> Rule {
    var operations: [OperationRef] = []
    var filters: [Filter] = []

    // Parse operations and filters
    while !isAtEnd && !check(.rightParen) {
      if case .symbol(let name) = currentToken.kind {
        // This is an operation name
        operations.append(OperationRef(range: currentToken.range, name: name))
        advance()
      } else if case .leftParen = currentToken.kind {
        // This is a filter
        if let filter = try? parseFilter() {
          filters.append(filter)
        } else {
          skipToCloseParen()
        }
      } else {
        addError(.unexpectedToken, "Unexpected token in rule", at: currentToken.range)
        advance()
      }
    }

    try expectCloseParen()

    return Rule(
      range: SourceRange(start: startToken.range.start, end: previousToken.range.end),
      action: action,
      operations: operations,
      filters: filters
    )
  }

  // MARK: - Filter Parsing

  private func parseFilter() throws -> Filter {
    guard case .leftParen = currentToken.kind else {
      throw ParseError.expected("filter")
    }

    let startToken = currentToken
    advance()

    guard case .symbol(let filterType) = currentToken.kind else {
      addError(.expectedExpression, "Expected filter type", at: currentToken.range)
      skipToCloseParen()
      throw ParseError.expected("filter type")
    }

    let typeRange = currentToken.range
    advance()

    let filter: Filter

    switch filterType {
    case "require-all":
      var subFilters: [Filter] = []
      while !isAtEnd && !check(.rightParen) {
        if let f = try? parseFilter() {
          subFilters.append(f)
        } else if case .leftParen = currentToken.kind {
          skipToCloseParen()
        } else {
          advance()
        }
      }
      try expectCloseParen()
      filter = .compound(
        type: .requireAll,
        filters: subFilters,
        range: SourceRange(start: startToken.range.start, end: previousToken.range.end)
      )

    case "require-any":
      var subFilters: [Filter] = []
      while !isAtEnd && !check(.rightParen) {
        if let f = try? parseFilter() {
          subFilters.append(f)
        } else if case .leftParen = currentToken.kind {
          skipToCloseParen()
        } else {
          advance()
        }
      }
      try expectCloseParen()
      filter = .compound(
        type: .requireAny,
        filters: subFilters,
        range: SourceRange(start: startToken.range.start, end: previousToken.range.end)
      )

    case "require-not":
      let subFilter = try parseFilter()
      try expectCloseParen()
      filter = .not(
        filter: subFilter,
        range: SourceRange(start: startToken.range.start, end: previousToken.range.end)
      )

    default:
      // Simple filter with a value
      let value = try scanExpr()
      // Skip any additional arguments (some filters have multiple)
      while !isAtEnd && !check(.rightParen) {
        _ = try? scanExpr()
      }
      try expectCloseParen()
      filter = .simple(
        type: filterType,
        typeRange: typeRange,
        value: value,
        range: SourceRange(start: startToken.range.start, end: previousToken.range.end)
      )
    }

    return filter
  }

  // MARK: - Expr Parsing

  private func scanExpr() throws -> Expr {
    switch currentToken.kind {
    case .integer(let n):
      let range = currentToken.range
      advance()
      return .integer(n, range: range)

    case .string(let s):
      let range = currentToken.range
      advance()
      return .string(s, range: range)

    case .rawString(let s):
      let range = currentToken.range
      advance()
      return .rawString(s, range: range)

    case .boolean(let b):
      let range = currentToken.range
      advance()
      return .boolean(b, range: range)

    case .symbol(let s):
      let range = currentToken.range
      advance()
      return .symbol(s, range: range)

    case .leftParen:
      return try parseList()

    default:
      addError(.expectedExpression, "Expected expression", at: currentToken.range)
      throw ParseError.expected("expression")
    }
  }

  private func parseList() throws -> Expr {
    guard case .leftParen = currentToken.kind else {
      throw ParseError.expected("list")
    }

    let startToken = currentToken
    advance()

    var elements: [Expr] = []

    while !isAtEnd && !check(.rightParen) {
      let expr = try scanExpr()
      elements.append(expr)
    }

    try expectCloseParen()

    return .list(
      elements,
      range: SourceRange(start: startToken.range.start, end: previousToken.range.end)
    )
  }

  // MARK: - Helpers

  private var currentToken: Token {
    tokens[current]
  }

  private var previousToken: Token {
    tokens[max(0, current - 1)]
  }

  private var isAtEnd: Bool {
    currentToken.kind.isEOF
  }

  private func check(_ kind: TokenKind) -> Bool {
    if isAtEnd { return false }
    return tokenKindMatches(currentToken.kind, kind)
  }

  private func tokenKindMatches(_ a: TokenKind, _ b: TokenKind) -> Bool {
    switch (a, b) {
    case (.leftParen, .leftParen),
      (.rightParen, .rightParen),
      (.eof, .eof):
      return true
    case (.integer, .integer),
      (.string, .string),
      (.rawString, .rawString),
      (.boolean, .boolean),
      (.symbol, .symbol):
      return true
    default:
      return false
    }
  }

  private func advance() {
    if !isAtEnd {
      current += 1
    }
  }

  private func expectCloseParen() throws {
    guard case .rightParen = currentToken.kind else {
      addError(.expectedCloseParen, "Expected ')'", at: currentToken.range)
      throw ParseError.expected(")")
    }
    advance()
  }

  private func skipToCloseParen() {
    var depth = 1
    while !isAtEnd && depth > 0 {
      if case .leftParen = currentToken.kind {
        depth += 1
      } else if case .rightParen = currentToken.kind {
        depth -= 1
      }
      advance()
    }
  }

  private func synchronize() {
    advance()
    while !isAtEnd {
      // Sync at top-level open paren
      if case .leftParen = currentToken.kind {
        return
      }
      advance()
    }
  }

  private func addError(_ code: DiagnosticCode, _ message: String, at range: SourceRange) {
    diagnostics.append(Diagnostic.error(code, message: message, at: range))
  }
}

// MARK: - Parse Error

private enum ParseError: Error {
  case expected(String)
}
