// Windows port of `fetchPorts()` in ../App/main.swift: join "what's
// listening" (ports.ts, netstat) with "whose process is that" (processInfo.ts,
// one batched PowerShell call), tag each with isDev, and sort by port —
// same shape and same two-call budget as the macOS lsof+ps version.

import { listListeningPorts } from "./ports.ts";
import { getProcessInfoWindows } from "./processInfo.ts";
import { isDevProcessName } from "./devPatterns.ts";
import type { PortInfo, ExecRaw } from "./types.ts";

export interface DevPortsDeps {
  execRaw?: ExecRaw;
}

/** Every currently-listening TCP port on Windows, with process name/uptime/isDev. */
export function fetchDevPortsWindows(deps: DevPortsDeps = {}): PortInfo[] {
  // Passing `undefined` explicitly still lets each function's own default
  // parameter (the real execFileSync-backed implementation) kick in.
  const listening = listListeningPorts("win32", deps.execRaw);
  if (listening.length === 0) return [];

  const pids = listening.map((l) => l.pid);
  const infoByPid = getProcessInfoWindows(pids, deps.execRaw);

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
