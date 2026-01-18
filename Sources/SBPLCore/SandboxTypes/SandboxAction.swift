/// The action to take when a sandbox rule matches.
public enum SandboxAction: String, Codable, Sendable, CaseIterable {
  /// Allow the operation.
  case allow
  /// Deny the operation.
  case deny

  /// The SBPL representation of this action.
  public var sbplValue: String {
    rawValue
  }
}
