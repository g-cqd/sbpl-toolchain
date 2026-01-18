import * as vscode from 'vscode';

// Top-level declaration keywords
const DECLARATIONS: CompletionData[] = [
  { label: 'version', detail: 'Version declaration', doc: 'Declares the sandbox profile version.\n\nExample: `(version 1)`', snippet: '(version ${1:1})' },
  { label: 'debug', detail: 'Debug mode declaration', doc: 'Sets debug mode for the profile.\n\nExample: `(debug deny)`', snippet: '(debug ${1|deny,allow|})' },
  { label: 'import', detail: 'Import declaration', doc: 'Imports another sandbox profile.\n\nExample: `(import "system.sb")`', snippet: '(import "${1:system.sb}")' },
  { label: 'define', detail: 'Define a variable or macro', doc: 'Defines a reusable value or filter.\n\nExample: `(define my-paths (subpath "/usr"))`', snippet: '(define ${1:name} ${2:value})' },
  { label: 'allow', detail: 'Allow rule', doc: 'Allows the specified operations.\n\nExample: `(allow file-read-data (subpath "/usr"))`', snippet: '(allow ${1:operation}\n  ${2:filter})' },
  { label: 'deny', detail: 'Deny rule', doc: 'Denies the specified operations.\n\nExample: `(deny default)`', snippet: '(deny ${1:default})' },
];

