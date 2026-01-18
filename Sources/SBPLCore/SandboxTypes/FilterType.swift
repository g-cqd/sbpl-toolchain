/// The type of matching used by a sandbox filter.
public enum FilterType: String, Codable, Sendable, CaseIterable {
  // MARK: - Path Filters

  /// Exact path match.
  case literal
  /// Path and all its descendants.
  case subpath
  /// Path prefix match.
  case prefix
  /// Regular expression match.
  case regex
  /// Alias for literal (exact path match).
  case path

  // MARK: - Extended Filters (from system profiles)

  /// Home relative path.
  case homeSubpath = "home-subpath"
  /// Home relative literal.
  case homeLiteral = "home-literal"
  /// Home relative prefix.
  case homePrefix = "home-prefix"

  /// Require all filters to match.
  case requireAll = "require-all"
  /// Require any filter to match.
  case requireAny = "require-any"
  /// Require entitlement.
  case requireEntitlement = "require-entitlement"
  /// Require not (negation).
  case requireNot = "require-not"

  /// Mach global name filter.
  case globalName = "global-name"
  /// Mach local name filter.
  case localName = "local-name"
  /// Extension filter.
  case `extension`
  /// Extension class filter.
  case extensionClass = "extension-class"

  /// File mode filter.
  case fileMode = "file-mode"

  /// VNode type filter.
  case vnodeType = "vnode-type"

  /// Device filter (conforms to).
  case deviceConformsTo = "device-conforms-to"
  /// Device major number.
  case deviceMajor = "device-major"
  /// Device minor number.
  case deviceMinor = "device-minor"

  /// I/O Kit class filter.
  case iokitClass = "iokit-class"
  /// I/O Kit property filter.
  case iokitProperty = "iokit-property"
  /// I/O Kit user client class.
  case iokitUserClientClass = "iokit-user-client-class"
  /// I/O Kit registry entry class.
  case iokitRegistryEntryClass = "iokit-registry-entry-class"
  /// I/O Kit connection.
  case iokitConnection = "iokit-connection"

  /// Kext bundle ID filter.
  case kextBundleId = "kext-bundle-id"

  /// Info type filter.
  case infoType = "info-type"

  /// Notification name filter.
  case notificationName = "notification-name"

  /// Preference domain filter.
  case preferenceDomain = "preference-domain"

  /// Apple event destination filter.
  case appleeventDestination = "appleevent-destination"

  /// Target signing identifier.
  case targetSigningIdentifier = "target-signing-identifier"
  /// Target code signature.
  case targetCodeSignature = "target-code-signature"

  /// Sysctl name filter.
  case sysctlName = "sysctl-name"

  /// Semaphore name filter.
  case semaphoreName = "semaphore-name"

  /// Signal filter (signal number).
  case signalNumber = "signal-number"

  /// Socket filter.
  case socketDomain = "socket-domain"
  case socketType = "socket-type"
  case socketProtocol = "socket-protocol"

  /// Network filter types.
  case local
  case remote
  case localIp = "local-ip"
  case remoteIp = "remote-ip"
  case localPort = "local-port"
  case remotePort = "remote-port"

  /// Process filter.
  case process

  /// Right name filter (authorization).
  case rightName = "right-name"

  /// Filesystem name.
  case fsName = "fs-name"
  /// Mount relative.
  case mountRelative = "mount-relative"

  /// XPC service name.
  case xpcServiceName = "xpc-service-name"

  /// Storage class filter.
  case storageClass = "storage-class"
  /// Storage class extension.
  case storageClassExtension = "storage-class-extension"

  /// Random device filter.
  case randomDevice = "random-device"

  /// Debug mode.
  case debugMode = "debug-mode"

  /// Entitlement value filter.
  case entitlementValue = "entitlement-value"

  /// Darwin notification filter.
  case darwinNotification = "darwin-notification"
}

// MARK: - Metadata

extension FilterType {
  /// Whether this filter takes a path as its argument.
  public var isPathFilter: Bool {
    switch self {
    case .literal, .subpath, .prefix, .regex, .path,
      .homeSubpath, .homeLiteral, .homePrefix,
      .mountRelative:
      return true
    default:
      return false
    }
  }

  /// Whether this is a compound filter that contains other filters.
  public var isCompound: Bool {
    switch self {
    case .requireAll, .requireAny, .requireNot:
      return true
    default:
      return false
    }
  }

  /// Human-readable documentation for this filter type.
  public var documentation: String {
    switch self {
    case .literal: return "Match exact path."
    case .subpath: return "Match path and all descendants."
    case .prefix: return "Match path prefix."
    case .regex: return "Match using regular expression."
    case .path: return "Match exact path (alias for literal)."
    case .homeSubpath: return "Match relative to home directory (subpath)."
    case .homeLiteral: return "Match relative to home directory (exact)."
    case .homePrefix: return "Match relative to home directory (prefix)."
    case .requireAll: return "All conditions must match."
    case .requireAny: return "Any condition must match."
    case .requireEntitlement: return "Require specific entitlement."
    case .requireNot: return "Negate the condition."
    case .globalName: return "Match Mach global service name."
    case .localName: return "Match Mach local service name."
    case .extension: return "Match extension token."
    case .extensionClass: return "Match extension class."
    case .fileMode: return "Match file mode/permissions."
    case .vnodeType: return "Match vnode type."
    case .deviceConformsTo: return "Match device conformance."
    case .deviceMajor: return "Match device major number."
    case .deviceMinor: return "Match device minor number."
    case .iokitClass: return "Match I/O Kit class name."
    case .iokitProperty: return "Match I/O Kit property."
    case .iokitUserClientClass: return "Match I/O Kit user client class."
    case .iokitRegistryEntryClass: return "Match I/O Kit registry entry class."
    case .iokitConnection: return "Match I/O Kit connection."
    case .kextBundleId: return "Match kernel extension bundle ID."
    case .infoType: return "Match info type."
    case .notificationName: return "Match notification name."
    case .preferenceDomain: return "Match preference domain."
    case .appleeventDestination: return "Match Apple Event destination."
    case .targetSigningIdentifier: return "Match target signing identifier."
    case .targetCodeSignature: return "Match target code signature."
    case .sysctlName: return "Match sysctl name."
    case .semaphoreName: return "Match semaphore name."
    case .signalNumber: return "Match signal number."
    case .socketDomain: return "Match socket domain."
    case .socketType: return "Match socket type."
    case .socketProtocol: return "Match socket protocol."
    case .local: return "Match local address."
    case .remote: return "Match remote address."
    case .localIp: return "Match local IP address."
    case .remoteIp: return "Match remote IP address."
    case .localPort: return "Match local port."
    case .remotePort: return "Match remote port."
    case .process: return "Match process."
    case .rightName: return "Match authorization right name."
    case .fsName: return "Match filesystem name."
    case .mountRelative: return "Match relative to mount point."
    case .xpcServiceName: return "Match XPC service name."
    case .storageClass: return "Match storage class."
    case .storageClassExtension: return "Match storage class extension."
    case .randomDevice: return "Match random device."
    case .debugMode: return "Debug mode."
    case .entitlementValue: return "Match entitlement value."
    case .darwinNotification: return "Match Darwin notification name."
    }
  }
}
