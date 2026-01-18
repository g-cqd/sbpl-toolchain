import Foundation
import SBPLCore
import SBPLParser

/// Converts SBPL source to JSON representation.
public struct SBPLToJSON: Sendable {
  public init() {}

  /// Converts SBPL source text to JSON.
  ///
  /// - Parameters:
  ///   - source: The SBPL source text.
  ///   - path: Optional file path for diagnostics.
  /// - Returns: The conversion result containing the JSON profile and diagnostics.
  public func convert(source: String, path: String? = nil) -> ConversionResult {
    let parser = Parser(source: source, path: path)
    let (profile, diagnostics) = parser.parse()

    let json = convertProfile(profile)

    return ConversionResult(profile: json, diagnostics: diagnostics)
  }

  /// Converts a parsed profile AST to JSON.
  public func convertProfile(_ profile: Profile) -> ProfileJSON {
    var json = ProfileJSON()

    json.version = profile.version?.version

    if let debugMode = profile.debugMode {
      json.debugMode = debugMode.action.rawValue
    }

    if !profile.imports.isEmpty {
      json.imports = profile.imports.map { $0.path }
    }

    if !profile.definitions.isEmpty {
      json.definitions = profile.definitions.map { convertDefinition($0) }
    }

    if !profile.rules.isEmpty {
      json.rules = profile.rules.map { convertRule($0) }
    }

    return json
  }

  private func convertDefinition(_ def: DefineDecl) -> DefinitionJSON {
    DefinitionJSON(
      name: def.name,
      value: convertExpr(def.value)
    )
  }

  private func convertRule(_ rule: Rule) -> RuleJSON {
    var json = RuleJSON(
      action: rule.action.rawValue,
      operations: rule.operations.map { $0.name }
    )

    if !rule.filters.isEmpty {
      json.filters = rule.filters.map { convertFilter($0) }
    }

    return json
  }

  private func convertFilter(_ filter: Filter) -> FilterJSON {
    switch filter {
    case .simple(let type, _, let value, _):
      return FilterJSON(type: type, value: convertExpr(value))

    case .compound(let type, let subFilters, _):
      return FilterJSON(
        type: type.rawValue,
        filters: subFilters.map { convertFilter($0) }
      )

    case .not(let subFilter, _):
      return FilterJSON(
        type: "require-not",
        filters: [convertFilter(subFilter)]
      )

    case .expression(let expr, _):
      // For generic expressions, wrap in a filter
      return FilterJSON(type: "expression", value: convertExpr(expr))
    }
  }

  private func convertExpr(_ expr: Expr) -> ExpressionJSON {
    switch expr {
    case .integer(let n, _):
      return .integer(n)

    case .string(let s, _), .rawString(let s, _):
      return .string(s)

    case .boolean(let b, _):
      return .boolean(b)

    case .symbol(let s, _):
      return .symbol(s)

    case .list(let elements, _):
      return .list(elements.map { convertExpr($0) })

    case .quoted(let inner, _):
      return .list([.symbol("quote"), convertExpr(inner)])
    }
  }
}

// MARK: - JSON Output

extension SBPLToJSON {
  /// Converts SBPL source to a JSON string.
  ///
  /// - Parameters:
  ///   - source: The SBPL source text.
  ///   - path: Optional file path for diagnostics.
  ///   - prettyPrint: Whether to format the JSON with indentation.
  /// - Returns: A tuple of (jsonString, diagnostics).
  public func convertToString(
    source: String,
    path: String? = nil,
    prettyPrint: Bool = true
  ) -> (json: String?, diagnostics: [Diagnostic]) {
    let result = convert(source: source, path: path)

    guard let profile = result.profile else {
      return (nil, result.diagnostics)
    }

    let encoder = JSONEncoder()
    if prettyPrint {
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    do {
      let data = try encoder.encode(profile)
      let jsonString = String(data: data, encoding: .utf8)
      return (jsonString, result.diagnostics)
    } catch {
      let errorDiag = Diagnostic.error(
        .invalidForm,
        message: "Failed to encode JSON: \(error.localizedDescription)",
        at: SourceRange(position: .zero)
      )
      return (nil, result.diagnostics + [errorDiag])
    }
  }
}
