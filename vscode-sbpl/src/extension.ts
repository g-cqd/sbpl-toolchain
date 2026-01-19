import * as vscode from 'vscode';
import { SBPLCompletionProvider } from './completion.js';

let diagnosticCollection: vscode.DiagnosticCollection;

interface SBPLDiagnostic {
  severity: 'error' | 'warning' | 'information' | 'hint';
  message: string;
  range: {
    start: { line: number; column: number };
    end: { line: number; column: number };
  };
  code?: string;
}

export function activate(context: vscode.ExtensionContext): void {
  console.log('SBPL extension activated');

  diagnosticCollection = vscode.languages.createDiagnosticCollection('sbpl');
  context.subscriptions.push(diagnosticCollection);

  // Register completion provider
  const completionProvider = new SBPLCompletionProvider();
  context.subscriptions.push(
    vscode.languages.registerCompletionItemProvider(
      'sbpl',
      completionProvider,
      '(', ' ', '\n' // Trigger on open paren, space, or newline
    )
  );

  // Register document change listener
  context.subscriptions.push(
    vscode.workspace.onDidChangeTextDocument((event) => {
      if (event.document.languageId === 'sbpl') {
        validateDocument(event.document);
      }
    })
  );

  // Register document open listener
  context.subscriptions.push(
    vscode.workspace.onDidOpenTextDocument((document) => {
      if (document.languageId === 'sbpl') {
        validateDocument(document);
      }
    })
  );

  // Register document save listener
  context.subscriptions.push(
    vscode.workspace.onDidSaveTextDocument((document) => {
      if (document.languageId === 'sbpl') {
        validateDocument(document);
      }
    })
  );

  // Validate all open SBPL documents
  for (const document of vscode.workspace.textDocuments) {
    if (document.languageId === 'sbpl') {
      validateDocument(document);
    }
  }

  // Register command to manually check syntax
  context.subscriptions.push(
    vscode.commands.registerCommand('sbpl.checkSyntax', () => {
      const editor = vscode.window.activeTextEditor;
      if (editor && editor.document.languageId === 'sbpl') {
        validateDocument(editor.document);
      }
    })
  );

  // Register command to convert to JSON
  context.subscriptions.push(
    vscode.commands.registerCommand('sbpl.convertToJSON', async () => {
      const editor = vscode.window.activeTextEditor;
      if (editor && editor.document.languageId === 'sbpl') {
        await convertToJSON(editor.document);
      }
    })
  );
}

export function deactivate(): void {
  diagnosticCollection?.dispose();
}

function getExecutablePath(): string {
  const config = vscode.workspace.getConfiguration('sbpl');
  const configuredPath = config.get<string>('executablePath');

  if (configuredPath && configuredPath.length > 0) {
    return configuredPath;
  }

  // Default: look for sbpl-convert in PATH
  return 'sbpl-convert';
}

async function validateDocument(document: vscode.TextDocument): Promise<void> {
  const config = vscode.workspace.getConfiguration('sbpl');
  if (!config.get<boolean>('enableDiagnostics', true)) {
    diagnosticCollection.delete(document.uri);
    return;
  }

  const text = document.getText();
  const execPath = getExecutablePath();

  try {
    const proc = Bun.spawn([execPath, 'check', '-'], {
      stdin: new Blob([text]),
      stdout: 'pipe',
      stderr: 'pipe',
    });

    const [exitCode, stderr] = await Promise.all([
      proc.exited,
      new Response(proc.stderr).text(),
    ]);

    const diagnostics: vscode.Diagnostic[] = [];

    // Parse diagnostics from stderr
    if (stderr) {
      const lines = stderr.trim().split('\n');
      for (const line of lines) {
        if (line.startsWith('{')) {
          try {
            const diag = JSON.parse(line) as SBPLDiagnostic;
            diagnostics.push(convertDiagnostic(diag));
          } catch {
            // Skip malformed JSON
          }
        } else if (line.includes(':')) {
          // Simple format: "line:column: severity: message"
          const match = line.match(/(\d+):(\d+):\s*(error|warning|info|hint):\s*(.+)/);
          if (match) {
            const lineNum = parseInt(match[1], 10) - 1;
            const colNum = parseInt(match[2], 10) - 1;
            const severity = mapSeverity(match[3]);
            const message = match[4];

            diagnostics.push(new vscode.Diagnostic(
              new vscode.Range(lineNum, colNum, lineNum, colNum + 1),
              message,
              severity
            ));
          }
        }
      }
    }

    diagnosticCollection.set(document.uri, diagnostics);
  } catch (error) {
    // If the executable is not found, clear diagnostics silently
    console.warn('sbpl-convert not found. Syntax checking disabled.');
    diagnosticCollection.delete(document.uri);
  }
}

function convertDiagnostic(diag: SBPLDiagnostic): vscode.Diagnostic {
  const range = new vscode.Range(
    diag.range.start.line - 1,
    diag.range.start.column - 1,
    diag.range.end.line - 1,
    diag.range.end.column - 1
  );

  const severity = mapSeverity(diag.severity);
  const diagnostic = new vscode.Diagnostic(range, diag.message, severity);

  if (diag.code) {
    diagnostic.code = diag.code;
  }

  diagnostic.source = 'sbpl';

  return diagnostic;
}

function mapSeverity(severity: string): vscode.DiagnosticSeverity {
  switch (severity.toLowerCase()) {
    case 'error':
      return vscode.DiagnosticSeverity.Error;
    case 'warning':
      return vscode.DiagnosticSeverity.Warning;
    case 'information':
    case 'info':
      return vscode.DiagnosticSeverity.Information;
    case 'hint':
      return vscode.DiagnosticSeverity.Hint;
    default:
      return vscode.DiagnosticSeverity.Error;
  }
}

async function convertToJSON(document: vscode.TextDocument): Promise<void> {
  const text = document.getText();
  const execPath = getExecutablePath();

  try {
    const proc = Bun.spawn([execPath, 'to-json', '-'], {
      stdin: new Blob([text]),
      stdout: 'pipe',
      stderr: 'pipe',
    });

    const [exitCode, stdout, stderr] = await Promise.all([
      proc.exited,
      new Response(proc.stdout).text(),
      new Response(proc.stderr).text(),
    ]);

    if (exitCode === 0 && stdout) {
      // Open a new document with the JSON content
      const jsonDoc = await vscode.workspace.openTextDocument({
        content: stdout,
        language: 'json'
      });
      await vscode.window.showTextDocument(jsonDoc, vscode.ViewColumn.Beside);
    } else {
      vscode.window.showErrorMessage(`Conversion failed: ${stderr || 'Unknown error'}`);
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    vscode.window.showErrorMessage(`Failed to run sbpl-convert: ${message}`);
  }
}
