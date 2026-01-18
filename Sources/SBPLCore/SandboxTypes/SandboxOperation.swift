/// Sandbox operations that can be allowed or denied.
///
/// Operations use a hierarchical naming scheme where `*` suffix indicates
/// a wildcard matching all sub-operations (e.g., `file-read*` matches
/// `file-read-data`, `file-read-metadata`, etc.).
public enum SandboxOperation: String, Codable, CaseIterable, Sendable {
  // MARK: - Default

  /// Matches all operations not explicitly covered by other rules.
  case `default`

  // MARK: - File Operations

  /// All file operations.
  case fileAll = "file*"
  /// All file read operations.
  case fileReadAll = "file-read*"
  /// Read file contents.
  case fileReadData = "file-read-data"
  /// Read file metadata (stat, etc.).
  case fileReadMetadata = "file-read-metadata"
  /// Read extended attributes.
  case fileReadXattr = "file-read-xattr"
  /// All file write operations.
  case fileWriteAll = "file-write*"
  /// Write file contents.
  case fileWriteData = "file-write-data"
  /// Create new files.
  case fileWriteCreate = "file-write-create"
  /// Delete files.
  case fileWriteUnlink = "file-write-unlink"
  /// Write extended attributes.
  case fileWriteXattr = "file-write-xattr"
  /// Change file mode/permissions.
  case fileWriteMode = "file-write-mode"
  /// Change file owner.
  case fileWriteOwner = "file-write-owner"
  /// Change file flags.
  case fileWriteFlags = "file-write-flags"
  /// File I/O control operations.
  case fileIoctl = "file-ioctl"
  /// Revoke file access.
  case fileRevoke = "file-revoke"
  /// Mount operations.
  case fileMount = "file-mount"
  /// Unmount operations.
  case fileUnmount = "file-unmount"
  /// Set timestamps on files.
  case fileWriteSetugid = "file-write-setugid"
  /// File write times.
  case fileWriteTimes = "file-write-times"
  /// File chroot.
  case fileChroot = "file-chroot"
  /// File link.
  case fileLink = "file-link"
  /// File symlink.
  case fileSymlink = "file-symlink"
  /// File clone.
  case fileClone = "file-clone"
  /// File map executable.
  case fileMapExecutable = "file-map-executable"
  /// Issue file extension.
  case fileIssueExtension = "file-issue-extension"

  // MARK: - Network Operations

  /// All network operations.
  case networkAll = "network*"
  /// Accept incoming network connections.
  case networkInbound = "network-inbound"
  /// Make outgoing network connections.
  case networkOutbound = "network-outbound"
  /// Bind to network sockets.
  case networkBind = "network-bind"

  // MARK: - Process Operations

  /// All process operations.
  case processAll = "process*"
  /// Execute processes.
  case processExec = "process-exec"
  /// Execute interpreter processes.
  case processExecInterpreter = "process-exec-interpreter"
  /// Fork new processes.
  case processFork = "process-fork"
  /// All process info operations.
  case processInfoAll = "process-info*"
  /// Read code signature information.
  case processInfoCodesignature = "process-info-codesignature"
  /// Read process information.
  case processInfoPidinfo = "process-info-pidinfo"
  /// Read process info for listing.
  case processInfoListpids = "process-info-listpids"
  /// Set process information.
  case processInfoSetcontrol = "process-info-setcontrol"
  /// Dirstat process info.
  case processInfoDirstatdev = "process-info-dirstatdev"
  /// Rusage.
  case processInfoRusage = "process-info-rusage"
  /// Send signals to processes.
  case signal

  // MARK: - IPC Operations

