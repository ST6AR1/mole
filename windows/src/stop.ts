// Windows port of doKill()/killAll() in ../App/main.swift. The macOS app
// sends a single SIGTERM straight to the pid that owns the listening
// socket (as reported by lsof) — not a process-tree kill, and no SIGKILL
// follow-up if the process ignores it. `taskkill /PID <pid>` (no `/F`) is
// the closest Windows equivalent: it asks the process to close (WM_CLOSE /
// CTRL_CLOSE_EVENT) rather than force-terminating it, matching the
// "graceful ask, no tree walk" behavior exactly.
//
// Note this deliberately does NOT add a `/T` (kill process tree) or a `/F`
// (force) that the real app doesn't have either — the pid returned by
// netstat is the actual process bound to the socket (e.g. the real `node`
// or `python` process), not a shell wrapper, so there's normally no
// separate child to worry about.

import { execFileSync } from "node:child_process";
import type { ExecRaw, PortInfo } from "./types.ts";

const realExecRaw: ExecRaw = (cmd, args) => execFileSync(cmd, args, { encoding: "utf8" });

/** Stops the process bound to one port. Swallows the error if it's already gone. */
export function stopPort(pid: number, execRaw: ExecRaw = realExecRaw): void {
  try {
    execRaw("taskkill.exe", ["/PID", String(pid)]);
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
  execRaw: ExecRaw = realExecRaw,
): void {
  for (const info of ports) {
    if (info.isDev && !isPersistent(info.port)) {
      stopPort(info.pid, execRaw);
    }
  }
}
