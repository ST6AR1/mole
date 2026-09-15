// Orchestrator that wires detect.ts -> launcher.ts -> poll.ts together,
// mirroring launchAndAutoOpen() in ../App/main.swift step for step:
// detect -> snapshot current dev ports ("before") -> launch -> (skip
// waiting for non-web launches like Flutter) -> poll for a new port ->
// hand the caller the port to open a browser on.
//
// This intentionally has no knowledge of Electron, a UI, or localized
// strings — it reports progress through `onStage` as plain, translatable-
// key-shaped stage objects, so the eventual Electron main process (phase 3,
// not built yet) can map each one to whatever UI text it wants, the same
// way main.swift maps its stages to `t("loading.xxx")` calls.

import { detectProject, type DetectDeps } from "./detect.ts";
import { launchProject, readLastLogLine, type LaunchDeps } from "./launcher.ts";
import { waitForNewPort, isLikelyNonWebLaunch } from "./poll.ts";
import type { DetectionResult, PortInfo, SupportedPlatform } from "./types.ts";

export type LaunchStage =
  | { stage: "detecting" }
  | { stage: "unrecognized" }
  | { stage: "preparing" }
  | { stage: "starting-server" }
  | { stage: "opened-non-web" }
  | { stage: "waiting-localhost"; elapsedSeconds: number; lastLogLine: string }
  | { stage: "no-port-found" }
  | { stage: "ready"; port: number };

export type RunResult =
  | { ok: true; result: DetectionResult; port: number | null }
  | { ok: false; reason: "unrecognized" | "no-port-found"; result?: DetectionResult };

export interface RunProjectDeps {
  platform?: SupportedPlatform;
  detectDeps?: DetectDeps;
  launchDeps?: LaunchDeps;
  fetchDevPorts: () => PortInfo[];
  sleep: (ms: number) => Promise<void>;
  maxAttempts?: number;
  /** Called once a port is confirmed up, e.g. to open it in the default browser. Optional for callers that only care about the result. */
  onPortReady?: (port: number) => void;
}

/** Runs the full detect -> launch -> wait-for-port flow for one folder. */
export async function runProject(
  dir: string,
  onStage: (stage: LaunchStage) => void,
  deps: RunProjectDeps,
): Promise<RunResult> {
  onStage({ stage: "detecting" });
  const result = detectProject(dir, deps.platform, deps.detectDeps);
  if (!result) {
    onStage({ stage: "unrecognized" });
    return { ok: false, reason: "unrecognized" };
  }

  onStage({ stage: "preparing" });
  const before = new Set(
    deps.fetchDevPorts().filter((p) => p.isDev).map((p) => p.port),
  );

  onStage({ stage: "starting-server" });
  launchProject(result, deps.launchDeps);

  if (isLikelyNonWebLaunch(result)) {
    onStage({ stage: "opened-non-web" });
    return { ok: true, result, port: null };
  }

  onStage({ stage: "waiting-localhost", elapsedSeconds: 0, lastLogLine: readLastLogLine() });

  const newPort = await waitForNewPort(
    before,
    {
      maxAttempts: deps.maxAttempts,
      onTick: (elapsed) => {
        onStage({ stage: "waiting-localhost", elapsedSeconds: elapsed, lastLogLine: readLastLogLine() });
      },
    },
    { fetchDevPorts: deps.fetchDevPorts, sleep: deps.sleep },
  );

  if (!newPort) {
    onStage({ stage: "no-port-found" });
    return { ok: false, reason: "no-port-found", result };
  }

  deps.onPortReady?.(newPort.port);
  onStage({ stage: "ready", port: newPort.port });
  return { ok: true, result, port: newPort.port };
}