// Filter types
const FILTERS: CompletionData[] = [
  // Compound filters
  { label: 'require-all', detail: 'Compound filter (AND)', doc: 'All sub-filters must match.\n\nExample:\n```\n(require-all\n  (subpath "/usr")\n  (extension "com.apple.app-sandbox.read"))\n```', snippet: '(require-all\n  ${1:filter1}\n  ${2:filter2})' },
  { label: 'require-any', detail: 'Compound filter (OR)', doc: 'Any sub-filter must match.\n\nExample:\n```\n(require-any\n  (literal "/a")\n  (literal "/b"))\n```', snippet: '(require-any\n  ${1:filter1}\n  ${2:filter2})' },
  { label: 'require-not', detail: 'Negation filter', doc: 'Negates the sub-filter.\n\nExample: `(require-not (literal "/secret"))`', snippet: '(require-not ${1:filter})' },
  { label: 'require-entitlement', detail: 'Entitlement requirement', doc: 'Requires a specific entitlement.', snippet: '(require-entitlement "${1:entitlement}")' },

  // Path filters
  { label: 'literal', detail: 'Exact path match', doc: 'Matches an exact path.\n\nExample: `(literal "/etc/passwd")`', snippet: '(literal "${1:/path}")' },
  { label: 'subpath', detail: 'Path prefix match', doc: 'Matches a path and all its children.\n\nExample: `(subpath "/usr")`', snippet: '(subpath "${1:/path}")' },
  { label: 'regex', detail: 'Regex path match', doc: 'Matches paths against a regular expression.\n\nExample: `(regex #"^/tmp/.*\\.log$")`', snippet: '(regex #"${1:pattern}")' },
  { label: 'prefix', detail: 'String prefix match', doc: 'Matches if the path starts with the given prefix.', snippet: '(prefix "${1:/path}")' },

  // Home directory filters
  { label: 'home-literal', detail: 'Literal path in home', doc: 'Matches an exact path relative to home directory.', snippet: '(home-literal "${1:/relative/path}")' },
  { label: 'home-subpath', detail: 'Subpath in home', doc: 'Matches a subpath relative to home directory.', snippet: '(home-subpath "${1:/relative/path}")' },
  { label: 'home-regex', detail: 'Regex in home', doc: 'Matches paths in home directory against a regex.', snippet: '(home-regex #"${1:pattern}")' },
  { label: 'home-prefix', detail: 'Prefix in home', doc: 'Matches paths in home directory with given prefix.', snippet: '(home-prefix "${1:/relative/path}")' },

  // Mach/IPC filters
  { label: 'global-name', detail: 'Mach global name', doc: 'Matches a global Mach service name.\n\nExample: `(global-name "com.apple.system.logger")`', snippet: '(global-name "${1:com.apple.service}")' },
  { label: 'local-name', detail: 'Mach local name', doc: 'Matches a local Mach service name.', snippet: '(local-name "${1:service}")' },

  // Extension filters
  { label: 'extension', detail: 'Sandbox extension', doc: 'Matches a sandbox extension.\n\nExample: `(extension "com.apple.app-sandbox.read")`', snippet: '(extension "${1:com.apple.app-sandbox.read}")' },

  // Network filters
  { label: 'remote', detail: 'Remote network filter', doc: 'Matches remote network connections.\n\nExample: `(remote tcp "*:443")`', snippet: '(remote ${1|tcp,udp|} "${2:*:*}")' },
  { label: 'local', detail: 'Local network filter', doc: 'Matches local network bindings.', snippet: '(local ${1|tcp,udp|} "${2:*:*}")' },

  // IOKit filters
  { label: 'iokit-user-client-class', detail: 'IOKit user client class', doc: 'Matches an IOKit user client class name.', snippet: '(iokit-user-client-class "${1:class}")' },
  { label: 'iokit-property', detail: 'IOKit property', doc: 'Matches an IOKit property.', snippet: '(iokit-property "${1:property}")' },
  { label: 'iokit-connection', detail: 'IOKit connection', doc: 'Matches an IOKit connection.', snippet: '(iokit-connection "${1:connection}")' },
  { label: 'iokit-registry-entry-class', detail: 'IOKit registry class', doc: 'Matches an IOKit registry entry class.', snippet: '(iokit-registry-entry-class "${1:class}")' },

  // Process filters
  { label: 'process-attribute', detail: 'Process attribute', doc: 'Matches a process attribute.', snippet: '(process-attribute ${1:attribute})' },
  { label: 'entitlement-value', detail: 'Entitlement value', doc: 'Matches an entitlement value.', snippet: '(entitlement-value "${1:entitlement}" ${2:value})' },

  // Other filters
  { label: 'vnode-type', detail: 'Vnode type filter', doc: 'Matches a vnode type (REGULAR-FILE, DIRECTORY, etc.).', snippet: '(vnode-type ${1|REGULAR-FILE,DIRECTORY,SYMLINK,BLOCK-DEVICE,CHARACTER-DEVICE|})' },
  { label: 'file-mode', detail: 'File mode filter', doc: 'Matches file permission mode.', snippet: '(file-mode ${1:#o0644})' },
  { label: 'socket-domain', detail: 'Socket domain filter', doc: 'Matches socket domain.', snippet: '(socket-domain ${1:AF_INET})' },
  { label: 'socket-type', detail: 'Socket type filter', doc: 'Matches socket type.', snippet: '(socket-type ${1:SOCK_STREAM})' },
  { label: 'socket-protocol', detail: 'Socket protocol filter', doc: 'Matches socket protocol.', snippet: '(socket-protocol ${1:protocol})' },
  { label: 'sysctl-name', detail: 'Sysctl name filter', doc: 'Matches a sysctl name.', snippet: '(sysctl-name "${1:kern.ostype}")' },
  { label: 'device-conforms-to', detail: 'Device class filter', doc: 'Matches device class.', snippet: '(device-conforms-to "${1:class}")' },

  // Modifiers
  { label: 'with', detail: 'Rule modifier', doc: 'Adds modifiers to a rule.\n\nOptions: report, send-signal, no-report, no-sandbox', snippet: '(with ${1|report,send-signal,no-report,no-sandbox|})' },
];