  /// All IPC operations.
  case ipcAll = "ipc*"
  /// POSIX shared memory operations.
  case ipcPosixShm = "ipc-posix-shm"
  /// POSIX shared memory read operations.
  case ipcPosixShmReadAll = "ipc-posix-shm-read*"
  /// Create POSIX shared memory.
  case ipcPosixShmWriteCreate = "ipc-posix-shm-write-create"
  /// Write to POSIX shared memory.
  case ipcPosixShmWriteData = "ipc-posix-shm-write-data"
  /// Unlink POSIX shared memory.
  case ipcPosixShmWriteUnlink = "ipc-posix-shm-write-unlink"
  /// POSIX semaphore operations.
  case ipcPosixSem = "ipc-posix-sem"
  /// Open POSIX semaphore.
  case ipcPosixSemOpen = "ipc-posix-sem-open"
  /// Create POSIX semaphore.
  case ipcPosixSemCreate = "ipc-posix-sem-create"
  /// Post POSIX semaphore.
  case ipcPosixSemPost = "ipc-posix-sem-post"
  /// Wait POSIX semaphore.
  case ipcPosixSemWait = "ipc-posix-sem-wait"
  /// Unlink POSIX semaphore.
  case ipcPosixSemUnlink = "ipc-posix-sem-unlink"
  /// System V shared memory.
  case ipcSysvShm = "ipc-sysv-shm"
  /// System V semaphores.
  case ipcSysvSem = "ipc-sysv-sem"
  /// System V message queues.
  case ipcSysvMsg = "ipc-sysv-msg"

  // MARK: - Mach Operations

  /// All Mach IPC operations.
  case machAll = "mach*"
  /// Look up Mach/XPC services.
  case machLookup = "mach-lookup"
  /// Register Mach services.
  case machRegister = "mach-register"
  /// All privileged Mach operations.
  case machPrivAll = "mach-priv*"
  /// Access host port.
  case machPrivHostPort = "mach-priv-host-port"
  /// Access task port.
  case machPrivTaskPort = "mach-priv-task-port"
  /// Access task name.
  case machTaskName = "mach-task-name"
  /// Cross-domain operations.
  case machCrossDomain = "mach-cross-domain-lookup"
  /// Bootstrap operations.
  case machBootstrap = "mach-bootstrap"
  /// Per-user lookup.
  case machPerUserLookup = "mach-per-user-lookup"
  /// Issue Mach extension.
  case machIssueExtension = "mach-issue-extension"

  // MARK: - Sysctl Operations

  /// All sysctl operations.
  case sysctlAll = "sysctl*"
  /// Read sysctl values.
  case sysctlRead = "sysctl-read"
  /// Write sysctl values.
  case sysctlWrite = "sysctl-write"

  // MARK: - System Operations

  /// All system operations.
  case systemAll = "system*"
  /// Socket system calls.
  case systemSocket = "system-socket"
  /// File system control operations.
  case systemFsctl = "system-fsctl"
  /// System information.
  case systemInfo = "system-info"
  /// Scheduler operations.
  case systemSched = "system-sched"
  /// Swap operations.
  case systemSwap = "system-swap"
  /// Audit operations.
  case systemAudit = "system-audit"
  /// MAC label operations.
  case systemMacLabel = "system-mac-label"
  /// Reboot operations.
  case systemReboot = "system-reboot"
  /// Chud operations.
  case systemChud = "system-chud"
  /// Privilege operations.
  case systemPrivilege = "system-privilege"
  /// Debug operations.
  case systemDebug = "system-debug"
  /// Kext operations.
  case systemKextLoad = "system-kext-load"
  /// KAS info.
  case systemKasInfo = "system-kas-info"
  /// Nfssvc.
  case systemNfssvc = "system-nfssvc"
  /// Acct.
  case systemAcct = "system-acct"
  /// Set time.
  case systemSetTime = "system-set-time"

  // MARK: - I/O Kit Operations

  /// All I/O Kit operations.
  case iokitAll = "iokit*"
  /// Open I/O Kit devices.
  case iokitOpen = "iokit-open"
  /// Set I/O Kit properties.
  case iokitSetProperties = "iokit-set-properties"
  /// Get I/O Kit properties.
  case iokitGetProperties = "iokit-get-properties"
  /// Issue I/O Kit extension.
  case iokitIssueExtension = "iokit-issue-extension"
  /// I/O Kit user client class.
  case iokitOpenUserClient = "iokit-open-user-client"
  /// External method.
  case iokitExternalMethod = "iokit-external-method"

