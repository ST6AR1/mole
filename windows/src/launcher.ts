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
import { tmpdir, homedir } from "node:os";
import { join } from "node:path";
import type { DetectionResult } from "./types.ts";

/**
 * A GUI app (unlike a Terminal) doesn't inherit the user's login-shell
 * PATH, so tools installed via nvm/homebrew are often invisible to it.
 * bin/smart-launch.sh handles this by prepending the common install
 * locations itself (see its own comment: "用 AppleScript do shell script
 * 啟動時 PATH 很精簡，補上常見的安裝位置") rather than sourcing the user's
 * shell profile with `bash -l` — profile scripts can be slow, or, as
 * found while smoke-testing this module against a real (if unrelated)
 * broken Homebrew Node install, can simply crash the launch outright by
 * loading something unrelated. This ports that same fixed prepend list.
 */
export function posixPathWithCommonBinDirs(currentPath: string | undefined, home: string = homedir()): string {
  const extra = [`${home}/.local/bin`, "/opt/homebrew/bin", "/usr/local/bin", `${home}/.nvm/current/bin`];
  return [...extra, currentPath ?? ""].filter(Boolean).join(":");
}

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
 *
 * `dirPath` matters even though `runCommand` never mentions it: detect.ts
 * writes every command (plain `"npm run dev"`, or `Set-Location 'sub'; ...`
 * for a monorepo subfolder) as relative to the project directory it was
 * given, on the assumption that the shell is already standing in it. This
 * was caught by actually running a real project through this during
 * development — without `cwd` set, the command runs wherever the app
 * process's own cwd happens to be instead, so `npm run dev` fails with
 * "Missing script" (or worse, silently runs some *other* project's script)
 * instead of the one that was dropped.
 */
export function launchProject(
  result: DetectionResult,
  dirPath: string,
  deps: LaunchDeps = defaultLaunchDeps,
): { logPath: string } {
  const logPath = launchLogPath(deps.tmpDir);
  const logFd = openSync(logPath, "a");

  const [command, args] =
    result.shell === "powershell"
      ? ["powershell.exe", ["-NoProfile", "-Command", result.runCommand]]
      : ["bash", ["-c", result.runCommand]];

  const spawnOptions: SpawnOptions = { detached: true, stdio: ["ignore", logFd, logFd], cwd: dirPath };
  if (result.shell === "bash") {
    spawnOptions.env = { ...process.env, PATH: posixPathWithCommonBinDirs(process.env.PATH) };
  }

  const child = deps.spawn(command, args, spawnOptions);
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
