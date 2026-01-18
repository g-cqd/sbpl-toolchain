import Foundation
import SBPLCore

/// JSON-serializable representation of an SBPL profile.
public struct ProfileJSON: Codable, Sendable {
  public var version: Int?
  public var debugMode: String?
  public var imports: [String]?
  public var definitions: [DefinitionJSON]?
  public var rules: [RuleJSON]?

  public init(
    version: Int? = nil,
    debugMode: String? = nil,
    imports: [String]? = nil,
    definitions: [DefinitionJSON]? = nil,
    rules: [RuleJSON]? = nil
  ) {
    self.version = version
    self.debugMode = debugMode
    self.imports = imports
    self.definitions = definitions
    self.rules = rules
  }
}

/// JSON-serializable representation of a definition.
public struct DefinitionJSON: Codable, Sendable {
  public var name: String
  public var value: ExpressionJSON

  public init(name: String, value: ExpressionJSON) {
    self.name = name
    self.value = value
  }
}

/// JSON-serializable representation of a rule.
public struct RuleJSON: Codable, Sendable {
  public var action: String
  public var operations: [String]
  public var filters: [FilterJSON]?

  public init(action: String, operations: [String], filters: [FilterJSON]? = nil) {
    self.action = action
    self.operations = operations
    self.filters = filters
  }
}

/// JSON-serializable representation of a filter.
public struct FilterJSON: Codable, Sendable {
  public var type: String
  public var value: ExpressionJSON?
  public var filters: [FilterJSON]?

  public init(type: String, value: ExpressionJSON? = nil, filters: [FilterJSON]? = nil) {
    self.type = type
    self.value = value
    self.filters = filters
  }
}

/// JSON-serializable representation of an expression.
public enum ExpressionJSON: Codable, Sendable {
  case integer(Int)
  case string(String)
  case boolean(Bool)
  case symbol(String)
  case list([ExpressionJSON])

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    if let intValue = try? container.decode(Int.self) {
      self = .integer(intValue)
    } else if let boolValue = try? container.decode(Bool.self) {
      self = .boolean(boolValue)
    } else if let stringValue = try? container.decode(String.self) {
      // Distinguish between string literals and symbols
      if stringValue.hasPrefix("\"") {
        self = .string(String(stringValue.dropFirst().dropLast()))
      } else {
        self = .symbol(stringValue)
      }
    } else if let arrayValue = try? container.decode([ExpressionJSON].self) {
      self = .list(arrayValue)
    } else {
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode ExpressionJSON")
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .integer(let n):
      try container.encode(n)
    case .string(let s):
      try container.encode("\"\(s)\"")
    case .boolean(let b):
      try container.encode(b)
    case .symbol(let s):
      try container.encode(s)
    case .list(let elements):
      try container.encode(elements)
    }
  }
}

// MARK: - Conversion Result

/// Result of parsing and converting an SBPL profile.
public struct ConversionResult: Sendable {
  public let profile: ProfileJSON?
  public let diagnostics: [Diagnostic]
  public let hasErrors: Bool

  public init(profile: ProfileJSON?, diagnostics: [Diagnostic]) {
    self.profile = profile
    self.diagnostics = diagnostics
    self.hasErrors = diagnostics.contains { $0.severity == .error }
  }
}
