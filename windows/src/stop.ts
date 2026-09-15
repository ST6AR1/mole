// Port of doKill()/killAll() in ../App/main.swift. The macOS app sends a
// single SIGTERM straight to the pid that owns the listening socket (as
// reported by lsof) — not a process-tree kill, and no SIGKILL follow-up if
// the process ignores it.
//
// Windows has no SIGTERM, so `taskkill /PID <pid>` (no `/F`) is the closest
// equivalent there: it asks the process to close (WM_CLOSE / CTRL_CLOSE_EVENT)
// rather than force-terminating it, matching the "graceful ask, no tree
// walk" behavior. Elsewhere (macOS/Linux — kept so this module can be
// exercised for real while developing without a Windows machine, per
// devPorts.ts's same reasoning) this sends the actual SIGTERM directly via
// Node's `process.kill`, which is the exact syscall the Swift app makes —
// no need to shell out to `/bin/kill` for that.
//
// Neither branch adds a `/T`/tree-kill that the real app doesn't have
// either — the pid netstat/lsof reports is the actual process bound to the
// socket (e.g. the real `node` or `python` process), not a shell wrapper,
// so there's normally no separate child to worry about.

import { execFileSync } from "node:child_process";
import type { ExecRaw, PortInfo, SupportedPlatform } from "./types.ts";

const realExecRaw: ExecRaw = (cmd, args) => execFileSync(cmd, args, { encoding: "utf8" });

export type PosixKillFn = (pid: number, signal: NodeJS.Signals) => void;
const realPosixKill: PosixKillFn = (pid, signal) => process.kill(pid, signal);

export interface StopDeps {
  execRaw?: ExecRaw;
  posixKill?: PosixKillFn;
}

/** Stops the process bound to one port. Swallows the error if it's already gone. */
export function stopPort(
  pid: number,
  platform: SupportedPlatform = process.platform as SupportedPlatform,
  deps: StopDeps = {},
): void {
  const execRaw = deps.execRaw ?? realExecRaw;
  const posixKill = deps.posixKill ?? realPosixKill;
  try {
    if (platform === "win32") {
      execRaw("taskkill.exe", ["/PID", String(pid)]);
    } else {
      posixKill(pid, "SIGTERM");
    }
  } catch {
    // Already exited, or refused to close — mirrors the mac app's fire-and-forget kill().
  }
}

/**
 * Stops every dev port except the ones the user pinned ("persistent"),
 * mirroring killAll()'s `devPorts.filter { !isPersistent($0.port) }`.
 */
export function killAllDevPorts(
  ports: PortInfo[],
  isPersistent: (port: number) => boolean,
  platform: SupportedPlatform = process.platform as SupportedPlatform,
  deps: StopDeps = {},
): void {
  for (const info of ports) {
    if (info.isDev && !isPersistent(info.port)) {
      stopPort(info.pid, platform, deps);
    }
  }
}