// Sandbox operations
const OPERATIONS: CompletionData[] = [
  // Special
  { label: 'default', detail: 'Default operation', doc: 'Matches all operations not explicitly handled.', category: 'special' },

  // File operations
  { label: 'file-read-data', detail: 'Read file contents', doc: 'Read the contents of a file.', category: 'file' },
  { label: 'file-read-metadata', detail: 'Read file metadata', doc: 'Read file metadata (stat, etc.).', category: 'file' },
  { label: 'file-read-xattr', detail: 'Read extended attributes', doc: 'Read file extended attributes.', category: 'file' },
  { label: 'file-read*', detail: 'All file read operations', doc: 'Matches all file read operations.', category: 'file' },
  { label: 'file-write-data', detail: 'Write file contents', doc: 'Write to file contents.', category: 'file' },
  { label: 'file-write-create', detail: 'Create files', doc: 'Create new files.', category: 'file' },
  { label: 'file-write-unlink', detail: 'Delete files', doc: 'Delete/unlink files.', category: 'file' },
  { label: 'file-write-xattr', detail: 'Write extended attributes', doc: 'Write file extended attributes.', category: 'file' },
  { label: 'file-write-mode', detail: 'Change file mode', doc: 'Change file permissions.', category: 'file' },
  { label: 'file-write-flags', detail: 'Change file flags', doc: 'Change file flags.', category: 'file' },
  { label: 'file-write-owner', detail: 'Change file owner', doc: 'Change file ownership.', category: 'file' },
  { label: 'file-write-times', detail: 'Change file times', doc: 'Modify file timestamps.', category: 'file' },
  { label: 'file-write*', detail: 'All file write operations', doc: 'Matches all file write operations.', category: 'file' },
  { label: 'file-ioctl', detail: 'File ioctl', doc: 'Perform ioctl on files.', category: 'file' },
  { label: 'file-mount', detail: 'Mount filesystems', doc: 'Mount filesystems.', category: 'file' },
  { label: 'file-unmount', detail: 'Unmount filesystems', doc: 'Unmount filesystems.', category: 'file' },
  { label: 'file-chroot', detail: 'Change root', doc: 'Change root directory.', category: 'file' },
  { label: 'file-clone', detail: 'Clone files', doc: 'Clone files (copy-on-write).', category: 'file' },
  { label: 'file-link', detail: 'Create links', doc: 'Create hard/symbolic links.', category: 'file' },
  { label: 'file-map-executable', detail: 'Map executable', doc: 'Memory-map executable files.', category: 'file' },
  { label: 'file-revoke', detail: 'Revoke access', doc: 'Revoke file access.', category: 'file' },
  { label: 'file-search', detail: 'Search directories', doc: 'Search/traverse directories.', category: 'file' },
  { label: 'file-test-existence', detail: 'Test file existence', doc: 'Check if file exists.', category: 'file' },
  { label: 'file-mknod', detail: 'Create device nodes', doc: 'Create device nodes.', category: 'file' },
  { label: 'file-issue-extension', detail: 'Issue file extension', doc: 'Issue sandbox extension for file.', category: 'file' },

  // Mach operations
  { label: 'mach-lookup', detail: 'Mach service lookup', doc: 'Look up a Mach service by name.', category: 'mach' },
  { label: 'mach-register', detail: 'Register Mach service', doc: 'Register a Mach service.', category: 'mach' },
  { label: 'mach-priv', detail: 'Mach privileged operations', doc: 'Privileged Mach operations.', category: 'mach' },
  { label: 'mach-priv-host-port', detail: 'Host port access', doc: 'Access to host port.', category: 'mach' },
  { label: 'mach-priv-task-port', detail: 'Task port access', doc: 'Access to task port.', category: 'mach' },
  { label: 'mach-task-name', detail: 'Task name port', doc: 'Access to task name port.', category: 'mach' },
  { label: 'mach-per-user-lookup', detail: 'Per-user lookup', doc: 'Per-user Mach lookup.', category: 'mach' },
  { label: 'mach-cross-domain-lookup', detail: 'Cross-domain lookup', doc: 'Cross-domain Mach lookup.', category: 'mach' },
  { label: 'mach-host-exception-port-set', detail: 'Host exception port', doc: 'Set host exception port.', category: 'mach' },
  { label: 'mach-host-special-port-set', detail: 'Host special port', doc: 'Set host special port.', category: 'mach' },
  { label: 'mach-issue-extension', detail: 'Issue Mach extension', doc: 'Issue sandbox extension for Mach.', category: 'mach' },

  // IPC operations
  { label: 'ipc-posix-sem', detail: 'POSIX semaphores', doc: 'POSIX semaphore operations.', category: 'ipc' },
  { label: 'ipc-posix-shm', detail: 'POSIX shared memory', doc: 'POSIX shared memory operations.', category: 'ipc' },
  { label: 'ipc-posix-shm-read-data', detail: 'Read shared memory', doc: 'Read from POSIX shared memory.', category: 'ipc' },
  { label: 'ipc-posix-shm-read-metadata', detail: 'Read shm metadata', doc: 'Read POSIX shared memory metadata.', category: 'ipc' },
  { label: 'ipc-posix-shm-write-data', detail: 'Write shared memory', doc: 'Write to POSIX shared memory.', category: 'ipc' },
  { label: 'ipc-posix-shm-write-create', detail: 'Create shared memory', doc: 'Create POSIX shared memory.', category: 'ipc' },
  { label: 'ipc-posix-shm-write-unlink', detail: 'Unlink shared memory', doc: 'Unlink POSIX shared memory.', category: 'ipc' },
  { label: 'ipc-posix-issue-extension', detail: 'Issue IPC extension', doc: 'Issue sandbox extension for IPC.', category: 'ipc' },
  { label: 'ipc-sysv-msg', detail: 'SysV messages', doc: 'System V message queue operations.', category: 'ipc' },
  { label: 'ipc-sysv-sem', detail: 'SysV semaphores', doc: 'System V semaphore operations.', category: 'ipc' },
  { label: 'ipc-sysv-shm', detail: 'SysV shared memory', doc: 'System V shared memory operations.', category: 'ipc' },

  // Network operations
  { label: 'network*', detail: 'All network operations', doc: 'Matches all network operations.', category: 'network' },
  { label: 'network-inbound', detail: 'Inbound connections', doc: 'Accept inbound network connections.', category: 'network' },
  { label: 'network-outbound', detail: 'Outbound connections', doc: 'Make outbound network connections.', category: 'network' },
  { label: 'network-bind', detail: 'Bind to port', doc: 'Bind to network port.', category: 'network' },

  // System operations
  { label: 'sysctl-read', detail: 'Read sysctl', doc: 'Read sysctl values.', category: 'system' },
  { label: 'sysctl-write', detail: 'Write sysctl', doc: 'Write sysctl values.', category: 'system' },
  { label: 'system-debug', detail: 'System debug', doc: 'System debugging operations.', category: 'system' },
  { label: 'system-fcntl', detail: 'System fcntl', doc: 'fcntl operations.', category: 'system' },
  { label: 'system-fsctl', detail: 'System fsctl', doc: 'fsctl operations.', category: 'system' },
  { label: 'system-info', detail: 'System info', doc: 'Access system information.', category: 'system' },
  { label: 'system-socket', detail: 'System socket', doc: 'Socket operations.', category: 'system' },
  { label: 'system-kext-load', detail: 'Load kernel extension', doc: 'Load kernel extensions.', category: 'system' },
  { label: 'system-kext-unload', detail: 'Unload kernel extension', doc: 'Unload kernel extensions.', category: 'system' },
  { label: 'system-kext-query', detail: 'Query kernel extension', doc: 'Query kernel extension info.', category: 'system' },
  { label: 'system-privilege', detail: 'System privilege', doc: 'Privileged system operations.', category: 'system' },
  { label: 'system-reboot', detail: 'System reboot', doc: 'Reboot the system.', category: 'system' },
  { label: 'system-set-time', detail: 'Set system time', doc: 'Modify system time.', category: 'system' },
  { label: 'system-swap', detail: 'System swap', doc: 'Swap operations.', category: 'system' },
  { label: 'system-suspend-resume', detail: 'Suspend/resume', doc: 'System suspend/resume.', category: 'system' },
  { label: 'system-mac-label', detail: 'MAC label', doc: 'MAC label operations.', category: 'system' },

  // IOKit operations
  { label: 'iokit-open', detail: 'Open IOKit', doc: 'Open IOKit connections.', category: 'iokit' },
  { label: 'iokit-open-user-client', detail: 'Open user client', doc: 'Open IOKit user client.', category: 'iokit' },
  { label: 'iokit-set-properties', detail: 'Set IOKit properties', doc: 'Set IOKit properties.', category: 'iokit' },
  { label: 'iokit-get-properties', detail: 'Get IOKit properties', doc: 'Get IOKit properties.', category: 'iokit' },
  { label: 'iokit-issue-extension', detail: 'Issue IOKit extension', doc: 'Issue sandbox extension for IOKit.', category: 'iokit' },

  // Process operations
  { label: 'process-exec', detail: 'Execute process', doc: 'Execute a new process.', category: 'process' },
  { label: 'process-exec*', detail: 'All exec operations', doc: 'All process execution operations.', category: 'process' },
  { label: 'process-fork', detail: 'Fork process', doc: 'Fork a new process.', category: 'process' },
  { label: 'process-info', detail: 'Process info', doc: 'Access process information.', category: 'process' },
  { label: 'process-info*', detail: 'All process info', doc: 'All process info operations.', category: 'process' },
  { label: 'process-info-codesignature', detail: 'Code signature info', doc: 'Access code signature info.', category: 'process' },
  { label: 'process-info-pidinfo', detail: 'PID info', doc: 'Access PID information.', category: 'process' },
  { label: 'process-info-listpids', detail: 'List PIDs', doc: 'List process IDs.', category: 'process' },
  { label: 'process-codesigning-status', detail: 'Codesigning status', doc: 'Check codesigning status.', category: 'process' },
  { label: 'signal', detail: 'Send signals', doc: 'Send signals to processes.', category: 'process' },

  // User operations
  { label: 'user-preference-read', detail: 'Read preferences', doc: 'Read user preferences.', category: 'user' },
  { label: 'user-preference-write', detail: 'Write preferences', doc: 'Write user preferences.', category: 'user' },

  // Device operations
  { label: 'device-camera', detail: 'Camera access', doc: 'Access camera device.', category: 'device' },
  { label: 'device-microphone', detail: 'Microphone access', doc: 'Access microphone device.', category: 'device' },
  { label: 'hid-control', detail: 'HID control', doc: 'Control HID devices.', category: 'device' },
  { label: 'pseudo-tty', detail: 'Pseudo TTY', doc: 'Pseudo-terminal operations.', category: 'device' },

  // Other operations
  { label: 'appleevent-send', detail: 'Send AppleEvents', doc: 'Send AppleEvents.', category: 'other' },
  { label: 'lsopen', detail: 'Launch Services open', doc: 'Open via Launch Services.', category: 'other' },
  { label: 'authorization-right-obtain', detail: 'Obtain auth rights', doc: 'Obtain authorization rights.', category: 'other' },
  { label: 'darwin-notification', detail: 'Darwin notifications', doc: 'Darwin notification operations.', category: 'other' },
  { label: 'distributed-notification-post', detail: 'Post notifications', doc: 'Post distributed notifications.', category: 'other' },
  { label: 'job-creation', detail: 'Create jobs', doc: 'Create launchd jobs.', category: 'other' },
  { label: 'nvram-get', detail: 'Get NVRAM', doc: 'Read NVRAM values.', category: 'other' },
  { label: 'nvram-set', detail: 'Set NVRAM', doc: 'Write NVRAM values.', category: 'other' },
  { label: 'nvram-delete', detail: 'Delete NVRAM', doc: 'Delete NVRAM values.', category: 'other' },
  { label: 'nvram*', detail: 'All NVRAM operations', doc: 'All NVRAM operations.', category: 'other' },
  { label: 'storage-class-map', detail: 'Storage class map', doc: 'Map storage classes.', category: 'other' },

  // Filesystem operations
  { label: 'fs-quota', detail: 'Filesystem quota', doc: 'Filesystem quota operations.', category: 'fs' },
  { label: 'fs-rename', detail: 'Rename files', doc: 'Rename files/directories.', category: 'fs' },
  { label: 'fs-snapshot', detail: 'Filesystem snapshot', doc: 'Filesystem snapshot operations.', category: 'fs' },
  { label: 'fs-snapshot-create', detail: 'Create snapshot', doc: 'Create filesystem snapshot.', category: 'fs' },
  { label: 'fs-snapshot-delete', detail: 'Delete snapshot', doc: 'Delete filesystem snapshot.', category: 'fs' },
  { label: 'fs-snapshot-mount', detail: 'Mount snapshot', doc: 'Mount filesystem snapshot.', category: 'fs' },
  { label: 'fs-snapshot-rename', detail: 'Rename snapshot', doc: 'Rename filesystem snapshot.', category: 'fs' },
  { label: 'fs-snapshot-revert', detail: 'Revert snapshot', doc: 'Revert to filesystem snapshot.', category: 'fs' },
];

