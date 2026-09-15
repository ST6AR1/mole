// Shared types for the project-type detector. Kept separate from detect.ts
// so the eventual launcher/process-manager module can import just the shape
// without pulling in the detection logic itself.

export type Shell = "powershell" | "bash";

export interface DetectionResult {
  /** Human-readable label shown in the UI, e.g. "Node.js (pnpm)". */
  label: string;
  /** Command to install dependencies first, if needed (run before `run`). */
  installCommand?: string;
  /** The command that actually starts the project. */
  runCommand: string;
  /** Which shell `installCommand`/`runCommand` are written for. */
  shell: Shell;
  /** Non-fatal notes worth surfacing to the user (e.g. "make may not be installed on Windows"). */
  notes?: string[];
}

export type SupportedPlatform = "win32" | "darwin" | "linux";

/**
 * One currently-listening TCP port, joined with enough process metadata to
 * decide whether it's "ours" and how long it's been up. Mirrors the macOS
 * app's `PortInfo` (App/main.swift) so the UI layer can share behavior:
 * `isDev` drives which ports show up in the running list at all, and
 * `uptimeSeconds` drives the auto-close ("expire after N minutes") feature.
 */
export interface PortInfo {
  port: number;
  pid: number;
  processName: string;
  isDev: boolean;
  uptimeSeconds: number;
}

/**
 * The one real side-effecting primitive in the Windows runtime layer: run a
 * command and return its stdout. Every module that shells out (ports.ts,
 * processInfo.ts, stop.ts) takes this as an injectable dependency, the same
 * DI pattern detect.ts uses for `commandExists` — so their parsing logic can
 * be unit tested anywhere by feeding in captured real output, without a
 * Windows machine or a live process to inspect.
 */
export type ExecRaw = (cmd: string, args: string[]) => string;