  // MARK: - User Preference Operations

  /// All user preference operations.
  case userPreferenceAll = "user-preference*"
  /// Read user preferences.
  case userPreferenceRead = "user-preference-read"
  /// Write user preferences.
  case userPreferenceWrite = "user-preference-write"

  // MARK: - Device Operations

  /// Camera access.
  case deviceCamera = "device-camera"
  /// Microphone access.
  case deviceMicrophone = "device-microphone"

  // MARK: - Other Operations

  /// Launch Services open.
  case lsopen
  /// All NVRAM operations.
  case nvramAll = "nvram*"
  /// Delete NVRAM.
  case nvramDelete = "nvram-delete"
  /// Get NVRAM.
  case nvramGet = "nvram-get"
  /// Set NVRAM.
  case nvramSet = "nvram-set"
  /// Generic fallback operation.
  case generic = "generic-issue-extension"
  /// Authorization operations.
  case authorization = "authorization-right-obtain"
  /// Distributed notification post.
  case distributedNotificationPost = "distributed-notification-post"
  /// Apple events sending.
  case appleeventsSend = "appleevent-send"
  /// Keychain operations.
  case keychainAll = "keychain*"
  /// HID control.
  case hidControl = "hid-control"
  /// Job creation.
  case jobCreation = "job-creation"
  /// Pseudo TTY.
  case pseudoTty = "pseudo-tty"
}

// MARK: - Metadata

extension SandboxOperation {
  /// The category of this operation.
  public var category: OperationCategory {
    switch self {
    case .default:
      return .default

    case .fileAll, .fileReadAll, .fileReadData, .fileReadMetadata, .fileReadXattr,
      .fileWriteAll, .fileWriteData, .fileWriteCreate, .fileWriteUnlink,
      .fileWriteXattr, .fileWriteMode, .fileWriteOwner, .fileWriteFlags,
      .fileIoctl, .fileRevoke, .fileMount, .fileUnmount, .fileWriteSetugid,
      .fileWriteTimes, .fileChroot, .fileLink, .fileSymlink, .fileClone,
      .fileMapExecutable, .fileIssueExtension:
      return .file

    case .networkAll, .networkInbound, .networkOutbound, .networkBind:
      return .network

    case .processAll, .processExec, .processExecInterpreter, .processFork,
      .processInfoAll, .processInfoCodesignature, .processInfoPidinfo,
      .processInfoListpids, .processInfoSetcontrol, .processInfoDirstatdev,
      .processInfoRusage, .signal:
      return .process

    case .ipcAll, .ipcPosixShm, .ipcPosixShmReadAll, .ipcPosixShmWriteCreate,
      .ipcPosixShmWriteData, .ipcPosixShmWriteUnlink, .ipcPosixSem,
      .ipcPosixSemOpen, .ipcPosixSemCreate, .ipcPosixSemPost,
      .ipcPosixSemWait, .ipcPosixSemUnlink, .ipcSysvShm, .ipcSysvSem, .ipcSysvMsg:
      return .ipc

    case .machAll, .machLookup, .machRegister, .machPrivAll, .machPrivHostPort,
      .machPrivTaskPort, .machTaskName, .machCrossDomain, .machBootstrap,
      .machPerUserLookup, .machIssueExtension:
      return .mach

    case .sysctlAll, .sysctlRead, .sysctlWrite:
      return .sysctl

    case .systemAll, .systemSocket, .systemFsctl, .systemInfo, .systemSched,
      .systemSwap, .systemAudit, .systemMacLabel, .systemReboot, .systemChud,
      .systemPrivilege, .systemDebug, .systemKextLoad, .systemKasInfo,
      .systemNfssvc, .systemAcct, .systemSetTime:
      return .system

    case .iokitAll, .iokitOpen, .iokitSetProperties, .iokitGetProperties,
      .iokitIssueExtension, .iokitOpenUserClient, .iokitExternalMethod:
      return .iokit

    case .userPreferenceAll, .userPreferenceRead, .userPreferenceWrite:
      return .userPreference

    case .deviceCamera, .deviceMicrophone:
      return .device

    case .lsopen, .nvramAll, .nvramDelete, .nvramGet, .nvramSet, .generic,
      .authorization, .distributedNotificationPost, .appleeventsSend,
      .keychainAll, .hidControl, .jobCreation, .pseudoTty:
      return .other
    }
  }

