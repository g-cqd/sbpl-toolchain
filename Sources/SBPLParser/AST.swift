import SBPLCore

/// Base protocol for all AST nodes.
public protocol ASTNode: Sendable {
  /// The source range of this node.
  var range: SourceRange { get }
}

/// A complete SBPL profile.
public struct Profile: ASTNode, Sendable {
  public let range: SourceRange
  public let version: VersionDecl?
  public let imports: [ImportDecl]
  public let definitions: [DefineDecl]
  public let rules: [Rule]
  public let debugMode: DebugDecl?

  public init(
    range: SourceRange,
    version: VersionDecl?,
    imports: [ImportDecl],
    definitions: [DefineDecl],
    rules: [Rule],
    debugMode: DebugDecl?
  ) {
    self.range = range
    self.version = version
    self.imports = imports
    self.definitions = definitions
    self.rules = rules
    self.debugMode = debugMode
  }
}

/// Version declaration: (version 1)
public struct VersionDecl: ASTNode, Sendable {
  public let range: SourceRange
  public let version: Int

  public init(range: SourceRange, version: Int) {
    self.range = range
    self.version = version
  }
}

/// Debug declaration: (debug deny) or (debug allow)
public struct DebugDecl: ASTNode, Sendable {
  public let range: SourceRange
  public let action: SandboxAction

  public init(range: SourceRange, action: SandboxAction) {
    self.range = range
    self.action = action
  }
}

/// Import declaration: (import "system.sb")
public struct ImportDecl: ASTNode, Sendable {
  public let range: SourceRange
  public let path: String
  public let pathRange: SourceRange

  public init(range: SourceRange, path: String, pathRange: SourceRange) {
    self.range = range
    self.path = path
    self.pathRange = pathRange
  }
}

/// Define declaration: (define name value) or (define (name args...) body)
public struct DefineDecl: ASTNode, Sendable {
  public let range: SourceRange
  public let name: String
  public let nameRange: SourceRange
  public let value: Expr

  public init(range: SourceRange, name: String, nameRange: SourceRange, value: Expr) {
    self.range = range
    self.name = name
    self.nameRange = nameRange
    self.value = value
  }
}

/// A sandbox rule (allow or deny).
public struct Rule: ASTNode, Sendable {
  public let range: SourceRange
  public let action: SandboxAction
  public let operations: [OperationRef]
  public let filters: [Filter]

  public init(range: SourceRange, action: SandboxAction, operations: [OperationRef], filters: [Filter]) {
    self.range = range
    self.action = action
    self.operations = operations
    self.filters = filters
  }
}

/// Reference to an operation (e.g., file-read-data, file-read*).
public struct OperationRef: ASTNode, Sendable {
  public let range: SourceRange
  public let name: String

  public init(range: SourceRange, name: String) {
    self.range = range
    self.name = name
  }
}

/// A filter expression.
public indirect enum Filter: ASTNode, Sendable {
  /// Simple filter: (literal "/path"), (subpath "/dir"), etc.
  case simple(type: String, typeRange: SourceRange, value: Expr, range: SourceRange)

  /// Compound filter: (require-all ...) or (require-any ...)
  case compound(type: CompoundType, filters: [Filter], range: SourceRange)

  /// Negation filter: (require-not ...)
  case not(filter: Filter, range: SourceRange)

  /// Generic S-expression filter (for unknown/complex filters)
  case expression(Expr, range: SourceRange)

  public var range: SourceRange {
    switch self {
    case .simple(_, _, _, let range),
      .compound(_, _, let range),
      .not(_, let range),
      .expression(_, let range):
      return range
    }
  }
}

/// Compound filter types.
public enum CompoundType: String, Sendable {
  case requireAll = "require-all"
  case requireAny = "require-any"
}

/// Expression types in SBPL.
/// Named `Expr` to avoid conflict with Foundation.Expression.
public indirect enum Expr: ASTNode, Sendable {
  /// Integer literal
  case integer(Int, range: SourceRange)

  /// String literal
  case string(String, range: SourceRange)

  /// Raw string literal
  case rawString(String, range: SourceRange)

  /// Boolean literal
  case boolean(Bool, range: SourceRange)

  /// Symbol/identifier
  case symbol(String, range: SourceRange)

  /// S-expression (list)
  case list([Expr], range: SourceRange)

  /// Quoted expression
  case quoted(Expr, range: SourceRange)

  public var range: SourceRange {
    switch self {
    case .integer(_, let range),
      .string(_, let range),
      .rawString(_, let range),
      .boolean(_, let range),
      .symbol(_, let range),
      .list(_, let range),
      .quoted(_, let range):
      return range
    }
  }

  /// Extract string value if this is a string or raw string.
  public var stringValue: String? {
    switch self {
    case .string(let s, _), .rawString(let s, _):
      return s
    default:
      return nil
    }
  }

  /// Extract symbol name if this is a symbol.
  public var symbolName: String? {
    if case .symbol(let name, _) = self {
      return name
    }
    return nil
  }

  /// Extract list elements if this is a list.
  public var listElements: [Expr]? {
    if case .list(let elements, _) = self {
      return elements
    }
    return nil
  }
}

// MARK: - CustomStringConvertible

extension Expr: CustomStringConvertible {
  public var description: String {
    switch self {
    case .integer(let n, _):
      return "\(n)"
    case .string(let s, _):
      return "\"\(s)\""
    case .rawString(let s, _):
      return "#\"\(s)\""
    case .boolean(let b, _):
      return b ? "#t" : "#f"
    case .symbol(let s, _):
      return s
    case .list(let elements, _):
      return "(\(elements.map(\.description).joined(separator: " ")))"
    case .quoted(let expr, _):
      return "'\(expr)"
    }
  }
}
