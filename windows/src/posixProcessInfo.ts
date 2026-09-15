// macOS/Linux counterpart of processInfo.ts, ported from the `ps
// -o pid=,etime=,command= -p <pids>` half of fetchPorts() in
// ../App/main.swift. Exists so the Electron shell (src/electron/) can be
// smoke-tested end-to-end on this dev machine (darwin) even though the
// shipping target is Windows — the same reason ports.ts already supports
// both lsof and netstat.

import { execFileSync } from "node:child_process";
import type { ExecRaw } from "./types.ts";

export interface ProcessInfo {
  pid: number;
  name: string;
  uptimeSeconds: number;
}

const realExecRaw: ExecRaw = (cmd, args) => execFileSync(cmd, args, { encoding: "utf8" });

/**
 * Ported from `uptimeSeconds(fromEtime:)`. `ps`'s `etime=` format is
 * `[[dd-]hh:]mm:ss` — e.g. "05:12", "01:02:03", "3-04:05:06".
 */
export function uptimeFromEtime(raw: string): number {
  const trimmed = raw.trim();
  if (!trimmed) return 0;

  let days = 0;
  let rest = trimmed;
  const dashIndex = trimmed.indexOf("-");
  if (dashIndex !== -1) {
    days = Number.parseInt(trimmed.slice(0, dashIndex), 10) || 0;
    rest = trimmed.slice(dashIndex + 1);
  }

  const parts = rest.split(":").map((p) => Number.parseInt(p, 10) || 0);
  let hours = 0;
  let minutes = 0;
  let seconds = 0;
  if (parts.length === 3) [hours, minutes, seconds] = parts;
  else if (parts.length === 2) [minutes, seconds] = parts;
  else if (parts.length === 1) [seconds] = parts;

  return ((days * 24 + hours) * 60 + minutes) * 60 + seconds;
}

/** Looks up name + uptime for a set of pids in one batched `ps` call. */
export function getProcessInfoPosix(pids: number[], execRaw: ExecRaw = realExecRaw): Map<number, ProcessInfo> {
  const result = new Map<number, ProcessInfo>();
  const validPids = [...new Set(pids)].filter((p) => Number.isInteger(p) && p > 0);
  if (validPids.length === 0) return result;

  let raw: string;
  try {
    raw = execRaw("/bin/ps", ["-o", "pid=,etime=,comm=", "-p", validPids.join(",")]);
  } catch {
    return result;
  }

  for (const line of raw.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed) continue;
    const parts = trimmed.split(/\s+/, 3);
    if (parts.length < 3) continue;
    const pid = Number.parseInt(parts[0], 10);
    if (!Number.isFinite(pid)) continue;
    const uptimeSeconds = uptimeFromEtime(parts[1]);
    // `comm=` prints the full path to the executable; only the basename
    // matters for matching against devPatterns (e.g. "node", not
    // "/usr/local/bin/node").
    const name = parts[2].split("/").pop() ?? parts[2];
    result.set(pid, { pid, name, uptimeSeconds });
  }
  return result;
}
