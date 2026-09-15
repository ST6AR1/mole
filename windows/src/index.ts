// Public surface for the eventual Electron main process to import from.
export { detectProject, type DetectDeps } from "./detect.ts";
export { runProject, type LaunchStage, type RunResult, type RunProjectDeps } from "./run.ts";
export {
  launchProject,
  readLastLogLine,
  launchLogPath,
  posixPathWithCommonBinDirs,
  type LaunchDeps,
} from "./launcher.ts";
export { fetchDevPorts, fetchDevPortsWindows, type DevPortsDeps } from "./devPorts.ts";
export { waitForNewPort, isLikelyNonWebLaunch } from "./poll.ts";
export { stopPort, killAllDevPorts } from "./stop.ts";
export { findExpiredPorts } from "./expiry.ts";
export {
  loadSettings,
  saveSettings,
  togglePersistentPort,
  isPersistentPort,
  DEFAULT_SETTINGS,
  type Settings,
} from "./settings.ts";
export { isDevProcessName } from "./devPatterns.ts";
export type {
  DetectionResult,
  PortInfo,
  Shell,
  SupportedPlatform,
  ExecRaw,
} from "./types.ts";
