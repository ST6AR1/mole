// Windows port of pollForNewServer() + isLikelyNonWebLaunch() in
// ../App/main.swift.
//
// One structural simplification vs. the mac app: main.swift and
// smart-launch.sh are two separate processes, so it round-trips the
// detected label through a file (/tmp/smartlaunch-last-label.txt) to know
// whether the thing it just launched even opens a web port. Here,
// detect.ts and this module run in the same Node process, so the caller
// just has the DetectionResult already — no file needed.

import type { DetectionResult, PortInfo } from "./types.ts";

/** Labels that never open a localhost port, so polling for one would just burn the full timeout. */
const NON_WEB_LABEL_HINTS = ["Flutter", "Chrome 擴充功能"];

export function isLikelyNonWebLaunch(result: Pick<DetectionResult, "label">): boolean {
  return NON_WEB_LABEL_HINTS.some((hint) => result.label.includes(hint));
}

export interface WaitForNewPortOptions {
  /** Matches the mac app's `pollMaxAttempts = 150` (~150 one-second polls). */
  maxAttempts?: number;
  /** Called once per poll with the elapsed attempt count, e.g. to drive a "waiting… (12s)" label. */
  onTick?: (elapsed: number) => void;
}

export interface WaitForNewPortDeps {
  fetchDevPorts: () => PortInfo[];
  sleep: (ms: number) => Promise<void>;
}

const defaultSleep = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));

/**
 * Polls once a second for a dev port that wasn't in `before`, up to
 * `maxAttempts` times. Mirrors pollForNewServer()'s exact loop shape
 * (sleep first, then check) so a caller cancelling between polls behaves
 * the same way the mac app's `pollToken` cancellation does.
 */
export async function waitForNewPort(
  before: ReadonlySet<number>,
  options: WaitForNewPortOptions = {},
  deps: WaitForNewPortDeps,
): Promise<PortInfo | null> {
  const maxAttempts = options.maxAttempts ?? 150;

  for (let attemptsLeft = maxAttempts; attemptsLeft > 0; attemptsLeft--) {
    await deps.sleep(1000);

    const elapsed = maxAttempts - attemptsLeft + 1;
    options.onTick?.(elapsed);

    const current = deps.fetchDevPorts().filter((p) => p.isDev);
    const newOne = current.find((p) => !before.has(p.port));
    if (newOne) return newOne;
  }

  return null;
}

export { defaultSleep };
