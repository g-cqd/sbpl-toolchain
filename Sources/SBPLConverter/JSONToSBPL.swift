import Foundation
import SBPLCore

/// Converts JSON representation back to SBPL source.
public struct JSONToSBPL: Sendable {
  /// Indentation style for output.
  public enum IndentStyle: Sendable {
    case spaces(Int)
    case tabs
  }

  private let indentStyle: IndentStyle

  public init(indentStyle: IndentStyle = .spaces(2)) {
    self.indentStyle = indentStyle
  }

  /// Converts a ProfileJSON to SBPL source text.
  ///
  /// - Parameter profile: The JSON profile to convert.
  /// - Returns: The SBPL source text.
  public func convert(_ profile: ProfileJSON) -> String {
    var lines: [String] = []

    // Version
    if let version = profile.version {
      lines.append("(version \(version))")
      lines.append("")
    }

    // Debug mode
    if let debugMode = profile.debugMode {
      lines.append("(debug \(debugMode))")
      lines.append("")
    }

    // Imports
    if let imports = profile.imports, !imports.isEmpty {
      for importPath in imports {
        lines.append("(import \"\(importPath)\")")
      }
      lines.append("")
    }

    // Definitions
    if let definitions = profile.definitions, !definitions.isEmpty {
      for def in definitions {
        lines.append(convertDefinition(def))
      }
      lines.append("")
    }

    // Rules
    if let rules = profile.rules, !rules.isEmpty {
      for rule in rules {
        lines.append(convertRule(rule))
      }
    }

    return lines.joined(separator: "\n")
  }

  /// Converts a JSON string to SBPL source text.
  ///
  /// - Parameter jsonString: The JSON string.
  /// - Returns: The SBPL source text, or nil if parsing fails.
  public func convert(jsonString: String) throws -> String {
    let decoder = JSONDecoder()
    guard let data = jsonString.data(using: .utf8) else {
      throw ConversionError.invalidJSON("Failed to encode string as UTF-8")
    }

    let profile = try decoder.decode(ProfileJSON.self, from: data)
    return convert(profile)
  }

  // MARK: - Private

  private var indent: String {
    switch indentStyle {
    case .spaces(let n):
      return String(repeating: " ", count: n)
    case .tabs:
      return "\t"
    }
  }

  private func convertDefinition(_ def: DefinitionJSON) -> String {
    let value = convertExpression(def.value)
    return "(define \(def.name) \(value))"
  }

  private func convertRule(_ rule: RuleJSON) -> String {
    var parts: [String] = []
    parts.append("(\(rule.action)")

    // Operations
    for op in rule.operations {
      parts.append(op)
    }

    // Filters
    if let filters = rule.filters, !filters.isEmpty {
      let filterStrs = filters.map { convertFilter($0, depth: 1) }
      if filterStrs.count == 1 && !filterStrs[0].contains("\n") {
        // Single simple filter - inline
        parts.append(filterStrs[0])
        return parts.joined(separator: " ") + ")"
      } else {
        // Multiple or complex filters - one per line
        var result = parts.joined(separator: " ")
        for filterStr in filterStrs {
          result += "\n\(indent)\(filterStr)"
        }
        result += ")"
        return result
      }
    }

    return parts.joined(separator: " ") + ")"
  }

  private func convertFilter(_ filter: FilterJSON, depth: Int) -> String {
    let currentIndent = String(repeating: indent, count: depth)

    switch filter.type {
    case "require-all", "require-any":
      guard let subFilters = filter.filters, !subFilters.isEmpty else {
        return "(\(filter.type))"
      }

      var result = "(\(filter.type)"
      for subFilter in subFilters {
        result += "\n\(currentIndent)\(indent)\(convertFilter(subFilter, depth: depth + 1))"
      }
      result += ")"
      return result

    case "require-not":
      guard let subFilters = filter.filters, let first = subFilters.first else {
        return "(require-not)"
      }
      return "(require-not \(convertFilter(first, depth: depth)))"

    default:
      // Simple filter
      if let value = filter.value {
        return "(\(filter.type) \(convertExpression(value)))"
      } else {
        return "(\(filter.type))"
      }
    }
  }

  private func convertExpression(_ expr: ExpressionJSON) -> String {
    switch expr {
    case .integer(let n):
      return "\(n)"

    case .string(let s):
      // Escape special characters
      let escaped = s
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
        .replacingOccurrences(of: "\n", with: "\\n")
        .replacingOccurrences(of: "\r", with: "\\r")
        .replacingOccurrences(of: "\t", with: "\\t")
      return "\"\(escaped)\""

    case .boolean(let b):
      return b ? "#t" : "#f"

    case .symbol(let s):
      return s

    case .list(let elements):
      if elements.isEmpty {
        return "()"
      }
      // Check for quote
      if elements.count == 2,
        case .symbol("quote") = elements[0]
      {
        return "'\(convertExpression(elements[1]))"
      }
      let inner = elements.map { convertExpression($0) }.joined(separator: " ")
      return "(\(inner))"
    }
  }
}

// MARK: - Errors

public enum ConversionError: Error, LocalizedError {
  case invalidJSON(String)

  public var errorDescription: String? {
    switch self {
    case .invalidJSON(let message):
      return "Invalid JSON: \(message)"
    }
  }
}
