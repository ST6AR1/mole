import { test } from "node:test";
import assert from "node:assert/strict";
import { stopPort, killAllDevPorts } from "../src/stop.ts";
import type { PortInfo } from "../src/types.ts";

function port(overrides: Partial<PortInfo>): PortInfo {
  return { port: 3000, pid: 1, processName: "node", isDev: true, uptimeSeconds: 0, ...overrides };
}

test("stopPort sends a plain (non-forceful) taskkill to the given pid on win32", () => {
  const calls: Array<{ cmd: string; args: string[] }> = [];
  stopPort(14832, "win32", {
    execRaw: (cmd, args) => {
      calls.push({ cmd, args });
      return "";
    },
  });
  assert.deepEqual(calls, [{ cmd: "taskkill.exe", args: ["/PID", "14832"] }]);
});

test("stopPort sends a real SIGTERM directly (no shelling out) on darwin/linux", () => {
  const calls: Array<{ pid: number; signal: string }> = [];
  stopPort(14832, "darwin", { posixKill: (pid, signal) => calls.push({ pid, signal }) });
  assert.deepEqual(calls, [{ pid: 14832, signal: "SIGTERM" }]);
});

test("stopPort swallows the error when the process is already gone (win32)", () => {
  assert.doesNotThrow(() => {
    stopPort(999, "win32", {
      execRaw: () => {
        throw new Error("ERROR: The process with PID 999 could not be found.");
      },
    });
  });
});

test("stopPort swallows the error when the process is already gone (posix, ESRCH)", () => {
  assert.doesNotThrow(() => {
    stopPort(999, "darwin", {
      posixKill: () => {
        throw new Error("kill ESRCH");
      },
    });
  });
});

test("killAllDevPorts stops every dev port except pinned ones, and skips non-dev ports entirely", () => {
  const ports = [
    port({ port: 3000, pid: 1 }),
    port({ port: 4000, pid: 2 }),
    port({ port: 445, pid: 3, isDev: false }),
  ];
  const killed: number[] = [];
  killAllDevPorts(
    ports,
    (p) => p === 4000,
    "win32",
    {
      execRaw: (_cmd, args) => {
        killed.push(Number(args[1]));
        return "";
      },
    },
  );
  assert.deepEqual(killed, [1]);
});

test("killAllDevPorts uses the posix branch on darwin/linux", () => {
  const ports = [port({ port: 3000, pid: 1 })];
  const killed: number[] = [];
  killAllDevPorts(ports, () => false, "darwin", { posixKill: (pid) => killed.push(pid) });
  assert.deepEqual(killed, [1]);
});