// Boolean values
const BOOLEANS: CompletionData[] = [
  { label: '#t', detail: 'Boolean true', doc: 'True value' },
  { label: '#true', detail: 'Boolean true', doc: 'True value (alternative syntax)' },
  { label: '#f', detail: 'Boolean false', doc: 'False value' },
  { label: '#false', detail: 'Boolean false', doc: 'False value (alternative syntax)' },
];

interface CompletionData {
  label: string;
  detail: string;
  doc: string;
  snippet?: string;
  category?: string;
}

function createCompletionItem(data: CompletionData, kind: vscode.CompletionItemKind): vscode.CompletionItem {
  const item = new vscode.CompletionItem(data.label, kind);
  item.detail = data.detail;
  item.documentation = new vscode.MarkdownString(data.doc);

  if (data.snippet) {
    item.insertText = new vscode.SnippetString(data.snippet);
  }

  return item;
}

export class SBPLCompletionProvider implements vscode.CompletionItemProvider {
  provideCompletionItems(
    document: vscode.TextDocument,
    position: vscode.Position,
    _token: vscode.CancellationToken,
    _context: vscode.CompletionContext
  ): vscode.CompletionItem[] {
    const lineText = document.lineAt(position).text;
    const linePrefix = lineText.substring(0, position.character);
    const items: vscode.CompletionItem[] = [];

    // Determine context based on what's before the cursor
    const context = this.determineContext(document, position, linePrefix);

    switch (context) {
      case 'top-level':
        // At start of line or after open paren - suggest declarations
        for (const decl of DECLARATIONS) {
          items.push(createCompletionItem(decl, vscode.CompletionItemKind.Keyword));
        }
        break;

      case 'after-action':
        // After allow/deny - suggest operations
        for (const op of OPERATIONS) {
          const item = createCompletionItem(op, vscode.CompletionItemKind.Function);
          if (op.category) {
            item.sortText = op.category + op.label;
          }
          items.push(item);
        }
        break;

      case 'filter':
        // Inside a filter context - suggest filters
        for (const filter of FILTERS) {
          items.push(createCompletionItem(filter, vscode.CompletionItemKind.Method));
        }
        break;

      case 'value':
        // Suggest booleans and potential variable references
        for (const bool of BOOLEANS) {
          items.push(createCompletionItem(bool, vscode.CompletionItemKind.Constant));
        }
        break;

      default:
        // Unknown context - suggest everything relevant
        for (const decl of DECLARATIONS) {
          items.push(createCompletionItem(decl, vscode.CompletionItemKind.Keyword));
        }
        for (const filter of FILTERS) {
          items.push(createCompletionItem(filter, vscode.CompletionItemKind.Method));
        }
        for (const op of OPERATIONS) {
          items.push(createCompletionItem(op, vscode.CompletionItemKind.Function));
        }
        for (const bool of BOOLEANS) {
          items.push(createCompletionItem(bool, vscode.CompletionItemKind.Constant));
        }
    }

    return items;
  }