  /// Human-readable documentation for this operation.
  public var documentation: String {
    switch self {
    case .default:
      return "Matches all operations not explicitly covered by other rules."
    case .fileAll:
      return "All file operations including read, write, and metadata."
    case .fileReadAll:
      return "All file read operations."
    case .fileReadData:
      return "Read file contents."
    case .fileReadMetadata:
      return "Read file metadata (stat, attributes)."
    case .fileReadXattr:
      return "Read extended attributes."
    case .fileWriteAll:
      return "All file write operations."
    case .fileWriteData:
      return "Write file contents."
    case .fileWriteCreate:
      return "Create new files."
    case .fileWriteUnlink:
      return "Delete files."
    case .fileWriteXattr:
      return "Write extended attributes."
    case .fileWriteMode:
      return "Change file mode/permissions."
    case .fileWriteOwner:
      return "Change file owner."
    case .fileWriteFlags:
      return "Change file flags."
    case .fileIoctl:
      return "File I/O control operations."
    case .fileRevoke:
      return "Revoke file access."
    case .fileMount:
      return "Mount file systems."
    case .fileUnmount:
      return "Unmount file systems."
    case .fileWriteSetugid:
      return "Set user/group ID on execution."
    case .fileWriteTimes:
      return "Write file timestamps."
    case .fileChroot:
      return "Change root directory."
    case .fileLink:
      return "Create hard links."
    case .fileSymlink:
      return "Create symbolic links."
    case .fileClone:
      return "Clone files."
    case .fileMapExecutable:
      return "Map file as executable."
    case .fileIssueExtension:
      return "Issue file extension."
    case .networkAll:
      return "All network operations."
    case .networkInbound:
      return "Accept incoming network connections."
    case .networkOutbound:
      return "Make outgoing network connections."
    case .networkBind:
      return "Bind to network sockets."
    case .processAll:
      return "All process operations."
    case .processExec:
      return "Execute programs."
    case .processExecInterpreter:
      return "Execute interpreter programs."
    case .processFork:
      return "Fork new processes."
    case .processInfoAll:
      return "All process info operations."
    case .processInfoCodesignature:
      return "Read code signature information."
    case .processInfoPidinfo:
      return "Read process information."
    case .processInfoListpids:
      return "List process IDs."
    case .processInfoSetcontrol:
      return "Set process control information."
    case .processInfoDirstatdev:
      return "Read directory stat device info."
    case .processInfoRusage:
      return "Read resource usage information."
    case .signal:
      return "Send signals to processes."
    case .ipcAll:
      return "All IPC operations."
    case .ipcPosixShm:
      return "POSIX shared memory operations."
    case .ipcPosixShmReadAll:
      return "Read POSIX shared memory."
    case .ipcPosixShmWriteCreate:
      return "Create POSIX shared memory."
    case .ipcPosixShmWriteData:
      return "Write to POSIX shared memory."
    case .ipcPosixShmWriteUnlink:
      return "Unlink POSIX shared memory."
    case .ipcPosixSem:
      return "POSIX semaphore operations."
    case .ipcPosixSemOpen:
      return "Open POSIX semaphores."
    case .ipcPosixSemCreate:
      return "Create POSIX semaphores."
    case .ipcPosixSemPost:
      return "Post to POSIX semaphores."
    case .ipcPosixSemWait:
      return "Wait on POSIX semaphores."
    case .ipcPosixSemUnlink:
      return "Unlink POSIX semaphores."
    case .ipcSysvShm:
      return "System V shared memory."
    case .ipcSysvSem:
      return "System V semaphores."
    case .ipcSysvMsg:
      return "System V message queues."
    case .machAll:
      return "All Mach IPC operations."
    case .machLookup:
      return "Look up Mach/XPC services."
    case .machRegister:
      return "Register Mach services."
    case .machPrivAll:
      return "All privileged Mach operations."
    case .machPrivHostPort:
      return "Access host port."
    case .machPrivTaskPort:
      return "Access task port."
    case .machTaskName:
      return "Access task name."
    case .machCrossDomain:
      return "Cross-domain lookup."
    case .machBootstrap:
      return "Bootstrap operations."
    case .machPerUserLookup:
      return "Per-user lookup."
    case .machIssueExtension:
      return "Issue Mach extension."
    case .sysctlAll:
      return "All sysctl operations."
    case .sysctlRead:
      return "Read sysctl values."
    case .sysctlWrite:
      return "Write sysctl values."
    case .systemAll:
      return "All system operations."
    case .systemSocket:
      return "Socket system calls."
    case .systemFsctl:
      return "File system control operations."
    case .systemInfo:
      return "System information."
    case .systemSched:
      return "Scheduler operations."
    case .systemSwap:
      return "Swap operations."
    case .systemAudit:
      return "Audit operations."
    case .systemMacLabel:
      return "MAC label operations."
    case .systemReboot:
      return "Reboot the system."
    case .systemChud:
      return "CHUD operations."
    case .systemPrivilege:
      return "Privilege operations."
    case .systemDebug:
      return "Debug operations."
    case .systemKextLoad:
      return "Load kernel extensions."
    case .systemKasInfo:
      return "Kernel address space info."
    case .systemNfssvc:
      return "NFS service operations."
    case .systemAcct:
      return "Process accounting."
    case .systemSetTime:
      return "Set system time."
    case .iokitAll:
      return "All I/O Kit operations."
    case .iokitOpen:
      return "Open I/O Kit devices."
    case .iokitSetProperties:
      return "Set I/O Kit properties."
    case .iokitGetProperties:
      return "Get I/O Kit properties."
    case .iokitIssueExtension:
      return "Issue I/O Kit extension."
    case .iokitOpenUserClient:
      return "Open I/O Kit user client."
    case .iokitExternalMethod:
      return "Call I/O Kit external method."
    case .userPreferenceAll:
      return "All user preference operations."
    case .userPreferenceRead:
      return "Read user preferences."
    case .userPreferenceWrite:
      return "Write user preferences."
    case .deviceCamera:
      return "Access camera."
    case .deviceMicrophone:
      return "Access microphone."
    case .lsopen:
      return "Launch Services open."
    case .nvramAll:
      return "All NVRAM operations."
    case .nvramDelete:
      return "Delete NVRAM variables."
    case .nvramGet:
      return "Get NVRAM variables."
    case .nvramSet:
      return "Set NVRAM variables."
    case .generic:
      return "Generic issue extension."
    case .authorization:
      return "Obtain authorization rights."
    case .distributedNotificationPost:
      return "Post distributed notifications."
    case .appleeventsSend:
      return "Send Apple events."
    case .keychainAll:
      return "All keychain operations."
    case .hidControl:
      return "HID control access."
    case .jobCreation:
      return "Create jobs."
    case .pseudoTty:
      return "Pseudo terminal access."
    }
  }

  /// The SBPL string representation of this operation.
  public var sbplValue: String {
    rawValue
  }
}

/// Categories of sandbox operations.
public enum OperationCategory: String, Sendable, CaseIterable {
  case `default`
  case file
  case network
  case process
  case ipc
  case mach
  case sysctl
  case system
  case iokit
  case userPreference
  case device
  case other

  /// Human-readable name for the category.
  public var displayName: String {
    switch self {
    case .default: return "Default"
    case .file: return "File"
    case .network: return "Network"
    case .process: return "Process"
    case .ipc: return "IPC"
    case .mach: return "Mach"
    case .sysctl: return "Sysctl"
    case .system: return "System"
    case .iokit: return "I/O Kit"
    case .userPreference: return "User Preferences"
    case .device: return "Device"
    case .other: return "Other"
    }
  }
}
