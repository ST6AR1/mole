// Cross-platform port of `fetchPorts()` in ../App/main.swift: join "what's
// listening" (ports.ts: netstat on win32, lsof elsewhere) with "whose
// process is that" (processInfo.ts's batched PowerShell call on win32,
// posixProcessInfo.ts's batched `ps` call elsewhere), tag each with isDev,
// and sort by port — same shape and same two-call budget as the original.
//
// Windows is the shipping target, but this stays cross-platform so the
// Electron shell (src/electron/) can be smoke-tested end-to-end on a
// darwin dev machine — the same reasoning ports.ts already followed.

import { listListeningPorts } from "./ports.ts";
import { getProcessInfoWindows } from "./processInfo.ts";
import { getProcessInfoPosix } from "./posixProcessInfo.ts";
import { isDevProcessName } from "./devPatterns.ts";
import type { PortInfo, ExecRaw, SupportedPlatform } from "./types.ts";

export interface DevPortsDeps {
  execRaw?: ExecRaw;
}

/** Every currently-listening TCP port, with process name/uptime/isDev joined in. */
export function fetchDevPorts(
  platform: SupportedPlatform = process.platform as SupportedPlatform,
  deps: DevPortsDeps = {},
): PortInfo[] {
  // Passing `undefined` explicitly still lets each function's own default
  // parameter (the real execFileSync-backed implementation) kick in.
  const listening = listListeningPorts(platform, deps.execRaw);
  if (listening.length === 0) return [];

  const pids = listening.map((l) => l.pid);
  const infoByPid =
    platform === "win32" ? getProcessInfoWindows(pids, deps.execRaw) : getProcessInfoPosix(pids, deps.execRaw);

  const seen = new Set<string>();
  const results: PortInfo[] = [];
  for (const { port, pid } of listening) {
    const key = `${port}-${pid}`;
    if (seen.has(key)) continue;
    seen.add(key);

    const info = infoByPid.get(pid);
    const processName = info?.name ?? "";
    results.push({
      port,
      pid,
      processName,
      isDev: isDevProcessName(processName),
      uptimeSeconds: info?.uptimeSeconds ?? 0,
    });
  }

  return results.sort((a, b) => a.port - b.port);
}

/** @deprecated use fetchDevPorts("win32", deps) — kept for callers/tests written against phase 2. */
export function fetchDevPortsWindows(deps: DevPortsDeps = {}): PortInfo[] {
  return fetchDevPorts("win32", deps);
}
