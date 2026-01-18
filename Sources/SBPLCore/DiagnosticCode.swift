/// All diagnostic codes used by the SBPL toolchain.
///
/// Codes are organized by category:
/// - L0xx: Lexer errors
/// - P0xx: Parser errors
/// - S0xx: Semantic errors
/// - W0xx: Warnings
public enum DiagnosticCode: String, Hashable, Sendable, Codable {
  // MARK: - Lexer Errors (L0xx)

  /// An unknown or unexpected character was encountered.
  case unknownCharacter = "L001"

  /// A string literal was not terminated before end of line/file.
  case unterminatedString = "L002"

  /// A raw string literal was not terminated.
  case unterminatedRawString = "L003"

  /// An invalid escape sequence in a string.
  case invalidEscapeSequence = "L004"

  /// An invalid integer literal.
  case invalidIntegerLiteral = "L005"

  /// An unexpected end of file.
  case unexpectedEOF = "L006"

  /// A comment was not terminated.
  case unterminatedComment = "L007"

  /// Invalid hexadecimal escape sequence.
  case invalidHexEscape = "L008"

  // MARK: - Parser Errors (P0xx)

  /// Expected a specific token but found something else.
  case expectedToken = "P001"

  /// Expected an expression.
  case expectedExpression = "P002"

  /// Expected a closing parenthesis.
  case expectedCloseParen = "P003"

  /// Unexpected token in the input.
  case unexpectedToken = "P004"

  /// Missing required argument.
  case missingArgument = "P005"

  /// Too many arguments provided.
  case tooManyArguments = "P006"

  /// Invalid form (e.g., malformed allow/deny).
  case invalidForm = "P007"

  /// Empty list not allowed.
  case emptyListNotAllowed = "P008"

  // MARK: - Semantic Errors (S0xx)

  /// Undefined variable reference.
  case undefinedVariable = "S001"

  /// Undefined function/macro reference.
  case undefinedFunction = "S002"

  /// Type mismatch.
  case typeMismatch = "S003"

  /// Invalid operation name.
  case invalidOperation = "S004"

  /// Invalid filter type.
  case invalidFilterType = "S005"

  /// Duplicate definition.
  case duplicateDefinition = "S006"

  /// Invalid version requirement.
  case invalidVersion = "S007"

  /// Circular import detected.
  case circularImport = "S008"

  /// Import not found.
  case importNotFound = "S009"

  /// Invalid regex pattern.
  case invalidRegex = "S010"

  // MARK: - Warnings (W0xx)

  /// Unreachable code (shadowed by earlier rule).
  case unreachableCode = "W001"

  /// Deprecated feature usage.
  case deprecated = "W002"

  /// Redundant rule (already covered by another rule).
  case redundantRule = "W003"

  /// Unused variable or definition.
  case unusedDefinition = "W004"

  /// Potentially unsafe operation allowed.
  case unsafeOperation = "W005"

  /// Style issue (e.g., inconsistent naming).
  case styleIssue = "W006"

  /// Unknown operation (not in known operations list).
  case unknownOperation = "W007"
}

extension DiagnosticCode {
  /// A human-readable description of this diagnostic code.
  public var description: String {
    switch self {
    // Lexer Errors
    case .unknownCharacter:
      return "Unknown character"
    case .unterminatedString:
      return "Unterminated string literal"
    case .unterminatedRawString:
      return "Unterminated raw string literal"
    case .invalidEscapeSequence:
      return "Invalid escape sequence"
    case .invalidIntegerLiteral:
      return "Invalid integer literal"
    case .unexpectedEOF:
      return "Unexpected end of file"
    case .unterminatedComment:
      return "Unterminated comment"
    case .invalidHexEscape:
      return "Invalid hexadecimal escape sequence"

    // Parser Errors
    case .expectedToken:
      return "Expected token"
    case .expectedExpression:
      return "Expected expression"
    case .expectedCloseParen:
      return "Expected closing parenthesis"
    case .unexpectedToken:
      return "Unexpected token"
    case .missingArgument:
      return "Missing required argument"
    case .tooManyArguments:
      return "Too many arguments"
    case .invalidForm:
      return "Invalid form"
    case .emptyListNotAllowed:
      return "Empty list not allowed"

    // Semantic Errors
    case .undefinedVariable:
      return "Undefined variable"
    case .undefinedFunction:
      return "Undefined function or macro"
    case .typeMismatch:
      return "Type mismatch"
    case .invalidOperation:
      return "Invalid operation name"
    case .invalidFilterType:
      return "Invalid filter type"
    case .duplicateDefinition:
      return "Duplicate definition"
    case .invalidVersion:
      return "Invalid version requirement"
    case .circularImport:
      return "Circular import detected"
    case .importNotFound:
      return "Import not found"
    case .invalidRegex:
      return "Invalid regular expression"

    // Warnings
    case .unreachableCode:
      return "Unreachable code"
    case .deprecated:
      return "Deprecated feature"
    case .redundantRule:
      return "Redundant rule"
    case .unusedDefinition:
      return "Unused definition"
    case .unsafeOperation:
      return "Potentially unsafe operation"
    case .styleIssue:
      return "Style issue"
    case .unknownOperation:
      return "Unknown operation"
    }
  }

  /// The default severity for this diagnostic code.
  public var defaultSeverity: DiagnosticSeverity {
    switch self {
    case .unknownCharacter, .unterminatedString, .unterminatedRawString,
      .invalidEscapeSequence, .invalidIntegerLiteral, .unexpectedEOF,
      .unterminatedComment, .invalidHexEscape,
      .expectedToken, .expectedExpression, .expectedCloseParen,
      .unexpectedToken, .missingArgument, .tooManyArguments,
      .invalidForm, .emptyListNotAllowed,
      .undefinedVariable, .undefinedFunction, .typeMismatch,
      .invalidOperation, .invalidFilterType, .duplicateDefinition,
      .invalidVersion, .circularImport, .importNotFound, .invalidRegex:
      return .error

    case .unreachableCode, .deprecated, .redundantRule, .unusedDefinition,
      .unsafeOperation, .unknownOperation:
      return .warning

    case .styleIssue:
      return .hint
    }
  }
}

extension DiagnosticCode: CustomStringConvertible {}
