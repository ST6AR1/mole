// Windows equivalent of the single batched `ps -o pid=,etime=,command= -p
// <all pids>` call in fetchPorts() (../App/main.swift) — netstat tells us
// *which* ports are listening and *which* pid owns each one, but not the
// process's name or how long it's been running, so this is the second half
// of the join.
//
// Uptime is computed *inside* the PowerShell command (`(Get-Date) -
// StartTime`) rather than by shipping a raw timestamp back to Node and
// parsing it here: ConvertTo-Json serializes .NET DateTime differently
// between Windows PowerShell 5.1 (`/Date(169...)/`) and PowerShell 7+ (ISO
// 8601 string), and that's exactly the kind of cross-version footgun that's
// invisible in this sandbox and only bites on a real machine. A plain
// number sidesteps it entirely.

import { execFileSync } from "node:child_process";
import type { ExecRaw } from "./types.ts";

export interface ProcessInfo {
  pid: number;
  name: string;
  uptimeSeconds: number;
}

const realExecRaw: ExecRaw = (cmd, args) => execFileSync(cmd, args, { encoding: "utf8" });

/** Looks up name + uptime for a set of pids in one PowerShell round trip. */
export function getProcessInfoWindows(
  pids: number[],
  execRaw: ExecRaw = realExecRaw,
): Map<number, ProcessInfo> {
  const result = new Map<number, ProcessInfo>();
  const validPids = [...new Set(pids)].filter((p) => Number.isInteger(p) && p > 0);
  if (validPids.length === 0) return result;

  const script =
    `Get-Process -Id ${validPids.join(",")} -ErrorAction SilentlyContinue | ` +
    `Select-Object Id,ProcessName,@{Name='UptimeSeconds';Expression={[int64]((Get-Date) - $_.StartTime).TotalSeconds}} | ` +
    `ConvertTo-Json -Compress`;

  let raw: string;
  try {
    raw = execRaw("powershell.exe", ["-NoProfile", "-NonInteractive", "-Command", script]);
  } catch {
    return result;
  }

  for (const entry of parseProcessInfoJson(raw)) {
    result.set(entry.pid, entry);
  }
  return result;
}

/** Exported for unit testing against captured PowerShell output shapes. */
export function parseProcessInfoJson(raw: string): ProcessInfo[] {
  const trimmed = raw.trim();
  if (!trimmed) return [];

  let parsed: unknown;
  try {
    parsed = JSON.parse(trimmed);
  } catch {
    return [];
  }

  // ConvertTo-Json emits a bare object (not a 1-element array) when the
  // pipeline produced exactly one result — normalize both shapes.
  const items = Array.isArray(parsed) ? parsed : [parsed];

  const results: ProcessInfo[] = [];
  for (const item of items) {
    if (!item || typeof item !== "object") continue;
    const record = item as Record<string, unknown>;
    const pid = typeof record.Id === "number" ? record.Id : NaN;
    const name = typeof record.ProcessName === "string" ? record.ProcessName : "";
    const uptimeSeconds = Number(record.UptimeSeconds);
    if (!Number.isFinite(pid) || pid <= 0 || !name) continue;
    results.push({
      pid,
      name,
      uptimeSeconds: Number.isFinite(uptimeSeconds) && uptimeSeconds >= 0 ? uptimeSeconds : 0,
    });
  }
  return results;
}
