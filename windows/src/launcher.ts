// Windows port of launchProject() + lastLogLine() in ../App/main.swift.
//
// The mac app doesn't track the launched process's pid at all — it fires
// smart-launch.sh detached, and later finds the *real* dev-server pid by
// noticing a new listening port (see poll.ts) and reading that port's owner
// from lsof. This mirrors that: fire the detected `runCommand` detached in
// the right shell, redirect its output to a fixed log path, and let the
// port-polling step in poll.ts discover what actually ended up running.
// There is deliberately no "wait for exit" or pid bookkeeping here.

import { spawn, type ChildProcess, type SpawnOptions } from "node:child_process";
import { openSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { DetectionResult } from "./types.ts";

/** Matches the mac app's fixed `/tmp/smartlaunch-latest.log`. */
export function launchLogPath(tmpDirFn: () => string = tmpdir): string {
  return join(tmpDirFn(), "mole-launch-latest.log");
}

export type SpawnFn = (command: string, args: string[], options: SpawnOptions) => ChildProcess;

export interface LaunchDeps {
  spawn: SpawnFn;
  tmpDir: () => string;
}

const defaultLaunchDeps: LaunchDeps = { spawn, tmpDir: tmpdir };

/**
 * Fires `result.runCommand` (which already includes any install step —
 * see detect.ts) detached, in the shell it was written for, with output
 * appended to the shared launch log. Returns immediately; nothing here
 * waits for the server to actually come up — that's poll.ts's job.
 */
export function launchProject(result: DetectionResult, deps: LaunchDeps = defaultLaunchDeps): { logPath: string } {
  const logPath = launchLogPath(deps.tmpDir);
  const logFd = openSync(logPath, "a");

  const [command, args] =
    result.shell === "powershell"
      ? ["powershell.exe", ["-NoProfile", "-Command", result.runCommand]]
      : ["bash", ["-lc", result.runCommand]];

  const child = deps.spawn(command, args, {
    detached: true,
    stdio: ["ignore", logFd, logFd],
  });
  child.unref();

  return { logPath };
}

/** Pure string half of lastLogLine() — the part actually worth unit testing. */
export function lastNonEmptyLine(content: string, maxLength = 70): string {
  const lines = content.split(/\r?\n/).map((l) => l.trim()).filter((l) => l.length > 0);
  const last = lines.at(-1) ?? "";
  return last.length > maxLength ? last.slice(-maxLength) : last;
}

/** Reads the shared launch log and returns its last non-empty line, or "" if unreadable. */
export function readLastLogLine(logPath: string = launchLogPath()): string {
  try {
    return lastNonEmptyLine(readFileSync(logPath, "utf8"));
  } catch {
    return "";
  }
}
