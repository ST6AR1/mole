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
