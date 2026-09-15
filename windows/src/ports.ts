// Cross-platform "what TCP ports are listening right now" — the piece the
// launcher polls after starting a process to notice a dev server has come
// up. macOS's smart-launch.sh presumably shells out to `lsof`; Windows has
// no such tool, so this uses `netstat -ano` there instead.
//
// The actual OS call is isolated behind `execRaw` (defaults to the real
// `execFileSync`) so the *parsers* — the part that's actually easy to get
// subtly wrong (column offsets, state names, IPv6 formatting) — can be unit
// tested with real captured `netstat`/`lsof` output, on any machine,
// without needing the other OS to run the test.

import { execFileSync } from "node:child_process";
import type { SupportedPlatform, ExecRaw } from "./types.ts";

export type { ExecRaw } from "./types.ts";

export interface ListeningPort {
  port: number;
  pid: number;
}

const realExecRaw: ExecRaw = (cmd, args) => execFileSync(cmd, args, { encoding: "utf8" });

/** Every port currently in LISTEN state, with the PID that owns it. */
export function listListeningPorts(
  platform: SupportedPlatform = process.platform as SupportedPlatform,
  execRaw: ExecRaw = realExecRaw,
): ListeningPort[] {
  if (platform === "win32") {
    let raw: string;
    try {
      raw = execRaw("netstat.exe", ["-ano", "-p", "TCP"]);
    } catch {
      return [];
    }
    return parseNetstatWindows(raw);
  }

  let raw: string;
  try {
    raw = execRaw("lsof", ["-nP", "-iTCP", "-sTCP:LISTEN"]);
  } catch {
    return [];
  }
  return parseLsof(raw);
}

/**
 * Parses `netstat -ano -p TCP` output. Typical line:
 *   "  TCP    0.0.0.0:5173           0.0.0.0:0              LISTENING       12345"
 * IPv6 lines look like "  TCP    [::]:5173              [::]:0                 LISTENING       12345"
 * — the port is still the number right before the last `]`-or-`:`.
 */
export function parseNetstatWindows(raw: string): ListeningPort[] {
  const results: ListeningPort[] = [];
  for (const line of raw.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed.startsWith("TCP")) continue;

    const cols = trimmed.split(/\s+/); // ["TCP", localAddr, foreignAddr, "LISTENING", pid]
    if (cols.length < 5) continue;
    if (cols[cols.length - 2] !== "LISTENING") continue;
    const localAddr = cols[1];
    const pidStr = cols[cols.length - 1];
    const pid = Number.parseInt(pidStr, 10);
    if (!Number.isFinite(pid)) continue;

    const port = extractPort(localAddr);
    if (port === null) continue;

    results.push({ port, pid });
  }
  return results;
}

/**
 * Parses `lsof -nP -iTCP -sTCP:LISTEN` output. Typical line:
 *   "node      1234 wen   23u  IPv4 0x...      0t0  TCP *:5173 (LISTEN)"
 */
export function parseLsof(raw: string): ListeningPort[] {
  const results: ListeningPort[] = [];
  const lines = raw.split(/\r?\n/).slice(1); // header row: COMMAND PID USER FD TYPE ...
  for (const line of lines) {
    const cols = line.trim().split(/\s+/);
    if (cols.length < 9) continue;
    const pid = Number.parseInt(cols[1], 10);
    if (!Number.isFinite(pid)) continue;
    // The "NAME" column (last one before "(LISTEN)") looks like "*:5173" or "127.0.0.1:5173".
    const nameCol = cols.find((c) => /:\d+$/.test(c) && c !== cols[1]);
    if (!nameCol) continue;
    const port = extractPort(nameCol);
    if (port === null) continue;
    results.push({ port, pid });
  }
  return results;
}

function extractPort(address: string): number | null {
  const match = address.match(/:(\d+)$/);
  if (!match) return null;
  const port = Number.parseInt(match[1], 10);
  return Number.isFinite(port) ? port : null;
}