  private determineContext(
    document: vscode.TextDocument,
    position: vscode.Position,
    linePrefix: string
  ): 'top-level' | 'after-action' | 'filter' | 'value' | 'unknown' {
    // Count open parens to understand nesting
    const textUpToCursor = document.getText(new vscode.Range(0, 0, position.line, position.character));

    // Simple check: if we just typed ( at beginning or after whitespace
    if (/^\s*\($/.test(linePrefix) || /\(\s*$/.test(linePrefix)) {
      // Count nesting level
      const openParens = (textUpToCursor.match(/\(/g) || []).length;
      const closeParens = (textUpToCursor.match(/\)/g) || []).length;
      const nestingLevel = openParens - closeParens;

      if (nestingLevel <= 1) {
        return 'top-level';
      } else {
        return 'filter';
      }
    }

    // Check if we're right after 'allow' or 'deny'
    if (/\(\s*(allow|deny)\s+$/.test(linePrefix) || /\(\s*(allow|deny)\s+[\w*-]*$/.test(linePrefix)) {
      return 'after-action';
    }

    // Check if we're inside a rule (after allow/deny and operations)
    // Look back for the most recent opening construct
    const recentContext = linePrefix.match(/\(\s*(require-all|require-any|require-not|literal|subpath|regex|prefix|global-name|local-name|extension)/);
    if (recentContext) {
      return 'value';
    }

    // Check if we're likely in a filter position
    const lines = textUpToCursor.split('\n');
    for (let i = lines.length - 1; i >= 0; i--) {
      if (/\(\s*(allow|deny)\s+/.test(lines[i])) {
        return 'filter';
      }
      if (/\(\s*(version|debug|import|define)\s+/.test(lines[i])) {
        return 'value';
      }
    }

    return 'unknown';
  }
}

// Export a function to get all operations (for potential future use)
export function getAllOperations(): string[] {
  return OPERATIONS.map(op => op.label);
}

// Export a function to get all filters (for potential future use)
export function getAllFilters(): string[] {
  return FILTERS.map(f => f.label);
}
